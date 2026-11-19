import prisma from "../../lib/prisma.ts";
import { Role, VerificationStatus } from "@prisma/client";
import nodemailer from "nodemailer";
import { jsonResponse, errorResponse, createAuthToken } from "../utils.ts";

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

    const smtpUser = (process.env.SMTP_USER || "").trim();
    const smtpPass = (process.env.SMTP_PASS || "").replace(/\s+/g, "");

    if (smtpUser && smtpPass && smtpUser !== "your_email@gmail.com") {
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

    // 3. If user does not exist yet, create a dedicated isolated User (& FarmerProfile if FARMER)
    if (!user) {
      const slug = (normalizedEmail || `${Date.now()}`)
        .replace(/[^a-z0-9]/g, "_");
      const emailPrefix = normalizedEmail
        ? normalizedEmail.split("@")[0]
        : "მომხმარებელი";
      user = await prisma.user.create({
        data: {
          id: roleEnum === Role.FARMER ? `user_farmer_${slug}` : `user_client_${slug}`,
          fullName:
            body.name ||
            (roleEnum === Role.FARMER ? "ფერმერი" : emailPrefix),
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
                  farmName:
                    body.farmName ||
                    `${body.name || "ახალი ფერმერი"}-ის მეურნეობა`,
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
    } else if (roleEnum === Role.FARMER && !user.farmerProfile) {
      // Ensure existing farmer user always has its own isolated FarmerProfile
      const slug = (user.email || user.id).toLowerCase().replace(/[^a-z0-9]/g, "_");
      await prisma.farmerProfile.create({
        data: {
          id: `farmer_${slug}`,
          userId: user.id,
          farmName: body.farmName || `${user.fullName}-ის მეურნეობა`,
          region: "კახეთი",
          city: "თელავი",
          address: "თელავი, კახეთი",
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

    let existingUser = normalizedEmail
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

    let user;
    if (existingUser) {
      user = await prisma.user.update({
        where: { id: existingUser.id },
        data: {
          fullName: body.fullName || existingUser.fullName,
          role: roleEnum,
          ...(roleEnum === Role.FARMER
            ? {
              farmerProfile: existingUser.farmerProfile
                ? {
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
                }
                : {
                  create: {
                    id: `farmer_${slug}`,
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
    } else {
      user = await prisma.user.create({
        data: {
          id: roleEnum === Role.FARMER ? `user_farmer_${slug}` : `user_client_${slug}`,
          fullName: body.fullName || "ახალი მომხმარებელი",
          phoneNumber:
            body.phoneNumber &&
              body.phoneNumber !== "+995 599 12 34 56" &&
              body.phoneNumber !== "+995 599 00 00 00"
              ? body.phoneNumber
              : `+995599${Math.floor(100000 + Math.random() * 900000)}`,
          email: normalizedEmail || `user_${Date.now()}@agrokera.ge`,
          role: roleEnum,
          verificationStatus: VerificationStatus.VERIFIED,
          ...(roleEnum === Role.FARMER
            ? {
              farmerProfile: {
                create: {
                  id: `farmer_${slug}`,
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

