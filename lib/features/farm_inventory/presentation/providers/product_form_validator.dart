/// Pure validation and domain formatting logic for the 3-step Product Form flow.
/// Adheres to the same clean architecture pattern as [FarmerOnboardingValidator].
class ProductFormValidator {
  const ProductFormValidator._();

  /// Validates Step 1: Photos & Product Identity
  static String? validateStep1({
    required int photoCount,
    required String title,
    required String category,
  }) {
    if (photoCount <= 0) {
      return 'გთხოვთ დაამატოთ მინიმუმ 1 პროდუქტის ფოტო';
    }
    if (title.trim().isEmpty) {
      return 'გთხოვთ მიუთითოთ პროდუქტის დასახელება';
    }
    if (title.trim().length < 2) {
      return 'პროდუქტის დასახელება უნდა შეიცავდეს მინიმუმ 2 სიმბოლოს';
    }
    if (category.trim().isEmpty) {
      return 'გთხოვთ აირჩიოთ პროდუქტის კატეგორია';
    }
    return null;
  }

  /// Validates Step 2: Pricing, Stock, and Optional Discounts
  static String? validateStep2({
    required String priceText,
    required String stockText,
    required bool isDiscountActive,
    required String discountText,
    required bool isBulkDiscountActive,
    required String bulkMinQtyText,
    required String bulkDiscountText,
  }) {
    final price = double.tryParse(priceText.trim()) ?? 0.0;
    if (price <= 0) {
      return 'გთხოვთ მიუთითოთ სწორი ფასი (0-ზე მეტი)';
    }

    final stock = double.tryParse(stockText.trim()) ?? -1.0;
    if (stockText.trim().isEmpty || stock < 0) {
      return 'გთხოვთ მიუთითოთ მარაგის რაოდენობა';
    }

    if (isDiscountActive) {
      final discount = int.tryParse(discountText.trim());
      if (discount == null || discount <= 0 || discount >= 100) {
        return 'ფასდაკლების პროცენტი უნდა იყოს 1-დან 99-მდე';
      }
    }

    if (isBulkDiscountActive) {
      final bulkMinQty = double.tryParse(bulkMinQtyText.trim());
      final bulkDiscount = int.tryParse(bulkDiscountText.trim());

      if (bulkMinQty == null || bulkMinQty <= 0) {
        return 'მიუთითეთ საბითუმო ზღვარი (რაოდენობა)';
      }
      if (bulkDiscount == null || bulkDiscount <= 0 || bulkDiscount >= 100) {
        return 'საბითუმო ფასდაკლება უნდა იყოს 1-დან 99-მდე';
      }
    }

    return null;
  }

  /// Calculates the effective single unit discounted promo price
  static double calculateDiscountedPrice({
    required double basePrice,
    required bool isDiscountActive,
    required String discountText,
  }) {
    if (!isDiscountActive || basePrice <= 0) return basePrice;
    final discount = int.tryParse(discountText.trim()) ?? 0;
    if (discount <= 0 || discount >= 100) return basePrice;
    return basePrice * (1.0 - (discount / 100.0));
  }

  /// Calculates the effective bulk volume unit price
  static double calculateBulkUnitPrice({
    required double basePrice,
    required bool isBulkDiscountActive,
    required String bulkDiscountText,
  }) {
    if (!isBulkDiscountActive || basePrice <= 0) return basePrice;
    final discount = int.tryParse(bulkDiscountText.trim()) ?? 0;
    if (discount <= 0 || discount >= 100) return basePrice;
    return basePrice * (1.0 - (discount / 100.0));
  }

  /// Composes rich description text combining variety, agro-tags, and custom description
  static String composeDescription({
    String? variety,
    Set<String>? agroTags,
    String? rawDescription,
  }) {
    final buffer = StringBuffer();
    final cleanVariety = variety?.trim() ?? '';
    final cleanDesc = rawDescription?.trim() ?? '';

    if (cleanVariety.isNotEmpty) {
      buffer.writeln('ჯიში/სახეობა: $cleanVariety');
    }
    if (agroTags != null && agroTags.isNotEmpty) {
      buffer.writeln('მახასიათებლები: ${agroTags.join(', ')}');
    }
    if (cleanDesc.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(cleanDesc);
    } else if (buffer.isEmpty) {
      buffer.write('ნატურალური ქართული აგრო-პროდუქცია პირდაპირ მეურნეობიდან.');
    }

    return buffer.toString();
  }
}

