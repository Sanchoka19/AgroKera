import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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
  });
}
