import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/features/cart_checkout/data/models/cart_item_model.dart';
import 'package:agrokera/features/cart_checkout/presentation/providers/cart_provider.dart';
import 'package:agrokera/features/cart_checkout/presentation/screens/checkout_screen.dart';
import 'package:agrokera/features/orders/presentation/providers/farmer_orders_provider.dart';
import 'package:agrokera/features/orders/presentation/screens/client_orders_screen.dart';
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

    testWidgets('OrderChatScreen is active and allows messaging for pending orders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final pendingOrder = sampleOrder.copyWith(status: OrderStatus.pending);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: OrderChatScreen(order: pendingOrder),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // TextField should be present (chat not closed)
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('როდის შეძლებთ გამოგზავნას?'), findsOneWidget);

      await tester.tap(find.text('როდის შეძლებთ გამოგზავნას?'));
      await tester.pumpAndSettle();

      expect(find.text('როდის შეძლებთ გამოგზავნას?'), findsWidgets);
    });

    testWidgets('ClientOrdersScreen displays chat pill and chat button for pending order', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider.notifier).login(role: UserRole.customer);

      final pendingOrder = sampleOrder.copyWith(
        id: '99991',
        status: OrderStatus.pending,
      );

      container.read(farmerOrdersProvider.notifier).state = FarmerOrdersState(
        orders: [pendingOrder],
        clientOrders: [pendingOrder],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ClientOrdersScreen(),
          ),
        ),
      );
      await tester.pump();

      // Header chat pill
      expect(find.text('ჩათი'), findsWidgets);
      // Action button
      expect(find.text('ჩათი ფერმერთან'), findsWidgets);
    });
  });

  group('Logistics, Delivery Fee & 250kg Limit Tests', () {
    test('FarmerOrder includes deliveryFee, heavyFee and platformFee in totalAmount', () {
      final orderWithFees = FarmerOrder(
        id: '12350',
        createdAt: DateTime.now(),
        status: OrderStatus.inProgress,
        customerName: 'დავითი',
        contactPerson: 'დავითი',
        contactPhone: '+995599000000',
        deliveryFee: 15.0,
        heavyFee: 45.0,
        platformFee: 10.0,
        isPickup: false,
        items: const [
          FarmerOrderItem(
            name: 'კარტოფილი',
            quantityText: '100კგ',
            price: 200.0,
          ),
        ],
      );

      // subtotal 200 + delivery 15 + heavy 45 + platform 10 = 270
      expect(orderWithFees.subtotal, equals(200.0));
      expect(orderWithFees.totalDeliveryFee, equals(60.0));
      expect(orderWithFees.totalAmount, equals(270.0));

      // When isPickup is true, delivery fees become 0
      final pickupOrder = orderWithFees.copyWith(isPickup: true);
      expect(pickupOrder.totalDeliveryFee, equals(0.0));
      expect(pickupOrder.totalAmount, equals(210.0));
    });

    testWidgets('CheckoutScreen displays 250kg limit warning and forces pickup when weight > 250kg', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Add 300kg of potatoes
      const heavyItem = CartItemModel(
        id: 'prod_potato_300',
        title: 'ახალციხის კარტოფილი',
        packageText: '100კგ',
        farmerName: 'გიორგის ფერმა',
        farmerId: 'farmer_2',
        pricePerUnit: 150.0,
        imageUrl: '',
        quantity: 3,
        weightKg: 100.0, // 3 * 100 = 300 kg > 250 kg limit
      );

      container.read(cartProvider.notifier).clearCart();
      container.read(cartProvider.notifier).addItem(heavyItem);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Warning banner must be displayed
      expect(
        find.textContaining('წონა (300.0 კგ) აჭარბებს საკურიერო მიტანის ლიმიტს (250 კგ)'),
        findsOneWidget,
      );

      // Subtitle under delivery indicates impossible
      expect(find.text('>250 კგ (შეუძლებელია)'), findsOneWidget);

      // Price breakdown shows 0 ₾ (თვითგატანა)
      expect(find.text('0 ₾ (თვითგატანა)'), findsOneWidget);
    });
  });
}

