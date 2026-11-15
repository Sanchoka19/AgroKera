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
  final double stockQuantity;
  final String stockStatus; // 'მარაგშია', 'იწურება', 'ამოწურულია'
  final String imageUrl;
  final List<String> images;
  final String description;
  final double minOrderQuantity;
  final double? bulkDiscountMinQty;
  final int? bulkDiscountPercent;

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
    this.stockQuantity = 50.0,
    this.stockStatus = 'მარაგშია',
    required this.imageUrl,
    this.images = const [],
    required this.description,
    this.minOrderQuantity = 1.0,
    this.bulkDiscountMinQty,
    this.bulkDiscountPercent,
  });

  /// Returns all product images (at least the primary imageUrl)
  List<String> get galleryImages => images.isNotEmpty ? images : [imageUrl];

  /// Whether the product has an active base discount > 0%
  bool get hasDiscount => discountPercent != null && discountPercent! > 0;

  /// Whether the product has volume/wholesale tiered discount
  bool get hasBulkDiscount =>
      bulkDiscountMinQty != null &&
      bulkDiscountMinQty! > 0 &&
      bulkDiscountPercent != null &&
      bulkDiscountPercent! > 0;

  /// Effective unit price taking volume/bulk discount into account
  double priceForQuantity(num quantity) {
    if (hasBulkDiscount && quantity >= bulkDiscountMinQty!) {
      return price * (1.0 - (bulkDiscountPercent! / 100.0));
    }
    return price;
  }

  /// Bulk unit price if volume threshold is met
  double? get bulkUnitPrice {
    if (!hasBulkDiscount) return null;
    return price * (1.0 - (bulkDiscountPercent! / 100.0));
  }

  /// Formatted minimum order text
  String get minOrderDisplay =>
      '${minOrderQuantity.truncateToDouble() == minOrderQuantity ? minOrderQuantity.toInt() : minOrderQuantity} $unit';

  /// Computes the initial/original price before discount
  double? get effectiveOriginalPrice {
    if (originalPrice != null) return originalPrice;
    if (hasDiscount) {
      return price / (1.0 - (discountPercent! / 100.0));
    }
    return null;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final stockQty = (json['stockQuantity'] as num?)?.toDouble() ?? 50.0;
    final rawImages = (json['images'] as List<dynamic>?)
            ?.whereType<String>()
            .where((u) => u.isNotEmpty)
            .toList() ??
        const [];
    final primaryUrl = json['imageUrl'] as String? ??
        (rawImages.isNotEmpty
            ? rawImages.first
            : 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&auto=format&fit=crop&q=80');
    final rawDiscount = (json['discountPercent'] as num?)?.toInt();
    final validDiscount = (rawDiscount != null && rawDiscount > 0) ? rawDiscount : null;
    final rawBulkMin = (json['bulkDiscountMinQty'] as num?)?.toDouble();
    final rawBulkPct = (json['bulkDiscountPercent'] as num?)?.toInt();
    return ProductModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'ბოსტნეული',
      farmerId: json['farmerId'] as String? ?? 'farmer_2',
      farmerName: json['farmerName'] as String? ?? 'გიორგის ფერმა',
      price: ((json['price'] ?? json['pricePerUnit']) as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'კგ',
      discountPercent: validDiscount,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      stockQuantity: stockQty,
      stockStatus: json['stockStatus'] as String? ??
          (stockQty <= 0
              ? 'ამოწურულია'
              : stockQty < 20
                  ? 'იწურება'
                  : 'მარაგშია'),
      imageUrl: primaryUrl,
      images: rawImages.isNotEmpty ? rawImages : [primaryUrl],
      description: json['description'] as String? ?? '',
      minOrderQuantity: (json['minOrderQuantity'] as num?)?.toDouble() ?? 1.0,
      bulkDiscountMinQty: rawBulkMin != null && rawBulkMin > 0 ? rawBulkMin : null,
      bulkDiscountPercent: rawBulkPct != null && rawBulkPct > 0 ? rawBulkPct : null,
    );
  }

  ProductModel copyWith({
    String? id,
    String? title,
    String? category,
    String? farmerId,
    String? farmerName,
    double? price,
    double? originalPrice,
    String? unit,
    int? discountPercent,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    double? stockQuantity,
    String? stockStatus,
    String? imageUrl,
    List<String>? images,
    String? description,
    double? minOrderQuantity,
    double? bulkDiscountMinQty,
    int? bulkDiscountPercent,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      unit: unit ?? this.unit,
      discountPercent: discountPercent ?? this.discountPercent,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stockStatus: stockStatus ?? this.stockStatus,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      description: description ?? this.description,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      bulkDiscountMinQty: bulkDiscountMinQty ?? this.bulkDiscountMinQty,
      bulkDiscountPercent: bulkDiscountPercent ?? this.bulkDiscountPercent,
    );
  }
}
