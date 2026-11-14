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
          role?: string;
        };

        const roleEnum =
          body.role?.toUpperCase() === "FARMER" ? Role.FARMER : Role.CLIENT;

        let user = await prisma.user.findFirst({
          where: {
            OR: [
              ...(body.phone ? [{ phoneNumber: body.phone }] : []),
              ...(body.email ? [{ email: body.email }] : []),
            ],
          },
          include: { farmerProfile: true },
        });

        if (!user) {
          user = await prisma.user.create({
            data: {
              fullName: body.name || (roleEnum === Role.FARMER ? "გიორგი ბერიძე" : "საბა ევგენიძე"),
              phoneNumber: body.phone || `+995599${Math.floor(100000 + Math.random() * 900000)}`,
              email: body.email || `user_${Date.now()}@agrokera.ge`,
              role: roleEnum,
              verificationStatus:
                roleEnum === Role.FARMER
                  ? VerificationStatus.VERIFIED
                  : VerificationStatus.VERIFIED,
              ...(roleEnum === Role.FARMER
                ? {
                    farmerProfile: {
                      create: {
                        farmName: `${body.name || "გიორგის"} ფერმა`,
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
          isVatPayer?: boolean;
        };

        const roleEnum =
          body.role?.toUpperCase() === "FARMER" ? Role.FARMER : Role.CLIENT;

        const user = await prisma.user.upsert({
          where: {
            phoneNumber: body.phoneNumber || `+995599${Math.floor(100000 + Math.random() * 900000)}`,
          },
          update: {
            fullName: body.fullName,
            role: roleEnum,
          },
          create: {
            fullName: body.fullName || "ახალი მომხმარებელი",
            phoneNumber: body.phoneNumber,
            email: body.email,
            role: roleEnum,
            verificationStatus:
              roleEnum === Role.FARMER
                ? VerificationStatus.PENDING_REVIEW
                : VerificationStatus.VERIFIED,
            ...(roleEnum === Role.FARMER
              ? {
                  farmerProfile: {
                    create: {
                      farmName: body.farmName || `${body.fullName}-ის მეურნეობა`,
                      region: body.region || "კახეთი",
                      city: body.city || "თელავი",
                      address: body.address || "თელავი, კახეთი",
                      isVatPayer: body.isVatPayer ?? false,
                    },
                  },
                }
              : {}),
          },
          include: { farmerProfile: true },
        });

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
          };
        });

        return jsonResponse(formatted);
      }

      if (method === "POST" && path === "/api/products") {
        const body = (await request.json()) as {
          title: string;
          category: string;
          farmerId?: string;
          pricePerUnit: number;
          discountPercent?: number;
          unit?: string;
          stockQuantity?: number;
          minOrderQuantity?: number;
          imageUrl?: string;
          images?: string[];
          description?: string;
        };

        const targetFarmerId = body.farmerId || "farmer_2";
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
          // Decrement product stock
          for (const item of body.items) {
            const product = await tx.product.findUnique({
              where: { id: item.productId },
            });
            if (product) {
              const newStock = Math.max(0, product.stockQuantity - Number(item.quantity));
              await tx.product.update({
                where: { id: item.productId },
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
            }
          }

          const orderId = String(Math.floor(10000 + Math.random() * 90000));
          return tx.order.create({
            data: {
              id: orderId,
              clientId: body.clientId || "user_client_1",
              farmerId: body.farmerId || "farmer_2",
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
                create: body.items.map((i) => ({
                  productId: i.productId,
                  quantity: Number(i.quantity),
                  pricePerUnit: Number(i.pricePerUnit),
                  subtotal: Number(i.quantity) * Number(i.pricePerUnit),
                })),
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

        return jsonResponse(createdOrder, 201);
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

        const updated = await prisma.order.update({
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

        return jsonResponse(updated);
      }

      return errorResponse(`Route not found: ${method} ${path}`, 404);
    } catch (err) {
      console.error("[AgroKera API Error]:", err);
      const message = err instanceof Error ? err.message : "Internal server error";
      return errorResponse(message, 500);
    }
  },
};

