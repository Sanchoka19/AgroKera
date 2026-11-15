import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/orders/domain/models/farmer_order_model.dart';
import 'package:agrokera/features/orders/domain/models/order_message_model.dart';
import 'package:agrokera/features/orders/presentation/providers/order_chat_provider.dart';
import 'package:agrokera/features/orders/presentation/screens/order_chat_screen.dart';
import 'package:agrokera/features/orders/presentation/widgets/order_pin_verification_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleOrder = FarmerOrder(
    id: '12349',
    createdAt: DateTime.now(),
    status: OrderStatus.inProgress,
    customerName: 'ნინო დავითაშვილი',
    contactPerson: 'ნინო დავითაშვილი',
    contactPhone: '+995 591 99 88 77',
    paymentMethod: 'ESCROW',
    deliveryPin: '4821',
    items: const [
      FarmerOrderItem(
        name: 'ნატურალური მაისის თაფლი',
        quantityText: '3 ქილა (3კგ)',
        price: 75.00,
      ),
    ],
  );

  group('Delivery PIN & Order Message Models', () {
    test('FarmerOrder generates a deterministic 4-digit PIN when none provided', () {
      final orderWithAutoPin = FarmerOrder.fromJson(const {
        'id': '99482',
        'customerName': 'გიორგი',
        'contactPerson': 'გიორგი',
        'contactPhone': '+995599000000',
        'items': [],
      });

      expect(orderWithAutoPin.deliveryPin.length, equals(4));
      expect(int.tryParse(orderWithAutoPin.deliveryPin), isNotNull);
      expect(orderWithAutoPin.deliveryPin, equals(FarmerOrder.generatePinForId('99482')));
    });

    test('OrderMessage serialization and deserialization works cleanly', () {
      final now = DateTime.now();
      final msg = OrderMessage(
        id: 'msg_1',
        orderId: '12349',
        senderId: 'user_1',
        senderRole: UserRole.customer,
        senderName: 'ნინო',
        text: 'გამარჯობა, ადგილზე ვარ',
        createdAt: now,
      );

      final json = msg.toJson();
      expect(json['id'], equals('msg_1'));
      expect(json['senderRole'], equals('customer'));

      final parsed = OrderMessage.fromJson(json);
      expect(parsed.text, equals('გამარჯობა, ადგილზე ვარ'));
      expect(parsed.senderRole, equals(UserRole.customer));
    });
  });

  group('OrderChatNotifier Unit Tests', () {
    test('loadMessages initializes default system message and sends message', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(orderChatProvider.notifier);
      await notifier.loadMessages('12349');

      final initialMessages = container.read(orderChatProvider)['12349']!;
      expect(initialMessages.isNotEmpty, isTrue);
      expect(initialMessages.first.isSystem, isTrue);
      expect(initialMessages.first.text, contains('შეკვეთის ჩათი გააქტიურდა'));

      // Send a customer message
      await notifier.sendMessage(
        orderId: '12349',
        text: 'სადარბაზოს კოდია #45',
        senderId: 'cust_1',
        senderRole: UserRole.customer,
        senderName: 'ნინო',
      );

      final updatedMessages = container.read(orderChatProvider)['12349']!;
      expect(updatedMessages.length, equals(2));
      expect(updatedMessages.last.text, equals('სადარბაზოს კოდია #45'));
      expect(updatedMessages.last.senderRole, equals(UserRole.customer));
    });
  });

  group('Order PIN Verification BottomSheet Widget Tests', () {
    testWidgets('rejects invalid PIN and confirms when PIN matches', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await OrderPinVerificationBottomSheet.show(
                    context: context,
                    order: sampleOrder,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('ჩაბარების PIN კოდი'), findsOneWidget);

      // Enter wrong PIN '1111'
      await tester.enterText(find.byType(TextField), '1111');
      await tester.tap(find.text('დადასტურება'));
      await tester.pumpAndSettle();

      expect(find.text('არასწორი PIN კოდი! გადაამოწმეთ მყიდველთან.'), findsOneWidget);
      expect(result, isNull);

      // Enter correct PIN '4821'
      await tester.enterText(find.byType(TextField), '4821');
      await tester.tap(find.text('დადასტურება'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('OrderChatScreen Widget Tests', () {
    testWidgets('renders security banner, quick replies, and sends message', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: OrderChatScreen(order: sampleOrder),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check tracking title
      expect(find.textContaining('AK-12349'), findsOneWidget);

      // Check security warning banner
      expect(find.textContaining('უსაფრთხოებისთვის: თქვენი ჩაბარების PIN კოდი (4821)'), findsOneWidget);

      // Check quick reply chip
      expect(find.text('ადგილზე ვარ'), findsOneWidget);

      // Tap quick reply 'ადგილზე ვარ'
      await tester.tap(find.text('ადგილზე ვარ'));
      await tester.pumpAndSettle();

      // Check that message bubble appears in chat
      expect(find.text('ადგილზე ვარ'), findsWidgets);
    });
  });
}
