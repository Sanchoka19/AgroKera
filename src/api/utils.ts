import crypto from "node:crypto";

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PATCH, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Content-Type": "application/json; charset=utf-8",
};

const JWT_SECRET = process.env.JWT_SECRET || "agrokera_jwt_production_secret_key_2026";

/**
 * Creates a cryptographically signed HMAC-SHA256 authentication token.
 * Token includes standard JWT claims (sub, iat, exp) valid for 30 days.
 */
export function createAuthToken(userId: string): string {
  const header = Buffer.from(JSON.stringify({ alg: "HS256", typ: "JWT" })).toString("base64url");
  const payload = Buffer.from(
    JSON.stringify({
      sub: userId,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60, // 30 days
    })
  ).toString("base64url");
  const signature = crypto
    .createHmac("sha256", JWT_SECRET)
    .update(`${header}.${payload}`)
    .digest("base64url");

  return `ak_jwt_${header}.${payload}.${signature}`;
}

/**
 * Validates Authorization header and extracts the authenticated userId.
 * Supports both modern HMAC signed tokens and legacy ak_jwt_<id> for seamless backwards compatibility.
 */
export function extractAuthUserId(request: Request): string | null {
  const authHeader =
    request.headers.get("authorization") || request.headers.get("Authorization");
  if (!authHeader) return null;
  const parts = authHeader.split(" ");
  if (parts.length !== 2 || parts[0].toLowerCase() !== "bearer") return null;
  const token = parts[1].trim();

  if (token.startsWith("ak_jwt_")) {
    const raw = token.slice("ak_jwt_".length);
    if (!raw.includes(".")) {
      return raw || null;
    }
    try {
      const [header, payload, signature] = raw.split(".");
      if (!header || !payload || !signature) return null;
      const expectedSig = crypto
        .createHmac("sha256", JWT_SECRET)
        .update(`${header}.${payload}`)
        .digest("base64url");
      if (signature !== expectedSig) return null;
      const decoded = JSON.parse(Buffer.from(payload, "base64url").toString());
      if (decoded.exp && Math.floor(Date.now() / 1000) > decoded.exp) return null;
      return decoded.sub || null;
    } catch {
      return null;
    }
  }

  return null;
}

export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: corsHeaders,
  });
}

export function errorResponse(message: string, status = 400): Response {
  return jsonResponse({ error: message }, status);
}

/**
 * Secure password hashing using Node's crypto scrypt.
 */
export function hashPassword(password: string): string {
  const salt = crypto.randomBytes(16).toString("hex");
  const hash = crypto.scryptSync(password, salt, 64).toString("hex");
  return `${salt}:${hash}`;
}

/**
 * Verifies a plain text password against a stored scrypt hash string.
 */
export function verifyPassword(password: string, storedHash: string): boolean {
  try {
    const [salt, key] = storedHash.split(":");
    if (!salt || !key) return false;
    const keyBuffer = Buffer.from(key, "hex");
    const derivedBuffer = crypto.scryptSync(password, salt, 64);
    return crypto.timingSafeEqual(keyBuffer, derivedBuffer);
  } catch {
    return false;
  }
}

/**
 * Replaces phone numbers in chat messages so that client and farmer
 * cannot exchange numbers (e.g. "599 12 34 56", "+995599123456", "5-99-12-34-56").
 */
export function maskPhoneNumbers(text: string): string {
  return text.replace(/\+?\d(?:[\s\-().]*\d){8,}/g, "[ნომერი დამალულია]");
}

export interface FarmerDeliverySettings {
  isDeliveryEnabled?: boolean;
  deliveryCity?: string;
  deliveryDays?: string[];
  deliveryFee?: number;
  regionalDeliveryFees?: Record<string, number>;
  location?: string;
}

export const farmerDeliverySettingsMap = new Map<string, FarmerDeliverySettings>();


