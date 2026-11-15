import '../../../../core/auth/auth_state_provider.dart';

/// Represents a chat message within an order's lifecycle
class OrderMessage {
  final String id;
  final String orderId;
  final String senderId;
  final UserRole senderRole;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool isSystem;

  const OrderMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.isSystem = false,
  });

  factory OrderMessage.fromJson(Map<String, dynamic> json) {
    final roleRaw = json['senderRole'] as String? ?? 'customer';
    final role = switch (roleRaw.toLowerCase()) {
      'farmer' => UserRole.farmer,
      'guest' => UserRole.guest,
      _ => UserRole.customer,
    };

    return OrderMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: json['orderId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderRole: role,
      senderName: json['senderName'] as String? ?? 'მომხმარებელი',
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isSystem: json['isSystem'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'senderId': senderId,
      'senderRole': senderRole.name,
      'senderName': senderName,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'isSystem': isSystem,
    };
  }
}

