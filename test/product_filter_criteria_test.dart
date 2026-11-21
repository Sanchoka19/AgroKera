import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/features/marketplace/data/models/product_model.dart';
import 'package:agrokera/features/marketplace/domain/models/product_filter_criteria.dart';

void main() {
  group('ProductFilterCriteria Tests', () {
    const p1 = ProductModel(
      id: '1',
      title: 'კახური პომიდორი',
      category: 'ბოსტნეული',
      farmerId: 'farmer_1',
      farmerName: 'გიორგი ბერიძე',
      price: 3.50,
      rating: 4.8,
      imageUrl: '',
      description: 'ახალი პომიდორი კახეთიდან',
    );

    const p2 = ProductModel(
      id: '2',
      title: 'იმერული ყველი',
      category: 'რძის ნაწარმი',
      farmerId: 'farmer_2',
      farmerName: 'დავით კაპანაძე',
      price: 15.00,
      rating: 4.9,
      imageUrl: '',
      description: 'ნატურალური ყველი',
    );

    const p3 = ProductModel(
      id: '3',
      title: 'ვაშლი გოლდენი',
      category: 'ხილი',
      farmerId: 'farmer_1',
      farmerName: 'გიორგი ბერიძე',
      price: 2.00,
      rating: 4.2,
      imageUrl: '',
      description: 'ტკბილი ვაშლი',
    );

    final products = [p1, p2, p3];
    final farmerLocations = {
      'farmer_1': 'გურჯაანი, კახეთი',
      'farmer_2': 'ქუთაისი, იმერეთი',
    };

    test('initial/empty criteria does not filter or sort', () {
      const criteria = ProductFilterCriteria.empty();
      expect(criteria.hasActiveFilters, isFalse);
      expect(criteria.activeCount, 0);

      final result = criteria.filterProducts(products);
      expect(result.length, 3);
    });

    test('filters by category correctly', () {
      const criteria = ProductFilterCriteria(category: 'ბოსტნეული');
      expect(criteria.hasActiveFilters, isTrue);
      expect(criteria.activeCount, 1);
      expect(criteria.hasActiveFiltersExcludingCategory(), isFalse);
      expect(criteria.activeCountExcludingCategory(), 0);

      final result = criteria.filterProducts(products);
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('excluding category respects region and sort filters', () {
      const criteria = ProductFilterCriteria(
        category: 'ბოსტნეული',
        region: 'კახეთი',
        sortBy: 'ჯერ იაფი',
      );
      expect(criteria.hasActiveFilters, isTrue);
      expect(criteria.activeCount, 3);
      expect(criteria.hasActiveFiltersExcludingCategory(), isTrue);
      expect(criteria.activeCountExcludingCategory(), 2);
    });

    test('filters by region correctly using farmer locations', () {
      const criteria = ProductFilterCriteria(region: 'კახეთი');
      expect(criteria.hasActiveFilters, isTrue);

      final result = criteria.filterProducts(
        products,
        farmerLocations: farmerLocations,
      );
      expect(result.length, 2);
      expect(result.map((p) => p.id), containsAll(['1', '3']));
    });

    test('filters by search query correctly', () {
      const criteria = ProductFilterCriteria.empty();
      final result = criteria.filterProducts(products, searchQuery: 'ყველი');
      expect(result.length, 1);
      expect(result.first.id, '2');
    });

    test('sorts by price ascending ("ჯერ იაფი")', () {
      const criteria = ProductFilterCriteria(sortBy: 'ჯერ იაფი');
      final result = criteria.filterProducts(products);
      expect(result.map((p) => p.price).toList(), [2.00, 3.50, 15.00]);
    });

    test('sorts by price descending ("ჯერ ძვირი")', () {
      const criteria = ProductFilterCriteria(sortBy: 'ჯერ ძვირი');
      final result = criteria.filterProducts(products);
      expect(result.map((p) => p.price).toList(), [15.00, 3.50, 2.00]);
    });

    test('sorts by rating descending ("მაღალი რეიტინგი")', () {
      const criteria = ProductFilterCriteria(sortBy: 'მაღალი რეიტინგი');
      final result = criteria.filterProducts(products);
      expect(result.first.id, '2'); // 4.9 rating
    });

    test('filters by price range (minPrice & maxPrice)', () {
      const criteria = ProductFilterCriteria(minPrice: 3.0, maxPrice: 10.0);
      expect(criteria.hasActiveFilters, isTrue);
      expect(criteria.activeCount, 1);

      final result = criteria.filterProducts(products);
      expect(result.length, 1);
      expect(result.first.id, '1'); // 3.50
    });

    test('filters by bio/organic agroTag', () {
      const criteria = ProductFilterCriteria(isBioOnly: true);
      expect(criteria.hasActiveFilters, isTrue);

      final bioProducts = [
        const ProductModel(
          id: 'bio_1',
          title: 'ბიო მარწყვი',
          category: 'ხილი',
          farmerId: 'f1',
          farmerName: 'ფერმერი',
          price: 10.0,
          imageUrl: '',
          description: '',
          agroTags: ['ბიო / ორგანული'],
        ),
        const ProductModel(
          id: 'conv_1',
          title: 'სტანდარტული მარწყვი',
          category: 'ხილი',
          farmerId: 'f1',
          farmerName: 'ფერმერი',
          price: 6.0,
          imageUrl: '',
          description: '',
          agroTags: ['ჩვეულებრივი'],
        ),
      ];

      final result = criteria.filterProducts(bioProducts);
      expect(result.length, 1);
      expect(result.first.id, 'bio_1');
    });

    test('filters by inStockOnly and hasDiscountOnly', () {
      final stockProducts = [
        const ProductModel(
          id: 'instock_1',
          title: 'კარტოფილი',
          category: 'ბოსტნეული',
          farmerId: 'f1',
          farmerName: 'ფერმერი',
          price: 2.0,
          imageUrl: '',
          description: '',
          isAvailable: true,
          stockStatus: 'მარაგშია',
          discountPercent: 15,
        ),
        const ProductModel(
          id: 'out_1',
          title: 'სტაფილო',
          category: 'ბოსტნეული',
          farmerId: 'f1',
          farmerName: 'ფერმერი',
          price: 2.5,
          imageUrl: '',
          description: '',
          isAvailable: false,
          stockStatus: 'ამოწურულია',
        ),
      ];

      const inStockCriteria = ProductFilterCriteria(inStockOnly: true);
      final inStockResult = inStockCriteria.filterProducts(stockProducts);
      expect(inStockResult.length, 1);
      expect(inStockResult.first.id, 'instock_1');

      const discountCriteria = ProductFilterCriteria(hasDiscountOnly: true);
      final discountResult = discountCriteria.filterProducts(stockProducts);
      expect(discountResult.length, 1);
      expect(discountResult.first.id, 'instock_1');
    });
  });
}
