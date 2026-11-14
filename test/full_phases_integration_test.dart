import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/cart_checkout/data/models/cart_item_model.dart';
import 'package:agrokera/features/farm_inventory/presentation/screens/farmer_inventory_screen.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:agrokera/features/orders/presentation/providers/farmer_orders_provider.dart';
import 'package:agrokera/features/orders/presentation/screens/client_orders_screen.dart';
import 'package:agrokera/features/verification/presentation/screens/kyc_verification_screen.dart';

void main() {
  group('AgroKera Phases 1-4 Integration Tests', () {
    test('MarketplaceNotifier supports adding, updating, and deleting products', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialCount = container.read(marketplaceProvider).products.length;
      final added = await container.read(marketplaceProvider.notifier).addProduct(
            title: 'ახალი სატესტო კიტრი',
            category: 'ბოსტნეული',
            price: 4.5,
            stockQuantity: 40,
          );

      expect(
        container.read(marketplaceProvider).products.length,
        initialCount + 1,
      );

      await container.read(marketplaceProvider.notifier).updateProduct(
            added.id,
            stockQuantity: 10,
          );

      final updated = container
          .read(marketplaceProvider)
          .products
          .firstWhere((p) => p.id == added.id);
      expect(updated.stockQuantity, 10);
      expect(updated.stockStatus, 'იწურება');

      await container.read(marketplaceProvider.notifier).deleteProduct(added.id);
      expect(
        container.read(marketplaceProvider).products.length,
        initialCount,
      );
    });

    test('FarmerOrdersNotifier createOrderFromCart creates a pending order', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialOrders = container.read(farmerOrdersProvider).orders.length;
      final created = await container
          .read(farmerOrdersProvider.notifier)
          .createOrderFromCart(
            cartItems: const [
              CartItemModel(
                id: 'prod_1',
                title: 'მწვანილოვანი კომბოსტო',
                packageText: '1 კგ',
                farmerName: 'გიორგის ფერმა',
                pricePerUnit: 15.0,
                quantity: 2,
                imageUrl: 'https://example.com/img.jpg',
              ),
            ],
            deliveryAddress: 'თბილისი, ჭავჭავაძის 10',
            deliveryTimeWindow: 'დღეს, 14:00-16:00',
          );

      expect(
        container.read(farmerOrdersProvider).orders.length,
        initialOrders + 1,
      );
      expect(created.totalAmount, 30.0);
    });

    testWidgets('KycVerificationScreen renders status and allows status simulation', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: KycVerificationScreen(),
          ),
        ),
      );

      expect(find.text('ფერმერის ვერიფიკაცია (KYC)'), findsOneWidget);
      expect(find.text('თქვენი ფერმა ვერიფიცირებულია'), findsOneWidget);

      await tester.ensureVisible(find.text('მოწმდება'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('მოწმდება'));
      await tester.pumpAndSettle();

      expect(find.text('დოკუმენტები მოწმდება'), findsOneWidget);
    });

    testWidgets('FarmerInventoryScreen renders products and filter chips', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FarmerInventoryScreen(),
          ),
        ),
      );

      expect(find.text('მარაგის მართვა'), findsOneWidget);
      expect(find.text('ახალი პროდუქტი'), findsOneWidget);
      expect(find.text('მწვანილოვანი კომბოსტო'), findsOneWidget);
    });

    testWidgets('ClientOrdersScreen renders orders and tracking stepper', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider.notifier).login(role: UserRole.customer);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ClientOrdersScreen(),
          ),
        ),
      );

      expect(find.text('ჩემი შეკვეთები'), findsOneWidget);
      expect(find.text('შეკვეთა #12345'), findsOneWidget);
      expect(find.text('მიღებულია'), findsWidgets);
    });
  });
}
