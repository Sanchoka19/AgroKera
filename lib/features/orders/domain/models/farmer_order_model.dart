import 'package:flutter/material.dart';

/// Status of an incoming farmer order
enum OrderStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'მომლოდინე';
      case OrderStatus.inProgress:
        return 'მიმდინარე';
      case OrderStatus.completed:
        return 'დასრულებული';
      case OrderStatus.cancelled:
        return 'გაუქმებული';
    }
  }

  String get apiValue {
    switch (this) {
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.inProgress:
        return 'IN_PROGRESS';
      case OrderStatus.completed:
        return 'COMPLETED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static OrderStatus fromApi(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'IN_PROGRESS':
      case 'CONFIRMED':
        return OrderStatus.inProgress;
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'PENDING':
      default:
        return OrderStatus.pending;
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFD97706); // Amber
      case OrderStatus.inProgress:
        return const Color(0xFF2563EB); // Royal Blue
      case OrderStatus.completed:
        return const Color(0xFF16A34A); // Forest Green
      case OrderStatus.cancelled:
        return const Color(0xFFDC2626); // Crimson Red
    }
  }

  Color get badgeBg {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFFEF3C7);
      case OrderStatus.inProgress:
        return const Color(0xFFEFF6FF);
      case OrderStatus.completed:
        return const Color(0xFFE8F7EE);
      case OrderStatus.cancelled:
        return const Color(0xFFFEE2E2);
    }
  }
}

/// A line item inside a farmer order
class FarmerOrderItem {
  final String? productId;
  final String name;
  final String quantityText;
  final double price;
  final double quantity;

  const FarmerOrderItem({
    this.productId,
    required this.name,
    required this.quantityText,
    required this.price,
    this.quantity = 1.0,
  });

  factory FarmerOrderItem.fromJson(Map<String, dynamic> json) {
    return FarmerOrderItem(
      productId: json['productId'] as String? ?? json['id'] as String?,
      name: json['name'] as String? ?? 'პროდუქტი',
      quantityText: json['quantityText'] as String? ?? '1კგ',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (productId != null) 'productId': productId,
      'name': name,
      'quantityText': quantityText,
      'price': price,
      'quantity': quantity,
    };
  }
}

/// Rich domain model representing an order for both farmer & client views
class FarmerOrder {
  final String id;
  final String? farmerId;
  final String? clientId;
  final DateTime createdAt;
  final OrderStatus status;
  final String customerName;
  final String contactPerson;
  final String contactPhone;
  final List<FarmerOrderItem> items;
  final String? deliveryTimeWindow;
  final String? deliveryAddress;
  final String? cancellationReason;
  final bool hasVat;
  final DateTime? cancellationDeadline;
  final String? trackingNumber;
  final String paymentMethod;
  final bool hasClientReportedPayment;
  final bool isPaymentConfirmed;
  final String deliveryPin;
  final double deliveryFee;
  final double heavyFee;
  final double platformFee;
  final bool isPickup;
  final String? farmerName;
  final String? farmerAvatarUrl;

  const FarmerOrder({
    required this.id,
    this.farmerId,
    this.clientId,
    required this.createdAt,
    required this.status,
    required this.customerName,
    required this.contactPerson,
    required this.contactPhone,
    required this.items,
    this.deliveryTimeWindow,
    this.deliveryAddress,
    this.cancellationReason,
    this.hasVat = false,
    this.cancellationDeadline,
    this.trackingNumber,
    this.paymentMethod = 'ESCROW',
    this.hasClientReportedPayment = false,
    this.isPaymentConfirmed = false,
    this.deliveryPin = '4821',
    this.deliveryFee = 0.0,
    this.heavyFee = 0.0,
    this.platformFee = 0.0,
    this.isPickup = false,
    this.farmerName,
    this.farmerAvatarUrl,
  });

  static String generatePinForId(String id) {
    final code = (id.hashCode.abs() % 9000) + 1000;
    return code.toString();
  }

