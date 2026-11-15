import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/orders/domain/models/farmer_order_model.dart';
import 'package:agrokera/features/orders/presentation/providers/farmer_orders_provider.dart';
import 'package:agrokera/features/orders/presentation/screens/client_order_detail_screen.dart';
import 'package:agrokera/features/orders/presentation/screens/client_orders_screen.dart';

void main() {
  final sampleOrder = FarmerOrder(
    id: '12345',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    status: OrderStatus.inProgress,
    customerName: 'შპს "გემრიელი რესტორანი"',
    contactPerson: 'საბა ევგენიძე',
    contactPhone: '+995599112233',
    deliveryAddress: '32 ჭავჭავაძე, Batumi',
    deliveryPin: '4829',
    deliveryFee: 15.0,
    heavyFee: 0.0,
    platformFee: 0.0,
    hasVat: true,
    paymentMethod: 'ESCROW',
    items: const [
      FarmerOrderItem(
        productId: 'prod_1',
        name: 'ქართული პომიდორი (ჩერი)',
        quantityText: '50 კგ',
        price: 225.0,
      ),
      FarmerOrderItem(
        productId: 'prod_2',
        name: 'კიტრი (მუხრანის)',
        quantityText: '30 კგ',
        price: 90.0,
      ),
    ],
  );

  group('ClientOrderDetailScreen Widget Tests', () {
    testWidgets('renders all order detail cards and sections correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider.notifier).login(role: UserRole.customer);

      container.read(farmerOrdersProvider.notifier).state = FarmerOrdersState(
        orders: [sampleOrder],
        clientOrders: [sampleOrder],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ClientOrderDetailScreen(orderId: '12345'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Tracking
      expect(find.text('შეკვეთა #12345'), findsOneWidget);
      expect(find.text('AK-12345'), findsWidgets);

      // Status Stepper
      expect(find.text('მოლოდინში'), findsOneWidget);
      expect(find.text('დადასტურდა'), findsOneWidget);
      expect(find.text('ჩაბარდა'), findsWidgets);

      // Escrow Section
      expect(find.text('AgroKera Escrow ანგარიშსწორება'), findsOneWidget);
      expect(find.text('GE29TB7553608011000018'), findsOneWidget);

      // PIN Card
      expect(find.text('ჩაბარების PIN კოდი'), findsOneWidget);
      expect(find.text('4829'), findsOneWidget);

      // Items
      expect(find.text('ქართული პომიდორი (ჩერი) (50 კგ)'), findsOneWidget);
      expect(find.text('კიტრი (მუხრანის) (30 კგ)'), findsOneWidget);

      // Financial breakdown
      expect(find.text('პროდუქტების ჯამი'), findsOneWidget);
      expect(find.text('დღგ (18%)'), findsOneWidget);
      expect(find.text('სულ გადასახდელი'), findsOneWidget);

      // Delivery
      expect(find.text('32 ჭავჭავაძე, Batumi'), findsOneWidget);

      // Handover button
      expect(find.text('ჩავიბარე შეკვეთა'), findsOneWidget);
    });

    testWidgets('ClientOrdersScreen navigates to ClientOrderDetailScreen on details tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider.notifier).login(role: UserRole.customer);

      container.read(farmerOrdersProvider.notifier).state = FarmerOrdersState(
        orders: [sampleOrder],
        clientOrders: [sampleOrder],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ClientOrdersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('დეტალები'), findsOneWidget);
      await tester.tap(find.text('დეტალები'));
      await tester.pumpAndSettle();

      // We should now be on ClientOrderDetailScreen
      expect(find.text('AgroKera Escrow ანგარიშსწორება'), findsOneWidget);
      expect(find.text('ჩაბარების PIN კოდი'), findsOneWidget);
      expect(find.text('ჩავიბარე შეკვეთა'), findsOneWidget);
    });
  });
}
