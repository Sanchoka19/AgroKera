import admin from "firebase-admin";
import fs from "fs";
import path from "path";

let isInitialized = false;

function initFirebase(): boolean {
  if (isInitialized) return true;
  try {
    const serviceAccountPath = path.resolve(
      process.cwd(),
      "firebase-service-account.json"
    );
    if (!fs.existsSync(serviceAccountPath)) {
      console.warn(
        "[FCM] firebase-service-account.json not found, push notifications disabled."
      );
      return false;
    }
    const serviceAccount = JSON.parse(
      fs.readFileSync(serviceAccountPath, "utf-8")
    );
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
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

  for (const targetToken of validTokens) {
    try {
      await admin.messaging().send({
        token: targetToken,
        notification: {
          title,
          body,
        },
        data,
        android: {
          priority: "high",
          notification: {
            channelId: "agrokera_high_importance_channel",
            sound: "default",
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

