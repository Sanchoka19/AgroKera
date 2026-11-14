import http from "node:http";
import apiHandler from "./index.ts";

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
  console.log(`🚀 AgroKera Neon API Server running on http://localhost:${PORT}`);
});