  factory FarmerOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const [];
    final id = json['id'] as String? ?? '00000';
    return FarmerOrder(
      id: id,
      farmerId: json['farmerId'] as String?,
      clientId: json['clientId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      status: OrderStatus.fromApi(json['status'] as String?),
      customerName: json['customerName'] as String? ?? 'მყიდველი',
      contactPerson: json['contactPerson'] as String? ?? 'მყიდველი',
      contactPhone: json['contactPhone'] as String? ?? '',
      hasVat: json['hasVat'] as bool? ?? false,
      deliveryTimeWindow: json['deliveryTimeWindow'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      cancellationDeadline: json['cancellationDeadline'] != null
          ? DateTime.tryParse(json['cancellationDeadline'] as String)
          : null,
      trackingNumber: json['trackingNumber'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? 'ESCROW',
      hasClientReportedPayment:
          json['hasClientReportedPayment'] as bool? ?? false,
      isPaymentConfirmed: json['isPaymentConfirmed'] as bool? ?? false,
      deliveryPin: json['deliveryPin'] as String? ?? generatePinForId(id),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      heavyFee: (json['heavyFee'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      isPickup: json['isPickup'] as bool? ?? false,
      farmerName: json['farmerName'] as String?,
      farmerAvatarUrl: json['farmerAvatarUrl'] as String?,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(FarmerOrderItem.fromJson)
          .toList(),
    );
  }

  /// Subtotal (sum of item prices)
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.price);

  /// Calculated 18% VAT if farmer is registered as VAT payer
  double get vatAmount => hasVat ? (subtotal * 0.18) : 0.0;

  /// Total logistics & delivery fee (standard delivery + heavy fee)
  double get totalDeliveryFee => isPickup ? 0.0 : (deliveryFee + heavyFee);

  /// Full Total Amount (Subtotal + VAT + Delivery Fee + Heavy Fee + Platform Fee)
  double get totalAmount =>
      subtotal + vatAmount + (isPickup ? 0.0 : (deliveryFee + heavyFee)) + platformFee;

  /// User friendly summary text of products for cards
  String get productsSummary {
    if (items.isEmpty) return 'პროდუქტი მითითებული არ არის';
    if (items.length == 1) {
      return items.first.name;
    }
    return '${items.first.name} +${items.length - 1} სხვა';
  }

  /// Whether payment is processed via AgroKera Escrow Bank Transfer
  bool get isBankTransfer {
    final pm = paymentMethod.toUpperCase();
    return pm == 'BANKTRANSFER' || pm == 'ESCROW';
  }

  /// Whether payment is made with cash on delivery/pickup
  bool get isCash {
    final pm = paymentMethod.toUpperCase();
    return pm == 'CASH';
  }

  /// Whether cancellation without prior approval is still possible
  bool get canDirectlyCancel {
    if (status != OrderStatus.inProgress && status != OrderStatus.pending) {
      return false;
    }
    if (cancellationDeadline == null) return false;
    return DateTime.now().isBefore(cancellationDeadline!);
  }

  /// Remaining duration before direct cancel window expires
  Duration get remainingCancellationTime {
    if (cancellationDeadline == null) return Duration.zero;
    final remaining = cancellationDeadline!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Formats the remaining review/cancellation duration for UI display
  String get formattedRemainingCancellationTime {
    final d = remainingCancellationTime;
    if (d == Duration.zero) return '0 წთ';
    final totalMinutes = (d.inSeconds + 30) ~/ 60;
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final remMin = totalMinutes % 60;
      return remMin > 0 ? '~$hours სთ $remMin წთ' : '~$hours სთ';
    }
    return '~${totalMinutes > 0 ? totalMinutes : 1} წთ';
  }

  /// Calculates the pending review deadline based on Georgia time (UTC+4):
  /// - Working hours: 08:00 - 21:00 GET
  /// - Urgent / same-day ("დღეს"): 45 min
  /// - Scheduled / future ("ხვალ" / "ზეგ"): 120 min (2 h)
  /// - Default: 60 min
  /// - Quiet hours (21:00 - 08:00): starts next morning from 08:00 GET.
  static DateTime calculatePendingOrderDeadline({
    DateTime? now,
    String? deliveryTimeWindow,
  }) {
    final effectiveNow = now ?? DateTime.now();
    const georgiaOffset = Duration(hours: 4);
    final georgiaTime = effectiveNow.toUtc().add(georgiaOffset);
    final gHours = georgiaTime.hour;
    final gMinutes = georgiaTime.minute;

    final windowStr = (deliveryTimeWindow ?? '').toLowerCase();
    int durationMinutes = 60;
    if (windowStr.contains('დღეს') || windowStr.contains('today')) {
      durationMinutes = 45;
    } else if (windowStr.contains('ხვალ') ||
        windowStr.contains('tomorrow') ||
        windowStr.contains('ზეგ')) {
      durationMinutes = 120;
    }

    if (gHours < 8) {
      // Early morning before working hours -> starts today at 08:00 GET
      final targetGeorgia = DateTime.utc(
        georgiaTime.year,
        georgiaTime.month,
        georgiaTime.day,
        8,
        0,
      ).add(Duration(minutes: durationMinutes));
      return targetGeorgia.subtract(georgiaOffset).toLocal();
    } else if (gHours >= 21) {
      // Night after working hours -> starts tomorrow at 08:00 GET
      final targetGeorgia = DateTime.utc(
        georgiaTime.year,
        georgiaTime.month,
        georgiaTime.day + 1,
        8,
        0,
      ).add(Duration(minutes: durationMinutes));
      return targetGeorgia.subtract(georgiaOffset).toLocal();
    } else {
      // During working hours (08:00 - 21:00 GET)
      final remainingWorkMinToday = (21 - gHours) * 60 - gMinutes;
      if (durationMinutes <= remainingWorkMinToday) {
        return effectiveNow.add(Duration(minutes: durationMinutes));
      } else {
        final overflowMin = durationMinutes - remainingWorkMinToday;
        final targetGeorgia = DateTime.utc(
          georgiaTime.year,
          georgiaTime.month,
          georgiaTime.day + 1,
          8,
          0,
        ).add(Duration(minutes: overflowMin));
        return targetGeorgia.subtract(georgiaOffset).toLocal();
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (farmerId != null) 'farmerId': farmerId,
      if (clientId != null) 'clientId': clientId,
      'createdAt': createdAt.toIso8601String(),
      'status': status.apiValue,
      'customerName': customerName,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      if (deliveryTimeWindow != null) 'deliveryTimeWindow': deliveryTimeWindow,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      'hasVat': hasVat,
      if (cancellationDeadline != null)
        'cancellationDeadline': cancellationDeadline!.toIso8601String(),
      if (trackingNumber != null) 'trackingNumber': trackingNumber,
      'paymentMethod': paymentMethod,
      'hasClientReportedPayment': hasClientReportedPayment,
      'isPaymentConfirmed': isPaymentConfirmed,
      'deliveryPin': deliveryPin,
      'deliveryFee': deliveryFee,
      'heavyFee': heavyFee,
      'platformFee': platformFee,
      'isPickup': isPickup,
      if (farmerName != null) 'farmerName': farmerName,
      if (farmerAvatarUrl != null) 'farmerAvatarUrl': farmerAvatarUrl,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  FarmerOrder copyWith({
    String? id,
    String? farmerId,
    String? clientId,
    DateTime? createdAt,
    OrderStatus? status,
    String? customerName,
    String? contactPerson,
    String? contactPhone,
    List<FarmerOrderItem>? items,
    String? deliveryTimeWindow,
    String? deliveryAddress,
    String? cancellationReason,
    bool? hasVat,
    DateTime? cancellationDeadline,
    String? trackingNumber,
    String? paymentMethod,
    bool? hasClientReportedPayment,
    bool? isPaymentConfirmed,
    String? deliveryPin,
    double? deliveryFee,
    double? heavyFee,
    double? platformFee,
    bool? isPickup,
    String? farmerName,
    String? farmerAvatarUrl,
  }) {
    return FarmerOrder(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      items: items ?? this.items,
      deliveryTimeWindow: deliveryTimeWindow ?? this.deliveryTimeWindow,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      hasVat: hasVat ?? this.hasVat,
      cancellationDeadline: cancellationDeadline ?? this.cancellationDeadline,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      hasClientReportedPayment:
          hasClientReportedPayment ?? this.hasClientReportedPayment,
      isPaymentConfirmed: isPaymentConfirmed ?? this.isPaymentConfirmed,
      deliveryPin: deliveryPin ?? this.deliveryPin,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      heavyFee: heavyFee ?? this.heavyFee,
      platformFee: platformFee ?? this.platformFee,
      isPickup: isPickup ?? this.isPickup,
      farmerName: farmerName ?? this.farmerName,
      farmerAvatarUrl: farmerAvatarUrl ?? this.farmerAvatarUrl,
    );
  }
}
