import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/orders/domain/models/farmer_order_model.dart';
import 'package:agrokera/features/orders/domain/models/order_message_model.dart';
import 'package:agrokera/features/orders/presentation/controllers/order_chat_actions_controller.dart';
import 'package:agrokera/features/orders/presentation/providers/order_chat_provider.dart';
import 'package:agrokera/features/orders/presentation/widgets/order_chat/order_chat_card_bubble.dart';
import 'package:agrokera/features/orders/presentation/widgets/order_chat/order_chat_quick_actions_sheet.dart';
import 'package:agrokera/features/profile/presentation/providers/user_address_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  final sampleOrder = FarmerOrder(
    id: '12349',
    createdAt: DateTime.now(),
    status: OrderStatus.inProgress,
    customerName: 'სანდრო კერვალიშვილი',
    contactPerson: 'სანდრო',
    contactPhone: '599123456',
    items: const [
      FarmerOrderItem(
        name: 'ქართული პომიდორი',
        quantityText: '5 კგ',
        price: 4.5,
        quantity: 5.0,
      ),
    ],
    deliveryAddress: 'თბილისი, ჭავჭავაძის გამზ. 24, სადარბაზო 2, ბინა 45',
    deliveryPin: '4821',
    paymentMethod: 'ESCROW',
  );

  group('OrderChatActionsController Unit Tests', () {
    test('sendDeliveryAddress formats and sends message with OrderMessageType.address', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(orderChatActionsControllerProvider);
      final element = createElement();

      final success = await controller.sendDeliveryAddress(
        context: element,
        order: sampleOrder,
      );

      expect(success, isTrue);

      final chatMap = container.read(orderChatProvider);
      final messages = chatMap[sampleOrder.id] ?? [];
      expect(messages.isNotEmpty, isTrue);

      final last = messages.last;
      expect(last.type, equals(OrderMessageType.address));
      expect(last.text, contains('მიწოდების მისამართი:'));
      expect(last.text, contains(sampleOrder.deliveryAddress!));
    });

    test(
        'sendDeliveryAddress shares customer personal address, never leaking farm pickup location',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const customerHomeAddress = 'რუსთაველის გამზ. 14, თბილისი';
      await container
          .read(userAddressProvider.notifier)
          .setActiveAddress(customerHomeAddress);

      final pickupOrder = sampleOrder.copyWith(
        isPickup: true,
        deliveryAddress: 'თვითგატანა მეურნეობიდან: მწვანე ველი (კახეთი, თელავი)',
      );

      final controller = container.read(orderChatActionsControllerProvider);
      final element = createElement();

      final success = await controller.sendDeliveryAddress(
        context: element,
        order: pickupOrder,
      );

      expect(success, isTrue);

      final chatMap = container.read(orderChatProvider);
      final messages = chatMap[pickupOrder.id] ?? [];
      expect(messages.isNotEmpty, isTrue);

      final last = messages.last;
      expect(last.type, equals(OrderMessageType.address));
      // Must contain customer's actual address
      expect(last.text, contains(customerHomeAddress));
      // Must NOT contain farm address
      expect(last.text, isNot(contains('თვითგატანა მეურნეობიდან')));
      expect(last.text, isNot(contains('მწვანე ველი')));
    });

    test('sendIntercomCode sends intercom details with OrderMessageType.intercom', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(orderChatActionsControllerProvider);
      final element = createElement();

      final success = await controller.sendIntercomCode(
        context: element,
        order: sampleOrder,
        codeDetails: 'კოდია #9921, მე-3 სართული',
      );

      expect(success, isTrue);

      final chatMap = container.read(orderChatProvider);
      final messages = chatMap[sampleOrder.id] ?? [];
      final last = messages.last;
      expect(last.type, equals(OrderMessageType.intercom));
      expect(last.text, contains('სადარბაზო / დომოფონი:'));
      expect(last.text, contains('#9921'));
    });

    test('sendDeliveryPin sends PIN code with OrderMessageType.pin', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(orderChatActionsControllerProvider);
      final element = createElement();

      final success = await controller.sendDeliveryPin(
        context: element,
        order: sampleOrder,
      );

      expect(success, isTrue);

      final chatMap = container.read(orderChatProvider);
      final messages = chatMap[sampleOrder.id] ?? [];
      final last = messages.last;
      expect(last.type, equals(OrderMessageType.pin));
      expect(last.text, contains('ჩაბარების PIN კოდი:'));
      expect(last.text, contains('4821'));
    });

    test('requestDeliveryPin sends PIN request from farmer with OrderMessageType.pinRequest', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(orderChatActionsControllerProvider);
      final element = createElement();

      final success = await controller.requestDeliveryPin(
        context: element,
        order: sampleOrder,
      );

      expect(success, isTrue);

      final chatMap = container.read(orderChatProvider);
      final messages = chatMap[sampleOrder.id] ?? [];
      final last = messages.last;
      expect(last.type, equals(OrderMessageType.pinRequest));
      expect(last.text, contains('გთხოვთ, შეამოწმოთ პროდუქცია და გადმომცეთ თქვენი 4-ნიშნა PIN კოდი'));
    });

    test('sendBankDetails sends formatted IBAN with OrderMessageType.bankDetails', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(orderChatActionsControllerProvider);
      final element = createElement();

      final success = await controller.sendBankDetails(
        context: element,
        order: sampleOrder,
        bankName: 'თიბისი ბანკი',
        iban: 'GE29TB7553608011000018',
        beneficiaryName: 'მწვანე მეურნეობა',
      );

      expect(success, isTrue);

      final chatMap = container.read(orderChatProvider);
      final messages = chatMap[sampleOrder.id] ?? [];
      final last = messages.last;
      expect(last.type, equals(OrderMessageType.bankDetails));
      expect(last.text, contains('საბანკო რეკვიზიტები:'));
      expect(last.text, contains('GE29TB7553608011000018'));
      expect(last.text, contains('მწვანე მეურნეობა'));
    });

    test('sendOrderSummary sends formatted items and total amount', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(orderChatActionsControllerProvider);
      final element = createElement();

      final success = await controller.sendOrderSummary(
        context: element,
        order: sampleOrder,
      );

      expect(success, isTrue);

      final chatMap = container.read(orderChatProvider);
      final messages = chatMap[sampleOrder.id] ?? [];
      final last = messages.last;
      expect(last.type, equals(OrderMessageType.summary));
      expect(last.text, contains('შეკვეთის შეჯამება'));
      expect(last.text, contains('ქართული პომიდორი (5 კგ)'));
    });
  });

  group('OrderChatCardBubble Widget Tests', () {
    testWidgets('renders PIN card with LucideIcons.keyRound and complete order button for farmer', (tester) async {
      final message = OrderMessage(
        id: 'msg_pin_1',
        orderId: '12349',
        senderId: 'user_1',
        senderRole: UserRole.customer,
        senderName: 'სანდრო',
        text: 'ჩაბარების PIN კოდი:\n4821',
        type: OrderMessageType.pin,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderChatCardBubble(
              message: message,
              isMe: false,
              order: sampleOrder,
              isFarmer: true,
            ),
          ),
        ),
      );

      expect(find.text('ჩაბარების PIN კოდი'), findsOneWidget);
      expect(find.text('4821'), findsOneWidget);
      expect(find.text('კოპირება'), findsOneWidget);
      expect(find.text('შეკვეთის დასრულება'), findsOneWidget);
      expect(find.byIcon(LucideIcons.keyRound), findsOneWidget);
      expect(find.byIcon(LucideIcons.copy), findsOneWidget);
    });

    testWidgets('renders PIN Request card with 1-Tap Transfer button for customer', (tester) async {
      final message = OrderMessage(
        id: 'msg_pin_req_1',
        orderId: '12349',
        senderId: 'farmer_1',
        senderRole: UserRole.farmer,
        senderName: 'მწვანე მეურნეობა',
        text: 'გთხოვთ, შეამოწმოთ პროდუქცია და გადმომცეთ თქვენი 4-ნიშნა PIN კოდი შეკვეთის დასახურად.',
        type: OrderMessageType.pinRequest,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderChatCardBubble(
              message: message,
              isMe: false,
              order: sampleOrder,
              isFarmer: false,
            ),
          ),
        ),
      );

      expect(find.text('PIN კოდის მოთხოვნა'), findsOneWidget);
      expect(find.text('PIN კოდის გადაცემა (1-Tap)'), findsOneWidget);
      expect(find.byIcon(LucideIcons.shieldCheck), findsOneWidget);
    });

    testWidgets('renders Bank Details card with copy button', (tester) async {
      final message = OrderMessage(
        id: 'msg_bank_1',
        orderId: '12349',
        senderId: 'farmer_1',
        senderRole: UserRole.farmer,
        senderName: 'მწვანე მეურნეობა',
        text: 'საბანკო რეკვიზიტები:\nბანკი: თიბისი ბანკი\nმიმღები: მწვანე მეურნეობა\nIBAN: GE29TB7553608011000018',
        type: OrderMessageType.bankDetails,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderChatCardBubble(
              message: message,
              isMe: false,
              order: sampleOrder,
              isFarmer: false,
            ),
          ),
        ),
      );

      expect(find.text('საბანკო რეკვიზიტები'), findsWidgets);
      expect(find.textContaining('GE29TB7553608011000018'), findsOneWidget);
      expect(find.byIcon(LucideIcons.creditCard), findsOneWidget);
      expect(find.text('კოპირება'), findsOneWidget);
    });
  });

  group('OrderChatQuickActionsSheet Role Tests', () {
    testWidgets('Farmer sheet renders ONLY PIN request and Bank details (2 actions)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OrderChatQuickActionsSheet(
                order: sampleOrder,
                isFarmer: true,
              ),
            ),
          ),
        ),
      );

      // Farmer actions MUST be present
      expect(find.text('ფერმერის მოქმედებები'), findsOneWidget);
      expect(find.text('PIN კოდის მოთხოვნა'), findsOneWidget);
      expect(find.text('საბანკო რეკვიზიტების გაზიარება'), findsOneWidget);

      // Customer actions MUST NOT be present for farmer
      expect(find.text('მისამართის გაზიარება'), findsNothing);
      expect(find.text('GPS ლოკაციის გაზიარება'), findsNothing);
      expect(find.text('სადარბაზო / დომოფონის კოდი'), findsNothing);
      expect(find.text('ჩაბარების PIN კოდის გადაცემა'), findsNothing);
      expect(find.text('შეკვეთის შეჯამება'), findsNothing);
    });

    testWidgets('Customer sheet renders customer actions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OrderChatQuickActionsSheet(
                order: sampleOrder,
                isFarmer: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('სწრაფი მოქმედებები'), findsOneWidget);
      expect(find.text('მისამართის გაზიარება'), findsOneWidget);
      expect(find.text('GPS ლოკაციის გაზიარება'), findsOneWidget);
      expect(find.text('სადარბაზო / დომოფონის კოდი'), findsOneWidget);
      expect(find.text('ჩაბარების PIN კოდის გადაცემა'), findsOneWidget);
      expect(find.text('შეკვეთის შეჯამება'), findsOneWidget);
    });
  });
}

BuildContext createElement() {
  final element = _FakeBuildContext();
  return element;
}

class _FakeBuildContext implements BuildContext {
  @override
  bool get mounted => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
