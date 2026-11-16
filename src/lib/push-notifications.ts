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
          priority: "high",
          notification: {
            channelId: "agrokera_high_importance_channel",
            sound: "default",
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: "ic_notification",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              alert: {
                title,
                body,
              },
              sound: "default",
              badge: 1,
              contentAvailable: true,
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
}

export async function createAndSendNotification({
  userId,
  title,
  body,
  category = "orders",
  orderId,
  data = {},
}: CreateAndSendNotificationOptions): Promise<void> {
  // 1. Persist notification to Neon Postgres
  try {
    await prisma.notification.create({
      data: {
        userId,
        title,
        body,
        category,
        orderId,
      },
    });
    console.log(`[Notification] Saved notification to DB for user ${userId}`);
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
        title,
        body,
        data: {
          ...data,
          title,
          body,
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


