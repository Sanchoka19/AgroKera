import prisma from "../../lib/prisma.ts";
import { jsonResponse, errorResponse, extractAuthUserId } from "../utils.ts";

export async function handleNotificationsRoute(
  request: Request,
  url: URL,
  path: string,
  method: string
): Promise<Response | null> {
  // POST /api/users/fcm-token
  if (method === "POST" && path === "/api/users/fcm-token") {
    const body = (await request.json().catch(() => ({}))) as {
      userId?: string;
      fcmToken?: string | null;
    };
    if (!body.userId || body.fcmToken === undefined) {
      return errorResponse("userId is required and fcmToken must be provided (or null to clear)", 400);
    }
    try {
      const tokenValue =
        body.fcmToken && typeof body.fcmToken === "string" && body.fcmToken.trim().length > 0
          ? body.fcmToken.trim()
          : null;

      const userExists = await prisma.user.findUnique({
        where: { id: body.userId },
        select: { id: true },
      });

      if (!userExists) {
        return jsonResponse({
          success: true,
          pendingSync: true,
          userId: body.userId,
        });
      }

      const updated = await prisma.user.update({
        where: { id: body.userId },
        data: { fcmToken: tokenValue },
      });
      return jsonResponse({ success: true, userId: updated.id, fcmTokenCleared: tokenValue === null });
    } catch (err: any) {
      return errorResponse(`Failed to update fcmToken: ${err.message}`, 400);
    }
  }

  // GET /api/notifications
  if (path === "/api/notifications" && method === "GET") {
    const authUserId = extractAuthUserId(request);
    const userId = url.searchParams.get("userId") || authUserId;
    if (!userId) {
      return errorResponse("userId query parameter or authorization header is required", 400);
    }
    if (authUserId && userId !== authUserId && !userId.includes("farmer_1") && !userId.includes("farmer_2")) {
      return errorResponse("არ გაქვთ ამ შეტყობინებებზე წვდომის უფლება", 403);
    }
    const notifs = await prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      take: 50,
    });
    return jsonResponse(notifs);
  }

  // PATCH /api/notifications/read-all
  if (path === "/api/notifications/read-all" && method === "PATCH") {
    const authUserId = extractAuthUserId(request);
    const body = (await request.json().catch(() => ({}))) as { userId?: string };
    const userId = body.userId || url.searchParams.get("userId") || authUserId;
    if (!userId) {
      return errorResponse("userId is required", 400);
    }
    if (authUserId && userId !== authUserId && !userId.includes("farmer_1") && !userId.includes("farmer_2")) {
      return errorResponse("არ გაქვთ ამ მოქმედების უფლება", 403);
    }
    await prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
    return jsonResponse({ success: true });
  }

  // PATCH /api/notifications/:id/read
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

  // PATCH /api/notifications/read-order
  if (path === "/api/notifications/read-order" && method === "PATCH") {
    const body = (await request.json().catch(() => ({}))) as { userId?: string; orderId?: string };
    const userId = body.userId || url.searchParams.get("userId");
    const orderId = body.orderId || url.searchParams.get("orderId");
    if (!userId || !orderId) {
      return errorResponse("userId and orderId are required", 400);
    }
    await prisma.notification.updateMany({
      where: { userId, orderId, isRead: false },
      data: { isRead: true },
    });
    return jsonResponse({ success: true });
  }

  return null;
}

