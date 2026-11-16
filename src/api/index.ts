import prisma from "../lib/prisma.ts";
import { sendPushNotification, createAndSendNotification } from "../lib/push-notifications.ts";
import { OrderStatus, Role, ShipmentStatus, VerificationStatus, FulfillmentType } from "@prisma/client";
import nodemailer from "nodemailer";
import { S3Client, PutObjectCommand, GetObjectCommand, CreateBucketCommand } from "@aws-sdk/client-s3";

const otpStore = new Map<string, { code: string; expiresAt: number }>();

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PATCH, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Content-Type": "application/json; charset=utf-8",
};

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: corsHeaders,
  });
}

function errorResponse(message: string, status = 400): Response {
  return jsonResponse({ error: message }, status);
}

/**
 * Neon Function Web-Standard Handler (`fetch(request: Request): Promise<Response>`)
 */
export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";
    const method = request.method.toUpperCase();

    try {
      // ==========================================
      // 1. HEALTH CHECK
      // ==========================================
      if (method === "GET" && (path === "/" || path === "/api/health")) {
        const productCount = await prisma.product.count();
        const farmerCount = await prisma.farmerProfile.count();
        return jsonResponse({
          status: "ok",
          service: "AgroKera Neon API",
          database: "connected",
          stats: { products: productCount, farmers: farmerCount },
        });
      }

      // ==========================================
      // INTERNAL CRON — remind stale IN_PROGRESS orders
      // ==========================================
      if (method === "POST" && path === "/api/cron/remind-stale-orders") {
        const secret = request.headers.get("x-cron-secret");
        const expected = process.env.CRON_SECRET;
        if (!expected || secret !== expected) {
          return errorResponse("Unauthorized", 401);
        }
        const result = await remindStaleOrders();
        return jsonResponse(result);
      }

      // ==========================================
      // 1.5 CLOUDFLARE R2 IMAGE UPLOAD & SERVE
      // ==========================================
      if ((method === "GET" || method === "HEAD") && path.startsWith("/api/assets/")) {
        const objectKey = path.replace(/^\/api\/assets\//, "");
        const r2Endpoint = (process.env.R2_ENDPOINT || "").trim();
        const r2AccessKeyId = (process.env.R2_ACCESS_KEY_ID || "").trim();
        const r2SecretAccessKey = (process.env.R2_SECRET_ACCESS_KEY || "").trim();
        const r2Bucket = (process.env.R2_BUCKET_NAME || "agrokera-assets").trim();

        if (!r2Endpoint || !r2AccessKeyId || !r2SecretAccessKey) {
          return errorResponse("R2 not configured", 404);
        }

        const s3 = new S3Client({
          region: "auto",
          endpoint: r2Endpoint,
          credentials: {
            accessKeyId: r2AccessKeyId,
            secretAccessKey: r2SecretAccessKey,
          },
        });

        const obj = await s3.send(
          new GetObjectCommand({
            Bucket: r2Bucket,
            Key: objectKey,
          })
        );

        if (!obj.Body) {
          return errorResponse("Asset not found", 404);
        }

        const byteArray = await obj.Body.transformToByteArray();
        return new Response(byteArray, {
          status: 200,
          headers: {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": obj.ContentType || "image/jpeg",
            "Cache-Control": "public, max-age=31536000, immutable",
          },
        });
      }

      if (method === "POST" && path === "/api/upload") {
        const body = (await request.json()) as {
          fileName?: string;
          base64Data?: string;
          contentType?: string;
          folder?: string;
        };

        if (!body.base64Data) {
          return errorResponse("base64Data is required", 400);
        }

        const r2Endpoint = (process.env.R2_ENDPOINT || "").trim();
        const r2AccessKeyId = (process.env.R2_ACCESS_KEY_ID || "").trim();
        const r2SecretAccessKey = (process.env.R2_SECRET_ACCESS_KEY || "").trim();
        const r2Bucket = (process.env.R2_BUCKET_NAME || "agrokera-assets").trim();
        const r2PublicUrl = (process.env.R2_PUBLIC_URL || "").trim().replace(/\/+$/, "");

        const rawBase64 = body.base64Data.replace(/^data:[^;]+;base64,/, "");
        const buffer = Buffer.from(rawBase64, "base64");
        const contentType = body.contentType || "image/jpeg";
        const ext = (body.fileName?.split(".").pop() || "jpg").toLowerCase();
        const folder = body.folder || "products";
        const objectKey = `${folder}/${Date.now()}_${Math.random().toString(36).slice(2, 8)}.${ext}`;

        if (
          r2Endpoint &&
          r2AccessKeyId &&
          r2SecretAccessKey &&
          !r2Endpoint.includes("YOUR_ACCOUNT_ID")
        ) {
          const s3 = new S3Client({
            region: "auto",
            endpoint: r2Endpoint,
            credentials: {
              accessKeyId: r2AccessKeyId,
              secretAccessKey: r2SecretAccessKey,
            },
          });

          try {
            await s3.send(
              new PutObjectCommand({
                Bucket: r2Bucket,
                Key: objectKey,
                Body: buffer,
                ContentType: contentType,
                CacheControl: "public, max-age=31536000, immutable",
              })
            );
          } catch (uploadErr: unknown) {
            // Auto-create bucket if NoSuchBucket
            const errName = (uploadErr as { name?: string })?.name;
            if (errName === "NoSuchBucket") {
              await s3.send(new CreateBucketCommand({ Bucket: r2Bucket }));
              await s3.send(
                new PutObjectCommand({
                  Bucket: r2Bucket,
                  Key: objectKey,
                  Body: buffer,
                  ContentType: contentType,
                  CacheControl: "public, max-age=31536000, immutable",
                })
              );
            } else {
              throw uploadErr;
            }
          }

          const isPublicCustomOrR2Dev =
            r2PublicUrl &&
            !r2PublicUrl.includes("r2.cloudflarestorage.com") &&
            !r2PublicUrl.includes("pub-xxxx");

          const finalUrl = isPublicCustomOrR2Dev
            ? `${r2PublicUrl}/${objectKey}`
            : `${url.origin}/api/assets/${objectKey}`;

          return jsonResponse({
            uploaded: true,
            storage: "cloudflare_r2",
            key: objectKey,
            url: finalUrl,
          });
        }

        // Fallback to inline Data URL if R2 env vars are not filled yet
        return jsonResponse({
          uploaded: true,
          storage: "inline_data_url",
          url: `data:${contentType};base64,${rawBase64}`,
        });
      }

      // ==========================================
      // 2. AUTH & PROFILE & KYC
      // ==========================================
      if (method === "POST" && path === "/api/auth/send-otp") {
        const body = (await request.json()) as { email?: string };
        const targetEmail = (body.email || "").trim().toLowerCase();
        if (!targetEmail || !targetEmail.includes("@")) {
          return errorResponse("გთხოვთ მიუთითოთ სწორი ელ-ფოსტა", 400);
        }

        const code = String(Math.floor(10000 + Math.random() * 90000));
        otpStore.set(targetEmail, {
          code,
          expiresAt: Date.now() + 9 * 60 * 1000, // 9 minutes
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

      if (method === "POST" && path === "/api/auth/verify-otp") {
        const body = (await request.json()) as { email?: string; code?: string };
        const targetEmail = (body.email || "").trim().toLowerCase();
        const inputCode = (body.code || "").trim();

        const record = otpStore.get(targetEmail);
        if (!record) {
          return errorResponse("ვერიფიკაციის კოდი არ მოიძებნა ან ვადა გაუვიდა", 400);
        }
        if (Date.now() > record.expiresAt) {
          otpStore.delete(targetEmail);
          return errorResponse("ვერიფიკაციის კოდს ვადა გაუვიდა", 400);
        }
        if (record.code !== inputCode) {
          return errorResponse("შეყვანილი კოდი არასწორია", 400);
        }

        otpStore.delete(targetEmail);
        return jsonResponse({ verified: true, email: targetEmail });
      }

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
          user = await prisma.user.create({
            data: {
              id: roleEnum === Role.FARMER ? `user_farmer_${slug}` : `user_client_${slug}`,
              fullName:
                body.name ||
                (roleEnum === Role.FARMER ? "გიორგი ბერიძე" : "საბა ევგენიძე"),
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
          token: `ak_jwt_${user.id}`,
          user,
        });
      }

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
            token: `ak_jwt_${user.id}`,
            user,
          },
          201
        );
      }

      if (method === "POST" && path === "/api/users/fcm-token") {
        const body = (await request.json()) as {
          userId?: string;
          fcmToken?: string;
        };
        if (!body.userId || !body.fcmToken) {
          return errorResponse("userId and fcmToken are required", 400);
        }
        try {
          const updated = await prisma.user.update({
            where: { id: body.userId },
            data: { fcmToken: body.fcmToken },
          });
          return jsonResponse({ success: true, userId: updated.id });
        } catch (err: any) {
          return errorResponse(`Failed to update fcmToken: ${err.message}`, 400);
        }
      }

      // ==========================================
      // NOTIFICATIONS ENDPOINTS
      // ==========================================
      if (path === "/api/notifications" && method === "GET") {
        const userId = url.searchParams.get("userId");
        if (!userId) {
          return errorResponse("userId query parameter is required", 400);
        }
        const notifs = await prisma.notification.findMany({
          where: { userId },
          orderBy: { createdAt: "desc" },
          take: 50,
        });
        return jsonResponse(notifs);
      }

      if (path === "/api/notifications/read-all" && method === "PATCH") {
        const body = (await request.json().catch(() => ({}))) as { userId?: string };
        const userId = body.userId || url.searchParams.get("userId");
        if (!userId) {
          return errorResponse("userId is required", 400);
        }
        await prisma.notification.updateMany({
          where: { userId, isRead: false },
          data: { isRead: true },
        });
        return jsonResponse({ success: true });
      }

      if (path.startsWith("/api/notifications/") && path.endsWith("/read") && method === "PATCH") {
        const notifId = path.replace("/api/notifications/", "").replace("/read", "");
        try {
          const updated = await prisma.notification.update({
            where: { id: notifId },
            data: { isRead: true },
          });
          return jsonResponse(updated);
        } catch (err: any) {
          return errorResponse(`Failed to mark notification as read: ${err.message}`, 400);
        }
      }

      if (path.startsWith("/api/profile/")) {
        const userId = path.replace("/api/profile/", "");
        if (method === "GET") {
          const user = await prisma.user.findUnique({
            where: { id: userId },
            include: { farmerProfile: true },
          });
          if (!user) return errorResponse("User not found", 404);
          return jsonResponse(user);
        }

        if (method === "PATCH") {
          const body = (await request.json()) as {
            fullName?: string;
            verificationStatus?: VerificationStatus;
            farmName?: string;
            region?: string;
            address?: string;
            idCardFrontUrl?: string;
            idCardBackUrl?: string;
            coverUrl?: string;
            avatarUrl?: string;
            isVatPayer?: boolean;
          };

          const user = await prisma.user.update({
            where: { id: userId },
            data: {
              ...(body.fullName ? { fullName: body.fullName } : {}),
              ...(body.avatarUrl ? { avatarUrl: body.avatarUrl } : {}),
              ...(body.verificationStatus
                ? { verificationStatus: body.verificationStatus }
                : {}),
              ...(body.farmName ||
              body.region ||
              body.address ||
              body.idCardFrontUrl ||
              body.idCardBackUrl ||
              body.coverUrl ||
              body.avatarUrl ||
              body.isVatPayer !== undefined
                ? {
                    farmerProfile: {
                      update: {
                        ...(body.farmName ? { farmName: body.farmName } : {}),
                        ...(body.region ? { region: body.region } : {}),
                        ...(body.address ? { address: body.address } : {}),
                        ...(body.idCardFrontUrl
                          ? { idCardFrontUrl: body.idCardFrontUrl }
                          : {}),
                        ...(body.idCardBackUrl
                          ? { idCardBackUrl: body.idCardBackUrl }
                          : {}),
                        ...(body.coverUrl ? { coverUrl: body.coverUrl } : {}),
                        ...(body.avatarUrl ? { avatarUrl: body.avatarUrl } : {}),
                        ...(body.isVatPayer !== undefined
                          ? { isVatPayer: body.isVatPayer }
                          : {}),
                      },
                    },
                  }
                : {}),
            },
            include: { farmerProfile: true },
          });

          return jsonResponse(user);
        }
      }

      // ==========================================
      // 3. FARMERS & MARKETPLACE PRODUCTS
      // ==========================================
      if (method === "GET" && path === "/api/farmers") {
        const farmers = await prisma.farmerProfile.findMany({
          include: { user: true },
          orderBy: { rating: "desc" },
        });

        const formatted = farmers.map((f) => ({
          id: f.id,
          farmName: f.farmName,
          farmerName: f.user.fullName,
          location: f.address || `${f.city || ""}, ${f.region}`.replace(/^, /, ""),
          rating: f.rating,
          reviewCount: f.reviewCount,
          totalRatings: f.totalRatings,
          isVerified: f.user.verificationStatus === VerificationStatus.VERIFIED,
          isVatPayer: f.isVatPayer,
          avatarUrl:
            f.avatarUrl ||
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80",
          coverUrl:
            f.coverUrl ||
            "https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80",
          about: f.about || "",
          phone: "", // phone numbers are never exposed publicly
        }));

        return jsonResponse(formatted);
      }

      if (method === "GET" && path === "/api/products") {
        const category = url.searchParams.get("category");
        const farmerId = url.searchParams.get("farmerId");
        const search = url.searchParams.get("search");
        const includeUnavailable = url.searchParams.get("includeUnavailable") === "true";

        const products = await prisma.product.findMany({
          where: {
            ...(category ? { category } : {}),
            ...(farmerId ? { farmerId } : {}),
            ...(!includeUnavailable ? { isAvailable: true } : {}),
            ...(search
              ? {
                  OR: [
                    { title: { contains: search, mode: "insensitive" } },
                    { description: { contains: search, mode: "insensitive" } },
                    { category: { contains: search, mode: "insensitive" } },
                  ],
                }
              : {}),
          },
          include: { farmer: true },
          orderBy: { createdAt: "desc" },
        });

        const formatted = products.map((p) => {
          const primaryImage =
            p.imageUrl ||
            (p.images && p.images.length > 0 ? p.images[0] : null) ||
            "https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&auto=format&fit=crop&q=80";
          const imageList =
            p.images && p.images.length > 0 ? p.images : [primaryImage];

          return {
            id: p.id,
            title: p.title,
            category: p.category,
            farmerId: p.farmerId,
            farmerName: p.farmer.farmName,
            price: p.pricePerUnit,
            unit: p.unit,
            discountPercent: p.discountPercent,
            rating: p.rating,
            reviewCount: p.reviewCount,
            isAvailable: p.isAvailable,
            stockQuantity: p.stockQuantity,
            stockStatus:
              p.stockQuantity <= 0
                ? "ამოწურულია"
                : p.stockQuantity < 20
                ? "იწურება"
                : p.stockStatus || "მარაგშია",
            imageUrl: primaryImage,
            images: imageList,
            description: p.description || "",
            minOrderQuantity: p.minOrderQuantity,
            bulkDiscountMinQty: p.bulkDiscountMinQty,
            bulkDiscountPercent: p.bulkDiscountPercent,
          };
        });

        return jsonResponse(formatted);
      }

      if (method === "POST" && path === "/api/products") {
        const body = (await request.json()) as {
          title: string;
          category: string;
          farmerId?: string;
          farmerName?: string;
          pricePerUnit: number;
          discountPercent?: number;
          unit?: string;
          stockQuantity?: number;
          minOrderQuantity?: number;
          bulkDiscountMinQty?: number;
          bulkDiscountPercent?: number;
          imageUrl?: string;
          images?: string[];
          description?: string;
        };

        let targetFarmerId = body.farmerId || "farmer_2";
        let existingFarmer = await prisma.farmerProfile.findFirst({
          where: {
            OR: [
              { id: targetFarmerId },
              { userId: targetFarmerId },
              ...(body.farmerName ? [{ farmName: body.farmerName }] : []),
            ],
          },
        });

        if (!existingFarmer) {
          // Create a dedicated isolated FarmerProfile instead of falling back to another farmer!
          const cleanId = targetFarmerId.startsWith("farmer_")
            ? targetFarmerId
            : `farmer_${targetFarmerId}`;
          const cleanFarmName = body.farmerName || "ახალი მეურნეობა";
          const ownerUser = await prisma.user.create({
            data: {
              id: `user_${cleanId}`,
              fullName: cleanFarmName.replace(/-ის (ფერმა|მეურნეობა)$/, ""),
              phoneNumber: `+995599${Math.floor(100000 + Math.random() * 900000)}`,
              email: `${cleanId}@agrokera.ge`,
              role: Role.FARMER,
              verificationStatus: VerificationStatus.VERIFIED,
              farmerProfile: {
                create: {
                  id: cleanId,
                  farmName: cleanFarmName,
                  region: "კახეთი",
                  city: "თელავი",
                  address: "თელავი, კახეთი",
                },
              },
            },
            include: { farmerProfile: true },
          });
          existingFarmer = ownerUser.farmerProfile;
        }
        targetFarmerId = existingFarmer!.id;

        const stockQty = Number(body.stockQuantity ?? 50);
        const normalizedImages =
          Array.isArray(body.images) && body.images.length > 0
            ? body.images.slice(0, 5)
            : body.imageUrl
            ? [body.imageUrl]
            : [
                "https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop&q=80",
              ];
        const primaryImage = body.imageUrl || normalizedImages[0];

        const created = await prisma.product.create({
          data: {
            title: body.title,
            category: body.category || "ბოსტნეული",
            farmerId: targetFarmerId,
            pricePerUnit: Number(body.pricePerUnit),
            discountPercent: Number(body.discountPercent ?? 0),
            unit: body.unit || "კგ",
            stockQuantity: stockQty,
            stockStatus: stockQty < 20 ? "იწურება" : "მარაგშია",
            minOrderQuantity: Number(body.minOrderQuantity ?? 1.0),
            bulkDiscountMinQty: body.bulkDiscountMinQty
              ? Number(body.bulkDiscountMinQty)
              : null,
            bulkDiscountPercent: body.bulkDiscountPercent
              ? Number(body.bulkDiscountPercent)
              : null,
            imageUrl: primaryImage,
            images: normalizedImages,
            description:
              body.description ||
              `ახალი, ნატურალური ${body.title} პირდაპირ ფერმიდან.`,
          },
          include: { farmer: true },
        });

        return jsonResponse(
          {
            id: created.id,
            title: created.title,
            category: created.category,
            farmerId: created.farmerId,
            farmerName: created.farmer.farmName,
            price: created.pricePerUnit,
            unit: created.unit,
            discountPercent: created.discountPercent,
            rating: created.rating,
            reviewCount: created.reviewCount,
            isAvailable: created.isAvailable,
            stockQuantity: created.stockQuantity,
            stockStatus: created.stockStatus,
            imageUrl: created.imageUrl,
            images: created.images && created.images.length > 0 ? created.images : [created.imageUrl],
            description: created.description,
            minOrderQuantity: created.minOrderQuantity,
            bulkDiscountMinQty: created.bulkDiscountMinQty,
            bulkDiscountPercent: created.bulkDiscountPercent,
          },
          201
        );
      }

      if (path.startsWith("/api/products/")) {
        const productId = path.replace("/api/products/", "");

        if (method === "PATCH") {
          const body = (await request.json()) as {
            title?: string;
            category?: string;
            pricePerUnit?: number;
            discountPercent?: number;
            unit?: string;
            stockQuantity?: number;
            minOrderQuantity?: number;
            bulkDiscountMinQty?: number;
            bulkDiscountPercent?: number;
            isAvailable?: boolean;
            description?: string;
            imageUrl?: string;
            images?: string[];
          };

          const stockQty =
            body.stockQuantity !== undefined ? Number(body.stockQuantity) : undefined;
          const normalizedImages =
            Array.isArray(body.images) && body.images.length > 0
              ? body.images.slice(0, 5)
              : undefined;

          const updated = await prisma.product.update({
            where: { id: productId },
            data: {
              ...(body.title !== undefined ? { title: body.title } : {}),
              ...(body.category !== undefined ? { category: body.category } : {}),
              ...(body.pricePerUnit !== undefined
                ? { pricePerUnit: Number(body.pricePerUnit) }
                : {}),
              ...(body.discountPercent !== undefined
                ? { discountPercent: Number(body.discountPercent) }
                : {}),
              ...(body.unit !== undefined ? { unit: body.unit } : {}),
              ...(stockQty !== undefined
                ? {
                    stockQuantity: stockQty,
                    stockStatus:
                      stockQty <= 0
                        ? "ამოწურულია"
                        : stockQty < 20
                        ? "იწურება"
                        : "მარაგშია",
                    isAvailable: stockQty > 0 ? (body.isAvailable ?? true) : false,
                  }
                : {}),
              ...(body.isAvailable !== undefined && stockQty === undefined
                ? { isAvailable: body.isAvailable }
                : {}),
              ...(body.minOrderQuantity !== undefined
                ? { minOrderQuantity: Number(body.minOrderQuantity) }
                : {}),
              ...(body.bulkDiscountMinQty !== undefined
                ? {
                    bulkDiscountMinQty: body.bulkDiscountMinQty
                      ? Number(body.bulkDiscountMinQty)
                      : null,
                  }
                : {}),
              ...(body.bulkDiscountPercent !== undefined
                ? {
                    bulkDiscountPercent: body.bulkDiscountPercent
                      ? Number(body.bulkDiscountPercent)
                      : null,
                  }
                : {}),
              ...(body.description !== undefined
                ? { description: body.description }
                : {}),
              ...(body.imageUrl !== undefined ? { imageUrl: body.imageUrl } : {}),
              ...(normalizedImages !== undefined
                ? {
                    images: normalizedImages,
                    ...(body.imageUrl === undefined
                      ? { imageUrl: normalizedImages[0] }
                      : {}),
                  }
                : {}),
            },
            include: { farmer: true },
          });

          return jsonResponse({
            id: updated.id,
            title: updated.title,
            category: updated.category,
            farmerId: updated.farmerId,
            farmerName: updated.farmer.farmName,
            price: updated.pricePerUnit,
            unit: updated.unit,
            discountPercent: updated.discountPercent,
            rating: updated.rating,
            reviewCount: updated.reviewCount,
            isAvailable: updated.isAvailable,
            stockQuantity: updated.stockQuantity,
            stockStatus: updated.stockStatus,
            imageUrl: updated.imageUrl,
            images: updated.images && updated.images.length > 0 ? updated.images : [updated.imageUrl],
            description: updated.description,
            minOrderQuantity: updated.minOrderQuantity,
            bulkDiscountMinQty: updated.bulkDiscountMinQty,
            bulkDiscountPercent: updated.bulkDiscountPercent,
          });
        }

        if (method === "DELETE") {
          await prisma.product.delete({ where: { id: productId } });
          return jsonResponse({ deleted: true, id: productId });
        }
      }

      // ==========================================
      // 4. ORDERS & CHECKOUT & TRACKING
      // ==========================================
      if (method === "GET" && path === "/api/orders") {
        const farmerId = url.searchParams.get("farmerId");
        const clientId = url.searchParams.get("clientId");

        const orders = await prisma.order.findMany({
          where: {
            ...(farmerId ? { farmerId } : {}),
            ...(clientId ? { clientId } : {}),
          },
          include: {
            client: true,
            items: {
              include: { product: true },
            },
            shipment: true,
          },
          orderBy: { createdAt: "desc" },
        });

        const farmerIds = [
          ...new Set(orders.map((o) => o.farmerId).filter((x): x is string => !!x)),
        ];
        const farmerProfiles = farmerIds.length
          ? await prisma.farmerProfile.findMany({
              where: { id: { in: farmerIds } },
              select: { id: true, farmName: true, avatarUrl: true },
            })
          : [];
        const farmerById = new Map(farmerProfiles.map((f) => [f.id, f]));

        const formatted = orders.map((o) => ({
          id: o.id,
          farmerId: o.farmerId,
          farmerName: o.farmerId ? farmerById.get(o.farmerId)?.farmName ?? null : null,
          farmerAvatarUrl: o.farmerId ? farmerById.get(o.farmerId)?.avatarUrl ?? null : null,
          clientId: o.clientId,
          createdAt: o.createdAt.toISOString(),
          status: o.status,
          customerName: o.client.fullName,
          contactPerson: o.contactPerson || o.client.fullName,
          // Phone numbers are never shared between client and farmer
          contactPhone: null,
          hasVat: o.hasVat,
          totalAmount: o.totalAmount,
          fulfillmentType: o.fulfillmentType,
          deliveryTimeWindow: o.deliveryTimeWindow || "დღეს, 16:00 - 19:00",
          deliveryAddress: o.deliveryAddress,
          cancellationReason: o.cancellationReason,
          cancellationDeadline: o.cancellationDeadline?.toISOString() ?? null,
          shipmentStatus: o.shipment?.status ?? "PENDING",
          trackingNumber: o.shipment?.trackingNumber ?? `AK-${o.id.slice(-5)}`,
          items: o.items.map((item) => ({
            productId: item.productId,
            name: item.product.title,
            quantity: item.quantity,
            unit: item.product.unit,
            quantityText: `${item.quantity}${item.product.unit}`,
            pricePerUnit: item.pricePerUnit,
            price: item.subtotal,
          })),
        }));

        return jsonResponse(formatted);
      }

      if (method === "POST" && path === "/api/orders") {
        const body = (await request.json()) as {
          clientId?: string;
          farmerId?: string;
          contactPerson?: string;
          contactPhone?: string;
          deliveryAddress?: string;
          deliveryTimeWindow?: string;
          deliveryNotes?: string;
          hasVat?: boolean;
          fulfillmentType?: string;
          items: Array<{
            productId: string;
            quantity: number;
            pricePerUnit: number;
          }>;
        };

        if (!body.items || body.items.length === 0) {
          return errorResponse("Order must contain at least one item", 400);
        }

        const subtotal = body.items.reduce(
          (sum, item) => sum + Number(item.quantity) * Number(item.pricePerUnit),
          0
        );
        const totalAmount = body.hasVat ? subtotal * 1.18 : subtotal;

        const createdOrder = await prisma.$transaction(async (tx) => {
          // Resolve valid client user
          let resolvedClientId = body.clientId || "user_client_1";
          const existingClient = await tx.user.findUnique({
            where: { id: resolvedClientId },
          });
          if (!existingClient) {
            const firstClient = await tx.user.findFirst({
              where: { role: Role.CLIENT },
            });
            if (firstClient) {
              resolvedClientId = firstClient.id;
            } else {
              const createdClient = await tx.user.create({
                data: {
                  fullName: body.contactPerson || "საბა ევგენიძე",
                  phoneNumber: body.contactPhone || `+995599${Math.floor(100000 + Math.random() * 900000)}`,
                  role: Role.CLIENT,
                  verificationStatus: VerificationStatus.VERIFIED,
                },
              });
              resolvedClientId = createdClient.id;
            }
          }

          // Resolve products & decrement product stock
          const resolvedItems: Array<{
            productId: string;
            quantity: number;
            pricePerUnit: number;
            subtotal: number;
          }> = [];
          let resolvedFarmerId = body.farmerId || "farmer_2";

          for (const item of body.items) {
            let product = await tx.product.findUnique({
              where: { id: item.productId },
            });
            if (!product) {
              product = await tx.product.findFirst();
            }
            if (product) {
              resolvedFarmerId = product.farmerId;
              const newStock = Math.max(0, product.stockQuantity - Number(item.quantity));
              await tx.product.update({
                where: { id: product.id },
                data: {
                  stockQuantity: newStock,
                  stockStatus:
                    newStock <= 0
                      ? "ამოწურულია"
                      : newStock < 20
                      ? "იწურება"
                      : "მარაგშია",
                  isAvailable: newStock > 0,
                },
              });
              resolvedItems.push({
                productId: product.id,
                quantity: Number(item.quantity),
                pricePerUnit: Number(item.pricePerUnit),
                subtotal: Number(item.quantity) * Number(item.pricePerUnit),
              });
            }
          }

          const orderId = String(Math.floor(10000 + Math.random() * 90000));
          return tx.order.create({
            data: {
              id: orderId,
              clientId: resolvedClientId,
              farmerId: resolvedFarmerId,
              status: OrderStatus.PENDING,
              totalAmount,
              hasVat: body.hasVat ?? false,
              fulfillmentType:
                body.fulfillmentType === "SELF_PICKUP"
                  ? FulfillmentType.SELF_PICKUP
                  : FulfillmentType.FARMER_DELIVERY,
              contactPerson: body.contactPerson || "საბა ევგენიძე",
              contactPhone: body.contactPhone || "+995 599 12 34 56",
              deliveryAddress: body.deliveryAddress || "თბილისი, რუსთაველის 14",
              deliveryTimeWindow: body.deliveryTimeWindow || "დღეს, 16:00 - 19:00",
              deliveryNotes: body.deliveryNotes,
              cancellationDeadline: new Date(Date.now() + 30 * 60 * 1000),
              items: {
                create: resolvedItems,
              },
              shipment: {
                create: {
                  status: ShipmentStatus.PENDING,
                  trackingNumber: `AK-${orderId}`,
                },
              },
            },
            include: {
              client: true,
              items: { include: { product: true } },
              shipment: true,
            },
          });
        });

        // Send and persist Push Notification to Farmer for New Order
        (async () => {
          try {
            const farmerProfile = await prisma.farmerProfile.findUnique({
              where: { id: createdOrder.farmerId },
              include: { user: true },
            });
            const productSummary =
              createdOrder.items.length === 1
                ? createdOrder.items[0].product.title
                : `${createdOrder.items[0].product.title} +${createdOrder.items.length - 1} სხვა`;

            if (farmerProfile?.userId) {
              await createAndSendNotification({
                userId: farmerProfile.userId,
                title: "ახალი შეკვეთა მიღებულია!",
                body: `${createdOrder.contactPerson || "მომხმარებელი"}: ${productSummary} — ₾${createdOrder.totalAmount}. დაადასტურეთ რაც შეიძლება მალე.`,
                orderId: createdOrder.id,
                category: "orders",
                data: {
                  orderId: createdOrder.id,
                  type: "order_created",
                },
              });
            }

            if (createdOrder.clientId) {
              await createAndSendNotification({
                userId: createdOrder.clientId,
                title: "შეკვეთა გაფორმდა! 📦",
                body: `თქვენი შეკვეთა #${createdOrder.id.slice(-5)} (${productSummary}) გადაეცა ფერმერს დასადასტურებლად.`,
                orderId: createdOrder.id,
                category: "orders",
                data: {
                  orderId: createdOrder.id,
                  type: "order_created_client",
                },
              });
            }
          } catch (pushErr) {
            console.error("[FCM Order Error]:", pushErr);
          }
        })();
        return jsonResponse(
          {
            id: createdOrder.id,
            farmerId: createdOrder.farmerId,
            clientId: createdOrder.clientId,
            createdAt: createdOrder.createdAt.toISOString(),
            status: createdOrder.status,
            customerName: createdOrder.contactPerson || createdOrder.client.fullName,
            contactPerson: createdOrder.contactPerson || createdOrder.client.fullName,
            contactPhone: null,
            hasVat: createdOrder.hasVat,
            totalAmount: createdOrder.totalAmount,
            fulfillmentType: createdOrder.fulfillmentType,
            deliveryTimeWindow:
              createdOrder.deliveryTimeWindow || "დღეს, 16:00 - 19:00",
            deliveryAddress: createdOrder.deliveryAddress,
            cancellationReason: createdOrder.cancellationReason,
            cancellationDeadline:
              createdOrder.cancellationDeadline?.toISOString() ?? null,
            shipmentStatus: createdOrder.shipment?.status ?? "PENDING",
            trackingNumber:
              createdOrder.shipment?.trackingNumber ??
              `AK-${createdOrder.id.slice(-5)}`,
            items: createdOrder.items.map((item) => ({
              productId: item.productId,
              name: item.product.title,
              quantity: item.quantity,
              unit: item.product.unit,
              quantityText: `${item.quantity}${item.product.unit}`,
              pricePerUnit: item.pricePerUnit,
              price: item.subtotal,
            })),
          },
          201
        );
      }

      if (path.startsWith("/api/orders/") && path.endsWith("/status") && method === "PATCH") {
        const orderId = path.replace("/api/orders/", "").replace("/status", "");
        const body = (await request.json()) as {
          status: OrderStatus;
          cancellationReason?: string;
          shipmentStatus?: ShipmentStatus;
          requesterId?: string;       // userId of the caller (client or farmer user)
          requesterFarmerId?: string; // farmerId if caller is a farmer
        };

        // ── Cancellation permission check ──────────────────────────────────
        if (body.status === OrderStatus.CANCELLED) {
          const orderToCheck = await prisma.order.findUnique({
            where: { id: orderId },
            select: {
              clientId: true,
              farmerId: true,
              status: true,
              cancellationDeadline: true,
            },
          });

          if (!orderToCheck) {
            return errorResponse("Order not found", 404);
          }

          const isAlreadyCancelled = orderToCheck.status === OrderStatus.CANCELLED;
          if (isAlreadyCancelled) {
            return errorResponse("Order is already cancelled", 409);
          }

          const isClient = body.requesterId === orderToCheck.clientId;
          const isFarmer =
            body.requesterFarmerId &&
            body.requesterFarmerId === orderToCheck.farmerId;

          if (!isClient && !isFarmer) {
            // If neither matches (e.g. requester fields missing), still allow
            // but log the anomaly — conservative approach during migration
            console.warn(`[Cancel] requesterId=${body.requesterId} farmerId=${body.requesterFarmerId} orderId=${orderId} — no match, allowing`);
          }

          if (isClient && !isFarmer) {
            // Client cancellation rules:
            //  • PENDING → always allowed
            //  • IN_PROGRESS → only within the 30-min window
            if (orderToCheck.status === OrderStatus.IN_PROGRESS) {
              const deadline = orderToCheck.cancellationDeadline;
              if (!deadline || new Date() > deadline) {
                return errorResponse(
                  "გაუქმების ვადა გავიდა. შეკვეთა IN_PROGRESS სტატუსშია — პირდაპირ გაუქმება ვეღარ შეიძლება.",
                  403
                );
              }
            } else if (orderToCheck.status !== OrderStatus.PENDING) {
              return errorResponse(
                "კლიენტს შეუძლია გაუქმება მხოლოდ PENDING ან IN_PROGRESS (30 წთ-ის განმავლობაში) სტატუსებში.",
                403
              );
            }
          }
          // Farmer can cancel any active (non-completed) order — no extra check needed
        }
        // ──────────────────────────────────────────────────────────────────

        const mappedShipmentStatus =
          body.shipmentStatus ??
          (body.status === OrderStatus.IN_PROGRESS
            ? ShipmentStatus.IN_TRANSIT
            : body.status === OrderStatus.COMPLETED
            ? ShipmentStatus.CONFIRMED
            : ShipmentStatus.PENDING);

        const updated = await prisma.$transaction(async (tx) => {
          const existingOrder = await tx.order.findUnique({
            where: { id: orderId },
            include: { items: true },
          });

          // If cancelling an active order, restore reserved product stock
          if (
            existingOrder &&
            body.status === OrderStatus.CANCELLED &&
            existingOrder.status !== OrderStatus.CANCELLED
          ) {
            for (const item of existingOrder.items) {
              const prod = await tx.product.findUnique({
                where: { id: item.productId },
              });
              if (prod) {
                const restoredStock = prod.stockQuantity + Number(item.quantity);
                await tx.product.update({
                  where: { id: prod.id },
                  data: {
                    stockQuantity: restoredStock,
                    stockStatus:
                      restoredStock <= 0
                        ? "ამოწურულია"
                        : restoredStock < 20
                        ? "იწურება"
                        : "მარაგშია",
                    isAvailable: restoredStock > 0,
                  },
                });
              }
            }
          }

          return tx.order.update({
            where: { id: orderId },
            data: {
              status: body.status,
              ...(body.cancellationReason
                ? { cancellationReason: body.cancellationReason }
                : {}),
              ...(body.status === OrderStatus.IN_PROGRESS
                ? { cancellationDeadline: new Date(Date.now() + 30 * 60 * 1000) }
                : {}),
              shipment: {
                upsert: {
                  create: {
                    status: mappedShipmentStatus,
                    trackingNumber: `AK-${orderId}`,
                  },
                  update: {
                    status: mappedShipmentStatus,
                  },
                },
              },
            },
            include: {
              client: true,
              items: { include: { product: true } },
              shipment: true,
            },
          });
        });

        // Send and persist Push Notification to Client about Order Status Change
        (async () => {
          try {
            // Skip PENDING — that's the initial state; client gets no spurious ping
            if (updated.status === "PENDING") return;

            const notifications: Record<string, { title: string; body: string }> = {
              IN_PROGRESS: {
                title: "შეკვეთა დადასტურდა!",
                body: `ფერმერი შეკვეთის #${updated.id.slice(-5)} მომზადებას იწყებს. ჩათი ახლა ხელმისაწვდომია.`,
              },
              CONFIRMED: {
                title: "შეკვეთა დადასტურდა!",
                body: `ფერმერი შეკვეთის #${updated.id.slice(-5)} მომზადებას იწყებს. ჩათი ახლა ხელმისაწვდომია.`,
              },
              COMPLETED: {
                title: "შეკვეთა ჩაბარდა!",
                body: `შეკვეთა #${updated.id.slice(-5)} წარმატებით დასრულდა. გმადლობთ AgroKera-ს გამოყენებისთვის!`,
              },
              CANCELLED: {
                title: "შეკვეთა გაუქმდა",
                body: `სამწუხაროდ, შეკვეთა #${updated.id.slice(-5)} გაუქმდა.${updated.cancellationReason ? " მიზეზი: " + updated.cancellationReason : ""}`,
              },
            };

            const notif = notifications[updated.status];
            if (!notif) return; // unknown status — skip

            await createAndSendNotification({
              userId: updated.clientId,
              title: notif.title,
              body: notif.body,
              orderId: updated.id,
              category: "orders",
              data: {
                orderId: updated.id,
                type: "order_status_updated",
                status: updated.status,
              },
            });
          } catch (pushErr) {
            console.error("[FCM Client Notification Error]:", pushErr);
          }
        })();

        return jsonResponse({
          id: updated.id,
          createdAt: updated.createdAt.toISOString(),
          status: updated.status,
          customerName: updated.contactPerson || updated.client.fullName,
          contactPerson: updated.contactPerson || updated.client.fullName,
          contactPhone: null,
          hasVat: updated.hasVat,
          totalAmount: updated.totalAmount,
          fulfillmentType: updated.fulfillmentType,
          deliveryTimeWindow: updated.deliveryTimeWindow || "დღეს, 16:00 - 19:00",
          deliveryAddress: updated.deliveryAddress,
          cancellationReason: updated.cancellationReason,
          cancellationDeadline:
            updated.cancellationDeadline?.toISOString() ?? null,
          shipmentStatus: updated.shipment?.status ?? "PENDING",
          trackingNumber:
            updated.shipment?.trackingNumber ?? `AK-${updated.id.slice(-5)}`,
          items: updated.items.map((item) => ({
            productId: item.productId,
            name: item.product.title,
            quantity: item.quantity,
            unit: item.product.unit,
            quantityText: `${item.quantity}${item.product.unit}`,
            pricePerUnit: item.pricePerUnit,
            price: item.subtotal,
          })),
        });
      }

      // ==========================================
      // 4.5 ORDER MESSAGES & CHAT
      // ==========================================
      if (path.startsWith("/api/orders/") && path.endsWith("/messages") && method === "GET") {
        const orderId = path.replace("/api/orders/", "").replace("/messages", "");
        let messages = await prisma.orderMessage.findMany({
          where: { orderId },
          orderBy: { createdAt: "asc" },
        });

        if (messages.length === 0) {
          try {
            const initial = await prisma.orderMessage.create({
              data: {
                id: `sys_${orderId}`,
                orderId,
                senderId: "system",
                senderRole: "guest",
                senderName: "AgroKera System",
                text: "შეკვეთის ჩათი გააქტიურდა. გამოიყენეთ მისამართისა და ჩაბარების დროის დასაზუსტებლად.",
                isSystem: true,
              },
            });
            messages = [initial];
          } catch (_) {
            messages = await prisma.orderMessage.findMany({
              where: { orderId },
              orderBy: { createdAt: "asc" },
            });
          }
        }

        return jsonResponse(
          messages.map((m) => ({
            id: m.id,
            orderId: m.orderId,
            senderId: m.senderId,
            senderRole: m.senderRole,
            senderName: m.senderName,
            text: m.text,
            isSystem: m.isSystem,
            createdAt: m.createdAt.toISOString(),
          }))
        );
      }

      if (path.startsWith("/api/orders/") && path.endsWith("/messages") && method === "POST") {
        const orderId = path.replace("/api/orders/", "").replace("/messages", "");
        const body = (await request.json()) as {
          id?: string;
          senderId?: string;
          senderRole?: string;
          senderName?: string;
          text?: string;
          isSystem?: boolean;
          createdAt?: string;
        };

        const rawText = (body.text || "").trim();
        if (!rawText) {
          return errorResponse("Message text cannot be empty", 400);
        }

        // Chat is open only after the farmer confirmed the order and
        // closes as soon as the order is completed or cancelled.
        const chatOrder = await prisma.order.findUnique({
          where: { id: orderId },
          select: { status: true },
        });
        if (!chatOrder) {
          return errorResponse("Order not found", 404);
        }
        if (!body.isSystem && chatOrder.status !== "IN_PROGRESS" && chatOrder.status !== "CONFIRMED") {
          const reason =
            chatOrder.status === "PENDING"
              ? "ჩათი გაიხსნება ფერმერის მიერ შეკვეთის დადასტურების შემდეგ"
              : "შეკვეთა დასრულებულია • ჩათი დახურულია";
          return errorResponse(reason, 403);
        }

        // Do not allow sharing phone numbers through chat
        const cleanText = maskPhoneNumbers(rawText);

        const msgId = body.id || `msg_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
        const message = await prisma.orderMessage.upsert({
          where: { id: msgId },
          create: {
            id: msgId,
            orderId,
            senderId: body.senderId || "unknown",
            senderRole: body.senderRole || "customer",
            senderName: body.senderName || "მომხმარებელი",
            text: cleanText,
            isSystem: Boolean(body.isSystem),
            createdAt: body.createdAt ? new Date(body.createdAt) : new Date(),
          },
          update: {
            text: cleanText,
          },
        });

        // Send and persist Push Notification to recipient
        (async () => {
          try {
            const order = await prisma.order.findUnique({
              where: { id: orderId },
              select: { clientId: true, farmerId: true },
            });
            if (!order) return;
            const farmerProfile = order.farmerId
              ? await prisma.farmerProfile.findUnique({
                  where: { id: order.farmerId },
                  select: { userId: true },
                })
              : null;
            const isSenderFarmer = body.senderRole === "farmer";
            const targetUserId = isSenderFarmer
              ? order.clientId
              : farmerProfile?.userId;
            if (targetUserId) {
              await createAndSendNotification({
                userId: targetUserId,
                title: `ახალი შეტყობინება (${body.senderName || "AgroKera"})`,
                body: cleanText,
                orderId,
                category: "orders",
                data: {
                  orderId,
                  type: "chat_message",
                },
              });
            }
          } catch (pushErr) {
            console.error("[FCM Chat Error]:", pushErr);
          }
        })();

        return jsonResponse(
          {
            id: message.id,
            orderId: message.orderId,
            senderId: message.senderId,
            senderRole: message.senderRole,
            senderName: message.senderName,
            text: message.text,
            isSystem: message.isSystem,
            createdAt: message.createdAt.toISOString(),
          },
          201
        );
      }

      return errorResponse(`Route not found: ${method} ${path}`, 404);
    } catch (err) {
      console.error("[AgroKera API Error]:", err);
      const message = err instanceof Error ? err.message : "Internal server error";
      return errorResponse(message, 500);
    }
  },
};

/**
 * Replaces phone numbers in chat messages so that client and farmer
 * cannot exchange numbers (e.g. "599 12 34 56", "+995599123456", "5-99-12-34-56").
 */
function maskPhoneNumbers(text: string): string {
  return text.replace(/\+?\d(?:[\s\-().]*\d){8,}/g, "[ნომერი დამალულია]");
}

// ============================================================
// CRON JOB: remind stale IN_PROGRESS orders
// POST /api/cron/remind-stale-orders  (called by server.ts setInterval)
// Header: x-cron-secret: <CRON_SECRET>
//
// Sends push to FARMER when order is IN_PROGRESS for > 2 h and not completed:
//   "PIN კოდი ჯერ არ ჩაწერია — შეკვეთა ვერ დაიხურება"
// Sends push to CLIENT when order is IN_PROGRESS for > 6 h:
//   "გთხოვთ გადასცეთ PIN ფერმერს შეკვეთის დასასრულებლად"
// ============================================================
export async function remindStaleOrders(): Promise<{ reminded: number }> {
  const now = new Date();
  const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

  // All orders stuck in IN_PROGRESS
  const staleOrders = await prisma.order.findMany({
    where: { status: "IN_PROGRESS" },
    select: {
      id: true,
      clientId: true,
      farmerId: true,
      updatedAt: true,
      cancellationReason: true,
    },
  });

  let reminded = 0;

  for (const order of staleOrders) {
    const ageMs = now.getTime() - order.updatedAt.getTime();
    const ageHours = ageMs / (1000 * 60 * 60);
    const shortId = order.id.slice(-5);

    // Check if we already sent a reminder for this order in the last 24 h
    const recentReminder = await prisma.notification.findFirst({
      where: {
        orderId: order.id,
        title: { in: ["შეკვეთა ვერ დაიხურება!", "შეკვეთა ჯერ არ დასრულებულა"] },
        createdAt: { gte: oneDayAgo },
      },
      select: { id: true },
    });

    // Already reminded today — skip entirely
    if (recentReminder) continue;

    // --- Remind farmer after 2 h ---
    if (ageHours >= 2 && order.farmerId) {
      const farmerProfile = await prisma.farmerProfile.findUnique({
        where: { id: order.farmerId },
        select: { userId: true },
      });
      if (farmerProfile?.userId) {
        await createAndSendNotification({
          userId: farmerProfile.userId,
          title: "შეკვეთა ვერ დაიხურება!",
          body: `შეკვეთა #${shortId} დიდი ხანია მიმდინარეა. PIN კოდი ჯერ არ ჩაწერია — სთხოვეთ კლიენტს.`,
          orderId: order.id,
          category: "orders",
          data: { orderId: order.id, type: "order_stale_farmer" },
        }).catch(() => {});
        reminded++;
      }
    }

    // --- Remind client after 6 h ---
    if (ageHours >= 6) {
      await createAndSendNotification({
        userId: order.clientId,
        title: "შეკვეთა ჯერ არ დასრულებულა",
        body: `შეკვეთა #${shortId} ჯერ ღიაა. გთხოვთ გადასცეთ PIN კოდი ფერმერს პროდუქციის ჩაბარებისთანავე.`,
        orderId: order.id,
        category: "orders",
        data: { orderId: order.id, type: "order_stale_client" },
      }).catch(() => {});
      reminded++;
    }
  }

  console.log(`[Cron] remindStaleOrders: checked ${staleOrders.length}, reminded ${reminded}`);
  return { reminded };
}
