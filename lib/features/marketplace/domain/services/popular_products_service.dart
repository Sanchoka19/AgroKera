import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';

/// Domain service for calculating product popularity score and ranking
/// Separated from UI and state management according to Clean Architecture
class PopularProductsService {
  const PopularProductsService._();

  /// Calculates popularity score for a product.
  /// Higher score means greater popularity and buyer engagement.
  /// Out-of-stock items return -1.0 so they can be filtered out.
  static double calculatePopularityScore(ProductModel product) {
    if (product.isOutOfStock || !product.isAvailable) {
      return -1.0;
    }

    // Weighted popularity calculation:
    // 1. Rating multiplied by review count reflects proven customer satisfaction
    // 2. Base rating weight ensures high-rated items without reviews still rank above 0-rating items
    // 3. Review count volume indicates active buying interest
    // 4. Active discount bonus slightly elevates promotional items
    final reviewFactor = product.reviewCount.toDouble();
    final weightedRating = product.rating * (reviewFactor + 1.0);
    final volumeBonus = reviewFactor * 2.0;
    final discountBonus = product.hasDiscount ? (product.discountPercent ?? 0) * 0.25 : 0.0;

    return weightedRating + volumeBonus + discountBonus;
  }

  /// Filters out out-of-stock products and ranks available products by popularity score descending.
  /// If scores are identical, tie-breaks with review count, then rating, then title.
  static List<ProductModel> rankPopularProducts(List<ProductModel> products) {
    final available = products.where((p) => p.isAvailable && !p.isOutOfStock).toList();

    available.sort((a, b) {
      final scoreA = calculatePopularityScore(a);
      final scoreB = calculatePopularityScore(b);

      if (scoreB != scoreA) {
        return scoreB.compareTo(scoreA);
      }
      if (b.reviewCount != a.reviewCount) {
        return b.reviewCount.compareTo(a.reviewCount);
      }
      if (b.rating != a.rating) {
        return b.rating.compareTo(a.rating);
      }
      return a.title.compareTo(b.title);
    });

    return available;
  }

  /// Calculates category popularity score based on total popularity score and active
  /// product availability within that category.
  static double calculateCategoryScore(
    CategoryModel category,
    List<ProductModel> products,
  ) {
    final catProducts = products
        .where((p) => p.category == category.name && p.isAvailable && !p.isOutOfStock)
        .toList();

    if (catProducts.isEmpty) {
      return 0.0;
    }

    double totalScore = 0.0;
    for (final p in catProducts) {
      totalScore += calculatePopularityScore(p);
    }

    // Blend cumulative product score with active product diversity
    return totalScore + (catProducts.length * 3.0);
  }

  /// Ranks categories by popularity score descending.
  /// If scores are equal, falls back to original catalog order.
  static List<CategoryModel> rankPopularCategories(
    List<ProductModel> products,
    List<CategoryModel> categories,
  ) {
    final ranked = List<CategoryModel>.from(categories);

    ranked.sort((a, b) {
      final scoreA = calculateCategoryScore(a, products);
      final scoreB = calculateCategoryScore(b, products);

      if (scoreB != scoreA) {
        return scoreB.compareTo(scoreA);
      }
      return categories.indexOf(a).compareTo(categories.indexOf(b));
    });

    return ranked;
  }
}
