import { cert, initializeApp, getApps } from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";
import fs from "fs";
import path from "path";
import prisma from "./prisma.ts";

let isInitialized = false;

function initFirebase(): boolean {
  if (isInitialized) return true;
  try {
    let serviceAccount: any = null;

    // 1. Check Environment Variable (recommended for Render / Cloud)
    const envValue =
      process.env.FIREBASE_SERVICE_ACCOUNT ||
      process.env.FIREBASE_SERVICE_ACCOUNT_JSON ||
      process.env.FIREBASE_CONFIG_JSON;

    if (envValue && envValue.trim().length > 0) {
      try {
        const trimmed = envValue.trim();
        if (trimmed.startsWith("{")) {
          serviceAccount = JSON.parse(trimmed);
        } else {
          // Attempt base64 decoding if not direct JSON
          const decoded = Buffer.from(trimmed, "base64").toString("utf-8");
          serviceAccount = JSON.parse(decoded);
        }
        console.log("[FCM] Loaded Firebase credentials from Environment Variable.");
      } catch (parseErr) {
        console.error(
          "[FCM] Failed to parse FIREBASE_SERVICE_ACCOUNT environment variable:",
          parseErr
        );
      }
    }

    // 2. Check file paths (Local or Render Secret File)
    if (!serviceAccount) {
      const candidatePaths = [
        path.resolve(process.cwd(), "firebase-service-account.json"),
        "/etc/secrets/firebase-service-account.json", // Render standard secret file mount path
      ];

      for (const p of candidatePaths) {
        if (fs.existsSync(p)) {
          try {
            serviceAccount = JSON.parse(fs.readFileSync(p, "utf-8"));
            console.log(`[FCM] Loaded Firebase credentials from file: ${p}`);
            break;
          } catch (fileErr) {
            console.error(`[FCM] Error reading file ${p}:`, fileErr);
          }
        }
      }
    }

    if (!serviceAccount) {
      console.warn(
        "[FCM] Firebase service account not found! Push notifications disabled.\n" +
          "-> Add 'FIREBASE_SERVICE_ACCOUNT' in Render Environment Variables OR\n" +
          "-> Upload 'firebase-service-account.json' in Render Secret Files."
      );
      return false;
    }

    if (getApps().length === 0) {
      initializeApp({
        credential: cert(serviceAccount),
      });
    }
    isInitialized = true;
    console.log("[FCM] Firebase Admin SDK initialized successfully.");
    return true;
  } catch (err) {
    console.error("[FCM] Error initializing Firebase Admin SDK:", err);
    return false;
  }
}

export interface SendPushOptions {
  token?: string | null;
  tokens?: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

export async function sendPushNotification({
  token,
  tokens,
  title,
  body,
  data = {},
}: SendPushOptions): Promise<void> {
  if (!initFirebase()) return;

  const validTokens: string[] = [];
  if (token && typeof token === "string" && token.trim().length > 10) {
    validTokens.push(token.trim());
  }
  if (tokens && Array.isArray(tokens)) {
    for (const t of tokens) {
      if (
        t &&
        typeof t === "string" &&
        t.trim().length > 10 &&
        !validTokens.includes(t.trim())
      ) {
        validTokens.push(t.trim());
      }
    }
  }

  if (validTokens.length === 0) {
    console.log("[FCM] No valid token(s) provided. Skipping push notification.");
    return;
  }

  const stringData = Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, String(v ?? "")])
  );

  const messaging = getMessaging();

  const isChat = stringData.type === "chat_message" || title.includes("შეტყობინება");
  const isPromo = stringData.category === "promotions";
  const channelId = isChat
    ? "agrokera_chat_channel"
    : isPromo
    ? "agrokera_promotions_channel"
    : "agrokera_orders_channel";

  for (const targetToken of validTokens) {
    try {
      await messaging.send({
        token: targetToken,
        notification: {
          title,
          body,
        },
        data: stringData,
        android: {
          priority: isPromo ? "normal" : "high",
          notification: {
            channelId,
            sound: isPromo ? undefined : "default",
            defaultSound: !isPromo,
            defaultVibrateTimings: !isPromo,
            icon: "ic_notification",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
            tag: isChat && stringData.orderId ? `order_chat_${stringData.orderId}` : undefined,
          },
        },
        apns: {
          headers: {
            "apns-priority": isPromo ? "5" : "10",
          },
          payload: {
            aps: {
              alert: {
                title,
                body,
              },
              sound: isPromo ? undefined : "default",
              badge: 1,
              contentAvailable: true,
              threadId: stringData.orderId ? `order_${stringData.orderId}` : undefined,
            },
          },
        },
      });
      console.log(
        `[FCM] Notification sent successfully: "${title}" to ${targetToken.substring(
          0,
          15
        )}...`
      );
    } catch (err: any) {
      console.error(
        `[FCM] Failed to send notification to ${targetToken.substring(
          0,
          15
        )}...:`,
        err.message || err
      );
    }
  }
}

