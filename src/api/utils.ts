export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PATCH, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Content-Type": "application/json; charset=utf-8",
};

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


