import http from "node:http";
import apiHandler, {
  remindStaleOrders,
  processOrderExpirations,
} from "./index.ts";

const PORT = Number(process.env.PORT || 3001);

const server = http.createServer(async (req, res) => {
  try {
    const forwardedProto = req.headers["x-forwarded-proto"];
    const protocol =
      typeof forwardedProto === "string"
        ? forwardedProto.split(",")[0].trim()
        : "http";
    const host = req.headers.host || `localhost:${PORT}`;
    const url = `${protocol}://${host}${req.url || "/"}`;

    const bodyChunks: Buffer[] = [];
    for await (const chunk of req) {
      bodyChunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    }
    const bodyBuffer = Buffer.concat(bodyChunks);

    const headers = new Headers();
    for (const [key, value] of Object.entries(req.headers)) {
      if (typeof value === "string") headers.set(key, value);
      else if (Array.isArray(value)) headers.set(key, value.join(", "));
    }

    const webReq = new Request(url, {
      method: req.method || "GET",
      headers,
      body:
        req.method !== "GET" && req.method !== "HEAD" && bodyBuffer.length > 0
          ? bodyBuffer
          : undefined,
    });

    const webRes = await apiHandler.fetch(webReq);

    res.statusCode = webRes.status;
    webRes.headers.forEach((val, key) => {
      res.setHeader(key, val);
    });

    const resBuffer = Buffer.from(await webRes.arrayBuffer());
    res.end(resBuffer);
  } catch (err) {
    console.error("Server error:", err);
    res.statusCode = 500;
    res.setHeader("Content-Type", "application/json");
    res.end(JSON.stringify({ error: "Internal server error" }));
  }
});

server.listen(PORT, "0.0.0.0", () => {
  const publicUrl = process.env.RENDER_EXTERNAL_URL || `http://localhost:${PORT}`;
  console.log(`🚀 AgroKera Neon API Server running on ${publicUrl} (port ${PORT})`);

  // ── Auto-cancellation & Pre-expiry Warning Cron ───────────────────────────
  // Runs every 60 seconds to:
  // 1. Auto-cancel pending orders past their cancellationDeadline and restore stock
  // 2. Send high-priority pre-expiry warning push notification to farmers when <= 10 min left
  const EXPIRATION_INTERVAL = 60 * 1000;
  const runExpirations = () => {
    processOrderExpirations().catch((err) =>
      console.error("[Cron] processOrderExpirations failed:", err)
    );
  };
  // Run immediately on server boot, then repeat every minute
  runExpirations();
  setInterval(runExpirations, EXPIRATION_INTERVAL);
  console.log("[Cron] Order auto-expiration & warning monitor scheduled — runs every 60 seconds");

  // ── Stale-order reminder cron ──────────────────────────────────────────────
  // Runs once a day. Notifies farmer (>2 h) and client (>6 h) when an
  // IN_PROGRESS order has not been closed via the delivery PIN.
  // A 24-hour DB check inside remindStaleOrders() ensures at most one
  // reminder per order per day regardless of how often the cron fires.
  const ONE_DAY = 24 * 60 * 60 * 1000;
  const runReminder = () => {
    remindStaleOrders().catch((err) =>
      console.error("[Cron] remindStaleOrders failed:", err)
    );
  };
  // First run after 24 h, then repeat daily
  setTimeout(() => {
    runReminder();
    setInterval(runReminder, ONE_DAY);
  }, ONE_DAY);

  console.log("[Cron] Stale-order reminder scheduled — runs daily");
});

