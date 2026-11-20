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

      final result = criteria.filterProducts(products);
      expect(result.length, 1);
      expect(result.first.id, '1');
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
  });
}
