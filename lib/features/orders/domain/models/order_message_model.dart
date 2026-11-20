import '../../../../core/auth/auth_state_provider.dart';

/// Semantic message types for custom structured rendering
enum OrderMessageType {
  text,
  image,
  pin,
  pinRequest,
  bankDetails,
  address,
  location,
  intercom,
  summary;

  static OrderMessageType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'image':
      case 'photo':
        return OrderMessageType.image;
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
  final String? imageUrl;
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
    this.imageUrl,
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
    String? resolvedImageUrl = json['imageUrl'] as String?;
    String displayText = rawText;

    if (rawText.startsWith('[IMAGE]')) {
      msgType = OrderMessageType.image;
      final payload = rawText.substring('[IMAGE]'.length).trim();
      final separatorIndex = payload.indexOf('|');
      if (separatorIndex != -1) {
        resolvedImageUrl = resolvedImageUrl ?? payload.substring(0, separatorIndex).trim();
        displayText = payload.substring(separatorIndex + 1).trim();
      } else {
        resolvedImageUrl = resolvedImageUrl ?? payload;
        displayText = '';
      }
    } else if (msgType == OrderMessageType.text) {
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
      text: displayText,
      imageUrl: resolvedImageUrl,
      type: msgType,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isSystem: json['isSystem'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final String serializedText;
    if (type == OrderMessageType.image && imageUrl != null) {
      serializedText = '[IMAGE]$imageUrl|${text.trim()}';
    } else {
      serializedText = text;
    }

    return {
      'id': id,
      'orderId': orderId,
      'senderId': senderId,
      'senderRole': senderRole.name,
      'senderName': senderName,
      'text': serializedText,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isSystem': isSystem,
    };
  }
}
