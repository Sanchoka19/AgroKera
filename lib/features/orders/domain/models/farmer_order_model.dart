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
  final String name;
  final String quantityText;
  final double price;

  const FarmerOrderItem({
    required this.name,
    required this.quantityText,
    required this.price,
  });

  factory FarmerOrderItem.fromJson(Map<String, dynamic> json) {
    return FarmerOrderItem(
      name: json['name'] as String? ?? 'პროდუქტი',
      quantityText: json['quantityText'] as String? ?? '1კგ',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
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
  });

  factory FarmerOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const [];
    return FarmerOrder(
      id: json['id'] as String? ?? '00000',
      farmerId: json['farmerId'] as String?,
      clientId: json['clientId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      status: OrderStatus.fromApi(json['status'] as String?),
      customerName: json['customerName'] as String? ?? 'მყიდველი',
      contactPerson: json['contactPerson'] as String? ?? 'მყიდველი',
      contactPhone: json['contactPhone'] as String? ?? '+995 599 12 34 56',
      hasVat: json['hasVat'] as bool? ?? false,
      deliveryTimeWindow: json['deliveryTimeWindow'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      cancellationDeadline: json['cancellationDeadline'] != null
          ? DateTime.tryParse(json['cancellationDeadline'] as String)
          : null,
      trackingNumber: json['trackingNumber'] as String?,
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

  /// Full Total Amount (Subtotal + VAT)
  double get totalAmount => subtotal + vatAmount;

  /// User friendly summary text of products for cards
  String get productsSummary {
    if (items.isEmpty) return 'პროდუქტი მითითებული არ არის';
    if (items.length == 1) {
      return items.first.name;
    }
    return '${items.first.name} +${items.length - 1} სხვა';
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
    );
  }
}
