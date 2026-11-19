import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/features/marketplace/data/models/product_model.dart';
import 'package:agrokera/features/marketplace/domain/services/product_share_service.dart';

void main() {
  group('ProductShareService', () {
    final service = ProductShareService();

    const sampleProduct = ProductModel(
      id: 'prod_99',
      title: 'სულგუნი',
      category: 'რძის პროდუქტები',
      farmerId: 'farmer_1',
      farmerName: 'გიორგი ბერიძე',
      price: 24.50,
      unit: 'კგ',
      imageUrl: 'https://example.com/sulguni.jpg',
      description: 'ნატურალური სულგუნი',
    );

    test('buildProductUrl returns correct canonical URL', () {
      final url = service.buildProductUrl('prod_99');
      expect(url, 'https://agrokera.ge/products/prod_99');
    });

    test('formatShareSubject returns correct subject without emojis', () {
      final subject = service.formatShareSubject(sampleProduct);
      expect(subject, 'AgroKera: სულგუნი');
      expect(subject.contains('🌿'), isFalse);
      expect(subject.contains('👨‍🌾'), isFalse);
    });

    test('formatShareText formats complete product details without emojis', () {
      final text = service.formatShareText(sampleProduct);

      expect(text, contains('სულგუნი'));
      expect(text, contains('ფასი: 24.50 ₾ / კგ'));
      expect(text, contains('ფერმერი: გიორგი ბერიძე'));
      expect(text, contains('იხილეთ AgroKera-ში:'));
      expect(text, contains('https://agrokera.ge/products/prod_99'));

      // Verify no emojis are present
      final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1F9FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]',
        unicode: true,
      );
      expect(emojiRegex.hasMatch(text), isFalse);
    });

    test('formatShareText handles empty farmer name gracefully', () {
      const productNoFarmer = ProductModel(
        id: 'prod_100',
        title: 'თაფლი',
        category: 'თაფლი',
        farmerId: 'farmer_2',
        farmerName: '',
        price: 30.00,
        unit: 'ქილა',
        imageUrl: 'https://example.com/honey.jpg',
        description: 'მთის თაფლი',
      );

      final text = service.formatShareText(productNoFarmer);

      expect(text, contains('თაფლი'));
      expect(text, contains('ფასი: 30.00 ₾ / ქილა'));
      expect(text.contains('ფერმერი:'), isFalse);
      expect(text, contains('https://agrokera.ge/products/prod_100'));
    });
  });
}
