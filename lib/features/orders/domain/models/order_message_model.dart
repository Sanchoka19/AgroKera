import '../../../../core/auth/auth_state_provider.dart';

/// Semantic message types for custom structured rendering
enum OrderMessageType {
  text,
  pin,
  pinRequest,
  bankDetails,
  address,
  location,
  intercom,
  summary;

  static OrderMessageType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'pin':
        return OrderMessageType.pin;
      case 'pinrequest':
      case 'pin_request':
        return OrderMessageType.pinRequest;
      case 'bankdetails':
      case 'bank_details':
      case 'bank':
        return OrderMessageType.bankDetails;
      case 'address':
        return OrderMessageType.address;
      case 'location':
        return OrderMessageType.location;
      case 'intercom':
        return OrderMessageType.intercom;
      case 'summary':
        return OrderMessageType.summary;
      default:
        return OrderMessageType.text;
    }
  }
}

/// Represents a chat message within an order's lifecycle
class OrderMessage {
  final String id;
  final String orderId;
  final String senderId;
  final UserRole senderRole;
  final String senderName;
  final String text;
  final OrderMessageType type;
  final DateTime createdAt;
  final bool isSystem;

  const OrderMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.text,
    this.type = OrderMessageType.text,
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

    final rawText = json['text'] as String? ?? '';
    var msgType = OrderMessageType.fromString(json['type'] as String?);

    // Fallback tag detection for backwards compatibility
    if (msgType == OrderMessageType.text) {
      if (rawText.startsWith('[PIN_REQUEST]')) {
        msgType = OrderMessageType.pinRequest;
      } else if (rawText.startsWith('[BANK]')) {
        msgType = OrderMessageType.bankDetails;
      } else if (rawText.startsWith('[PIN]')) {
        msgType = OrderMessageType.pin;
      } else if (rawText.startsWith('[ADDRESS]')) {
        msgType = OrderMessageType.address;
      } else if (rawText.startsWith('[LOCATION]')) {
        msgType = OrderMessageType.location;
      } else if (rawText.startsWith('[INTERCOM]')) {
        msgType = OrderMessageType.intercom;
      } else if (rawText.startsWith('[SUMMARY]')) {
        msgType = OrderMessageType.summary;
      }
    }

    return OrderMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: json['orderId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderRole: role,
      senderName: json['senderName'] as String? ?? 'მომხმარებელი',
      text: rawText,
      type: msgType,
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
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isSystem': isSystem,
    };
  }
}
