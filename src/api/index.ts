import prisma from "../lib/prisma.ts";
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
          phone: f.user.phoneNumber || "+995 599 11 22 33",
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

        const formatted = orders.map((o) => ({
          id: o.id,
          farmerId: o.farmerId,
          clientId: o.clientId,
          createdAt: o.createdAt.toISOString(),
          status: o.status,
          customerName: o.client.fullName,
          contactPerson: o.contactPerson || o.client.fullName,
          contactPhone: o.contactPhone || o.client.phoneNumber || "+995 599 12 34 56",
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

        return jsonResponse(
          {
            id: createdOrder.id,
            farmerId: createdOrder.farmerId,
            clientId: createdOrder.clientId,
            createdAt: createdOrder.createdAt.toISOString(),
            status: createdOrder.status,
            customerName: createdOrder.contactPerson || createdOrder.client.fullName,
            contactPerson: createdOrder.contactPerson || createdOrder.client.fullName,
            contactPhone:
              createdOrder.contactPhone ||
              createdOrder.client.phoneNumber ||
              "+995 599 12 34 56",
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
        };

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

        return jsonResponse({
          id: updated.id,
          createdAt: updated.createdAt.toISOString(),
          status: updated.status,
          customerName: updated.contactPerson || updated.client.fullName,
          contactPerson: updated.contactPerson || updated.client.fullName,
          contactPhone:
            updated.contactPhone ||
            updated.client.phoneNumber ||
            "+995 599 12 34 56",
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

        const cleanText = (body.text || "").trim();
        if (!cleanText) {
          return errorResponse("Message text cannot be empty", 400);
        }

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

