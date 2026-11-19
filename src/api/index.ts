import prisma from "../lib/prisma.ts";
import { corsHeaders, jsonResponse, errorResponse } from "./utils.ts";
import { handleAssetsRoute } from "./routes/assets.ts";
import { handleNotificationsRoute } from "./routes/notifications.ts";
import { handleAuthRoute } from "./routes/auth.ts";
import { handleProfileRoute } from "./routes/profile.ts";
import { handleProductsRoute } from "./routes/products.ts";
import { handleOrdersRoute } from "./routes/orders.ts";
import { handleReviewsRoute } from "./routes/reviews.ts";
import {
  remindStaleOrders,
  calculatePendingOrderDeadline,
  processOrderExpirations,
} from "../lib/order-cron.ts";

export {
  remindStaleOrders,
  calculatePendingOrderDeadline,
  processOrderExpirations,
};

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
      // INTERNAL CRON — process expired pending orders & pre-expiry warnings
      // ==========================================
      if ((method === "POST" || method === "GET") && path === "/api/cron/process-expirations") {
        const secret = request.headers.get("x-cron-secret");
        const expected = process.env.CRON_SECRET;
        if (expected && secret !== expected) {
          return errorResponse("Unauthorized", 401);
        }
        const result = await processOrderExpirations();
        return jsonResponse(result);
      }

      // ==========================================
      // 1.5 CLOUDFLARE R2 IMAGE UPLOAD & SERVE
      // ==========================================
      const assetsResponse = await handleAssetsRoute(request, url, path, method);
      if (assetsResponse) return assetsResponse;

      // ==========================================
      // 2. AUTH & ONBOARDING
      // ==========================================
      const authResponse = await handleAuthRoute(request, url, path, method);
      if (authResponse) return authResponse;

      // ==========================================
      // NOTIFICATIONS & FCM ENDPOINTS
      // ==========================================
      const notifResponse = await handleNotificationsRoute(request, url, path, method);
      if (notifResponse) return notifResponse;

      // ==========================================
      // PROFILE ENDPOINTS
      // ==========================================
      const profileResponse = await handleProfileRoute(request, url, path, method);
      if (profileResponse) return profileResponse;

      // ==========================================
      // 3. FARMERS & MARKETPLACE PRODUCTS
      // ==========================================
      const productsResponse = await handleProductsRoute(request, url, path, method);
      if (productsResponse) return productsResponse;

      // ==========================================
      // 4. ORDERS & CHECKOUT & TRACKING & CHAT
      // ==========================================
      const ordersResponse = await handleOrdersRoute(request, url, path, method);
      if (ordersResponse) return ordersResponse;

      // ==========================================
      // 4.6 REVIEWS & RATINGS
      // ==========================================
      const reviewsResponse = await handleReviewsRoute(request, url, path, method);
      if (reviewsResponse) return reviewsResponse;

      return errorResponse(`Route not found: ${method} ${path}`, 404);
    } catch (err) {
      console.error("[AgroKera API Error]:", err);
      const message = err instanceof Error ? err.message : "Internal server error";
      return errorResponse(message, 500);
    }
  },
};
