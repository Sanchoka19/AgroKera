import prisma from "../../lib/prisma.ts";
import { jsonResponse, errorResponse } from "../utils.ts";

export interface ReviewEntry {
  id: string;
  orderId: string;
  clientId: string;
  clientName: string;
  clientAvatarUrl?: string;
  farmerId: string;
  rating: number;
  tags: string[];
  comment?: string;
  createdAt: string;
}

// Clean runtime reviews cache (populated by real customer submissions and DB queries)
export const farmerReviewsList: ReviewEntry[] = [];

export async function handleReviewsRoute(
  request: Request,
  url: URL,
  path: string,
  method: string
): Promise<Response | null> {
  // GET /api/reviews/farmer/:id
  if (path.startsWith("/api/reviews/farmer/") && method === "GET") {
    const farmerId = path.replace("/api/reviews/farmer/", "");
    let reviews: ReviewEntry[] = [];
    try {
      const dbReviews = await prisma.review.findMany({
        where: { farmerId },
        include: { client: true },
        orderBy: { createdAt: "desc" },
      });
      if (dbReviews && dbReviews.length > 0) {
        reviews = dbReviews.map((r) => ({
          id: r.id,
          orderId: r.orderId,
          clientId: r.clientId,
          clientName: r.client.fullName,
          clientAvatarUrl: r.client.avatarUrl || undefined,
          farmerId: r.farmerId,
          rating: r.rating,
          tags: r.tags,
          comment: r.comment || undefined,
          createdAt: r.createdAt.toISOString(),
        }));
      }
    } catch (_) {}

    if (reviews.length === 0) {
      reviews = farmerReviewsList.filter((r) => r.farmerId === farmerId);
    }

    reviews.sort(
      (a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );

    const averageRating =
      reviews.length > 0
        ? Number(
            (
              reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length
            ).toFixed(1)
          )
        : 0.0;

    return jsonResponse({
      farmerId,
      averageRating,
      reviewCount: reviews.length,
      reviews,
    });
  }

  // GET /api/reviews/order/:id
  if (path.startsWith("/api/reviews/order/") && method === "GET") {
    const orderId = path.replace("/api/reviews/order/", "");
    try {
      const dbReview = await prisma.review.findUnique({
        where: { orderId },
        include: { client: true },
      });
      if (dbReview) {
        return jsonResponse({
          id: dbReview.id,
          orderId: dbReview.orderId,
          clientId: dbReview.clientId,
          clientName: dbReview.client.fullName,
          clientAvatarUrl: dbReview.client.avatarUrl || undefined,
          farmerId: dbReview.farmerId,
          rating: dbReview.rating,
          tags: dbReview.tags,
          comment: dbReview.comment || undefined,
          createdAt: dbReview.createdAt.toISOString(),
        });
      }
    } catch (_) {}

    const existing = farmerReviewsList.find((r) => r.orderId === orderId);
    return jsonResponse(existing || null);
  }

  // POST /api/reviews
  if (path === "/api/reviews" && method === "POST") {
    const body = (await request.json()) as {
      orderId: string;
      clientId?: string;
      farmerId?: string;
      clientName?: string;
      clientAvatarUrl?: string;
      rating: number;
      tags?: string[];
      comment?: string;
    };

    if (!body.orderId || !body.rating) {
      return errorResponse("orderId and rating are required", 400);
    }

    const rating = Math.max(1, Math.min(5, Math.round(Number(body.rating))));
    const existingIndex = farmerReviewsList.findIndex(
      (r) => r.orderId === body.orderId
    );

    const entry: ReviewEntry = {
      id:
        existingIndex >= 0
          ? farmerReviewsList[existingIndex].id
          : `rev_${Date.now()}`,
      orderId: body.orderId,
      clientId: body.clientId || "user_client_1",
      clientName: body.clientName || "მომხმარებელი",
      clientAvatarUrl: body.clientAvatarUrl,
      farmerId: body.farmerId || "farmer_2",
      rating,
      tags: Array.isArray(body.tags) ? body.tags : [],
      comment: body.comment?.trim() || undefined,
      createdAt: new Date().toISOString(),
    };

    if (existingIndex >= 0) {
      farmerReviewsList[existingIndex] = entry;
    } else {
      farmerReviewsList.unshift(entry);
    }

    try {
      await prisma.review.upsert({
        where: { orderId: entry.orderId },
        create: {
          id: entry.id,
          orderId: entry.orderId,
          clientId: entry.clientId,
          farmerId: entry.farmerId,
          rating: entry.rating,
          tags: entry.tags,
          comment: entry.comment,
        },
        update: {
          rating: entry.rating,
          tags: entry.tags,
          comment: entry.comment,
        },
      });
    } catch (_) {}

    const farmerRevs = farmerReviewsList.filter(
      (r) => r.farmerId === entry.farmerId
    );
    const averageRating = Number(
      (
        farmerRevs.reduce((sum, r) => sum + r.rating, 0) / farmerRevs.length
      ).toFixed(1)
    );
    const reviewCount = farmerRevs.length;

    try {
      await prisma.farmerProfile.update({
        where: { id: entry.farmerId },
        data: {
          rating: averageRating,
          reviewCount,
        },
      });
    } catch (_) {}

    return jsonResponse(
      {
        review: entry,
        farmerRating: averageRating,
        farmerReviewCount: reviewCount,
      },
      201
    );
  }

  return null;
}

