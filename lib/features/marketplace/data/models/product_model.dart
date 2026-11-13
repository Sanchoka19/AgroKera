class ProductModel {
  final String id;
  final String title;
  final String category;
  final String farmerId;
  final String farmerName;
  final double price;
  final double? originalPrice;
  final String unit;
  final int? discountPercent;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final String stockStatus; // 'მარაგშია' or 'იწურება'
  final String imageUrl;
  final String description;
  final double minOrderQuantity;

  const ProductModel({
    required this.id,
    required this.title,
    required this.category,
    required this.farmerId,
    required this.farmerName,
    required this.price,
    this.originalPrice,
    this.unit = 'კგ',
    this.discountPercent,
    this.rating = 4.9,
    this.reviewCount = 80,
    this.isAvailable = true,
    this.stockStatus = 'მარაგშია',
    required this.imageUrl,
    required this.description,
    this.minOrderQuantity = 1.0,
  });

  /// Computes the initial/original price before discount
  double? get effectiveOriginalPrice {
    if (originalPrice != null) return originalPrice;
    if (discountPercent != null && discountPercent! > 0) {
      return price / (1.0 - (discountPercent! / 100.0));
    }
    return null;
  }
}
