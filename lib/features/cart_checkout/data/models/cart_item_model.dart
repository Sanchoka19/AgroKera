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
  });

  double get totalPrice => pricePerUnit * quantity;
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
    );
  }
}

