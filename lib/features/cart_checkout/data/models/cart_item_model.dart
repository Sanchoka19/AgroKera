class CartItemModel {
  final String id;
  final String title;
  final String packageText;
  final String farmerName;
  final double pricePerUnit;
  final String unit;
  final String imageUrl;
  final int quantity;
  final double weightKg;
  final double minOrderQuantity;
  final double stockQuantity;
  final double? bulkDiscountMinQty;
  final int? bulkDiscountPercent;

  const CartItemModel({
    required this.id,
    required this.title,
    required this.packageText,
    required this.farmerName,
    required this.pricePerUnit,
    this.unit = 'კგ',
    required this.imageUrl,
    this.quantity = 1,
    this.weightKg = 1.0,
    this.minOrderQuantity = 1.0,
    this.stockQuantity = 99999.0,
    this.bulkDiscountMinQty,
    this.bulkDiscountPercent,
  });

  bool get hasBulkDiscount =>
      bulkDiscountMinQty != null &&
      bulkDiscountMinQty! > 0 &&
      bulkDiscountPercent != null &&
      bulkDiscountPercent! > 0;

  bool get isBulkDiscountApplied =>
      hasBulkDiscount && quantity >= bulkDiscountMinQty!;

  bool get isAtMaxStock => quantity >= stockQuantity;

  double get effectiveUnitPrice {
    if (isBulkDiscountApplied) {
      return pricePerUnit * (1.0 - (bulkDiscountPercent! / 100.0));
    }
    return pricePerUnit;
  }

  double get totalPrice => effectiveUnitPrice * quantity;
  double get totalWeight => weightKg * quantity;

  CartItemModel copyWith({
    String? id,
    String? title,
    String? packageText,
    String? farmerName,
    double? pricePerUnit,
    String? unit,
    String? imageUrl,
    int? quantity,
    double? weightKg,
    double? minOrderQuantity,
    double? stockQuantity,
    double? bulkDiscountMinQty,
    int? bulkDiscountPercent,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      packageText: packageText ?? this.packageText,
      farmerName: farmerName ?? this.farmerName,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      weightKg: weightKg ?? this.weightKg,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      bulkDiscountMinQty: bulkDiscountMinQty ?? this.bulkDiscountMinQty,
      bulkDiscountPercent: bulkDiscountPercent ?? this.bulkDiscountPercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'packageText': packageText,
      'farmerName': farmerName,
      'pricePerUnit': pricePerUnit,
      'unit': unit,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'weightKg': weightKg,
      'minOrderQuantity': minOrderQuantity,
      'stockQuantity': stockQuantity,
      'bulkDiscountMinQty': bulkDiscountMinQty,
      'bulkDiscountPercent': bulkDiscountPercent,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      packageText: json['packageText'] as String? ?? '',
      farmerName: json['farmerName'] as String? ?? '',
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'კგ',
      imageUrl: json['imageUrl'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 1.0,
      minOrderQuantity: (json['minOrderQuantity'] as num?)?.toDouble() ?? 1.0,
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 99999.0,
      bulkDiscountMinQty: (json['bulkDiscountMinQty'] as num?)?.toDouble(),
      bulkDiscountPercent: (json['bulkDiscountPercent'] as num?)?.toInt(),
    );
  }
}
