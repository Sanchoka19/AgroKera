import prisma from "../../lib/prisma.ts";
import { Role, VerificationStatus } from "@prisma/client";
import { jsonResponse, errorResponse, farmerDeliverySettingsMap } from "../utils.ts";

export async function handleProfileRoute(
  request: Request,
  url: URL,
  path: string,
  method: string
): Promise<Response | null> {
  if (!path.startsWith("/api/profile/")) {
    return null;
  }

  const userId = decodeURIComponent(path.replace("/api/profile/", ""));

  const findUserByIdOrEmail = async (idOrKey: string) => {
    let found = await prisma.user.findUnique({
      where: { id: idOrKey },
      include: { farmerProfile: true },
    });
    if (!found) {
      const fp = await prisma.farmerProfile.findUnique({
        where: { id: idOrKey },
        include: { user: { include: { farmerProfile: true } } },
      });
      if (fp?.user) found = fp.user;
    }
    return found;
  };

  // GET /api/profile/:id
  if (method === "GET") {
    const user = await findUserByIdOrEmail(userId);
    if (!user) return errorResponse("User not found", 404);
    if (user.farmerProfile) {
      const custom = farmerDeliverySettingsMap.get(user.farmerProfile.id);
      if (custom) {
        (user.farmerProfile as any).deliveryDays =
          custom.deliveryDays || (user.farmerProfile.id === "farmer_2" ? ["ოთხშაბათი", "შაბათი"] : ["შაბათი"]);
        (user.farmerProfile as any).regionalDeliveryFees =
          custom.regionalDeliveryFees || { [user.farmerProfile.city || "თბილისი"]: user.farmerProfile.deliveryFee || 7.0 };
      }
    }
    return jsonResponse(user);
  }

  // PATCH /api/profile/:id
  if (method === "PATCH") {
    const body = (await request.json()) as {
      fullName?: string;
      name?: string;
      email?: string;
      role?: string;
      verificationStatus?: VerificationStatus;
      farmName?: string;
      region?: string;
      address?: string;
      idCardFrontUrl?: string;
      idCardBackUrl?: string;
      coverUrl?: string;
      avatarUrl?: string;
      isVatPayer?: boolean;
      isDeliveryEnabled?: boolean;
      deliveryFee?: number;
      city?: string;
      deliveryCity?: string;
      deliveryDays?: string[];
      regionalDeliveryFees?: Record<string, number>;
    };

    let existingUser = await findUserByIdOrEmail(userId);
    if (!existingUser && body.email) {
      existingUser = await prisma.user.findFirst({
        where: {
          email: {
            equals: body.email.trim().toLowerCase(),
            mode: "insensitive",
          },
        },
        include: { farmerProfile: true },
      });
    }

    if (!existingUser) {
      const isFarmer =
        body.role?.toUpperCase() === "FARMER" ||
        userId.startsWith("user_farmer_") ||
        userId.startsWith("farmer_") ||
        Boolean(body.farmName || body.coverUrl);
      const slug = userId.replace(/^user_(farmer|client)_/, "").replace(/^farmer_/, "");
      existingUser = await prisma.user.create({
        data: {
          id: userId.startsWith("farmer_") ? `user_${userId}` : userId,
          fullName: body.fullName || body.name || (isFarmer ? "ფერმერი" : "მომხმარებელი"),
          email: body.email?.trim().toLowerCase() || `${slug}@agrokera.ge`,
          phoneNumber: `+995599${Math.floor(100000 + Math.random() * 900000)}`,
          role: isFarmer ? Role.FARMER : Role.CLIENT,
          verificationStatus: body.verificationStatus || VerificationStatus.VERIFIED,
          avatarUrl: body.avatarUrl,
          ...(isFarmer
            ? {
                farmerProfile: {
                  create: {
                    id: userId.startsWith("farmer_") ? userId : `farmer_${slug}`,
                    farmName: body.farmName || "ჩემი მეურნეობა",
                    region: body.region || "კახეთი",
                    city: "თელავი",
                    address: body.address || "თელავი, კახეთი",
                    coverUrl: body.coverUrl,
                    avatarUrl: body.avatarUrl,
                    isVatPayer: body.isVatPayer ?? false,
                    isDeliveryEnabled:
                      body.isDeliveryEnabled !== undefined
                        ? body.isDeliveryEnabled
                        : true,
                    deliveryFee: body.deliveryFee ?? 0.0,
                  },
                },
              }
            : {}),
        },
        include: { farmerProfile: true },
      });
      return jsonResponse(existingUser);
    }

    const resolvedFullName = body.fullName || body.name;
    const hasFarmerFieldUpdate = Boolean(
      body.farmName ||
        body.region ||
        body.address ||
        body.idCardFrontUrl ||
        body.idCardBackUrl ||
        body.coverUrl ||
        body.avatarUrl ||
        body.isVatPayer !== undefined ||
        body.isDeliveryEnabled !== undefined ||
        body.deliveryFee !== undefined ||
        body.city ||
        body.deliveryCity
    );

    const user = await prisma.user.update({
      where: { id: existingUser.id },
      data: {
        ...(resolvedFullName ? { fullName: resolvedFullName } : {}),
        ...(body.avatarUrl ? { avatarUrl: body.avatarUrl } : {}),
        ...(body.verificationStatus
          ? { verificationStatus: body.verificationStatus }
          : {}),
        ...(existingUser.farmerProfile && hasFarmerFieldUpdate
          ? {
            farmerProfile: {
              update: {
                ...(body.farmName ? { farmName: body.farmName } : {}),
                ...(body.region ? { region: body.region } : {}),
                ...(body.address ? { address: body.address } : {}),
                ...(body.idCardFrontUrl
                  ? { idCardFrontUrl: body.idCardFrontUrl }
                  : {}),
                ...(body.idCardBackUrl
                  ? { idCardBackUrl: body.idCardBackUrl }
                  : {}),
                ...(body.coverUrl ? { coverUrl: body.coverUrl } : {}),
                ...(body.avatarUrl ? { avatarUrl: body.avatarUrl } : {}),
                ...(body.isVatPayer !== undefined
                  ? { isVatPayer: body.isVatPayer }
                  : {}),
                ...(body.isDeliveryEnabled !== undefined
                  ? { isDeliveryEnabled: body.isDeliveryEnabled }
                  : {}),
                ...(body.deliveryFee !== undefined
                  ? { deliveryFee: body.deliveryFee }
                  : {}),
                ...(body.city || body.deliveryCity
                  ? { city: body.city || body.deliveryCity }
                  : {}),
              },
            },
          }
          : {}),
      },
      include: { farmerProfile: true },
    });

    const profileFarmerId =
      existingUser.farmerProfile?.id ||
      (userId.startsWith("farmer_")
        ? userId
        : `farmer_${userId.replace(/^user_(farmer|client)_/, "")}`);
    if (
      body.deliveryDays ||
      body.regionalDeliveryFees ||
      body.isDeliveryEnabled !== undefined ||
      body.deliveryFee !== undefined ||
      body.city ||
      body.deliveryCity
    ) {
      const current = farmerDeliverySettingsMap.get(profileFarmerId) || {};
      const updated = {
        ...current,
        ...(body.isDeliveryEnabled !== undefined
          ? { isDeliveryEnabled: body.isDeliveryEnabled }
          : {}),
        ...(body.deliveryFee !== undefined ? { deliveryFee: body.deliveryFee } : {}),
        ...(body.city || body.deliveryCity
          ? { deliveryCity: body.city || body.deliveryCity }
          : {}),
        ...(body.deliveryDays ? { deliveryDays: body.deliveryDays } : {}),
        ...(body.regionalDeliveryFees
          ? { regionalDeliveryFees: body.regionalDeliveryFees }
          : {}),
      };
      farmerDeliverySettingsMap.set(profileFarmerId, updated);
      if (profileFarmerId === "farmer_1" || profileFarmerId === "farmer_2") {
        farmerDeliverySettingsMap.set("farmer_1", { ...updated });
        farmerDeliverySettingsMap.set("farmer_2", { ...updated });
      }
    }

    if (user.farmerProfile) {
      const custom = farmerDeliverySettingsMap.get(user.farmerProfile.id);
      if (custom) {
        (user.farmerProfile as any).deliveryDays =
          custom.deliveryDays ||
          (user.farmerProfile.id === "farmer_2"
            ? ["ოთხშაბათი", "შაბათი"]
            : ["შაბათი"]);
        (user.farmerProfile as any).regionalDeliveryFees =
          custom.regionalDeliveryFees || {
            [user.farmerProfile.city || "თბილისი"]:
              user.farmerProfile.deliveryFee || 7.0,
          };
      }
    }

    return jsonResponse(user);
  }

  return null;
}

