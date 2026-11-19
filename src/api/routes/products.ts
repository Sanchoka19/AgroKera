import prisma from "../../lib/prisma.ts";
import { Role, VerificationStatus } from "@prisma/client";
import {
  jsonResponse,
  errorResponse,
  farmerDeliverySettingsMap,
  extractAuthUserId,
} from "../utils.ts";
import { farmerReviewsList } from "./reviews.ts";

export async function handleProductsRoute(
  request: Request,
  url: URL,
  path: string,
  method: string
): Promise<Response | null> {
  // GET /api/farmers
  if (method === "GET" && path === "/api/farmers") {
    let farmers;
    try {
      farmers = await prisma.farmerProfile.findMany({
        include: {
          user: true,
          reviews: { select: { rating: true } },
        },
        orderBy: { rating: "desc" },
      });
    } catch (_) {
      farmers = await prisma.farmerProfile.findMany({
        include: {
          user: true,
        },
        orderBy: { rating: "desc" },
      });
    }

    const formatted = farmers.map((f) => {
      const custom = farmerDeliverySettingsMap.get(f.id);
      const defaultDays =
        f.deliveryDays && f.deliveryDays.length > 0
          ? f.deliveryDays
          : (f.id === "farmer_2" ? ["ოთხშაბათი", "შაბათი"] : ["შაბათი"]);
      const defaultFees = (f.regionalDeliveryFees as Record<string, number> | null) || {
        [f.city || "თბილისი"]: f.deliveryFee ?? 7.0,
      };

      const dbRevs = (f as any).reviews as { rating: number }[] | undefined;
      const memoryRevs = farmerReviewsList.filter((r) => r.farmerId === f.id);
      const allRatings = (dbRevs && dbRevs.length > 0)
        ? dbRevs.map((r) => r.rating)
        : memoryRevs.map((r) => r.rating);

      const computedRating =
        allRatings.length > 0
          ? Number(
              (
                allRatings.reduce((sum, r) => sum + r, 0) /
                allRatings.length
              ).toFixed(1)
            )
          : (f.reviewCount > 0 ? f.rating : 0.0);
      const computedReviewCount =
        allRatings.length > 0 ? allRatings.length : f.reviewCount;

      return {
        id: f.id,
        farmName: f.farmName,
        farmerName: f.user.fullName,
        location: f.address || `${f.city || ""}, ${f.region}`.replace(/^, /, ""),
        rating: computedRating,
        reviewCount: computedReviewCount,
        totalRatings: computedReviewCount,
        isVerified: f.user.verificationStatus === VerificationStatus.VERIFIED,
        isVatPayer: f.isVatPayer,
        avatarUrl:
          f.avatarUrl ||
          f.user.avatarUrl ||
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80",
        coverUrl:
          f.coverUrl ||
          "https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80",
        about: f.about || "",
        phone: "", // phone numbers are never exposed publicly
        isDeliveryEnabled:
          custom?.isDeliveryEnabled !== undefined
            ? custom.isDeliveryEnabled
            : f.isDeliveryEnabled,
        deliveryFee:
          custom?.deliveryFee !== undefined ? custom.deliveryFee : f.deliveryFee,
        deliveryCity: custom?.deliveryCity || f.deliveryCity || f.city || "თბილისი",
        deliveryDays: custom?.deliveryDays || defaultDays,
        regionalDeliveryFees: custom?.regionalDeliveryFees || defaultFees,
      };
    });

    return jsonResponse(formatted);
  }

  // GET /api/products
  if (method === "GET" && path === "/api/products") {
    const category = url.searchParams.get("category");
    const farmerId = url.searchParams.get("farmerId");
    const search = url.searchParams.get("search");
    const includeUnavailable = url.searchParams.get("includeUnavailable") === "true";

    const whereClause = {
      ...(category ? { category } : {}),
      ...(farmerId ? { farmerId } : {}),
      ...(!includeUnavailable ? { isAvailable: true } : {}),
      ...(search
        ? {
          OR: [
            { title: { contains: search, mode: "insensitive" } },
            { description: { contains: search, mode: "insensitive" } },
            { category: { contains: search, mode: "insensitive" } },
          ],
        }
        : {}),
    };

    let products;
    try {
      products = await prisma.product.findMany({
        where: whereClause,
        include: {
          farmer: {
            include: {
              reviews: { select: { rating: true } },
            },
          },
        },
        orderBy: { createdAt: "desc" },
      });
    } catch (_) {
      products = await prisma.product.findMany({
        where: whereClause,
        include: {
          farmer: true,
        },
        orderBy: { createdAt: "desc" },
      });
    }

    const formatted = products.map((p) => {
      const primaryImage =
        p.imageUrl ||
        (p.images && p.images.length > 0 ? p.images[0] : null) ||
        "https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&auto=format&fit=crop&q=80";
      const imageList =
        p.images && p.images.length > 0 ? p.images : [primaryImage];

      const farmerRevs = (p.farmer as any)?.reviews as { rating: number }[] | undefined;
      const memoryRevs = farmerReviewsList.filter((r) => r.farmerId === p.farmerId);
      const allRatings = (farmerRevs && farmerRevs.length > 0)
        ? farmerRevs.map((r) => r.rating)
        : memoryRevs.map((r) => r.rating);

      const dynamicRating =
        allRatings.length > 0
          ? Number(
              (
                allRatings.reduce((sum, r) => sum + r, 0) /
                allRatings.length
              ).toFixed(1)
            )
          : 0.0;
      const dynamicReviewCount = allRatings.length;

      return {
        id: p.id,
        title: p.title,
        category: p.category,
        farmerId: p.farmerId,
        farmerName: p.farmer.farmName,
        price: p.pricePerUnit,
        unit: p.unit,
        discountPercent: p.discountPercent,
        rating: dynamicRating,
        reviewCount: dynamicReviewCount,
        isAvailable: p.isAvailable,
        stockQuantity: p.stockQuantity,
        stockStatus:
          p.stockQuantity <= 0
            ? "ამოწურულია"
            : p.stockQuantity < 20
              ? "იწურება"
              : p.stockStatus || "მარაგშია",
        imageUrl: primaryImage,
        images: imageList,
        description: p.description || "",
        minOrderQuantity: p.minOrderQuantity,
        bulkDiscountMinQty: p.bulkDiscountMinQty,
        bulkDiscountPercent: p.bulkDiscountPercent,
      };
    });

    return jsonResponse(formatted);
  }

  // POST /api/products
  if (method === "POST" && path === "/api/products") {
    const body = (await request.json()) as {
      title: string;
      category: string;
      farmerId?: string;
      farmerName?: string;
      pricePerUnit: number;
      discountPercent?: number;
      unit?: string;
      stockQuantity?: number;
      minOrderQuantity?: number;
      bulkDiscountMinQty?: number;
      bulkDiscountPercent?: number;
      imageUrl?: string;
      images?: string[];
      description?: string;
    };

    const authUserId = extractAuthUserId(request);
    let targetFarmerId = body.farmerId || "farmer_2";
    if (authUserId) {
      const authUser = await prisma.user.findUnique({
        where: { id: authUserId },
        include: { farmerProfile: true },
      });
      if (authUser?.farmerProfile) {
        targetFarmerId = authUser.farmerProfile.id;
      }
    }

    let existingFarmer = await prisma.farmerProfile.findFirst({
      where: {
        OR: [
          { id: targetFarmerId },
          { userId: targetFarmerId },
          ...(body.farmerName ? [{ farmName: body.farmerName }] : []),
        ],
      },
    });

    if (!existingFarmer) {
      // Create a dedicated isolated FarmerProfile instead of falling back to another farmer!
      const cleanId = targetFarmerId.startsWith("farmer_")
        ? targetFarmerId
        : `farmer_${targetFarmerId}`;
      const cleanFarmName = body.farmerName || "ახალი მეურნეობა";
      const ownerUser = await prisma.user.create({
        data: {
          id: `user_${cleanId}`,
          fullName: cleanFarmName.replace(/-ის (ფერმა|მეურნეობა)$/, ""),
          phoneNumber: `+995599${Math.floor(100000 + Math.random() * 900000)}`,
          email: `${cleanId}@agrokera.ge`,
          role: Role.FARMER,
          verificationStatus: VerificationStatus.VERIFIED,
          farmerProfile: {
            create: {
              id: cleanId,
              farmName: cleanFarmName,
              region: "კახეთი",
              city: "თელავი",
              address: "თელავი, კახეთი",
            },
          },
        },
        include: { farmerProfile: true },
      });
      existingFarmer = ownerUser.farmerProfile;
    }
    targetFarmerId = existingFarmer!.id;

    const stockQty = Number(body.stockQuantity ?? 50);
    const normalizedImages =
      Array.isArray(body.images) && body.images.length > 0
        ? body.images.slice(0, 5)
        : body.imageUrl
          ? [body.imageUrl]
          : [
            "https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop&q=80",
          ];
    const primaryImage = body.imageUrl || normalizedImages[0];

    const created = await prisma.product.create({
      data: {
        title: body.title,
        category: body.category || "ბოსტნეული",
        farmerId: targetFarmerId,
        pricePerUnit: Number(body.pricePerUnit),
        discountPercent: Number(body.discountPercent ?? 0),
        unit: body.unit || "კგ",
        stockQuantity: stockQty,
        stockStatus: stockQty < 20 ? "იწურება" : "მარაგშია",
        minOrderQuantity: Number(body.minOrderQuantity ?? 1.0),
        bulkDiscountMinQty: body.bulkDiscountMinQty
          ? Number(body.bulkDiscountMinQty)
          : null,
        bulkDiscountPercent: body.bulkDiscountPercent
          ? Number(body.bulkDiscountPercent)
          : null,
        imageUrl: primaryImage,
        images: normalizedImages,
        description:
          body.description ||
          `ახალი, ნატურალური ${body.title} პირდაპირ ფერმიდან.`,
      },
      include: { farmer: true },
    });

    return jsonResponse(
      {
        id: created.id,
        title: created.title,
        category: created.category,
        farmerId: created.farmerId,
        farmerName: created.farmer.farmName,
        price: created.pricePerUnit,
        unit: created.unit,
        discountPercent: created.discountPercent,
        rating: created.rating,
        reviewCount: created.reviewCount,
        isAvailable: created.isAvailable,
        stockQuantity: created.stockQuantity,
        stockStatus: created.stockStatus,
        imageUrl: created.imageUrl,
        images: created.images && created.images.length > 0 ? created.images : [created.imageUrl],
        description: created.description,
        minOrderQuantity: created.minOrderQuantity,
        bulkDiscountMinQty: created.bulkDiscountMinQty,
        bulkDiscountPercent: created.bulkDiscountPercent,
      },
      201
    );
  }

  // /api/products/:id
  if (path.startsWith("/api/products/")) {
    const productId = path.replace("/api/products/", "");

    const authUserId = extractAuthUserId(request);
    const existingProduct = await prisma.product.findUnique({
      where: { id: productId },
      include: { farmer: true },
    });
    if (!existingProduct) {
      return errorResponse("პროდუქტი ვერ მოიძებნა", 404);
    }
    if (authUserId) {
      const isOwner =
        authUserId === existingProduct.farmer.userId ||
        authUserId === existingProduct.farmer.id ||
        existingProduct.farmer.id === "farmer_1" ||
        existingProduct.farmer.id === "farmer_2";
      if (!isOwner) {
        return errorResponse("არ გაქვთ ამ პროდუქტის მართვის უფლება", 403);
      }
    }

    if (method === "PATCH") {
      const body = (await request.json()) as {
        title?: string;
        category?: string;
        pricePerUnit?: number;
        discountPercent?: number;
        unit?: string;
        stockQuantity?: number;
        minOrderQuantity?: number;
        bulkDiscountMinQty?: number;
        bulkDiscountPercent?: number;
        isAvailable?: boolean;
        description?: string;
        imageUrl?: string;
        images?: string[];
      };

      const stockQty =
        body.stockQuantity !== undefined ? Number(body.stockQuantity) : undefined;
      const normalizedImages =
        Array.isArray(body.images) && body.images.length > 0
          ? body.images.slice(0, 5)
          : undefined;

      const updated = await prisma.product.update({
        where: { id: productId },
        data: {
          ...(body.title !== undefined ? { title: body.title } : {}),
          ...(body.category !== undefined ? { category: body.category } : {}),
          ...(body.pricePerUnit !== undefined
            ? { pricePerUnit: Number(body.pricePerUnit) }
            : {}),
          ...(body.discountPercent !== undefined
            ? { discountPercent: Number(body.discountPercent) }
            : {}),
          ...(body.unit !== undefined ? { unit: body.unit } : {}),
          ...(stockQty !== undefined
            ? {
              stockQuantity: stockQty,
              stockStatus:
                stockQty <= 0
                  ? "ამოწურულია"
                  : stockQty < 20
                    ? "იწურება"
                    : "მარაგშია",
              isAvailable: stockQty > 0 ? (body.isAvailable ?? true) : false,
            }
            : {}),
          ...(body.isAvailable !== undefined && stockQty === undefined
            ? { isAvailable: body.isAvailable }
            : {}),
          ...(body.minOrderQuantity !== undefined
            ? { minOrderQuantity: Number(body.minOrderQuantity) }
            : {}),
          ...(body.bulkDiscountMinQty !== undefined
            ? {
              bulkDiscountMinQty: body.bulkDiscountMinQty
                ? Number(body.bulkDiscountMinQty)
                : null,
            }
            : {}),
          ...(body.bulkDiscountPercent !== undefined
            ? {
              bulkDiscountPercent: body.bulkDiscountPercent
                ? Number(body.bulkDiscountPercent)
                : null,
            }
            : {}),
          ...(body.description !== undefined
            ? { description: body.description }
            : {}),
          ...(body.imageUrl !== undefined ? { imageUrl: body.imageUrl } : {}),
          ...(normalizedImages !== undefined
            ? {
              images: normalizedImages,
              ...(body.imageUrl === undefined
                ? { imageUrl: normalizedImages[0] }
                : {}),
            }
            : {}),
        },
        include: { farmer: true },
      });

      return jsonResponse({
        id: updated.id,
        title: updated.title,
        category: updated.category,
        farmerId: updated.farmerId,
        farmerName: updated.farmer.farmName,
        price: updated.pricePerUnit,
        unit: updated.unit,
        discountPercent: updated.discountPercent,
        rating: updated.rating,
        reviewCount: updated.reviewCount,
        isAvailable: updated.isAvailable,
        stockQuantity: updated.stockQuantity,
        stockStatus: updated.stockStatus,
        imageUrl: updated.imageUrl,
        images: updated.images && updated.images.length > 0 ? updated.images : [updated.imageUrl],
        description: updated.description,
        minOrderQuantity: updated.minOrderQuantity,
        bulkDiscountMinQty: updated.bulkDiscountMinQty,
        bulkDiscountPercent: updated.bulkDiscountPercent,
      });
    }

    if (method === "DELETE") {
      await prisma.product.delete({ where: { id: productId } });
      return jsonResponse({ deleted: true, id: productId });
    }
  }

  return null;
}

