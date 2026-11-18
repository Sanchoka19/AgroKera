import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/cart_checkout/data/models/cart_item_model.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:agrokera/features/orders/domain/models/farmer_order_model.dart';
import 'package:agrokera/features/orders/presentation/providers/farmer_orders_provider.dart';
import 'package:agrokera/features/orders/presentation/screens/incoming_orders_screen.dart';
import 'package:agrokera/features/orders/presentation/screens/farmer_order_detail_screen.dart';

void main() {
  group('Farmer Orders Provider Unit Tests', () {
    test('initial state contains sample orders across all statuses', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(farmerOrdersProvider);
      expect(state.orders.length, greaterThanOrEqualTo(5));
      expect(state.selectedFilter, isNull);

      // Check counts
      expect(state.countForStatus(OrderStatus.pending), greaterThanOrEqualTo(1));
      expect(state.countForStatus(OrderStatus.inProgress), greaterThanOrEqualTo(2));
      expect(state.countForStatus(OrderStatus.completed), greaterThanOrEqualTo(1));
      expect(state.countForStatus(OrderStatus.cancelled), greaterThanOrEqualTo(1));
    });

    test('filtering by status correctly filters the list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(farmerOrdersProvider.notifier);

      notifier.setFilter(OrderStatus.completed);
      var state = container.read(farmerOrdersProvider);
      expect(state.selectedFilter, equals(OrderStatus.completed));
      expect(state.filteredOrders.every((o) => o.status == OrderStatus.completed), isTrue);

      notifier.setFilter(null);
      state = container.read(farmerOrdersProvider);
      expect(state.selectedFilter, isNull);
      expect(state.filteredOrders.length, equals(state.orders.length));
    });

    test('accepting, completing and cancelling orders updates status and fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(farmerOrdersProvider.notifier);

      // Accept pending order #12349
      notifier.acceptOrder('12349');
      var state = container.read(farmerOrdersProvider);
      var order = state.orders.firstWhere((o) => o.id == '12349');
      expect(order.status, equals(OrderStatus.inProgress));
      expect(order.cancellationDeadline, isNotNull);

      // Complete order #12346
      notifier.completeOrder('12346');
      state = container.read(farmerOrdersProvider);
      order = state.orders.firstWhere((o) => o.id == '12346');
      expect(order.status, equals(OrderStatus.completed));

      // Cancel order #12347
      notifier.cancelOrder('12347', reason: 'მყიდველის თხოვნით');
      state = container.read(farmerOrdersProvider);
      order = state.orders.firstWhere((o) => o.id == '12347');
      expect(order.status, equals(OrderStatus.cancelled));
      expect(order.cancellationReason, equals('მყიდველის თხოვნით'));
    });

    test('acceptOrder preserves inProgress status during backend refresh until server confirms', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(farmerOrdersProvider.notifier);
      final initialOrder = container
          .read(farmerOrdersProvider)
          .orders
          .firstWhere((o) => o.status == OrderStatus.pending);

      // Accept order optimistically
      await notifier.acceptOrder(initialOrder.id);
      expect(
        container
            .read(farmerOrdersProvider)
            .orders
            .firstWhere((o) => o.id == initialOrder.id)
            .status,
        equals(OrderStatus.inProgress),
      );

      // Trigger refreshFromBackend while sync is in-flight/reconciling
      await notifier.refreshFromBackend();
      expect(
        container
            .read(farmerOrdersProvider)
            .orders
            .firstWhere((o) => o.id == initialOrder.id)
            .status,
        equals(OrderStatus.inProgress),
      );
    });

    test('cancelOrder restores deducted stock back to marketplaceProvider inventory', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialProduct = container
          .read(marketplaceProvider)
          .products
          .firstWhere((p) => p.id == 'prod_1');
      final initialStock = initialProduct.stockQuantity;

      // Create an order containing 5 units of prod_1
      const item = CartItemModel(
        id: 'prod_1',
        title: 'მწვანილოვანი კომბოსტო',
        packageText: '1კგ',
        farmerName: 'გიორგის ფერმა',
        farmerId: 'farmer_2',
        pricePerUnit: 15.0,
        imageUrl: '',
        quantity: 5,
        weightKg: 1.0,
      );

      final ordersNotifier = container.read(farmerOrdersProvider.notifier);
      final createdOrder = await ordersNotifier.createOrderFromCart(
        cartItems: const [item],
        deliveryAddress: 'თბილისი',
        deliveryTimeWindow: 'შაბათი, 10:00-13:00',
      );

      // Stock was deducted by 5
      final deductedProduct = container
          .read(marketplaceProvider)
          .products
          .firstWhere((p) => p.id == 'prod_1');
      expect(deductedProduct.stockQuantity, equals(initialStock - 5));

      // Now cancel the order
      ordersNotifier.cancelOrder(createdOrder.id, reason: 'მყიდველის უარი');

      // Stock must be restored back to initialStock
      final restoredProduct = container
          .read(marketplaceProvider)
          .products
          .firstWhere((p) => p.id == 'prod_1');
      expect(restoredProduct.stockQuantity, equals(initialStock));
    });

    test('createOrderFromCart dynamically sets hasVat based on farmer VAT status', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ordersNotifier = container.read(farmerOrdersProvider.notifier);

      // farmer_2 in MockData has isVatPayer = false
      const itemFarmerNoVat = CartItemModel(
        id: 'prod_1',
        title: 'მწვანილოვანი კომბოსტო',
        packageText: '1კგ',
        farmerName: 'გიორგის ფერმა',
        farmerId: 'farmer_2',
        pricePerUnit: 100.0,
        imageUrl: '',
        quantity: 1,
      );

      final orderNoVat = await ordersNotifier.createOrderFromCart(
        cartItems: const [itemFarmerNoVat],
        deliveryAddress: 'თბილისი',
        deliveryTimeWindow: 'შაბათი, 10:00-13:00',
      );
      expect(orderNoVat.hasVat, isFalse);
      expect(orderNoVat.vatAmount, equals(0.0));

      // farmer_1 in MockData has isVatPayer = true
      const itemFarmerWithVat = CartItemModel(
        id: 'prod_f1',
        title: 'ორგანული ყველი',
        packageText: '1კგ',
        farmerName: 'შატო მუხრანი',
        farmerId: 'farmer_1',
        pricePerUnit: 100.0,
        imageUrl: '',
        quantity: 1,
      );

      final orderWithVat = await ordersNotifier.createOrderFromCart(
        cartItems: const [itemFarmerWithVat],
        deliveryAddress: 'თბილისი',
        deliveryTimeWindow: 'შაბათი, 10:00-13:00',
      );
      expect(orderWithVat.hasVat, isTrue);
      expect(orderWithVat.vatAmount, equals(18.0));
    });

    test('overdue pending orders auto-expire and cancel instead of auto-confirming', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ordersNotifier = container.read(farmerOrdersProvider.notifier);
      final initialProduct = container
          .read(marketplaceProvider)
          .products
          .firstWhere((p) => p.id == 'prod_1');
      final initialStock = initialProduct.stockQuantity;

      const item = CartItemModel(
        id: 'prod_1',
        title: 'მწვანილოვანი კომბოსტო',
        packageText: '1კგ',
        farmerName: 'გიორგის ფერმა',
        farmerId: 'farmer_2',
        pricePerUnit: 15.0,
        imageUrl: '',
        quantity: 3,
      );

      final created = await ordersNotifier.createOrderFromCart(
        cartItems: const [item],
        deliveryAddress: 'თბილისი',
        deliveryTimeWindow: 'შაბათი, 10:00-13:00',
      );

      // Stock was deducted by 3
      expect(
        container.read(marketplaceProvider).products.firstWhere((p) => p.id == 'prod_1').stockQuantity,
        equals(initialStock - 3),
      );

      // Mutate cancellation deadline to past
      final pastTime = DateTime.now().subtract(const Duration(minutes: 5));
      final currentState = container.read(farmerOrdersProvider);
      container.read(farmerOrdersProvider.notifier).state = currentState.copyWith(
        orders: currentState.orders.map((o) {
          if (o.id == created.id) {
            return o.copyWith(cancellationDeadline: pastTime);
          }
          return o;
        }).toList(),
      );

      // Trigger expiration check
      ordersNotifier.checkPendingOrderExpirations();

      final expiredOrder = container
          .read(farmerOrdersProvider)
          .orders
          .firstWhere((o) => o.id == created.id);

      // It must be cancelled, NOT inProgress!
      expect(expiredOrder.status, equals(OrderStatus.cancelled));
      expect(
        expiredOrder.cancellationReason,
        contains('ვადა ამოიწურა'),
      );

      // Stock must be restored
      expect(
        container.read(marketplaceProvider).products.firstWhere((p) => p.id == 'prod_1').stockQuantity,
        equals(initialStock),
      );
    });

    test('FarmerOrder.calculatePendingOrderDeadline respects working hours, quiet hours and delivery window', () {
      // 1. Same day within working hours (e.g. 14:00 Georgia time / 10:00 UTC)
      final middayUtc = DateTime.utc(2026, 6, 15, 10, 0); // 14:00 Georgia time
      final dl1 = FarmerOrder.calculatePendingOrderDeadline(
        now: middayUtc,
        deliveryTimeWindow: 'დღეს, 18:00 - 20:00',
      );
      // Expected: +45 min -> 10:45 UTC
      expect(dl1.toUtc(), equals(DateTime.utc(2026, 6, 15, 10, 45)));

      // 2. Next-day delivery ("ხვალ") within working hours
      final dl2 = FarmerOrder.calculatePendingOrderDeadline(
        now: middayUtc,
        deliveryTimeWindow: 'ხვალ, 12:00',
      );
      // Expected: +120 min (2 h) -> 12:00 UTC (16:00 Georgia)
      expect(dl2.toUtc(), equals(DateTime.utc(2026, 6, 15, 12, 0)));

      // 3. Late night quiet hours (23:00 Georgia / 19:00 UTC)
      final nightUtc = DateTime.utc(2026, 6, 15, 19, 0); // 23:00 Georgia
      final dl3 = FarmerOrder.calculatePendingOrderDeadline(
        now: nightUtc,
        deliveryTimeWindow: 'დღეს',
      );
      // Starts tomorrow at 08:00 Georgia (04:00 UTC) + 45 min = 08:45 Georgia (04:45 UTC)
      expect(dl3.toUtc(), equals(DateTime.utc(2026, 6, 16, 4, 45)));

      // 4. Early morning quiet hours (05:00 Georgia / 01:00 UTC)
      final earlyUtc = DateTime.utc(2026, 6, 15, 1, 0); // 05:00 Georgia
      final dl4 = FarmerOrder.calculatePendingOrderDeadline(
        now: earlyUtc,
        deliveryTimeWindow: 'დღეს',
      );
      // Starts today at 08:00 Georgia (04:00 UTC) + 45 min = 08:45 Georgia (04:45 UTC)
      expect(dl4.toUtc(), equals(DateTime.utc(2026, 6, 15, 4, 45)));

      // 5. Overflow at end of working day (20:30 Georgia / 16:30 UTC) with 45 min
      // 30 min left today until 21:00 Georgia, remaining 15 min overflow to tomorrow 08:15 Georgia (04:15 UTC)
      final eveningUtc = DateTime.utc(2026, 6, 15, 16, 30);
      final dl5 = FarmerOrder.calculatePendingOrderDeadline(
        now: eveningUtc,
        deliveryTimeWindow: 'დღეს',
      );
      expect(dl5.toUtc(), equals(DateTime.utc(2026, 6, 16, 4, 15)));
    });

    test('acceptOrder restricts direct cancellation window to 10 minutes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(farmerOrdersProvider.notifier);
      final beforeAccept = DateTime.now();
      notifier.acceptOrder('12349');

      final order = container
          .read(farmerOrdersProvider)
          .orders
          .firstWhere((o) => o.id == '12349');

      expect(order.status, equals(OrderStatus.inProgress));
      expect(order.cancellationDeadline, isNotNull);

      final diffSec = order.cancellationDeadline!.difference(beforeAccept).inSeconds;
      // Should be ~600 seconds (10 minutes)
      expect(diffSec, greaterThanOrEqualTo(590));
      expect(diffSec, lessThanOrEqualTo(615));
      expect(order.canDirectlyCancel, isTrue);

      // Once 10 minutes pass, direct cancellation is blocked
      final expiredOrder = order.copyWith(
        cancellationDeadline: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(expiredOrder.canDirectlyCancel, isFalse);
    });

    test('formattedRemainingCancellationTime formats hours and minutes cleanly', () {
      final now = DateTime.now();
      final orderWithHours = FarmerOrder(
        id: '990',
        createdAt: now,
        status: OrderStatus.pending,
        customerName: 'ტესტერი',
        contactPerson: 'ტესტერი',
        contactPhone: '+995599000000',
        items: const [],
        cancellationDeadline: now.add(const Duration(hours: 2, minutes: 15)),
      );
      expect(orderWithHours.formattedRemainingCancellationTime, contains('2 სთ'));

      final orderWithMinutes = FarmerOrder(
        id: '991',
        createdAt: now,
        status: OrderStatus.pending,
        customerName: 'ტესტერი',
        contactPerson: 'ტესტერი',
        contactPhone: '+995599000000',
        items: const [],
        cancellationDeadline: now.add(const Duration(minutes: 25)),
      );
      expect(orderWithMinutes.formattedRemainingCancellationTime, equals('~25 წთ'));
    });

    test('FarmerOrder payment method helpers correctly identify BankTransfer vs Cash', () {
      final now = DateTime.now();
      final escrowOrder = FarmerOrder(
        id: '991',
        createdAt: now,
        status: OrderStatus.inProgress,
        customerName: 'ტესტერი',
        contactPerson: 'ტესტერი',
        contactPhone: '+995599000000',
        items: const [],
        paymentMethod: 'BANKTRANSFER',
      );
      expect(escrowOrder.isBankTransfer, isTrue);
      expect(escrowOrder.isCash, isFalse);

      final cashOrder = FarmerOrder(
        id: '992',
        createdAt: now,
        status: OrderStatus.pending,
        customerName: 'ტესტერი',
        contactPerson: 'ტესტერი',
        contactPhone: '+995599000000',
        items: const [],
        paymentMethod: 'CASH',
      );
      expect(cashOrder.isBankTransfer, isFalse);
      expect(cashOrder.isCash, isTrue);
    });

    test('reportBankTransferSent updates hasClientReportedPayment on the order', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(farmerOrdersProvider.notifier);
      final initialOrder = container.read(farmerOrdersProvider).orders.first;
      expect(initialOrder.hasClientReportedPayment, isFalse);

      notifier.reportBankTransferSent(initialOrder.id);
      final updatedOrder = container
          .read(farmerOrdersProvider)
          .orders
          .firstWhere((o) => o.id == initialOrder.id);
      expect(updatedOrder.hasClientReportedPayment, isTrue);

      notifier.confirmEscrowPayment(initialOrder.id);
      final confirmedOrder = container
          .read(farmerOrdersProvider)
          .orders
          .firstWhere((o) => o.id == initialOrder.id);
      expect(confirmedOrder.isPaymentConfirmed, isTrue);
    });

    test('Farmer role strictly isolates incoming orders vs client purchases', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Login as farmer (farmer_1, მწვანე ველი)
      container.read(authStateProvider.notifier).login(
            email: 'lana@agrokera.ge',
            role: UserRole.farmer,
          );
      final farmerAuth = container.read(authStateProvider);
      expect(farmerAuth.role, equals(UserRole.farmer));
      expect(farmerAuth.farmerId, equals('farmer_1'));

      final state = container.read(farmerOrdersProvider);
      // Incoming orders must contain the farm's incoming orders from clients
      expect(state.incomingOrders.length, greaterThanOrEqualTo(5));
      // Client orders ("ჩემი შეკვეთები") must NOT contain incoming customer orders
      expect(state.clientOrders, isEmpty);

      // Now the farmer buys a product from another farmer (farmer_2)
      final ordersNotifier = container.read(farmerOrdersProvider.notifier);
      const purchaseItem = CartItemModel(
        id: 'prod_1',
        title: 'მწვანილოვანი კომბოსტო',
        packageText: '1კგ',
        farmerName: 'გიორგის ფერმა',
        farmerId: 'farmer_2',
        pricePerUnit: 15.0,
        imageUrl: '',
        quantity: 2,
      );

      final purchaseOrder = await ordersNotifier.createOrderFromCart(
        cartItems: const [purchaseItem],
        deliveryAddress: 'ქუთაისი',
        deliveryTimeWindow: 'ხვალ, 11:00-14:00',
      );

      final updatedState = container.read(farmerOrdersProvider);
      // The purchase must be in clientOrders ("ჩემი შეკვეთები")
      expect(updatedState.clientOrders.length, equals(1));
      expect(updatedState.clientOrders.first.id, equals(purchaseOrder.id));

      // The purchase must NOT be in incomingOrders ("შემოსული შეკვეთები")
      expect(
        updatedState.incomingOrders.any((o) => o.id == purchaseOrder.id),
        isFalse,
      );
    });
  });

  group('IncomingOrdersScreen Widget Tests', () {
    testWidgets('renders header, all 5 filter chips and order cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: IncomingOrdersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title
      expect(find.text('შემოსული შეკვეთები'), findsOneWidget);

      // Check filter chips
      expect(find.text('ყველა'), findsOneWidget);
      expect(find.text('მომლოდინე'), findsWidgets);
      expect(find.text('მიმდინარე'), findsWidgets);
      expect(find.text('დასრულებული'), findsWidgets);
      expect(find.text('გაუქმებული'), findsWidgets);

      // Check that cards show details button and total prices
      expect(find.text('დეტალები'), findsWidgets);
      expect(find.textContaining('#12345'), findsOneWidget);

      // Tap filter "დასრულებული" by key after ensuring visible
      await tester.ensureVisible(find.byKey(const ValueKey('chip_completed')));
      await tester.tap(find.byKey(const ValueKey('chip_completed')));
      await tester.pumpAndSettle();

      // Only completed order #12345 should remain
      expect(find.textContaining('#12345'), findsOneWidget);
      expect(find.textContaining('#12348'), findsNothing);

      // Tap filter "მომლოდინე" by key after ensuring visible
      await tester.ensureVisible(find.byKey(const ValueKey('chip_pending')));
      await tester.tap(find.byKey(const ValueKey('chip_pending')));
      await tester.pumpAndSettle();

      // Pending order #12349 should have both "დათანხმება" and "გაუქმება" buttons
      expect(find.text('დათანხმება'), findsOneWidget);
      expect(find.text('გაუქმება'), findsWidgets);
    });
  });

  group('FarmerOrderDetailScreen Widget Tests', () {
    testWidgets('renders completed order with overview, products and delivery details', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FarmerOrderDetailScreen(orderId: '12345'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title
      expect(find.text('შეკვეთა #12345'), findsOneWidget);

      // Sections
      expect(find.text('შეკვეთის მიმოხილვა'), findsOneWidget);
      expect(find.text('მომხმარებლის ინფორმაცია'), findsOneWidget);
      expect(find.text('პროდუქტის დეტალები'), findsOneWidget);
      expect(find.text('მიწოდების ინფორმაცია'), findsOneWidget);

      // Customer info
      expect(find.text('შპს "გემრიელი რესტორანი"'), findsOneWidget);
      expect(find.text('საბა ევგენიძე'), findsOneWidget);

      // VAT and Total
      expect(find.text('დღგ (18%)'), findsOneWidget);
      expect(find.text('სრული ჯამი'), findsOneWidget);

      // Delivery Address
      expect(find.text('32 ჭავჭავაძე, ბათუმი'), findsOneWidget);
    });

    testWidgets('renders cancelled order with red cancellation banner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FarmerOrderDetailScreen(orderId: '12348'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('შეკვეთა #12348'), findsOneWidget);
      expect(find.textContaining('შეკვეთა გაუქმდა მარაგის არ არსებობის გამო'), findsOneWidget);
    });
  });
}
