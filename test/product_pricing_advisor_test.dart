import 'package:flutter_test/flutter_test.dart';
import 'package:agrokera/features/farm_inventory/domain/models/product_pricing_advisory.dart';
import 'package:agrokera/features/farm_inventory/presentation/providers/product_form_validator.dart';

void main() {
  group('ProductPricingAdvisory Pure Domain Tests', () {
    test('triggers weight warning when unit is piece and no weight is specified', () {
      final advisory = ProductPricingAdvisory.evaluate(
        title: 'სოფლის ქათამი',
        category: 'ცხოველური პროდუქტები',
        unit: 'ცალი',
        basePrice: 24.0,
        stock: 10,
        minOrder: 1,
        estimatedPieceWeight: '',
        description: 'ახალი დაკლული ქათამი',
      );

      expect(advisory.requiresWeightClarification, isTrue);
      expect(advisory.weightWarningMessage, isNotNull);
      expect(advisory.isPriceSuspicious, isFalse);
    });

    test('clears weight warning when estimated weight is provided via dedicated field', () {
      final advisory = ProductPricingAdvisory.evaluate(
        title: 'სოფლის ქათამი',
        category: 'ცხოველური პროდუქტები',
        unit: 'ცალი',
        basePrice: 24.0,
        stock: 10,
        minOrder: 1,
        estimatedPieceWeight: '~1.5 კგ',
        description: 'ახალი დაკლული ქათამი',
      );

      expect(advisory.requiresWeightClarification, isFalse);
      expect(advisory.estimatedPieceWeight, equals('~1.5 კგ'));
    });

    test('clears weight warning when weight is mentioned in title or description', () {
      final advisoryWithTitle = ProductPricingAdvisory.evaluate(
        title: 'სოფლის ქათამი (~1.4 - 1.6 კგ)',
        category: 'ცხოველური პროდუქტები',
        unit: 'ცალი',
        basePrice: 24.0,
        stock: 10,
        minOrder: 1,
        description: 'ახალი დაკლული',
      );

      expect(advisoryWithTitle.requiresWeightClarification, isFalse);

      final advisoryWithDesc = ProductPricingAdvisory.evaluate(
        title: 'სოფლის ქათამი',
        category: 'ცხოველური პროდუქტები',
        unit: 'ცალი',
        basePrice: 24.0,
        stock: 10,
        minOrder: 1,
        description: 'საშუალო წონა: 1.5 კგ',
      );

      expect(advisoryWithDesc.requiresWeightClarification, isFalse);
    });

    test('does not require weight clarification for non-piece units (like kg)', () {
      final advisory = ProductPricingAdvisory.evaluate(
        title: 'სულგუნი',
        category: 'ცხოველური პროდუქტები',
        unit: 'კგ',
        basePrice: 20.0,
        stock: 50,
        minOrder: 1,
      );

      expect(advisory.requiresWeightClarification, isFalse);
    });

    test('flags suspiciously low price as a sanity check against typos', () {
      final advisory = ProductPricingAdvisory.evaluate(
        title: 'სოფლის ქათამი',
        category: 'ცხოველური პროდუქტები',
        unit: 'ცალი',
        basePrice: 0.24, // intended 24.00
        stock: 10,
        minOrder: 1,
      );

      expect(advisory.isPriceSuspicious, isTrue);
      expect(advisory.priceWarningMessage, contains('საეჭვოდ დაბალია'));
    });

    test('flags suspiciously high price as a sanity check', () {
      final advisory = ProductPricingAdvisory.evaluate(
        title: 'სოფლის ქათამი',
        category: 'ცხოველური პროდუქტები',
        unit: 'ცალი',
        basePrice: 1500.0,
        stock: 10,
        minOrder: 1,
      );

      expect(advisory.isPriceSuspicious, isTrue);
      expect(advisory.priceWarningMessage, contains('აღემატება 1,000 ₾-ს'));
    });

    test('extracts estimated piece weight from saved composite description', () {
      const description = '''
ჯიში/სახეობა: ქართული
სავარაუდო წონა 1 ცალზე: ~1.5 კგ
მახასიათებლები: სოფლის, ნატურალური

სიმინდზე ნაკვები სოფლის ქათამი.''';

      final extracted = ProductPricingAdvisory.extractEstimatedWeightFromDescription(description);
      expect(extracted, equals('~1.5 კგ'));
    });
  });

  group('ProductFormValidator Description Composition Tests', () {
    test('composes rich description including estimated piece weight without emojis', () {
      final composed = ProductFormValidator.composeDescription(
        variety: 'ადგილობრივი',
        estimatedPieceWeight: '~1.5 კგ',
        agroTags: {'სოფლის', 'საღი'},
        rawDescription: 'ახალი დაკლული ქათამი.',
      );

      expect(composed, contains('ჯიში/სახეობა: ადგილობრივი'));
      expect(composed, contains('სავარაუდო წონა 1 ცალზე: ~1.5 კგ'));
      expect(composed, contains('მახასიათებლები: სოფლის, საღი'));
      expect(composed, contains('ახალი დაკლული ქათამი.'));
      // Verify no emojis in output
      final emojiRegex = RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true);
      expect(emojiRegex.hasMatch(composed), isFalse);
    });
  });
}

