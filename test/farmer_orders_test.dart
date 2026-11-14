import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
