import 'package:flutter/foundation.dart';

/// Clean domain model representing a customer review and rating for an order.
@immutable
class OrderReviewModel {
  final String id;
  final String orderId;
  final String clientId;
  final String clientName;
  final String? clientAvatarUrl;
  final String farmerId;
  final int rating;
  final List<String> tags;
  final String? comment;
  final DateTime createdAt;

  const OrderReviewModel({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.clientName,
    this.clientAvatarUrl,
    required this.farmerId,
    required this.rating,
    this.tags = const [],
    this.comment,
    required this.createdAt,
  });

  factory OrderReviewModel.fromJson(Map<String, dynamic> json) {
    return OrderReviewModel(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      clientName: json['clientName'] as String? ?? 'მომხმარებელი',
      clientAvatarUrl: json['clientAvatarUrl'] as String?,
      farmerId: json['farmerId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'clientId': clientId,
        'clientName': clientName,
        if (clientAvatarUrl != null) 'clientAvatarUrl': clientAvatarUrl,
        'farmerId': farmerId,
        'rating': rating,
        'tags': tags,
        if (comment != null) 'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };
}

