import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/orders/domain/models/order_message_model.dart';

void main() {
  group('OrderMessage Image Attachment Domain Tests', () {
    test('parses image message from JSON with explicit imageUrl', () {
      final json = {
        'id': 'msg_img_1',
        'orderId': 'order_100',
        'senderId': 'farmer_1',
        'senderRole': 'farmer',
        'senderName': 'გიორგის ფერმა',
        'text': 'სასწორის ფოტო: 1.52 კგ',
        'type': 'image',
        'imageUrl': 'https://example.com/scale_proof.jpg',
        'createdAt': '2026-11-20T14:30:00.000Z',
      };

      final message = OrderMessage.fromJson(json);

      expect(message.type, equals(OrderMessageType.image));
      expect(message.imageUrl, equals('https://example.com/scale_proof.jpg'));
      expect(message.text, equals('სასწორის ფოტო: 1.52 კგ'));
      expect(message.senderRole, equals(UserRole.farmer));
    });

    test('parses legacy [IMAGE] text tag for backward database compatibility', () {
      final json = {
        'id': 'msg_img_2',
        'orderId': 'order_100',
        'senderId': 'client_1',
        'senderRole': 'customer',
        'senderName': 'ნინო',
        'text': '[IMAGE]data:image/jpeg;base64,abc123xyz|შეფუთვის მდგომარეობა',
        'type': 'text',
        'createdAt': '2026-11-20T14:35:00.000Z',
      };

      final message = OrderMessage.fromJson(json);

      expect(message.type, equals(OrderMessageType.image));
      expect(message.imageUrl, equals('data:image/jpeg;base64,abc123xyz'));
      expect(message.text, equals('შეფუთვის მდგომარეობა'));
    });

    test('serializes image message to JSON including backward compatible [IMAGE] text tag', () {
      final message = OrderMessage(
        id: 'msg_img_3',
        orderId: 'order_100',
        senderId: 'farmer_1',
        senderRole: UserRole.farmer,
        senderName: 'გიორგის ფერმა',
        text: 'გამზადებული პროდუქცია',
        imageUrl: 'https://images.example.com/chickens.jpg',
        type: OrderMessageType.image,
        createdAt: DateTime.parse('2026-11-20T14:40:00.000Z'),
      );

      final json = message.toJson();

      expect(json['type'], equals('image'));
      expect(json['imageUrl'], equals('https://images.example.com/chickens.jpg'));
      expect(json['text'], equals('[IMAGE]https://images.example.com/chickens.jpg|გამზადებული პროდუქცია'));
    });

    test('OrderMessageType.fromString correctly recognizes photo and image strings', () {
      expect(OrderMessageType.fromString('image'), equals(OrderMessageType.image));
      expect(OrderMessageType.fromString('IMAGE'), equals(OrderMessageType.image));
      expect(OrderMessageType.fromString('photo'), equals(OrderMessageType.image));
    });
  });
}

