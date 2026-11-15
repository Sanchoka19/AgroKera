import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/core/auth/auth_state_provider.dart';
import 'package:agrokera/features/cart_checkout/data/models/cart_item_model.dart';
import 'package:agrokera/features/cart_checkout/presentation/providers/cart_provider.dart';
import 'package:agrokera/features/cart_checkout/presentation/screens/cart_screen.dart';
import 'package:agrokera/features/cart_checkout/presentation/screens/checkout_screen.dart';
import 'package:agrokera/features/cart_checkout/presentation/widgets/fee_breakdown_sheet.dart';
import 'package:agrokera/features/marketplace/data/models/farmer_model.dart';
import 'package:agrokera/features/marketplace/presentation/screens/favorites_screen.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/product_details/product_delivery_info_card.dart';

void main() {
  group('Cart Provider Unit Tests', () {
    test('initial state is empty', () {
      final container = ProviderContainer();
      final items = container.read(cartProvider);
      expect(items.isEmpty, isTrue);
      expect(items.subtotal, 0.0);
    });

    test('can clear cart, increment, decrement and add items', () {
      final container = ProviderContainer();
      final notifier = container.read(cartProvider.notifier);

      notifier.clearCart();
      expect(container.read(cartProvider).isEmpty, isTrue);

      notifier.addItem(
        const CartItemModel(
          id: 'test_1',
          title: 'ტესტ პომიდორი',
          packageText: '1კგ',
          farmerName: 'მწვანე ველი',
          pricePerUnit: 5.0,
          quantity: 2,
          imageUrl: '',
          weightKg: 1.0,
        ),
      );

      expect(container.read(cartProvider).length, 1);
      expect(container.read(cartProvider).first.quantity, 2);
      expect(container.read(cartProvider).subtotal, 10.0);

      notifier.increment('test_1');
      expect(container.read(cartProvider).first.quantity, 3);
      expect(container.read(cartProvider).subtotal, 15.0);

      notifier.decrement('test_1');
      expect(container.read(cartProvider).first.quantity, 2);
    });

    test('bulk discount calculation and min order enforcement in CartItemModel and CartNotifier', () {
      final container = ProviderContainer();
      final notifier = container.read(cartProvider.notifier);
      notifier.clearCart();

      const item = CartItemModel(
        id: 'bulk_1',
        title: 'მარწყვი',
        packageText: 'კგ',
        farmerName: 'სანჩოს ფერმა',
        pricePerUnit: 10.0,
        quantity: 5,
        imageUrl: '',
        weightKg: 1.0,
        minOrderQuantity: 5.0,
        bulkDiscountMinQty: 10.0,
        bulkDiscountPercent: 20,
      );

      notifier.addItem(item);
      final currentItem = container.read(cartProvider).first;
      expect(currentItem.quantity, 5);
      expect(currentItem.isBulkDiscountApplied, isFalse);
      expect(currentItem.effectiveUnitPrice, 10.0);
      expect(currentItem.totalPrice, 50.0);

      // Decrementing should NOT go below minOrderQuantity (5)
      notifier.decrement('bulk_1');
      expect(container.read(cartProvider).first.quantity, 5);

      // Incrementing to 10 should trigger bulk discount (20% off => 8 GEL/kg)
      for (int i = 0; i < 5; i++) {
        notifier.increment('bulk_1');
      }
      final bulkActiveItem = container.read(cartProvider).first;
      expect(bulkActiveItem.quantity, 10);
      expect(bulkActiveItem.isBulkDiscountApplied, isTrue);
      expect(bulkActiveItem.effectiveUnitPrice, 8.0);
      expect(bulkActiveItem.totalPrice, 80.0);
    });
  });

  group('Cart & Favorites Auth Guard Tests', () {
    testWidgets('shows auth required screen for unauthenticated user on CartScreen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ავტორიზაცია აუცილებელია'), findsOneWidget);
      expect(find.text('შესვლა / რეგისტრაცია'), findsOneWidget);
    });

    testWidgets('shows auth required screen for unauthenticated user on FavoritesScreen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ავტორიზაცია აუცილებელია'), findsOneWidget);
      expect(find.text('შესვლა / რეგისტრაცია'), findsOneWidget);
    });

    testWidgets('renders populated cart with stepper and totals for authenticated user', (tester) async {
      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(role: UserRole.customer);
      container.read(cartProvider.notifier).addItem(
        const CartItemModel(
          id: 'prod_1',
          title: 'მწვანილოვანი კომბოსტო',
          packageText: '10კგ პატარა ყუთი',
          farmerName: 'გიორგის ფერმა',
          pricePerUnit: 15.00,
          unit: 'კგ',
          imageUrl: '',
          quantity: 5,
          weightKg: 2.0,
          minOrderQuantity: 1.0,
          stockQuantity: 50.0,
        ),
      );
      container.read(cartProvider.notifier).addItem(
        const CartItemModel(
          id: 'prod_2',
          title: 'ბულგარული წიწაკა',
          packageText: 'სუფთა მოსავალი',
          farmerName: 'გიორგის ფერმა',
          pricePerUnit: 15.00,
          unit: 'კგ',
          imageUrl: '',
          quantity: 10,
          weightKg: 1.8,
          minOrderQuantity: 1.0,
          stockQuantity: 50.0,
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('კალათი'), findsOneWidget);
      expect(find.text('მწვანილოვანი კომბოსტო'), findsOneWidget);
      expect(find.text('ბულგარული წიწაკა'), findsOneWidget);
    });

    testWidgets('renders empty cart state when cart has no items for authenticated user', (tester) async {
      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(role: UserRole.customer);
      container.read(cartProvider.notifier).clearCart();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ჩემი კალათი'), findsOneWidget);
      expect(find.text('შენი კალათი ცარიელია!'), findsOneWidget);
      expect(find.text('კალათის შევსება'), findsOneWidget);
    });

    testWidgets('renders checkout screen with order summary', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('გადახდა'), findsOneWidget);
      expect(find.text('მიტანის მისამართი'), findsOneWidget);
      expect(find.text('შეკვეთის შეჯამება'), findsOneWidget);
      expect(find.text('მოსაკრებელი'), findsOneWidget);
    });

    testWidgets('renders fee breakdown sheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeeBreakdownSheet(
              currentWeight: 26.0,
              currentSubtotal: 50.0,
              type: FeeBreakdownType.heavyWeight,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('რა განსაზღვრავს ჩვენს'), findsOneWidget);
      expect(find.text('მიტანის საფასური კარამდე'), findsOneWidget);
      expect(find.text('გასაგებია'), findsOneWidget);
    });

    testWidgets('ProductDeliveryInfoCard displays dynamic regional delivery and days on modal tap', (tester) async {
      const farmer = FarmerModel(
        id: 'f1',
        farmName: 'ლანას მეურნეობა',
        farmerName: 'ლანა',
        location: 'გურჯაანი, კახეთი',
        rating: 4.9,
        reviewCount: 10,
        avatarUrl: '',
        coverUrl: '',
        about: '',
        isDeliveryEnabled: true,
        deliveryDays: ['შაბათი', 'კვირა'],
        regionalDeliveryFees: {'თბილისი': 7.0, 'რუსთავი': 9.0},
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProductDeliveryInfoCard(farmer: farmer),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('მიწოდება და თვითგატანა'), findsOneWidget);
      expect(find.text('დეტალები'), findsOneWidget);

      // Tap card to open bottom sheet modal
      await tester.tap(find.text('მიწოდება და თვითგატანა'));
      await tester.pumpAndSettle();

      expect(find.text('მიწოდების პირობები'), findsOneWidget);
      expect(find.text('თბილისი • 7 ₾'), findsOneWidget);
      expect(find.text('რუსთავი • 9 ₾'), findsOneWidget);
      expect(find.textContaining('შაბათი, კვირა'), findsOneWidget);
      expect(find.textContaining('გურჯაანი, კახეთი'), findsOneWidget);
      expect(find.text('გასაგებია'), findsOneWidget);

      await tester.tap(find.text('გასაგებია'));
      await tester.pumpAndSettle();
    });

    testWidgets('ProductDeliveryInfoCard displays pickup-only modal when delivery disabled', (tester) async {
      const farmer = FarmerModel(
        id: 'f2',
        farmName: 'დავითის ბაღები',
        farmerName: 'დავითი',
        location: 'ყვარელი',
        rating: 4.8,
        reviewCount: 5,
        avatarUrl: '',
        coverUrl: '',
        about: '',
        isDeliveryEnabled: false,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProductDeliveryInfoCard(farmer: farmer),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('მიღების მეთოდი'), findsOneWidget);

      // Tap card to open bottom sheet modal
      await tester.tap(find.text('მიღების მეთოდი'));
      await tester.pumpAndSettle();

      expect(find.text('მიწოდების პირობები'), findsOneWidget);
      expect(find.textContaining('ფერმერს საკურიერო მიტანა არ აქვს'), findsOneWidget);
      expect(find.textContaining('ყვარელი'), findsWidgets);
      expect(find.textContaining('0 ₾ • უფასო'), findsWidgets);

      await tester.tap(find.text('გასაგებია'));
      await tester.pumpAndSettle();
    });

    testWidgets('CheckoutScreen updates pricing dynamically on regional address switch', (tester) async {
      final container = ProviderContainer();
      container.read(cartProvider.notifier).addItem(
        const CartItemModel(
          id: 'prod_1',
          title: 'მწვანილოვანი კომბოსტო',
          packageText: '10კგ',
          farmerName: 'გიორგის ფერმა',
          pricePerUnit: 15.00,
          unit: 'კგ',
          imageUrl: '',
          quantity: 2,
          weightKg: 2.0,
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default is Tbilisi (10 ₾ delivery fee for farmer_2)
      expect(find.textContaining('მიტანა ხელმისაწვდომია: თბილისი (10 ₾)'), findsOneWidget);
      expect(find.text('10 ₾'), findsWidgets);

      // Open redesigned Address Bottom Sheet
      await tester.tap(find.text('შეცვლა').first);
      await tester.pumpAndSettle();

      expect(find.text('მისამართის შენახვა'), findsOneWidget);
      await tester.tap(find.text('რუსთავი'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('მისამართის შენახვა'));
      await tester.pumpAndSettle();

      expect(find.textContaining('მიტანა ხელმისაწვდომია: რუსთავი (12 ₾)'), findsOneWidget);
      expect(find.text('12 ₾'), findsWidgets);

      // Switch to Batumi (out-of-zone) via Address Bottom Sheet
      await tester.tap(find.text('შეცვლა').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('ბათუმი'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('მისამართის შენახვა'));
      await tester.pumpAndSettle();

      expect(find.text('მიტანა შეუძლებელია ამ მისამართზე'), findsOneWidget);
      expect(find.textContaining('შეკვეთა გადართულია თვითგატანაზე'), findsOneWidget);
      expect(find.text('0 ₾ (თვითგატანა)'), findsOneWidget);

      // Switch back to Tbilisi and manually select self-pickup
      await tester.tap(find.text('შეცვლა').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('თბილისი'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('მისამართის შენახვა'));
      await tester.pumpAndSettle();

      expect(find.textContaining('მიტანა ხელმისაწვდომია: თბილისი (10 ₾)'), findsOneWidget);

      await tester.tap(find.text('თვითგატანა'));
      await tester.pumpAndSettle();
      expect(find.text('0 ₾ (თვითგატანა)'), findsOneWidget);
    });
  });
}
