import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:agrokera/features/marketplace/data/models/farmer_model.dart';
import 'package:agrokera/features/marketplace/data/models/product_model.dart';
import 'package:agrokera/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:agrokera/features/marketplace/presentation/providers/nearby_farmers_provider.dart';
import 'package:agrokera/features/marketplace/data/mock_data.dart';
import 'package:agrokera/features/marketplace/domain/services/farmer_proximity_service.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/nearby_farm_card.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/nearby_farms_section.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });
  group('FarmerProximityService Domain Tests', () {
    test('Calculates and formats distances correctly', () {
      final farmer = MockData.farmers.first; // გურჯაანი, კახეთი

      final infoClose = FarmerDistanceInfo.fromDistance(
        farmer: farmer,
        distanceKm: 0.75,
      );
      expect(infoClose.formattedDistance, '750 მ');

      final infoMid = FarmerDistanceInfo.fromDistance(
        farmer: farmer,
        distanceKm: 4.23,
      );
      expect(infoMid.formattedDistance, '4.2 კმ');

      final infoFar = FarmerDistanceInfo.fromDistance(
        farmer: farmer,
        distanceKm: 81.4,
      );
      expect(infoFar.formattedDistance, '81 კმ');
    });

    test('sortAndCalculateDistances correctly ranks farmers by proximity', () {
      // Baseline origin: Tbilisi Freedom square
      const tbilisiOrigin = LatLng(41.7151, 44.8271);

      final sorted = FarmerProximityService.sortAndCalculateDistances(
        farmers: MockData.farmers,
        origin: tbilisiOrigin,
      );

      expect(sorted.length, MockData.farmers.length);
      // Ensure strictly ascending distance
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(sorted[i].distanceKm <= sorted[i + 1].distanceKm, isTrue);
      }

      // Telavi (~63km) should be closer to Tbilisi than Gurjaani (~81km) and Kvareli (~87km)
      expect(sorted.first.farmer.location.contains('თელავი'), isTrue);
    });
  });

  group('NearbyFarmsSection & NearbyFarmCard Widget Tests', () {
    testWidgets('Renders NearbyFarmsSection with sorted cards and distance badges without emojis',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NearbyFarmsSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header and Proximity indicator
      expect(find.text('ახლოს მდებარე'), findsOneWidget);
      expect(find.text('სიახლოვის მიხედვით'), findsOneWidget);

      // Verify NearbyFarmCards are rendered
      expect(find.byType(NearbyFarmCard), findsWidgets);

      // Verify Distance badges are rendered
      expect(find.textContaining('კმ'), findsWidgets);

      // Verify Delivery tags are rendered without emojis
      expect(find.text('მიწოდებით'), findsWidgets);
    });

    test('nearbyFarmersProvider excludes farmers with no purchasable products or stock below minimum order', () {
      final f1 = MockData.farmers[0]; // farmer with good stock
      final f2 = MockData.farmers[1]; // farmer with stock below min order
      final f3 = MockData.farmers[2]; // farmer with 0 products

      final p1 = ProductModel(
        id: 'p_good',
        title: 'პომიდორი',
        category: 'ბოსტნეული',
        farmerId: f1.id,
        farmerName: f1.farmName,
        price: 4.5,
        stockQuantity: 20.0,
        minOrderQuantity: 5.0,
        isAvailable: true,
        imageUrl: '',
        description: '',
      );
      final p2 = ProductModel(
        id: 'p_below_min',
        title: 'კიტრი',
        category: 'ბოსტნეული',
        farmerId: f2.id,
        farmerName: f2.farmName,
        price: 3.0,
        stockQuantity: 2.0,
        minOrderQuantity: 5.0, // stock 2 < minOrder 5 -> out of stock
        isAvailable: true,
        imageUrl: '',
        description: '',
      );

      final container = ProviderContainer(
        overrides: [
          marketplaceProvider.overrideWith(
            () => _TestProximityMarketplaceNotifier([p1, p2], [f1, f2, f3]),
          ),
        ],
      );

      final state = container.read(nearbyFarmersProvider);
      final farmerIds = state.farmers.map((f) => f.farmer.id).toList();

      // Only f1 has a purchasable product (stockQuantity >= minOrderQuantity)
      expect(farmerIds, contains(f1.id));
      expect(farmerIds, isNot(contains(f2.id)));
      expect(farmerIds, isNot(contains(f3.id)));
    });
  });
}

class _TestProximityMarketplaceNotifier extends MarketplaceNotifier {
  final List<ProductModel> testProducts;
  final List<FarmerModel> testFarmers;
  _TestProximityMarketplaceNotifier(this.testProducts, this.testFarmers);

  @override
  MarketplaceState build() {
    return MarketplaceState(
      products: testProducts,
      farmers: testFarmers,
      categories: MockData.categories,
      isSyncing: false,
    );
  }
}
