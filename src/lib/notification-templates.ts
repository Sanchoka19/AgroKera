/**
 * Notification Templates & Copywriting rules for AgroKera.
 * 
 * Centralizes all push notification titles, bodies, and data payloads
 * to keep API endpoints lean and maintain single-responsibility.
 */

export interface FormattedNotification {
  title: string;
  body: string;
  category: "orders" | "promotions" | "system";
  data: Record<string, string>;
}

export class NotificationTemplates {
  /**
   * Helper to format consistent short order ID (e.g. #12345)
   */
  static shortId(orderId: string): string {
    return orderId.length > 5 ? orderId.slice(-5) : orderId;
  }

  /**
   * Farmer notification when a new order is placed
   */
  static orderCreatedForFarmer(params: {
    orderId: string;
    contactName: string;
    productSummary: string;
    totalAmount: number;
  }): FormattedNotification {
    const id = this.shortId(params.orderId);
    return {
      title: `ახალი შეკვეთა #${id} • ₾${params.totalAmount}`,
      body: `${params.contactName}: ${params.productSummary}. დასადასტურებლად გაქვთ 15 წთ.`,
      category: "orders",
      data: {
        orderId: params.orderId,
        type: "order_created",
      },
    };
  }

  /**
   * Client notification when their order has been placed
   */
  static orderCreatedForClient(params: {
    orderId: string;
    productSummary: string;
  }): FormattedNotification {
    const id = this.shortId(params.orderId);
    return {
      title: `შეკვეთა #${id} გაფორმდა`,
      body: `თქვენი შეკვეთა (${params.productSummary}) გადაეცა ფერმერს დასადასტურებლად.`,
      category: "orders",
      data: {
        orderId: params.orderId,
        type: "order_created_client",
      },
    };
  }

  /**
   * Client notification when order status changes (confirmed, completed, cancelled)
   */
  static orderStatusUpdated(params: {
    orderId: string;
    status: string;
    cancellationReason?: string | null;
  }): FormattedNotification | null {
    const id = this.shortId(params.orderId);
    switch (params.status) {
      case "IN_PROGRESS":
      case "CONFIRMED":
        return {
          title: `შეკვეთა #${id} დადასტურდა`,
          body: `ფერმერმა დაიწყო პროდუქციის მომზადება. ჩატი უკვე ხელმისაწვდომია.`,
          category: "orders",
          data: {
            orderId: params.orderId,
            type: "order_status_updated",
            status: params.status,
          },
        };
      case "COMPLETED":
        return {
          title: `შეკვეთა #${id} ჩაბარდა`,
          body: `შეკვეთა წარმატებით დასრულდა. გთხოვთ შეაფასოთ ფერმერი და პროდუქტის ხარისხი.`,
          category: "orders",
          data: {
            orderId: params.orderId,
            type: "order_review_prompt",
            status: params.status,
          },
        };
      case "CANCELLED":
        return {
          title: `შეკვეთა #${id} გაუქმდა`,
          body: params.cancellationReason
            ? `შეკვეთა გაუქმდა. მიზეზი: ${params.cancellationReason}`
            : `შეკვეთა გაუქმდა.`,
          category: "orders",
          data: {
            orderId: params.orderId,
            type: "order_status_updated",
            status: params.status,
          },
        };
      default:
        return null;
    }
  }

  /**
   * Stale order reminder for farmer (PIN confirmation required)
   */
  static staleReminderFarmer(orderId: string): FormattedNotification {
    const id = this.shortId(orderId);
    return {
      title: `შეკვეთა #${id} • PIN კოდის დამოწმება`,
      body: `შეკვეთის დასახურად სთხოვეთ კლიენტს 4-ნიშნა PIN კოდი პროდუქციის გადაცემისას.`,
      category: "orders",
      data: {
        orderId,
        type: "order_stale_farmer",
      },
    };
  }

  /**
   * Stale order reminder for client (provide PIN upon delivery)
   */
  static staleReminderClient(orderId: string): FormattedNotification {
    const id = this.shortId(orderId);
    return {
      title: `შეკვეთა #${id} • მიღების დასტური`,
      body: `პროდუქციის მიღებისას გთხოვთ გადასცეთ თქვენი PIN კოდი ფერმერს.`,
      category: "orders",
      data: {
        orderId,
        type: "order_stale_client",
      },
    };
  }

  /**
   * Farmer notification when a customer submits a review
   */
  static reviewReceived(params: {
    orderId: string;
    clientName: string;
    rating: number;
    comment?: string;
    farmerId: string;
  }): FormattedNotification {
    const id = this.shortId(params.orderId);
    const commentSnippet =
      params.comment && params.comment.trim().length > 0
        ? `: "${params.comment.trim().length > 60 ? params.comment.trim().slice(0, 57) + "..." : params.comment.trim()}"`
        : "";

    return {
      title: `ახალი შეფასება • ${params.rating}/5`,
      body: `${params.clientName}-მ შეაფასა შეკვეთა #${id}${commentSnippet}`,
      category: "orders",
      data: {
        orderId: params.orderId,
        farmerId: params.farmerId,
        type: "farmer_review_received",
        rating: String(params.rating),
      },
    };
  }

  /**
   * Pre-expiry warning for farmer
   */
  static expiryWarningFarmer(orderId: string, remainingMinutes: number): FormattedNotification {
    const id = this.shortId(orderId);
    const rounded = Math.max(1, Math.round(remainingMinutes));
    return {
      title: `შეკვეთა #${id} • დარჩენილია ~${rounded} წთ`,
      body: `შეკვეთის დასადასტურებლად დარჩენილია ცოტა დრო. გთხოვთ დაადასტუროთ ან უარყოთ.`,
      category: "orders",
      data: {
        orderId,
        type: "order_expiry_warning",
      },
    };
  }

  /**
   * Auto-cancelled notification due to expiration
   */
  static autoCancelled(orderId: string, isFarmer: boolean): FormattedNotification {
    const id = this.shortId(orderId);
    if (isFarmer) {
      return {
        title: `შეკვეთა #${id} • ვადა ამოიწურა`,
        body: `შეკვეთა გაუქმდა დასტურის ვადის ამოწურვის გამო.`,
        category: "orders",
        data: {
          orderId,
          type: "order_auto_cancelled_farmer",
        },
      };
    }
    return {
      title: `შეკვეთა #${id} გაუქმდა`,
      body: `შეკვეთა #${id} ავტომატურად გაუქმდა: ფერმერმა დადგენილ დროში ვერ დაადასტურა.`,
      category: "orders",
      data: {
        orderId,
        type: "order_auto_cancelled_client",
      },
    };
  }
}

