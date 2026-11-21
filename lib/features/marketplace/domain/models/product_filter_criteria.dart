import '../../data/models/product_model.dart';

/// Clean immutable model for holding product filter & sort criteria.
/// Decoupled from UI widgets to prevent "god object" anti-patterns.
class ProductFilterCriteria {
  final String? region;
  final String? category;
  final String sortBy; // 'პოპულარული', 'ჯერ იაფი', 'ჯერ ძვირი', 'მაღალი რეიტინგი'
  final double? minPrice;
  final double? maxPrice;
  final bool isBioOnly;
  final bool inStockOnly;
  final bool hasDiscountOnly;

  const ProductFilterCriteria({
    this.region,
    this.category,
    this.sortBy = 'პოპულარული',
    this.minPrice,
    this.maxPrice,
    this.isBioOnly = false,
    this.inStockOnly = false,
    this.hasDiscountOnly = false,
  });

  const ProductFilterCriteria.empty()
      : region = null,
        category = null,
        sortBy = 'პოპულარული',
        minPrice = null,
        maxPrice = null,
        isBioOnly = false,
        inStockOnly = false,
        hasDiscountOnly = false;

  /// Whether any non-default filter or sort is currently active
  bool get hasActiveFilters {
    final hasRegion =
        region != null && region != 'ყველა' && region!.trim().isNotEmpty;
    final hasCategory =
        category != null && category != 'ყველა' && category!.trim().isNotEmpty;
    final hasSort = sortBy != 'პოპულარული';
    final hasPrice = minPrice != null || maxPrice != null;
    return hasRegion ||
        hasCategory ||
        hasSort ||
        hasPrice ||
        isBioOnly ||
        inStockOnly ||
        hasDiscountOnly;
  }

  /// Number of active filters applied
  int get activeCount {
    int count = 0;
    if (region != null && region != 'ყველა' && region!.trim().isNotEmpty) count++;
    if (category != null && category != 'ყველა' && category!.trim().isNotEmpty) count++;
    if (sortBy != 'პოპულარული') count++;
    if (minPrice != null || maxPrice != null) count++;
    if (isBioOnly) count++;
    if (inStockOnly) count++;
    if (hasDiscountOnly) count++;
    return count;
  }

  /// Whether active filters are present, excluding the category filter (e.g. for CategoryProductsScreen)
  bool hasActiveFiltersExcludingCategory() {
    final hasRegion =
        region != null && region != 'ყველა' && region!.trim().isNotEmpty;
    final hasSort = sortBy != 'პოპულარული';
    final hasPrice = minPrice != null || maxPrice != null;
    return hasRegion ||
        hasSort ||
        hasPrice ||
        isBioOnly ||
        inStockOnly ||
        hasDiscountOnly;
  }

  /// Number of active filters applied, excluding the category filter
  int activeCountExcludingCategory() {
    int count = 0;
    if (region != null && region != 'ყველა' && region!.trim().isNotEmpty) count++;
    if (sortBy != 'პოპულარული') count++;
    if (minPrice != null || maxPrice != null) count++;
    if (isBioOnly) count++;
    if (inStockOnly) count++;
    if (hasDiscountOnly) count++;
    return count;
  }

  ProductFilterCriteria copyWith({
    String? region,
    bool clearRegion = false,
    String? category,
    bool clearCategory = false,
    String? sortBy,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    bool? isBioOnly,
    bool? inStockOnly,
    bool? hasDiscountOnly,
  }) {
    return ProductFilterCriteria(
      region: clearRegion ? null : (region ?? this.region),
      category: clearCategory ? null : (category ?? this.category),
      sortBy: sortBy ?? this.sortBy,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      isBioOnly: isBioOnly ?? this.isBioOnly,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      hasDiscountOnly: hasDiscountOnly ?? this.hasDiscountOnly,
    );
  }

  /// Filters and sorts a product list according to criteria and search query.
  List<ProductModel> filterProducts(
    List<ProductModel> products, {
    String? searchQuery,
    Map<String, String>? farmerLocations,
  }) {
    // 1. Filter
    final filtered = products.where((p) {
      // Search query filter (title, farmer, category, description)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchesTitle = p.title.toLowerCase().contains(q);
        final matchesFarmer = p.farmerName.toLowerCase().contains(q);
        final matchesCategory = p.category.toLowerCase().contains(q);
        final matchesDesc = p.description.toLowerCase().contains(q);
        if (!matchesTitle && !matchesFarmer && !matchesCategory && !matchesDesc) {
          return false;
        }
      }

      // Category filter
      if (category != null && category != 'ყველა' && category!.trim().isNotEmpty) {
        if (p.category.trim() != category!.trim()) return false;
      }

      // Region filter
      if (region != null && region != 'ყველა' && region!.trim().isNotEmpty) {
        final reg = region!.toLowerCase().trim();
        final farmerLoc = farmerLocations?[p.farmerId];
        final locMatches =
            farmerLoc != null && farmerLoc.toLowerCase().contains(reg);
        final descMatches = p.description.toLowerCase().contains(reg);
        final farmerNameMatches = p.farmerName.toLowerCase().contains(reg);
        if (!locMatches && !descMatches && !farmerNameMatches) {
          return false;
        }
      }

      // Price range filter
      if (minPrice != null && p.price < minPrice!) return false;
      if (maxPrice != null && p.price > maxPrice!) return false;

      // In-stock only filter
      if (inStockOnly &&
          (p.stockStatus == 'ამოწურულია' || !p.isAvailable || p.stockQuantity <= 0)) {
        return false;
      }

      // Discount only filter
      if (hasDiscountOnly && !p.hasDiscount) return false;

      // Bio / organic only filter
      if (isBioOnly) {
        final isBio = p.effectiveAgroTags.any((t) {
          final lower = t.toLowerCase();
          return lower.contains('ბიო') || lower.contains('ორგანულ');
        });
        if (!isBio) return false;
      }

      return true;
    }).toList();

    // 2. Sort
    switch (sortBy) {
      case 'ჯერ იაფი':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'ჯერ ძვირი':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'მაღალი რეიტინგი':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'პოპულარული':
      default:
        // Preserves original order / popular score order
        break;
    }

    return filtered;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductFilterCriteria &&
          runtimeType == other.runtimeType &&
          region == other.region &&
          category == other.category &&
          sortBy == other.sortBy &&
          minPrice == other.minPrice &&
          maxPrice == other.maxPrice &&
          isBioOnly == other.isBioOnly &&
          inStockOnly == other.inStockOnly &&
          hasDiscountOnly == other.hasDiscountOnly;

  @override
  int get hashCode =>
      region.hashCode ^
      category.hashCode ^
      sortBy.hashCode ^
      minPrice.hashCode ^
      maxPrice.hashCode ^
      isBioOnly.hashCode ^
      inStockOnly.hashCode ^
      hasDiscountOnly.hashCode;
}
