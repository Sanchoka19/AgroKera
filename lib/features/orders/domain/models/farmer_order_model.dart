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
}

/// Rich domain model representing an incoming order for a farmer
class FarmerOrder {
  final String id;
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

  const FarmerOrder({
    required this.id,
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
  });

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
  }) {
    return FarmerOrder(
      id: id ?? this.id,
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
    );
  }
}
