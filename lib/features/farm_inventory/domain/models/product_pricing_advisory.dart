/// Pure business logic and domain model for evaluating product pricing,
/// variable weight risks, and pre-publish advisory recommendations.
///
/// Keeps validation and decision rules decoupled from Flutter UI widgets.
class ProductPricingAdvisory {
  final bool requiresWeightClarification;
  final String? weightWarningMessage;
  final bool isPriceSuspicious;
  final String? priceWarningMessage;
  final String title;
  final String category;
  final double effectivePrice;
  final String unit;
  final double stock;
  final double minOrder;
  final String? estimatedPieceWeight;

  const ProductPricingAdvisory({
    required this.requiresWeightClarification,
    this.weightWarningMessage,
    required this.isPriceSuspicious,
    this.priceWarningMessage,
    required this.title,
    required this.category,
    required this.effectivePrice,
    required this.unit,
    required this.stock,
    required this.minOrder,
    this.estimatedPieceWeight,
  });

  /// Standard quick presets for poultry, cheese, and farm produce sold by piece.
  static const List<String> quickWeightPresets = [
    '~0.5 კგ',
    '~1.0 კგ',
    '~1.5 კგ',
    '~2.0 კგ',
    '~2.5 კგ',
  ];

  /// Categories where individual piece items typically have variable agricultural weights.
  static const Set<String> variableWeightCategories = {
    'ცხოველური პროდუქტები',
    'ფრინველის ხორცი',
    'ხორცი',
    'რძის ნაწარმი',
    'ბოსტნეული',
    'ხილი',
    'კენკრა',
    'ციტრუსი',
  };

  /// Checks whether a text snippet contains an explicit weight indication.
  static bool hasWeightMention(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final lower = text.toLowerCase();
    final weightRegex = RegExp(r'(\d+([\.,]\d+)?\s*(კგ|გრ|kg|g|გრამი|კილო))|~|მინიმუმ');
    return weightRegex.hasMatch(lower);
  }

  /// Extracts previously saved estimated weight from a composite description if present.
  static String? extractEstimatedWeightFromDescription(String? description) {
    if (description == null || description.isEmpty) return null;
    const marker = 'სავარაუდო წონა 1 ცალზე:';
    for (final line in description.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith(marker)) {
        final value = trimmed.substring(marker.length).trim();
        return value.isNotEmpty ? value : null;
      }
    }
    return null;
  }

  /// Evaluates business rules and returns a structured [ProductPricingAdvisory].
  static ProductPricingAdvisory evaluate({
    required String title,
    required String category,
    required String unit,
    required double basePrice,
    int? discountPercent,
    required double stock,
    required double minOrder,
    String? estimatedPieceWeight,
    String? description,
  }) {
    final cleanUnit = unit.trim();
    final cleanWeight = estimatedPieceWeight?.trim();
    final hasDedicatedWeight = cleanWeight != null && cleanWeight.isNotEmpty;

    final hasWeightInText = hasDedicatedWeight ||
        hasWeightMention(title) ||
        hasWeightMention(description);

    final isPieceUnit = cleanUnit == 'ცალი';
    final isVarWeightCategory = variableWeightCategories.any(
      (c) => category.toLowerCase().contains(c.toLowerCase()),
    );

    // Rule 1: Weight clarification needed for piece units in variable-weight categories
    final bool requiresClarification = isPieceUnit && isVarWeightCategory && !hasWeightInText;
    final String? weightWarning = requiresClarification
        ? 'პროდუქტი იყიდება ცალობით, თუმცა სავარაუდო წონა არ არის მითითებული. რეკომენდებულია წონის დამატება, რათა თავიდან აირიდოთ გაუგებრობა მყიდველთან.'
        : null;

    // Calculate effective selling price
    final hasDiscount = discountPercent != null && discountPercent > 0;
    final double effectivePrice = hasDiscount
        ? (basePrice * (1.0 - (discountPercent / 100.0)))
        : basePrice;

    // Rule 2: Suspicious pricing checks (preventing unintended typos)
    bool isSuspicious = false;
    String? priceWarning;

    if (effectivePrice < 1.0 && isVarWeightCategory) {
      isSuspicious = true;
      priceWarning = 'მითითებული ფასი (${effectivePrice.toStringAsFixed(2)} ₾) საეჭვოდ დაბალია ამ კატეგორიისთვის. დარწმუნდით, რომ ფასი სწორადაა შეყვანილი.';
    } else if (effectivePrice > 1000.0) {
      isSuspicious = true;
      priceWarning = 'მითითებული ფასი (${effectivePrice.toStringAsFixed(2)} ₾) აღემატება 1,000 ₾-ს. გადაამოწმეთ შეყვანილი თანხა.';
    }

    return ProductPricingAdvisory(
      requiresWeightClarification: requiresClarification,
      weightWarningMessage: weightWarning,
      isPriceSuspicious: isSuspicious,
      priceWarningMessage: priceWarning,
      title: title.trim(),
      category: category.trim(),
      effectivePrice: effectivePrice,
      unit: cleanUnit,
      stock: stock,
      minOrder: minOrder,
      estimatedPieceWeight: hasDedicatedWeight ? cleanWeight : null,
    );
  }
}

