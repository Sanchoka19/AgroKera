import '../../data/models/product_model.dart';

/// Clean immutable model for holding product filter & sort criteria.
/// Decoupled from UI widgets to prevent "god object" anti-patterns.
class ProductFilterCriteria {
  final String? region;
  final String? category;
  final String sortBy; // 'პოპულარული', 'ჯერ იაფი', 'ჯერ ძვირი', 'მაღალი რეიტინგი'

  const ProductFilterCriteria({
    this.region,
    this.category,
    this.sortBy = 'პოპულარული',
  });

  const ProductFilterCriteria.empty()
      : region = null,
        category = null,
        sortBy = 'პოპულარული';

  /// Whether any non-default filter or sort is currently active
  bool get hasActiveFilters {
    final hasRegion = region != null && region != 'ყველა' && region!.trim().isNotEmpty;
    final hasCategory = category != null && category != 'ყველა' && category!.trim().isNotEmpty;
    final hasSort = sortBy != 'პოპულარული';
    return hasRegion || hasCategory || hasSort;
  }

  /// Number of active filters applied
  int get activeCount {
    int count = 0;
    if (region != null && region != 'ყველა' && region!.trim().isNotEmpty) count++;
    if (category != null && category != 'ყველა' && category!.trim().isNotEmpty) count++;
    if (sortBy != 'პოპულარული') count++;
    return count;
  }

  ProductFilterCriteria copyWith({
    String? region,
    bool clearRegion = false,
    String? category,
    bool clearCategory = false,
    String? sortBy,
  }) {
    return ProductFilterCriteria(
      region: clearRegion ? null : (region ?? this.region),
      category: clearCategory ? null : (category ?? this.category),
      sortBy: sortBy ?? this.sortBy,
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
        final locMatches = farmerLoc != null && farmerLoc.toLowerCase().contains(reg);
        final descMatches = p.description.toLowerCase().contains(reg);
        final farmerNameMatches = p.farmerName.toLowerCase().contains(reg);
        if (!locMatches && !descMatches && !farmerNameMatches) {
          return false;
        }
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
          sortBy == other.sortBy;

  @override
  int get hashCode => region.hashCode ^ category.hashCode ^ sortBy.hashCode;
}

