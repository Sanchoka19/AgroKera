import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  CreateBucketCommand,
} from "@aws-sdk/client-s3";
import { jsonResponse, errorResponse } from "../utils.ts";

export async function handleAssetsRoute(
  request: Request,
  url: URL,
  path: string,
  method: string
): Promise<Response | null> {
  // GET or HEAD /api/assets/*
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

  // POST /api/upload
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
    if (buffer.length > 10 * 1024 * 1024) {
      return errorResponse("ფაილის ზომა არ უნდა აღემატებოდეს 10MB-ს", 413);
    }

    const rawContentType = body.contentType || "image/jpeg";
    const contentType = rawContentType.startsWith("image/") ? rawContentType : "image/jpeg";
    const ext = (body.fileName?.split(".").pop() || "jpg").toLowerCase().replace(/[^a-z0-9]/g, "");
    const allowedFolders = ["products", "avatars", "covers", "kyc", "chat"];
    const folder = allowedFolders.includes(body.folder || "") ? body.folder! : "products";
    const objectKey = `${folder}/${Date.now()}_${Math.random().toString(36).slice(2, 8)}.${ext || "jpg"}`;

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

  return null;
}

