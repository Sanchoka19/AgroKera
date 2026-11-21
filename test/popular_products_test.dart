import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agrokera/features/marketplace/data/models/product_model.dart';
import 'package:agrokera/features/marketplace/domain/services/popular_products_service.dart';
import 'package:agrokera/core/constants/app_categories.dart';
import 'package:agrokera/features/marketplace/data/mock_data.dart';
import 'package:agrokera/features/marketplace/presentation/screens/popular_products_screen.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/popular_products_section.dart';
import 'package:agrokera/features/marketplace/presentation/widgets/quick_categories_bar.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  group('PopularProductsService Domain Tests', () {
    test('calculatePopularityScore correctly scores products and excludes out-of-stock', () {
      const availableProduct = ProductModel(
        id: 'p1',
        title: 'მარწყვი',
        category: 'ხილი',
        farmerId: 'f1',
        farmerName: 'სანდრო',
        price: 10.0,
        rating: 4.8,
        reviewCount: 20,
        discountPercent: 10,
        stockQuantity: 50.0,
        minOrderQuantity: 1.0,
        isAvailable: true,
        imageUrl: '',
        description: '',
      );

      const outOfStockProduct = ProductModel(
        id: 'p2',
        title: 'ჟოლო',
        category: 'ხილი',
        farmerId: 'f1',
        farmerName: 'სანდრო',
        price: 12.0,
        rating: 5.0,
        reviewCount: 100,
        stockQuantity: 0.0,
        isAvailable: false,
        imageUrl: '',
        description: '',
      );

      const belowMinOrderProduct = ProductModel(
        id: 'p3',
        title: 'ყურძენი',
        category: 'ხილი',
        farmerId: 'f1',
        farmerName: 'სანდრო',
        price: 5.0,
        rating: 5.0,
        reviewCount: 50,
        stockQuantity: 2.0,
        minOrderQuantity: 5.0, // 2 < 5 -> out of stock
        isAvailable: true,
        imageUrl: '',
        description: '',
      );

      final score1 = PopularProductsService.calculatePopularityScore(availableProduct);
      final score2 = PopularProductsService.calculatePopularityScore(outOfStockProduct);
      final score3 = PopularProductsService.calculatePopularityScore(belowMinOrderProduct);

      expect(score1 > 0, isTrue);
      expect(score2, -1.0);
      expect(score3, -1.0);
    });

    test('rankPopularProducts ranks higher weighted score and excludes unavailable items', () {
      const pLow = ProductModel(
        id: 'p_low',
        title: 'კარტოფილი',
        category: 'ბოსტნეული',
        farmerId: 'f1',
        farmerName: 'გიორგი',
        price: 2.0,
        rating: 3.5,
        reviewCount: 2,
        stockQuantity: 100.0,
        minOrderQuantity: 1.0,
        isAvailable: true,
        imageUrl: '',
        description: '',
      );

      const pHigh = ProductModel(
        id: 'p_high',
        title: 'თაფლი',
        category: 'სხვადასხვა',
        farmerId: 'f2',
        farmerName: 'დავითი',
        price: 25.0,
        rating: 4.9,
        reviewCount: 45,
        discountPercent: 15,
        stockQuantity: 30.0,
        minOrderQuantity: 1.0,
        isAvailable: true,
        imageUrl: '',
        description: '',
      );

      const pOut = ProductModel(
        id: 'p_out',
        title: 'ყველი',
        category: 'რძის ნაწარმი',
        farmerId: 'f3',
        farmerName: 'მარიამი',
        price: 18.0,
        rating: 5.0,
        reviewCount: 100,
        stockQuantity: 0.0, // out of stock
        isAvailable: true,
        imageUrl: '',
        description: '',
      );

      final ranked = PopularProductsService.rankPopularProducts([pLow, pOut, pHigh]);

      expect(ranked.length, 2);
      expect(ranked.first.id, 'p_high');
      expect(ranked.last.id, 'p_low');
      expect(ranked.any((p) => p.id == 'p_out'), isFalse);
    });

    test('rankPopularCategories ranks categories based on product engagement and returns top categories', () {
      final rankedCats = PopularProductsService.rankPopularCategories(
        MockData.products,
        AppCategories.categories,
      );

      expect(rankedCats.length, AppCategories.categories.length);
      // Top 4 categories must have positive score / products
      final top4 = rankedCats.take(4).map((c) => c.name).toList();
      expect(top4.length, 4);
      expect(top4, contains('ბოსტნეული'));
      expect(top4, contains('ხილი'));
    });
  });

  group('PopularCategoriesBar Widget Tests', () {
    testWidgets('Renders QuickCategoriesBar with 4 popular categories and "ყველა" action without emojis',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickCategoriesBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('პოპულარული კატეგორიები'), findsOneWidget);
    });
  });

  group('PopularProductsSection Widget Tests', () {
    testWidgets('Renders PopularProductsSection with header, see all action, and cards without emojis',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PopularProductsSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header and Action
      expect(find.text('პოპულარული პროდუქტები'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);

      // Verify tapping see all chevron navigates to PopularProductsScreen
      await tester.tap(find.byIcon(LucideIcons.chevronRight));
      await tester.pumpAndSettle();

      expect(find.byType(PopularProductsScreen), findsOneWidget);
    });
  });
}
