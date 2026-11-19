import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agrokera/features/marketplace/data/models/farmer_model.dart';
import 'package:agrokera/features/marketplace/data/models/product_model.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:agrokera/features/marketplace/presentation/screens/farmer_profile_screen.dart';
import 'package:agrokera/core/widgets/draggable_floating_cart.dart';

void main() {
  testWidgets('FarmerProfileScreen cart visibility with 1 product and tab switching', (tester) async {
    const testFarmer = FarmerModel(
      id: 'farmer_1',
      farmName: 'ტესტ ფერმა',
      farmerName: 'სანდრო',
      location: 'თელავი',
      rating: 5.0,
      reviewCount: 10,
      avatarUrl: '',
      coverUrl: '',
      about: 'აღწერა',
      phone: '599112233',
    );

    const product1 = ProductModel(
      id: 'p1',
      title: 'პროდუქტი 1',
      description: 'ახალი პროდუქტი',
      category: 'ბოსტნეული',
      price: 5.0,
      unit: 'კგ',
      farmerId: 'farmer_1',
      farmerName: 'სანდრო',
      imageUrl: '',
      stockQuantity: 10,
      isAvailable: true,
      minOrderQuantity: 1,
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketplaceProvider.overrideWith(
            () => _TestMarketplaceNotifier([product1], [testFarmer]),
          ),
        ],
        child: const MaterialApp(
          home: FarmerProfileScreen(farmer: testFarmer),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. With only 1 product uploaded, floating cart MUST be visible in Products tab
    expect(find.byType(DraggableFloatingCart), findsOneWidget);
    final cartRect = tester.getRect(find.byType(DraggableFloatingCart));
    final mediaSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(cartRect.bottom, lessThanOrEqualTo(mediaSize.height));
    expect(cartRect.right, lessThanOrEqualTo(mediaSize.width));

    // 2. Switching to "ფერმის შესახებ" tab: cart must disappear
    await tester.tap(find.text('ფერმის შესახებ'));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableFloatingCart), findsNothing);

    // 3. Switching back to "პროდუქტები" tab: cart reappears
    await tester.tap(find.text('პროდუქტები'));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableFloatingCart), findsOneWidget);
  });
}

class _TestMarketplaceNotifier extends MarketplaceNotifier {
  final List<ProductModel> testProducts;
  final List<FarmerModel> testFarmers;
  _TestMarketplaceNotifier(this.testProducts, this.testFarmers);

  @override
  MarketplaceState build() {
    return MarketplaceState(
      products: testProducts,
      farmers: testFarmers,
      categories: [],
      isSyncing: false,
    );
  }
}
