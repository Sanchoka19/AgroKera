import prisma from "../../lib/prisma.ts";
import { Role, VerificationStatus } from "@prisma/client";
import nodemailer from "nodemailer";
import {
  jsonResponse,
  errorResponse,
  createAuthToken,
  hashPassword,
  verifyPassword,
} from "../utils.ts";

const otpStore = new Map<string, { code: string; expiresAt: number }>();
const otpRateLimitMap = new Map<string, { lastSentAt: number; count: number }>();

export async function handleAuthRoute(
  request: Request,
  url: URL,
  path: string,
  method: string
): Promise<Response | null> {
  // POST /api/auth/send-otp
  if (method === "POST" && path === "/api/auth/send-otp") {
    const body = (await request.json()) as { email?: string };
    const targetEmail = (body.email || "").trim().toLowerCase();
    if (!targetEmail || !targetEmail.includes("@")) {
      return errorResponse("გთხოვთ მიუთითოთ სწორი ელ-ფოსტა", 400);
    }

    // Rate Limiting Guard: 60s cooldown, max 5 attempts in 15 minutes
    const now = Date.now();
    const rateLimit = otpRateLimitMap.get(targetEmail);
    if (rateLimit) {
      if (now - rateLimit.lastSentAt < 60 * 1000) {
        const waitSec = Math.ceil((60 * 1000 - (now - rateLimit.lastSentAt)) / 1000);
        return errorResponse(`გთხოვთ მოიცადოთ ${waitSec} წამი ახალი კოდის მოთხოვნამდე`, 429);
      }
      if (rateLimit.count >= 5 && now - rateLimit.lastSentAt < 15 * 60 * 1000) {
        return errorResponse("ძალიან ბევრი მცდელობა. გთხოვთ სცადოთ 15 წუთის შემდეგ", 429);
      }
      otpRateLimitMap.set(targetEmail, {
        lastSentAt: now,
        count: now - rateLimit.lastSentAt > 15 * 60 * 1000 ? 1 : rateLimit.count + 1,
      });
    } else {
      otpRateLimitMap.set(targetEmail, { lastSentAt: now, count: 1 });
    }

    const code = String(Math.floor(10000 + Math.random() * 90000));
    const expiresAt = new Date(Date.now() + 9 * 60 * 1000);
    try {
      await prisma.otpCode.upsert({
        where: { email: targetEmail },
        create: {
          email: targetEmail,
          code,
          expiresAt,
        },
        update: {
          code,
          expiresAt,
        },
      });
    } catch (dbErr) {
      console.error("[OTP DB Error]:", dbErr);
    }
    otpStore.set(targetEmail, {
      code,
      expiresAt: expiresAt.getTime(),
    });

    const brevoApiKey = (process.env.BREVO_API_KEY || "").trim();
    const brevoSender = (process.env.BREVO_SENDER_EMAIL || process.env.SMTP_USER || "sabaevgenidze0919@gmail.com").trim();

    // 1. Prioritize Brevo HTTPS REST API (100% allowed on Render Free Tier via Port 443)
    if (brevoApiKey) {
      try {
        const brevoRes = await fetch("https://api.brevo.com/v3/smtp/email", {
          method: "POST",
          headers: {
            "accept": "application/json",
            "api-key": brevoApiKey,
            "content-type": "application/json",
          },
          body: JSON.stringify({
            sender: {
              name: "AgroKera ვერიფიკაცია",
              email: brevoSender,
            },
            to: [{ email: targetEmail }],
            subject: `AgroKera — თქვენი ვერიფიკაციის კოდია: ${code}`,
            htmlContent: `
              <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 16px;">
                <h2 style="color: #0f766e; margin-top: 0;">AgroKera ვერიფიკაცია</h2>
                <p style="color: #334155; font-size: 15px;">თქვენი 5-ნიშნა დადასტურების კოდია:</p>
                <div style="font-size: 32px; font-weight: 800; letter-spacing: 6px; color: #0f172a; background: #f8fafc; padding: 16px; text-align: center; border-radius: 12px; margin: 16px 0;">
                  ${code}
                </div>
                <p style="color: #64748b; font-size: 13px;">კოდი აქტიურია 9 წუთის განმავლობაში.</p>
              </div>
            `,
          }),
        });

        if (brevoRes.ok) {
          return jsonResponse({
            sent: true,
            email: targetEmail,
            delivery: "brevo_https",
          });
        } else {
          const errData = await brevoRes.json().catch(() => ({}));
          console.error("[Brevo API Error]:", errData);
        }
      } catch (brevoErr) {
        console.error("[Brevo Exception]:", brevoErr);
      }
    }

    const smtpUser = (process.env.SMTP_USER || "").trim();
    const smtpPass = (process.env.SMTP_PASS || "").replace(/\s+/g, "");

    if (smtpUser && smtpPass && smtpUser !== "your_email@gmail.com") {
      try {
        const transporter = nodemailer.createTransport({
          service: "gmail",
          auth: {
            user: smtpUser,
            pass: smtpPass,
          },
        });

        await transporter.sendMail({
          from: `"AgroKera ვერიფიკაცია" <${smtpUser}>`,
          to: targetEmail,
          subject: `AgroKera — თქვენი ვერიფიკაციის კოდია: ${code}`,
          html: `
            <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 16px;">
              <h2 style="color: #0f766e; margin-top: 0;">AgroKera ვერიფიკაცია</h2>
              <p style="color: #334155; font-size: 15px;">თქვენი 5-ნიშნა დადასტურების კოდია:</p>
              <div style="font-size: 32px; font-weight: 800; letter-spacing: 6px; color: #0f172a; background: #f8fafc; padding: 16px; text-align: center; border-radius: 12px; margin: 16px 0;">
                ${code}
              </div>
              <p style="color: #64748b; font-size: 13px;">კოდი აქტიურია 9 წუთის განმავლობაში.</p>
            </div>
          `,
        });

        return jsonResponse({
          sent: true,
          email: targetEmail,
          delivery: "gmail_smtp",
        });
      } catch (smtpErr) {
        console.error("[SMTP Delivery Error]:", smtpErr);
      }
    }

    console.log(`[AgroKera OTP Demo] Code for ${targetEmail}: ${code}`);
    return jsonResponse({
      sent: true,
      email: targetEmail,
      delivery: "console_fallback",
    });
  }

  // POST /api/auth/verify-otp
  if (method === "POST" && path === "/api/auth/verify-otp") {
    const body = (await request.json()) as { email?: string; code?: string };
    const targetEmail = (body.email || "").trim().toLowerCase();
    const inputCode = (body.code || "").trim();

    let dbOtp = null;
    try {
      dbOtp = await prisma.otpCode.findUnique({
        where: { email: targetEmail },
      });
    } catch (_) {}

    const memoryOtp = otpStore.get(targetEmail);
    const validCode = dbOtp?.code || memoryOtp?.code;
    const expiresAtMs = dbOtp ? dbOtp.expiresAt.getTime() : memoryOtp?.expiresAt;

    if (!validCode || !expiresAtMs) {
      return errorResponse("ვერიფიკაციის კოდი არ მოიძებნა ან ვადა გაუვიდა", 400);
    }
    if (Date.now() > expiresAtMs) {
      otpStore.delete(targetEmail);
      try { await prisma.otpCode.deleteMany({ where: { email: targetEmail } }); } catch (_) {}
      return errorResponse("ვერიფიკაციის კოდს ვადა გაუვიდა", 400);
    }
    if (validCode !== inputCode) {
      return errorResponse("შეყვანილი კოდი არასწორია", 400);
    }

    otpStore.delete(targetEmail);
    try { await prisma.otpCode.deleteMany({ where: { email: targetEmail } }); } catch (_) {}
    return jsonResponse({ verified: true, email: targetEmail });
  }

  // POST /api/auth/login
  if (method === "POST" && path === "/api/auth/login") {
    const body = (await request.json()) as {
      phone?: string;
      email?: string;
      password?: string;
      isGoogleAuth?: boolean;
      name?: string;
      farmName?: string;
      role?: string;
      fcmToken?: string;
    };

    const roleEnum =
      body.role?.toUpperCase() === "FARMER" ? Role.FARMER : Role.CLIENT;
    const normalizedEmail = body.email?.trim().toLowerCase();

    // 1. Always look up by email first (strict account isolation)
    let user = normalizedEmail
      ? await prisma.user.findFirst({
        where: {
          email: {
            equals: normalizedEmail,
            mode: "insensitive",
          },
        },
        include: { farmerProfile: true },
      })
      : null;

    // 2. Only fall back to phone lookup if no email was provided
    if (!user && !normalizedEmail && body.phone) {
      user = await prisma.user.findFirst({
        where: { phoneNumber: body.phone },
        include: { farmerProfile: true },
      });
    }

    // 3. User verification and password checking
    if (!user) {
      // If logging in via Google OAuth, create profile if first time
      if (body.isGoogleAuth) {
        const slug = (normalizedEmail || `${Date.now()}`).replace(/[^a-z0-9]/g, "_");
        const emailPrefix = normalizedEmail ? normalizedEmail.split("@")[0] : "მომხმარებელი";
        const targetUserId = roleEnum === Role.FARMER ? `user_farmer_${slug}` : `user_client_${slug}`;
        const existingById = await prisma.user.findUnique({
          where: { id: targetUserId },
          include: { farmerProfile: true },
        });

        if (existingById) {
          user = existingById;
        } else {
          user = await prisma.user.create({
            data: {
              id: targetUserId,
              fullName: body.name || (roleEnum === Role.FARMER ? "ფერმერი" : emailPrefix),
              phoneNumber:
                body.phone && body.phone !== "+995 599 12 34 56"
                  ? body.phone
                  : `+995599${Math.floor(100000 + Math.random() * 900000)}`,
              email: normalizedEmail || `user_${Date.now()}@agrokera.ge`,
              role: roleEnum,
              verificationStatus: VerificationStatus.VERIFIED,
              ...(roleEnum === Role.FARMER
                ? {
                  farmerProfile: {
                    create: {
                      id: `farmer_${slug}`,
                      farmName: body.farmName || `${body.name || "ახალი ფერმერი"}-ის მეურნეობა`,
                      region: "კახეთი",
                      city: "თელავი",
                      address: "თელავი, კახეთი",
                    },
                  },
                }
                : {}),
            },
            include: { farmerProfile: true },
          });
        }
      } else {
        return errorResponse("მომხმარებელი ამ ელ-ფოსტით არ არსებობს. გთხოვთ გაიაროთ რეგისტრაცია", 401);
      }
    } else if (!body.isGoogleAuth) {
      // Regular login requires valid password if passwordHash exists
      if (user.passwordHash) {
        if (!body.password) {
          return errorResponse("გთხოვთ შეიყვანოთ პაროლი", 400);
        }
        if (!verifyPassword(body.password, user.passwordHash)) {
          return errorResponse("არასწორი პაროლი", 401);
        }
      } else if (body.password) {
        // First-time password set for legacy accounts without password
        await prisma.user.update({
          where: { id: user.id },
          data: { passwordHash: hashPassword(body.password) },
        });
      }
    }

    if (roleEnum === Role.FARMER && !user.farmerProfile) {
      // Ensure existing farmer user always has its own isolated FarmerProfile
      const slug = (user.email || user.id).toLowerCase().replace(/[^a-z0-9]/g, "_");
      await prisma.farmerProfile.upsert({
        where: { userId: user.id },
        create: {
          id: `farmer_${slug}`,
          userId: user.id,
          farmName: body.farmName || `${user.fullName}-ის მეურნეობა`,
          region: "კახეთი",
          city: "თელავი",
          address: "თელავი, კახეთი",
        },
        update: {
          farmName: body.farmName || `${user.fullName}-ის მეურნეობა`,
        },
      });
      user = await prisma.user.update({
        where: { id: user.id },
        data: { role: Role.FARMER },
        include: { farmerProfile: true },
      });
    }

    if (body.fcmToken && user.fcmToken !== body.fcmToken) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { fcmToken: body.fcmToken },
        include: { farmerProfile: true },
      });
    }

    return jsonResponse({
      token: createAuthToken(user.id),
      user,
    });
  }

  // POST /api/auth/register
  if (method === "POST" && path === "/api/auth/register") {
    const body = (await request.json()) as {
      fullName: string;
      phoneNumber?: string;
      email?: string;
      password?: string;
      role?: string;
      farmName?: string;
      region?: string;
      city?: string;
      address?: string;
      coverUrl?: string;
      avatarUrl?: string;
      isVatPayer?: boolean;
    };

    const roleEnum =
      body.role?.toUpperCase() === "FARMER" ? Role.FARMER : Role.CLIENT;
    const normalizedEmail = body.email?.trim().toLowerCase();
    const slug = (normalizedEmail || `${Date.now()}`)
      .replace(/[^a-z0-9]/g, "_");
    const passwordHash = body.password?.trim() ? hashPassword(body.password.trim()) : undefined;

    const targetUserId = roleEnum === Role.FARMER ? `user_farmer_${slug}` : `user_client_${slug}`;
    const targetFarmerId = `farmer_${slug}`;

    let existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          ...(normalizedEmail
            ? [{ email: { equals: normalizedEmail, mode: "insensitive" as const } }]
            : []),
          { id: targetUserId },
          ...(body.phoneNumber ? [{ phoneNumber: body.phoneNumber }] : []),
        ],
      },
      include: { farmerProfile: true },
    });

    let user;
    if (existingUser) {
      user = await prisma.user.update({
        where: { id: existingUser.id },
        data: {
          fullName: body.fullName || existingUser.fullName,
          role: roleEnum,
          ...(passwordHash ? { passwordHash } : {}),
          ...(roleEnum === Role.FARMER
            ? {
              farmerProfile: {
                upsert: {
                  create: {
                    id: targetFarmerId,
                    farmName:
                      body.farmName || `${body.fullName}-ის მეურნეობა`,
                    region: body.region || "კახეთი",
                    city: body.city || "თელავი",
                    address: body.address || "თელავი, კახეთი",
                    coverUrl: body.coverUrl,
                    avatarUrl: body.avatarUrl,
                    isVatPayer: body.isVatPayer ?? false,
                  },
                  update: {
                    ...(body.farmName ? { farmName: body.farmName } : {}),
                    ...(body.region ? { region: body.region } : {}),
                    ...(body.city ? { city: body.city } : {}),
                    ...(body.address ? { address: body.address } : {}),
                    ...(body.isVatPayer !== undefined
                      ? { isVatPayer: body.isVatPayer }
                      : {}),
                    ...(body.coverUrl ? { coverUrl: body.coverUrl } : {}),
                    ...(body.avatarUrl ? { avatarUrl: body.avatarUrl } : {}),
                  },
                },
              },
            }
            : {}),
        },
        include: { farmerProfile: true },
      });
    } else {
      let uniqueUserId = targetUserId;
      const userExists = await prisma.user.findUnique({
        where: { id: uniqueUserId },
        select: { id: true },
      });
      if (userExists) {
        uniqueUserId = `${targetUserId}_${Date.now()}`;
      }

      let uniqueFarmerId = targetFarmerId;
      const fpExists = await prisma.farmerProfile.findUnique({
        where: { id: uniqueFarmerId },
        select: { id: true },
      });
      if (fpExists) {
        uniqueFarmerId = `${targetFarmerId}_${Date.now()}`;
      }

      let safePhone =
        body.phoneNumber &&
        body.phoneNumber !== "+995 599 12 34 56" &&
        body.phoneNumber !== "+995 599 00 00 00"
          ? body.phoneNumber
          : null;

      if (safePhone) {
        const phoneExists = await prisma.user.findUnique({
          where: { phoneNumber: safePhone },
          select: { id: true },
        });
        if (phoneExists) {
          safePhone = `+995599${Math.floor(100000 + Math.random() * 900000)}`;
        }
      } else {
        safePhone = `+995599${Math.floor(100000 + Math.random() * 900000)}`;
      }

      try {
        user = await prisma.user.create({
          data: {
            id: uniqueUserId,
            fullName: body.fullName || "ახალი მომხმარებელი",
            phoneNumber: safePhone,
            email: normalizedEmail || `user_${Date.now()}@agrokera.ge`,
            role: roleEnum,
            verificationStatus: VerificationStatus.VERIFIED,
            ...(passwordHash ? { passwordHash } : {}),
            ...(roleEnum === Role.FARMER
              ? {
                farmerProfile: {
                  create: {
                    id: uniqueFarmerId,
                    farmName:
                      body.farmName || `${body.fullName}-ის მეურნეობა`,
                    region: body.region || "კახეთი",
                    city: body.city || "თელავი",
                    address: body.address || "თელავი, კახეთი",
                    coverUrl: body.coverUrl,
                    avatarUrl: body.avatarUrl,
                    isVatPayer: body.isVatPayer ?? false,
                  },
                },
              }
              : {}),
          },
          include: { farmerProfile: true },
        });
      } catch (err: any) {
        // Fallback for race condition: find and update
        const fallbackUser = await prisma.user.findFirst({
          where: {
            OR: [
              ...(normalizedEmail ? [{ email: { equals: normalizedEmail, mode: "insensitive" as const } }] : []),
              { id: uniqueUserId },
            ],
          },
          include: { farmerProfile: true },
        });
        if (fallbackUser) {
          user = fallbackUser;
        } else {
          throw err;
        }
      }
    }

    return jsonResponse(
      {
        token: createAuthToken(user.id),
        user,
      },
      201
    );
  }

  return null;
}

