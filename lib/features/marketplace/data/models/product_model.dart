class ProductModel {
  final String id;
  final String title;
  final String category;
  final String farmerId;
  final String farmerName;
  final double price;
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
}
