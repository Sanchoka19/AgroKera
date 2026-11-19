import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/orders/domain/models/farmer_order_model.dart';
import 'package:agrokera/features/orders/presentation/providers/farmer_orders_provider.dart';
import 'package:agrokera/features/profile/presentation/widgets/farmer_kpi_card.dart';

void main() {
  testWidgets('FarmerKpiCard dynamically calculates revenue, order count, and rating', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();

    // 1. Log in as farmer
    container.read(authStateProvider.notifier).login(
          name: 'გიორგი მაისურაძე',
          email: 'giorgi@farm.ge',
          role: UserRole.farmer,
        );

    // Initial state with 0 orders
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: FarmerKpiCard(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('საფერმო მაჩვენებლები და KPI'), findsOneWidget);
    expect(find.text('0 ₾'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);

    // 2. Add realistic incoming orders (2 active/completed, 1 cancelled)
    final now = DateTime.now();
    final testIncoming = [
      FarmerOrder(
        id: '101',
        createdAt: now,
        status: OrderStatus.completed,
        customerName: 'საბა',
        contactPerson: 'საბა',
        contactPhone: '+995 599 00 00 00',
        items: const [
          FarmerOrderItem(
            productId: 'p1',
            name: 'თაფლი',
            quantityText: '2კგ',
            price: 50.0,
            quantity: 2.0,
          ),
        ],
        deliveryFee: 10.0,
      ), // total = 60
      FarmerOrder(
        id: '102',
        createdAt: now,
        status: OrderStatus.inProgress,
        customerName: 'ნინო',
        contactPerson: 'ნინო',
        contactPhone: '+995 599 11 11 11',
        items: const [
          FarmerOrderItem(
            productId: 'p2',
            name: 'ყველი',
            quantityText: '1კგ',
            price: 25.0,
            quantity: 1.0,
          ),
        ],
        deliveryFee: 5.0,
      ), // total = 30
      FarmerOrder(
        id: '103',
        createdAt: now,
        status: OrderStatus.cancelled,
        cancellationReason: 'გაუქმდა',
        customerName: 'დავით',
        contactPerson: 'დავით',
        contactPhone: '+995 599 22 22 22',
        items: const [
          FarmerOrderItem(
            productId: 'p3',
            name: 'ღვინო',
            quantityText: '2ბოთლი',
            price: 40.0,
            quantity: 2.0,
          ),
        ],
        deliveryFee: 7.0,
      ), // total = 47 (cancelled - should NOT be in revenue)
    ];

    container.read(farmerOrdersProvider.notifier).state =
        container.read(farmerOrdersProvider).copyWith(
              incomingOrders: testIncoming,
            );

    await tester.pumpAndSettle();

    // Total non-cancelled revenue = 60 + 30 = 90 ₾
    expect(find.text('90 ₾'), findsOneWidget);
    // Total incoming orders = 3
    expect(find.text('3'), findsOneWidget);
    // Rating remains dynamic
    expect(find.text('—'), findsOneWidget);

    container.dispose();
  });
}