export interface CreateAndSendNotificationOptions {
  userId: string;
  title: string;
  body: string;
  category?: string;
  orderId?: string;
  data?: Record<string, string>;
  senderName?: string;
}

export function stripNotificationEmojis(text: string): string {
  return text
    .replace(
      /([\u2700-\u27BF]|[\uE000-\uF8FF]|\uD83C[\uDC00-\uDFFF]|\uD83D[\uDC00-\uDFFF]|[\u2011-\u26FF]|\uD83E[\uDD10-\uDDFF])/g,
      ""
    )
    .replace(/\s{2,}/g, " ")
    .trim();
}

export async function createAndSendNotification({
  userId,
  title,
  body,
  category = "orders",
  orderId,
  data = {},
  senderName,
}: CreateAndSendNotificationOptions): Promise<void> {
  const sanitizedTitle = stripNotificationEmojis(title);
  const sanitizedBody = stripNotificationEmojis(body);
  const isChatMessage = data?.type === "chat_message" || sanitizedTitle.includes("შეტყობინება");
  let dispatchTitle = sanitizedTitle;

  // 1. Persist notification to Neon Postgres with grouping for chat messages
  try {
    if (isChatMessage && orderId) {
      // Grouping: Check if a chat notification already exists for this order & user
      const existingNotifs = await prisma.notification.findMany({
        where: {
          userId,
          orderId,
          OR: [
            { title: { contains: "შეტყობინება" } },
          ],
        },
        orderBy: { createdAt: "desc" },
      });

      if (existingNotifs.length > 0) {
        const primary = existingNotifs[0];
        let unreadCount = 1;
        if (!primary.isRead) {
          const match = primary.title.match(/ახალი შეტყობინება \((\d+)\)/);
          const currentCount = match ? parseInt(match[1], 10) : 1;
          unreadCount = currentCount + 1;
        }

        const sender = senderName || primary.title.split("•")[1]?.trim() || "AgroKera";
        dispatchTitle = unreadCount > 1
          ? `ახალი შეტყობინება (${unreadCount}) • ${sender}`
          : `ახალი შეტყობინება • ${sender}`;

        await prisma.notification.update({
          where: { id: primary.id },
          data: {
            title: dispatchTitle,
            body: sanitizedBody,
            isRead: false,
            createdAt: new Date(),
          },
        });

        // Clean up any duplicate legacy chat notifications for this order
        if (existingNotifs.length > 1) {
          const duplicateIds = existingNotifs.slice(1).map((n) => n.id);
          await prisma.notification.deleteMany({
            where: { id: { in: duplicateIds } },
          });
        }
        console.log(
          `[Notification] Grouped chat notification updated for user ${userId}, order ${orderId} (unread: ${unreadCount})`
        );
      } else {
        const sender = senderName || "AgroKera";
        dispatchTitle = `ახალი შეტყობინება • ${sender}`;
        await prisma.notification.create({
          data: {
            userId,
            title: dispatchTitle,
            body: sanitizedBody,
            category,
            orderId,
          },
        });
        console.log(
          `[Notification] Saved new chat notification for user ${userId}, order ${orderId}`
        );
      }
    } else {
      await prisma.notification.create({
        data: {
          userId,
          title: dispatchTitle,
          body: sanitizedBody,
          category,
          orderId,
        },
      });
      console.log(`[Notification] Saved notification to DB for user ${userId}`);
    }
  } catch (err: any) {
    console.error(`[Notification DB Error]: ${err.message || err}`);
  }

  // 2. Fetch user's FCM token and dispatch push notification
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });
    if (user?.fcmToken) {
      await sendPushNotification({
        token: user.fcmToken,
        title: dispatchTitle,
        body: sanitizedBody,
        data: {
          ...data,
          title: dispatchTitle,
          body: sanitizedBody,
          category,
          ...(orderId ? { orderId } : {}),
        },
      });
    } else {
      console.warn(
        `[FCM] User ${userId} has no fcmToken registered in database. Push skipped.`
      );
    }
  } catch (err: any) {
    console.error(`[Notification FCM Error]: ${err.message || err}`);
  }
}


