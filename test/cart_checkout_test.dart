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
import 'package:agrokera/features/marketplace/data/models/product_model.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:agrokera/features/marketplace/presentation/screens/favorites_screen.dart';
import 'package:agrokera/features/marketplace/presentation/screens/product_details_screen.dart';
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
    testWidgets('allows unauthenticated guest to view cart and prompts auth on checkout button', (tester) async {
      final container = ProviderContainer();
      container.read(cartProvider.notifier).addItem(
        const CartItemModel(
          id: 'guest_prod_1',
          title: 'სოფლის პომიდორი',
          packageText: '1კგ',
          farmerName: 'სოფლის ფერმა',
          pricePerUnit: 35.00,
          unit: 'კგ',
          imageUrl: '',
          quantity: 1,
          weightKg: 1.0,
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
      expect(find.text('სოფლის პომიდორი'), findsOneWidget);
      expect(find.text('გაგრძელება'), findsOneWidget);

      await tester.tap(find.text('გაგრძელება'));
      await tester.pumpAndSettle();

      expect(find.text('ავტორიზაცია'), findsWidgets);
    });

    testWidgets('prompts AddressRequiredBottomSheet when authenticated user attempts checkout without saved address', (tester) async {
      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(role: UserRole.customer);
      container.read(cartProvider.notifier).addItem(
        const CartItemModel(
          id: 'authed_prod_1',
          title: 'სოფლის პომიდორი',
          packageText: '1კგ',
          farmerName: 'სოფლის ფერმა',
          pricePerUnit: 35.00,
          unit: 'კგ',
          imageUrl: '',
          quantity: 1,
          weightKg: 1.0,
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

      expect(find.text('გაგრძელება'), findsOneWidget);
      await tester.tap(find.text('გაგრძელება'));
      await tester.pumpAndSettle();

      expect(find.text('მიუთითეთ მისამართი'), findsOneWidget);
      expect(find.text('მისამართის დამატება'), findsOneWidget);
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
      expect(find.text('მიტანის საფასური'), findsOneWidget);
      expect(find.text('მოსაკრებელი'), findsNothing);
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

  group('Farmer Own Product Restriction Tests', () {
    const ownProduct = ProductModel(
      id: 'prod_giorgi_1',
      title: 'გიორგის პომიდორი',
      category: 'ბოსტნეული',
      farmerId: 'farmer_2',
      farmerName: 'გიორგის ფერმა',
      price: 15.0,
      stockQuantity: 50.0,
      imageUrl: '',
      description: 'ახალი პომიდორი',
    );

    const otherProduct = ProductModel(
      id: 'prod_lana_1',
      title: 'ლანას თაფლი',
      category: 'თაფლი',
      farmerId: 'farmer_1',
      farmerName: 'მწვანე ველი',
      price: 25.0,
      stockQuantity: 20.0,
      imageUrl: '',
      description: 'ბიო თაფლი',
    );

    test('farmer cannot add their own product to cart', () {
      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(
            role: UserRole.farmer,
            email: 'giorgi@agrokera.ge',
          );

      expect(container.read(authStateProvider).farmerId, 'farmer_2');
      expect(ownProduct.isOwnedBy(container.read(authStateProvider)), isTrue);

      final result = container
          .read(cartProvider.notifier)
          .addProduct(ownProduct, 2);

      expect(result, isA<AddToCartOwnerForbidden>());
      expect(container.read(cartProvider).isEmpty, isTrue);

      // Farmer CAN add products from another farmer
      final successResult = container
          .read(cartProvider.notifier)
          .addProduct(otherProduct, 1);
      expect(successResult, isA<AddToCartSuccess>());
      expect(container.read(cartProvider).length, 1);
    });

    test('customer can freely add any farmer product', () {
      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(role: UserRole.customer);

      final result = container
          .read(cartProvider.notifier)
          .addProduct(ownProduct, 2);

      expect(result, isA<AddToCartSuccess>());
      expect(container.read(cartProvider).length, 1);
    });

    test('cart validation identifies owned product', () {
      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(role: UserRole.customer);

      // Add item as customer
      container.read(cartProvider.notifier).addProduct(ownProduct, 2);
      expect(container.read(cartProvider).length, 1);

      // Switch to farmer who owns this product
      container.read(authStateProvider.notifier).login(
            role: UserRole.farmer,
            email: 'giorgi@agrokera.ge',
          );

      final validation = container
          .read(cartProvider.notifier)
          .validateAndSyncStock([ownProduct]);

      expect(validation, isA<CartValidationContainsOwnProduct>());
    });

    testWidgets('ProductDetailsScreen disables purchase CTA for owner farmer',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(
            role: UserRole.farmer,
            email: 'giorgi@agrokera.ge',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProductDetailsScreen(product: ownProduct),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('თქვენი პროდუქტი'), findsOneWidget);
      expect(
        find.textContaining('ეს თქვენი მეურნეობის პროდუქტია'),
        findsOneWidget,
      );
    });

    test('buyerProductsProvider completely hides farmer own products from marketplace feed', () {
      final container = ProviderContainer();

      // Default/Customer view: all marketplace products are visible
      container.read(authStateProvider.notifier).login(role: UserRole.customer);
      final customerProducts = container.read(buyerProductsProvider);
      expect(customerProducts.any((p) => p.farmerId == 'farmer_2'), isTrue);

      // Farmer 2 view: all farmer_2 products are filtered out from marketplace feed
      container.read(authStateProvider.notifier).login(
            role: UserRole.farmer,
            email: 'giorgi@agrokera.ge',
          );
      final farmerProducts = container.read(buyerProductsProvider);
      expect(farmerProducts.any((p) => p.farmerId == 'farmer_2'), isFalse);
      expect(farmerProducts.any((p) => p.farmerName == 'გიორგის ფერმა'), isFalse);
      // Products of other farmers (e.g. farmer_1) remain available
      expect(farmerProducts.any((p) => p.farmerId == 'farmer_1'), isTrue);
    });

    test('Single-Vendor Cart enforces one farmer and allows replacement on confirmation', () {
      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(role: UserRole.customer);
      final notifier = container.read(cartProvider.notifier);
      notifier.clearCart();

      // Product 1 from Farmer 1
      final p1 = ProductModel(
        id: 'prod_f1_1',
        title: 'ყურძენი',
        category: 'ხილი',
        farmerId: 'farmer_1',
        farmerName: 'მწვანე ველი',
        price: 5.0,
        imageUrl: '',
        description: '',
        stockQuantity: 50,
      );

      // Product 2 from Farmer 2
      final p2 = ProductModel(
        id: 'prod_f2_1',
        title: 'ატამი',
        category: 'ხილი',
        farmerId: 'farmer_2',
        farmerName: 'გიორგის ფერმა',
        price: 7.0,
        imageUrl: '',
        description: '',
        stockQuantity: 50,
      );

      // Add product from Farmer 1 -> Success
      final res1 = notifier.addProduct(p1, 2);
      expect(res1, isA<AddToCartSuccess>());
      expect(container.read(cartProvider).length, 1);
      expect(container.read(cartProvider).first.farmerName, 'მწვანე ველი');

      // Attempt to add product from Farmer 2 without force -> AddToCartDifferentFarmer
      final res2 = notifier.addProduct(p2, 3);
      expect(res2, isA<AddToCartDifferentFarmer>());
      final diff = res2 as AddToCartDifferentFarmer;
      expect(diff.currentFarmerName, 'მწვანე ველი');
      expect(diff.newFarmerName, 'გიორგის ფერმა');
      expect(diff.quantity, 3);
      // Cart should still contain only Farmer 1's product
      expect(container.read(cartProvider).length, 1);
      expect(container.read(cartProvider).first.farmerName, 'მწვანე ველი');

      // User confirms replacement -> forceReplaceFarmer: true
      final res3 = notifier.addProduct(p2, 3, forceReplaceFarmer: true);
      expect(res3, isA<AddToCartSuccess>());
      expect(container.read(cartProvider).length, 1);
      expect(container.read(cartProvider).first.farmerName, 'გიორგის ფერმა');
      expect(container.read(cartProvider).first.quantity, 3);
    });

    test('Weight calculation correctly reflects linear weight rather than squared weight', () {
      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(role: UserRole.customer);
      final notifier = container.read(cartProvider.notifier);
      notifier.clearCart();

      final p = ProductModel(
        id: 'prod_weight_1',
        title: 'კარტოფილი',
        category: 'ბოსტნეული',
        farmerId: 'farmer_1',
        farmerName: 'მწვანე ველი',
        price: 2.0,
        imageUrl: '',
        description: '',
        stockQuantity: 100,
      );

      // Adding 5 kg
      final res = notifier.addProduct(p, 5);
      expect(res, isA<AddToCartSuccess>());

      final items = container.read(cartProvider);
      expect(items.length, 1);
      // Weight per unit is 1.0, totalWeight is 5.0 kg (NOT 25 kg!)
      expect(items.totalWeight, 5.0);
      expect(items.heavyFee, 0.0);
    });

    test('Minimum order quantity is automatically enforced on addProduct', () {
      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(role: UserRole.customer);
      final notifier = container.read(cartProvider.notifier);
      notifier.clearCart();

      final p = ProductModel(
        id: 'prod_min_1',
        title: 'კაკალი',
        category: 'ჩირი და თხილეული',
        farmerId: 'farmer_1',
        farmerName: 'მწვანე ველი',
        price: 15.0,
        imageUrl: '',
        description: '',
        minOrderQuantity: 5.0,
        stockQuantity: 50,
      );

      // Attempt to add 2 units (less than minOrderQuantity = 5)
      final res = notifier.addProduct(p, 2);
      expect(res, isA<AddToCartSuccess>());
      final success = res as AddToCartSuccess;
      expect(success.minOrderAdjusted, isTrue);
      expect(success.totalInCart, 5);
      expect(container.read(cartProvider).first.quantity, 5);
    });

    test('Bulk discount upsell and applied states are accurately computed', () {
      final container = ProviderContainer();
      container.read(authStateProvider.notifier).login(role: UserRole.customer);
      final notifier = container.read(cartProvider.notifier);
      notifier.clearCart();

      final p = ProductModel(
        id: 'prod_bulk_test_1',
        title: 'მარწყვი',
        category: 'ხილი',
        farmerId: 'farmer_1',
        farmerName: 'მწვანე ველი',
        price: 10.0,
        imageUrl: '',
        description: '',
        bulkDiscountMinQty: 10.0,
        bulkDiscountPercent: 20,
        stockQuantity: 100,
      );

      // Add 8 units (2 units short of bulk threshold 10)
      final res1 = notifier.addProduct(p, 8);
      expect(res1, isA<AddToCartSuccess>());
      final s1 = res1 as AddToCartSuccess;
      expect(s1.hasBulkUpsell, isTrue);
      expect(s1.remainingForBulkDiscount, 2);
      expect(s1.bulkDiscountPercent, 20);
      expect(s1.bulkDiscountApplied, isFalse);

      // Add 2 more units (reach 10)
      final res2 = notifier.addProduct(p, 2);
      expect(res2, isA<AddToCartSuccess>());
      final s2 = res2 as AddToCartSuccess;
      expect(s2.bulkDiscountApplied, isTrue);
      expect(s2.hasBulkUpsell, isFalse);
      expect(container.read(cartProvider).first.isBulkDiscountApplied, isTrue);
    });

    test('Unit logistics weight conversion matrix calculates correct weight for bottles, crates, pieces, bundles', () {
      expect(CartItemModel.resolveDefaultUnitWeight('კგ'), 1.0);
      expect(CartItemModel.resolveDefaultUnitWeight('ლიტრი'), 1.1);
      expect(CartItemModel.resolveDefaultUnitWeight('ლ'), 1.1);
      expect(CartItemModel.resolveDefaultUnitWeight('ბოთლი'), 1.4);
      expect(CartItemModel.resolveDefaultUnitWeight('ყუთი'), 10.0);
      expect(CartItemModel.resolveDefaultUnitWeight('ცალი'), 1.5);
      expect(CartItemModel.resolveDefaultUnitWeight('შეკვრა'), 0.5);

      const wineItem = CartItemModel(
        id: 'wine_1',
        title: 'საფერავი',
        packageText: 'ბოთლი',
        farmerName: 'კახური ველი',
        pricePerUnit: 25.0,
        unit: 'ბოთლი',
        imageUrl: '',
        quantity: 10,
      );
      // 10 bottles * 1.4 kg = 14.0 kg
      expect(wineItem.totalWeight, 14.0);

      const crateItem = CartItemModel(
        id: 'crate_1',
        title: 'ატამი',
        packageText: 'ყუთი',
        farmerName: 'კახური ველი',
        pricePerUnit: 30.0,
        unit: 'ყუთი',
        imageUrl: '',
        quantity: 3,
      );
      // 3 crates * 10.0 kg = 30.0 kg
      expect(crateItem.totalWeight, 30.0);
    });

    test('Vehicle capacity tiers and heavy fee surcharges work properly across weight thresholds', () {
      final container = ProviderContainer();
      final notifier = container.read(cartProvider.notifier);
      notifier.clearCart();

      // Tier 1: <= 20 kg (Standard Courier, heavyFee = 0)
      notifier.addItem(
        const CartItemModel(
          id: 'tier1_item',
          title: 'პომიდორი',
          packageText: 'კგ',
          farmerName: 'ფერმა',
          pricePerUnit: 5.0,
          unit: 'კგ',
          imageUrl: '',
          quantity: 15, // 15 kg
        ),
      );
      var items = container.read(cartProvider);
      expect(items.totalWeight, 15.0);
      expect(items.vehicleType, DeliveryVehicleType.standardCourier);
      expect(items.heavyFee, 0.0);
      expect(items.isWeightLimitExceeded, isFalse);

      // Tier 2: 20.01 - 60 kg (Passenger Car, heavyFee = 8.0)
      notifier.addItem(
        const CartItemModel(
          id: 'tier2_item',
          title: 'ღვინო',
          packageText: 'ბოთლი',
          farmerName: 'ფერმა',
          pricePerUnit: 20.0,
          unit: 'ბოთლი',
          imageUrl: '',
          quantity: 15, // 15 * 1.4 = 21.0 kg -> Total = 36.0 kg
        ),
      );
      items = container.read(cartProvider);
      expect(items.totalWeight, 36.0);
      expect(items.vehicleType, DeliveryVehicleType.passengerCar);
      expect(items.heavyFee, 8.0);
      expect(items.isWeightLimitExceeded, isFalse);

      // Tier 3: 60.01 - 250 kg (Cargo Van, heavyFee = 45.0)
      notifier.addItem(
        const CartItemModel(
          id: 'tier3_item',
          title: 'კარტოფილი',
          packageText: 'ყუთი',
          farmerName: 'ფერმა',
          pricePerUnit: 15.0,
          unit: 'ყუთი',
          imageUrl: '',
          quantity: 5, // 5 * 10.0 = 50.0 kg -> Total = 86.0 kg
        ),
      );
      items = container.read(cartProvider);
      expect(items.totalWeight, 86.0);
      expect(items.vehicleType, DeliveryVehicleType.cargoVan);
      expect(items.heavyFee, 45.0);
      expect(items.isWeightLimitExceeded, isFalse);

      // Tier 4: > 250 kg (Exceeded Limit -> Courier delivery blocked, pickup required)
      notifier.addItem(
        const CartItemModel(
          id: 'tier4_item',
          title: 'საზამთრო საბითუმო',
          packageText: 'კგ',
          farmerName: 'ფერმა',
          pricePerUnit: 1.0,
          unit: 'კგ',
          imageUrl: '',
          quantity: 200, // 200 kg -> Total = 286.0 kg
        ),
      );
      items = container.read(cartProvider);
      expect(items.totalWeight, 286.0);
      expect(items.vehicleType, DeliveryVehicleType.exceededLimit);
      expect(items.isWeightLimitExceeded, isTrue);
      expect(items.heavyFee, 0.0); // No courier heavy fee charged because delivery is blocked
    });
  });
}
