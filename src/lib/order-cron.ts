import prisma from "./prisma.ts";
import { OrderStatus, ShipmentStatus } from "@prisma/client";
import { NotificationTemplates } from "./notification-templates.ts";
import { createAndSendNotification } from "./push-notifications.ts";

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
        const tmpl = NotificationTemplates.staleReminderFarmer(order.id);
        await createAndSendNotification({
          userId: farmerProfile.userId,
          title: tmpl.title,
          body: tmpl.body,
          orderId: order.id,
          category: tmpl.category,
          data: tmpl.data,
        }).catch(() => { });
        reminded++;
      }
    }

    // --- Remind client after 6 h ---
    if (ageHours >= 6) {
      const tmpl = NotificationTemplates.staleReminderClient(order.id);
      await createAndSendNotification({
        userId: order.clientId,
        title: tmpl.title,
        body: tmpl.body,
        orderId: order.id,
        category: tmpl.category,
        data: tmpl.data,
      }).catch(() => { });
      reminded++;
    }
  }

  console.log(`[Cron] remindStaleOrders: checked ${staleOrders.length}, reminded ${reminded}`);
  return { reminded };
}

// ============================================================
// WORKING HOURS & ORDER EXPIRATION MONITOR
// ============================================================

/**
 * Calculates the pending order review deadline based on Georgia time (UTC+4):
 * - Working hours: 08:00 - 21:00 GET
 * - Urgent/same-day ("დღეს"): 45 min
 * - Scheduled/future ("ხვალ"/"ზეგ"): 120 min (2 h)
 * - Default: 60 min
 * - If created during quiet hours (21:00 - 08:00), the deadline starts from next 08:00.
 */
export function calculatePendingOrderDeadline(
  now: Date = new Date(),
  deliveryTimeWindow?: string | null
): Date {
  const georgiaOffsetMs = 4 * 60 * 60 * 1000;
  const georgiaTime = new Date(now.getTime() + georgiaOffsetMs);
  const gHours = georgiaTime.getUTCHours();
  const gMinutes = georgiaTime.getUTCMinutes();

  const windowStr = (deliveryTimeWindow || "").toLowerCase();
  let durationMinutes = 60;
  if (windowStr.includes("დღეს") || windowStr.includes("today")) {
    durationMinutes = 45;
  } else if (
    windowStr.includes("ხვალ") ||
    windowStr.includes("tomorrow") ||
    windowStr.includes("ზეგ")
  ) {
    durationMinutes = 120;
  }

  // Quiet Hours Check: 21:00 - 08:00 Georgia time
  if (gHours < 8) {
    // Before working hours today -> Start at today 08:00 GET
    const targetGeorgiaMs =
      Date.UTC(
        georgiaTime.getUTCFullYear(),
        georgiaTime.getUTCMonth(),
        georgiaTime.getUTCDate(),
        8,
        0,
        0
      ) + durationMinutes * 60 * 1000;
    return new Date(targetGeorgiaMs - georgiaOffsetMs);
  } else if (gHours >= 21) {
    // After working hours today -> Start at tomorrow 08:00 GET
    const targetGeorgiaMs =
      Date.UTC(
        georgiaTime.getUTCFullYear(),
        georgiaTime.getUTCMonth(),
        georgiaTime.getUTCDate() + 1,
        8,
        0,
        0
      ) + durationMinutes * 60 * 1000;
    return new Date(targetGeorgiaMs - georgiaOffsetMs);
  } else {
    // During working hours (08:00 - 21:00)
    const remainingWorkMinToday = (21 - gHours) * 60 - gMinutes;
    if (durationMinutes <= remainingWorkMinToday) {
      return new Date(now.getTime() + durationMinutes * 60 * 1000);
    } else {
      // Overflows past 21:00 into tomorrow 08:00
      const overflowMin = durationMinutes - remainingWorkMinToday;
      const targetGeorgiaMs =
        Date.UTC(
          georgiaTime.getUTCFullYear(),
          georgiaTime.getUTCMonth(),
          georgiaTime.getUTCDate() + 1,
          8,
          0,
          0
        ) + overflowMin * 60 * 1000;
      return new Date(targetGeorgiaMs - georgiaOffsetMs);
    }
  }
}

/**
 * CRON JOB: Process pending order auto-expirations and pre-expiry warning notifications.
 *
 * 1. Overdue pending orders (now > cancellationDeadline):
 *    - Status set to CANCELLED
 *    - Reserved stock restored
 *    - Push notifications sent to client & farmer
 *
 * 2. Pre-expiry warning (remaining <= 10 min):
 *    - High-priority push sent to farmer before deadline expires
 */
