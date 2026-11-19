import prisma from "../../lib/prisma.ts";
import {
  OrderStatus,
  Role,
  ShipmentStatus,
  VerificationStatus,
  FulfillmentType,
} from "@prisma/client";
import { createAndSendNotification } from "../../lib/push-notifications.ts";
import { NotificationTemplates } from "../../lib/notification-templates.ts";
import {
  jsonResponse,
  errorResponse,
  maskPhoneNumbers,
  extractAuthUserId,
} from "../utils.ts";
import { calculatePendingOrderDeadline } from "../../lib/order-cron.ts";

const orderMetadataMap = new Map<string, {
  deliveryFee?: number;
  heavyFee?: number;
  platformFee?: number;
  paymentMethod?: string;
  isPickup?: boolean;
}>();

export async function handleOrdersRoute(
  request: Request,
  url: URL,
  path: string,
  method: string
): Promise<Response | null> {
  // GET /api/orders
  if (method === "GET" && path === "/api/orders") {
    const authUserId = extractAuthUserId(request);
    const farmerId = url.searchParams.get("farmerId");
    const clientId = url.searchParams.get("clientId");

    if (!farmerId && !clientId && !authUserId) {
      return errorResponse("ავტორიზაცია აუცილებელია", 401);
    }

    let resolvedClientId = clientId;
    let resolvedFarmerId = farmerId;

    if (!resolvedClientId && !resolvedFarmerId && authUserId) {
      const user = await prisma.user.findUnique({
        where: { id: authUserId },
        include: { farmerProfile: true },
      });
      if (user?.farmerProfile) {
        resolvedFarmerId = user.farmerProfile.id;
      } else {
        resolvedClientId = authUserId;
      }
    }

    const orders = await prisma.order.findMany({
      where: {
        ...(resolvedFarmerId ? { farmerId: resolvedFarmerId } : {}),
        ...(resolvedClientId ? { clientId: resolvedClientId } : {}),
      },
      include: {
        client: true,
        items: {
          include: { product: true },
        },
        shipment: true,
      },
      orderBy: { createdAt: "desc" },
    });

    const farmerIds = [
      ...new Set(orders.map((o) => o.farmerId).filter((x): x is string => !!x)),
    ];
    const farmerProfiles = farmerIds.length
      ? await prisma.farmerProfile.findMany({
        where: { id: { in: farmerIds } },
        select: { id: true, farmName: true, avatarUrl: true },
      })
      : [];
    const farmerById = new Map(farmerProfiles.map((f) => [f.id, f]));

    const formatted = orders.map((o) => {
      const meta = orderMetadataMap.get(o.id);
      const isPickup =
        o.fulfillmentType === FulfillmentType.SELF_PICKUP ||
        o.isPickup ||
        Boolean(meta?.isPickup);
      const deliveryFee = isPickup ? 0 : (o.deliveryFee || (meta?.deliveryFee ?? 0));
      const heavyFee = isPickup ? 0 : (o.heavyFee || (meta?.heavyFee ?? 0));
      const platformFee = o.platformFee || (meta?.platformFee ?? 0);
      const paymentMethod = o.paymentMethod || meta?.paymentMethod || "ESCROW";

      return {
        id: o.id,
        farmerId: o.farmerId,
        farmerName: o.farmerId ? farmerById.get(o.farmerId)?.farmName ?? null : null,
        farmerAvatarUrl: o.farmerId ? farmerById.get(o.farmerId)?.avatarUrl ?? null : null,
        customerAvatarUrl: o.client?.avatarUrl ?? null,
        clientId: o.clientId,
        createdAt: o.createdAt.toISOString(),
        status: o.status,
        customerName: o.client.fullName,
        contactPerson: o.contactPerson || o.client.fullName,
        // Phone numbers are never shared between client and farmer
        contactPhone: null,
        hasVat: o.hasVat,
        totalAmount: o.totalAmount,
        fulfillmentType: o.fulfillmentType,
        isPickup,
        deliveryFee,
        heavyFee,
        platformFee,
        paymentMethod,
        deliveryTimeWindow: o.deliveryTimeWindow || "დღეს, 16:00 - 19:00",
        deliveryAddress: o.deliveryAddress,
        cancellationReason: o.cancellationReason,
        cancellationDeadline: o.cancellationDeadline?.toISOString() ?? null,
        shipmentStatus: o.shipment?.status ?? "PENDING",
        trackingNumber: o.shipment?.trackingNumber ?? `AK-${o.id.slice(-5)}`,
        items: o.items.map((item) => ({
          productId: item.productId,
          name: item.product.title,
          quantity: item.quantity,
          unit: item.product.unit,
          quantityText: `${item.quantity}${item.product.unit}`,
          pricePerUnit: item.pricePerUnit,
          price: item.subtotal,
        })),
      };
    });

    return jsonResponse(formatted);
  }

  // POST /api/orders
  if (method === "POST" && path === "/api/orders") {
    const body = (await request.json()) as {
      clientId?: string;
      clientEmail?: string;
      farmerId?: string;
      contactPerson?: string;
      contactPhone?: string;
      deliveryAddress?: string;
      deliveryTimeWindow?: string;
      deliveryNotes?: string;
      hasVat?: boolean;
      fulfillmentType?: string;
      isPickup?: boolean;
      deliveryFee?: number;
      heavyFee?: number;
      platformFee?: number;
      paymentMethod?: string;
      totalAmount?: number;
      items: Array<{
        productId: string;
        quantity: number;
        pricePerUnit: number;
      }>;
    };

    if (!body.items || body.items.length === 0) {
      return errorResponse("Order must contain at least one item", 400);
    }

    const isPickup =
      body.fulfillmentType === "SELF_PICKUP" ||
      body.isPickup === true;
    const deliveryFee = isPickup ? 0 : (body.deliveryFee ?? 0);
    const heavyFee = isPickup ? 0 : (body.heavyFee ?? 0);
    const platformFee = body.platformFee ?? 0;
    const paymentMethod = body.paymentMethod || "ESCROW";

    const subtotal = body.items.reduce(
      (sum, item) => sum + Number(item.quantity) * Number(item.pricePerUnit),
      0
    );
    const totalAmount =
      body.totalAmount ??
      ((body.hasVat ? subtotal * 1.18 : subtotal) +
        deliveryFee +
        heavyFee +
        platformFee);

    const createdOrder = await prisma.$transaction(async (tx) => {
      // Resolve valid isolated client user (never fall back to another client's account)
      const normalizedClientEmail = body.clientEmail?.trim().toLowerCase();
      let resolvedClientId =
        body.clientId ||
        (normalizedClientEmail
          ? `user_client_${normalizedClientEmail.replace(/[^a-z0-9]/g, "_")}`
          : "user_client_1");

      let existingClient = await tx.user.findUnique({
        where: { id: resolvedClientId },
      });
      if (!existingClient && normalizedClientEmail) {
        existingClient = await tx.user.findFirst({
          where: {
            email: {
              equals: normalizedClientEmail,
              mode: "insensitive",
            },
          },
        });
      }
      if (existingClient) {
        resolvedClientId = existingClient.id;
      } else {
        const createdClient = await tx.user.create({
          data: {
            id: resolvedClientId,
            email: normalizedClientEmail || `${resolvedClientId}@agrokera.ge`,
            fullName:
              body.contactPerson ||
              (normalizedClientEmail
                ? normalizedClientEmail.split("@")[0]
                : "მომხმარებელი"),
            phoneNumber: `+995599${Math.floor(100000 + Math.random() * 900000)}`,
            role: Role.CLIENT,
            verificationStatus: VerificationStatus.VERIFIED,
          },
        });
        resolvedClientId = createdClient.id;
      }

      // Resolve products & decrement product stock
      const resolvedItems: Array<{
        productId: string;
        quantity: number;
        pricePerUnit: number;
        subtotal: number;
      }> = [];
      let resolvedFarmerId = body.farmerId || "farmer_2";

      for (const item of body.items) {
        let product = await tx.product.findUnique({
          where: { id: item.productId },
        });
        if (!product) {
          product = await tx.product.findFirst();
        }
        if (product) {
          resolvedFarmerId = product.farmerId;
          const newStock = Math.max(0, product.stockQuantity - Number(item.quantity));
          await tx.product.update({
            where: { id: product.id },
            data: {
              stockQuantity: newStock,
              stockStatus:
                newStock <= 0
                  ? "ამოწურულია"
                  : newStock < 20
                    ? "იწურება"
                    : "მარაგშია",
              isAvailable: newStock > 0,
            },
          });
          resolvedItems.push({
            productId: product.id,
            quantity: Number(item.quantity),
            pricePerUnit: Number(item.pricePerUnit),
            subtotal: Number(item.quantity) * Number(item.pricePerUnit),
          });
        }
      }

      const orderId = String(Math.floor(10000 + Math.random() * 90000));
      return tx.order.create({
        data: {
          id: orderId,
          clientId: resolvedClientId,
          farmerId: resolvedFarmerId,
          status: OrderStatus.PENDING,
          totalAmount,
          deliveryFee,
          heavyFee,
          platformFee,
          paymentMethod,
          isPickup,
          hasVat: body.hasVat ?? false,
          fulfillmentType:
            body.fulfillmentType === "SELF_PICKUP" || (body as { isPickup?: boolean }).isPickup === true
              ? FulfillmentType.SELF_PICKUP
              : FulfillmentType.FARMER_DELIVERY,
          contactPerson:
            body.contactPerson || existingClient?.fullName || "მომხმარებელი",
          contactPhone: body.contactPhone || "+995 599 12 34 56",
          deliveryAddress: body.deliveryAddress || "თბილისი, რუსთაველის 14",
          deliveryTimeWindow: body.deliveryTimeWindow || "დღეს, 16:00 - 19:00",
          deliveryNotes: body.deliveryNotes,
          cancellationDeadline: calculatePendingOrderDeadline(
            new Date(),
            body.deliveryTimeWindow
          ),
          items: {
            create: resolvedItems,
          },
          shipment: {
            create: {
              status: ShipmentStatus.PENDING,
              trackingNumber: `AK-${orderId}`,
            },
          },
        },
        include: {
          client: true,
          items: { include: { product: true } },
          shipment: true,
        },
      });
    });

    // Send and persist Push Notification to Farmer for New Order
    (async () => {
      try {
        const farmerProfile = await prisma.farmerProfile.findUnique({
          where: { id: createdOrder.farmerId },
          include: { user: true },
        });
        const productSummary =
          createdOrder.items.length === 1
            ? createdOrder.items[0].product.title
            : `${createdOrder.items[0].product.title} +${createdOrder.items.length - 1} სხვა`;

        if (farmerProfile?.userId) {
          const tmpl = NotificationTemplates.orderCreatedForFarmer({
            orderId: createdOrder.id,
            contactName: createdOrder.contactPerson || "მომხმარებელი",
            productSummary,
            totalAmount: createdOrder.totalAmount,
          });
          await createAndSendNotification({
            userId: farmerProfile.userId,
            title: tmpl.title,
            body: tmpl.body,
            orderId: createdOrder.id,
            category: tmpl.category,
            data: tmpl.data,
          });
        }

        if (createdOrder.clientId) {
          const tmpl = NotificationTemplates.orderCreatedForClient({
            orderId: createdOrder.id,
            productSummary,
          });
          await createAndSendNotification({
            userId: createdOrder.clientId,
            title: tmpl.title,
            body: tmpl.body,
            orderId: createdOrder.id,
            category: tmpl.category,
            data: tmpl.data,
          });
        }
      } catch (pushErr) {
        console.error("[FCM Order Error]:", pushErr);
      }
    })();

    orderMetadataMap.set(createdOrder.id, {
      deliveryFee,
      heavyFee,
      platformFee,
      paymentMethod,
      isPickup,
    });

    return jsonResponse(
      {
        id: createdOrder.id,
        farmerId: createdOrder.farmerId,
        customerAvatarUrl: createdOrder.client?.avatarUrl ?? null,
        clientId: createdOrder.clientId,
        createdAt: createdOrder.createdAt.toISOString(),
        status: createdOrder.status,
        customerName: createdOrder.contactPerson || createdOrder.client.fullName,
        contactPerson: createdOrder.contactPerson || createdOrder.client.fullName,
        contactPhone: null,
        hasVat: createdOrder.hasVat,
        totalAmount: createdOrder.totalAmount,
        fulfillmentType: createdOrder.fulfillmentType,
        isPickup,
        deliveryFee,
        heavyFee,
        platformFee,
        paymentMethod,
        deliveryTimeWindow:
          createdOrder.deliveryTimeWindow || "დღეს, 16:00 - 19:00",
        deliveryAddress: createdOrder.deliveryAddress,
        cancellationReason: createdOrder.cancellationReason,
        cancellationDeadline:
          createdOrder.cancellationDeadline?.toISOString() ?? null,
        shipmentStatus: createdOrder.shipment?.status ?? "PENDING",
        trackingNumber:
          createdOrder.shipment?.trackingNumber ??
          `AK-${createdOrder.id.slice(-5)}`,
        items: createdOrder.items.map((item) => ({
          productId: item.productId,
          name: item.product.title,
          quantity: item.quantity,
          unit: item.product.unit,
          quantityText: `${item.quantity}${item.product.unit}`,
          pricePerUnit: item.pricePerUnit,
          price: item.subtotal,
        })),
      },
      201
    );
  }

  // PATCH /api/orders/:id/status
  if (path.startsWith("/api/orders/") && path.endsWith("/status") && method === "PATCH") {
    const orderId = path.replace("/api/orders/", "").replace("/status", "");
    const body = (await request.json()) as {
      status: OrderStatus;
      cancellationReason?: string;
      shipmentStatus?: ShipmentStatus;
      requesterId?: string;       // userId of the caller (client or farmer user)
      requesterFarmerId?: string; // farmerId if caller is a farmer
    };

    // ── Cancellation permission check ──────────────────────────────────
    if (body.status === OrderStatus.CANCELLED) {
      const orderToCheck = await prisma.order.findUnique({
        where: { id: orderId },
        select: {
          clientId: true,
          farmerId: true,
          status: true,
          cancellationDeadline: true,
        },
      });

      if (!orderToCheck) {
        return errorResponse("Order not found", 404);
      }

      const isAlreadyCancelled = orderToCheck.status === OrderStatus.CANCELLED;
      if (isAlreadyCancelled) {
        return errorResponse("Order is already cancelled", 409);
      }

      const isClient = body.requesterId === orderToCheck.clientId;
      const isFarmer =
        body.requesterFarmerId &&
        body.requesterFarmerId === orderToCheck.farmerId;

      if (!isClient && !isFarmer) {
        // If neither matches (e.g. requester fields missing), still allow
        // but log the anomaly — conservative approach during migration
        console.warn(`[Cancel] requesterId=${body.requesterId} farmerId=${body.requesterFarmerId} orderId=${orderId} — no match, allowing`);
      }

      if (isClient && !isFarmer) {
        // Client cancellation rules:
        //  • PENDING → always allowed
        //  • IN_PROGRESS → only within the 10-min window
        if (orderToCheck.status === OrderStatus.IN_PROGRESS) {
          const deadline = orderToCheck.cancellationDeadline;
          if (!deadline || new Date() > deadline) {
            return errorResponse(
              "პირდაპირი გაუქმების ვადა (10 წუთი) გავიდა. შეკვეთა უკვე მზადდება — გასაუქმებლად დაუკავშირდით ფერმერს ან მხარდაჭერას.",
              403
            );
          }
        } else if (orderToCheck.status !== OrderStatus.PENDING) {
          return errorResponse(
            "კლიენტს შეუძლია პირდაპირი გაუქმება მხოლოდ PENDING ან IN_PROGRESS (დასტურიდან 10 წთ-ის განმავლობაში) სტატუსებში.",
            403
          );
        }
      }
      // Farmer can cancel any active (non-completed) order — no extra check needed
    }
    // ──────────────────────────────────────────────────────────────────

    const mappedShipmentStatus =
      body.shipmentStatus ??
      (body.status === OrderStatus.IN_PROGRESS
        ? ShipmentStatus.IN_TRANSIT
        : body.status === OrderStatus.COMPLETED
          ? ShipmentStatus.CONFIRMED
          : ShipmentStatus.PENDING);

    const updated = await prisma.$transaction(async (tx) => {
      const existingOrder = await tx.order.findUnique({
        where: { id: orderId },
        include: { items: true },
      });

      // If cancelling an active order, restore reserved product stock
      if (
        existingOrder &&
        body.status === OrderStatus.CANCELLED &&
        existingOrder.status !== OrderStatus.CANCELLED
      ) {
        for (const item of existingOrder.items) {
          const prod = await tx.product.findUnique({
            where: { id: item.productId },
          });
          if (prod) {
            const restoredStock = prod.stockQuantity + Number(item.quantity);
            await tx.product.update({
              where: { id: prod.id },
              data: {
                stockQuantity: restoredStock,
                stockStatus:
                  restoredStock <= 0
                    ? "ამოწურულია"
                    : restoredStock < 20
                      ? "იწურება"
                      : "მარაგშია",
                isAvailable: restoredStock > 0,
              },
            });
          }
        }
      }

      return tx.order.update({
        where: { id: orderId },
        data: {
          status: body.status,
          ...(body.cancellationReason
            ? { cancellationReason: body.cancellationReason }
            : {}),
          ...(body.status === OrderStatus.IN_PROGRESS
            ? { cancellationDeadline: new Date(Date.now() + 10 * 60 * 1000) }
            : {}),
          shipment: {
            upsert: {
              create: {
                status: mappedShipmentStatus,
                trackingNumber: `AK-${orderId}`,
              },
              update: {
                status: mappedShipmentStatus,
              },
            },
          },
        },
        include: {
          client: true,
          items: { include: { product: true } },
          shipment: true,
        },
      });
    });

    // Send and persist Push Notification to Client about Order Status Change
    (async () => {
      try {
        // Skip PENDING — that's the initial state; client gets no spurious ping
        if (updated.status === "PENDING") return;

        const tmpl = NotificationTemplates.orderStatusUpdated({
          orderId: updated.id,
          status: updated.status,
          cancellationReason: updated.cancellationReason,
        });
        if (!tmpl) return;

        await createAndSendNotification({
          userId: updated.clientId,
          title: tmpl.title,
          body: tmpl.body,
          orderId: updated.id,
          category: tmpl.category,
          data: tmpl.data,
        });
      } catch (pushErr) {
        console.error("[FCM Client Notification Error]:", pushErr);
      }
    })();

    return jsonResponse({
      id: updated.id,
      createdAt: updated.createdAt.toISOString(),
      status: updated.status,
      customerName: updated.contactPerson || updated.client.fullName,
      contactPerson: updated.contactPerson || updated.client.fullName,
      contactPhone: null,
      hasVat: updated.hasVat,
      totalAmount: updated.totalAmount,
      fulfillmentType: updated.fulfillmentType,
      isPickup: updated.fulfillmentType === FulfillmentType.SELF_PICKUP,
      deliveryFee: 0,
      heavyFee: 0,
      platformFee: 0,
      paymentMethod: "ESCROW",
      deliveryTimeWindow: updated.deliveryTimeWindow || "დღეს, 16:00 - 19:00",
      deliveryAddress: updated.deliveryAddress,
      cancellationReason: updated.cancellationReason,
      cancellationDeadline:
        updated.cancellationDeadline?.toISOString() ?? null,
      shipmentStatus: updated.shipment?.status ?? "PENDING",
      trackingNumber:
        updated.shipment?.trackingNumber ?? `AK-${updated.id.slice(-5)}`,
      items: updated.items.map((item) => ({
        productId: item.productId,
        name: item.product.title,
        quantity: item.quantity,
        unit: item.product.unit,
        quantityText: `${item.quantity}${item.product.unit}`,
        pricePerUnit: item.pricePerUnit,
        price: item.subtotal,
      })),
    });
  }

  // GET /api/orders/:id/messages
  if (path.startsWith("/api/orders/") && path.endsWith("/messages") && method === "GET") {
    const orderId = path.replace("/api/orders/", "").replace("/messages", "");
    let messages = await prisma.orderMessage.findMany({
      where: { orderId },
      orderBy: { createdAt: "asc" },
    });

    if (messages.length === 0) {
      try {
        const initial = await prisma.orderMessage.create({
          data: {
            id: `sys_${orderId}`,
            orderId,
            senderId: "system",
            senderRole: "guest",
            senderName: "AgroKera System",
            text: "შეკვეთის ჩათი გააქტიურდა. გამოიყენეთ მისამართისა და ჩაბარების დროის დასაზუსტებლად.",
            isSystem: true,
          },
        });
        messages = [initial];
      } catch (_) {
        messages = await prisma.orderMessage.findMany({
          where: { orderId },
          orderBy: { createdAt: "asc" },
        });
      }
    }

    return jsonResponse(
      messages.map((m) => ({
        id: m.id,
        orderId: m.orderId,
        senderId: m.senderId,
        senderRole: m.senderRole,
        senderName: m.senderName,
        text: m.text,
        isSystem: m.isSystem,
        createdAt: m.createdAt.toISOString(),
      }))
    );
  }

  // POST /api/orders/:id/messages
  if (path.startsWith("/api/orders/") && path.endsWith("/messages") && method === "POST") {
    const orderId = path.replace("/api/orders/", "").replace("/messages", "");
    const body = (await request.json()) as {
      id?: string;
      senderId?: string;
      senderRole?: string;
      senderName?: string;
      text?: string;
      isSystem?: boolean;
      createdAt?: string;
    };

    const rawText = (body.text || "").trim();
    if (!rawText) {
      return errorResponse("Message text cannot be empty", 400);
    }

    // Chat is open only after the farmer confirmed the order and
    // closes as soon as the order is completed or cancelled.
    const chatOrder = await prisma.order.findUnique({
      where: { id: orderId },
      select: { status: true },
    });
    if (!chatOrder) {
      return errorResponse("Order not found", 404);
    }
    if (!body.isSystem && chatOrder.status !== "IN_PROGRESS" && chatOrder.status !== "CONFIRMED") {
      const reason =
        chatOrder.status === "PENDING"
          ? "ჩათი გაიხსნება ფერმერის მიერ შეკვეთის დადასტურების შემდეგ"
          : "შეკვეთა დასრულებულია • ჩათი დახურულია";
      return errorResponse(reason, 403);
    }

    // Do not allow sharing phone numbers through chat
    const cleanText = maskPhoneNumbers(rawText);

    const msgId = body.id || `msg_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const message = await prisma.orderMessage.upsert({
      where: { id: msgId },
      create: {
        id: msgId,
        orderId,
        senderId: body.senderId || "unknown",
        senderRole: body.senderRole || "customer",
        senderName: body.senderName || "მომხმარებელი",
        text: cleanText,
        isSystem: Boolean(body.isSystem),
        createdAt: body.createdAt ? new Date(body.createdAt) : new Date(),
      },
      update: {
        text: cleanText,
      },
    });

    // Send and persist Push Notification to recipient
    (async () => {
      try {
        const order = await prisma.order.findUnique({
          where: { id: orderId },
          select: { clientId: true, farmerId: true },
        });
        if (!order) return;
        const farmerProfile = order.farmerId
          ? await prisma.farmerProfile.findUnique({
            where: { id: order.farmerId },
            select: { userId: true },
          })
          : null;
        const isSenderFarmer = body.senderRole === "farmer";
        const targetUserId = isSenderFarmer
          ? order.clientId
          : farmerProfile?.userId;
        if (targetUserId) {
          await createAndSendNotification({
            userId: targetUserId,
            title: `ახალი შეტყობინება (${body.senderName || "AgroKera"})`,
            body: cleanText,
            orderId,
            category: "orders",
            senderName: body.senderName || "AgroKera",
            data: {
              orderId,
              type: "chat_message",
              senderName: body.senderName || "AgroKera",
            },
          });
        }
      } catch (pushErr) {
        console.error("[FCM Chat Error]:", pushErr);
      }
    })();

    return jsonResponse(
      {
        id: message.id,
        orderId: message.orderId,
        senderId: message.senderId,
        senderRole: message.senderRole,
        senderName: message.senderName,
        text: message.text,
        isSystem: message.isSystem,
        createdAt: message.createdAt.toISOString(),
      },
      201
    );
  }

  return null;
}