export async function processOrderExpirations(): Promise<{
  cancelled: number;
  warned: number;
}> {
  const now = new Date();
  let cancelled = 0;
  let warned = 0;

  // 1. Auto-cancel expired pending orders
  const expiredOrders = await prisma.order.findMany({
    where: {
      status: OrderStatus.PENDING,
      cancellationDeadline: {
        not: null,
        lte: now,
      },
    },
    include: {
      items: true,
      client: true,
    },
  });

  for (const order of expiredOrders) {
    try {
      await prisma.$transaction(async (tx) => {
        const current = await tx.order.findUnique({
          where: { id: order.id },
          select: { status: true },
        });
        if (current?.status !== OrderStatus.PENDING) return;

        // Restore reserved product stock
        for (const item of order.items) {
          const prod = await tx.product.findUnique({
            where: { id: item.productId },
          });
          if (prod) {
            const restoredStock = prod.quantity + item.quantity;
            await tx.product.update({
              where: { id: item.productId },
              data: {
                quantity: restoredStock,
                isAvailable: restoredStock > 0,
              },
            });
          }
        }

        // Mark order cancelled
        await tx.order.update({
          where: { id: order.id },
          data: {
            status: OrderStatus.CANCELLED,
            cancellationReason:
              "ფერმერმა შეკვეთა დადგენილ დროში ვერ დაადასტურა (ვადა ამოიწურა)",
            shipment: {
              upsert: {
                create: {
                  status: ShipmentStatus.PENDING,
                  trackingNumber: `AK-${order.id}`,
                },
                update: {
                  status: ShipmentStatus.PENDING,
                },
              },
            },
          },
        });
      });

      cancelled++;

      // Notify client
      if (order.clientId) {
        const tmpl = NotificationTemplates.autoCancelled(order.id, false);
        await createAndSendNotification({
          userId: order.clientId,
          title: tmpl.title,
          body: tmpl.body,
          orderId: order.id,
          category: tmpl.category,
          data: tmpl.data,
        }).catch(() => { });
      }

      // Notify farmer
      if (order.farmerId) {
        const farmerProfile = await prisma.farmerProfile.findUnique({
          where: { id: order.farmerId },
          select: { userId: true },
        });
        if (farmerProfile?.userId) {
          const tmpl = NotificationTemplates.autoCancelled(order.id, true);
          await createAndSendNotification({
            userId: farmerProfile.userId,
            title: tmpl.title,
            body: tmpl.body,
            orderId: order.id,
            category: tmpl.category,
            data: tmpl.data,
          }).catch(() => { });
        }
      }
    } catch (err) {
      console.error(`[Cron] Failed to auto-cancel order ${order.id}:`, err);
    }
  }

  // 2. Pre-expiry warning to farmer (<= 10 minutes remaining)
  const pendingOrders = await prisma.order.findMany({
    where: {
      status: OrderStatus.PENDING,
      cancellationDeadline: {
        not: null,
        gt: now,
      },
    },
    select: {
      id: true,
      farmerId: true,
      cancellationDeadline: true,
    },
  });

  for (const order of pendingOrders) {
    if (!order.cancellationDeadline || !order.farmerId) continue;
    const diffMs = order.cancellationDeadline.getTime() - now.getTime();
    const remainingMinutes = diffMs / (60 * 1000);

    if (remainingMinutes <= 10 && remainingMinutes > 0) {
      const alreadyWarned = await prisma.notification.findFirst({
        where: {
          orderId: order.id,
          OR: [
            { title: { contains: "მალე გაუქმდება" } },
            { title: { contains: "დარჩენილია" } },
          ],
        },
        select: { id: true },
      });

      if (!alreadyWarned) {
        const farmerProfile = await prisma.farmerProfile.findUnique({
          where: { id: order.farmerId },
          select: { userId: true },
        });
        if (farmerProfile?.userId) {
          const tmpl = NotificationTemplates.expiryWarningFarmer(order.id, remainingMinutes);
          await createAndSendNotification({
            userId: farmerProfile.userId,
            title: tmpl.title,
            body: tmpl.body,
            orderId: order.id,
            category: tmpl.category,
            data: tmpl.data,
          }).catch(() => { });
          warned++;
        }
      }
    }
  }

  if (cancelled > 0 || warned > 0) {
    console.log(
      `[Cron] processOrderExpirations: cancelled ${cancelled}, warned ${warned}`
    );
  }
  return { cancelled, warned };
}

