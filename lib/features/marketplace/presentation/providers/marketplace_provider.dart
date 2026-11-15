// ignore_for_file: use_null_aware_elements

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../cart_checkout/data/models/cart_item_model.dart';
import '../../data/mock_data.dart';
import '../../data/models/category_model.dart';
import '../../data/models/farmer_model.dart';
import '../../data/models/product_model.dart';

class MarketplaceState {
  final List<ProductModel> products;
  final List<FarmerModel> farmers;
  final List<CategoryModel> categories;
  final bool isSyncing;

  const MarketplaceState({
    required this.products,
    required this.farmers,
    required this.categories,
    this.isSyncing = false,
  });

  List<ProductModel> get availableProducts =>
      products.where((p) => p.isAvailable).toList();

  List<ProductModel> productsForFarmer(String farmerId) =>
      products.where((p) => p.farmerId == farmerId).toList();

  List<ProductModel> productsForCategory(String categoryName) =>
      availableProducts.where((p) => p.category == categoryName).toList();

  MarketplaceState copyWith({
    List<ProductModel>? products,
    List<FarmerModel>? farmers,
    List<CategoryModel>? categories,
    bool? isSyncing,
  }) {
    return MarketplaceState(
      products: products ?? this.products,
      farmers: farmers ?? this.farmers,
      categories: categories ?? this.categories,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class MarketplaceNotifier extends Notifier<MarketplaceState> {
  @override
  MarketplaceState build() {
    unawaited(Future.microtask(refreshFromBackend));
    return const MarketplaceState(
      products: MockData.products,
      farmers: MockData.farmers,
      categories: MockData.categories,
    );
  }

  Future<void> refreshFromBackend() async {
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.get<List<dynamic>>(
          '/api/products',
          queryParameters: {'includeUnavailable': 'true'},
        ),
        api.get<List<dynamic>>('/api/farmers'),
      ]);

      final rawProducts = results[0].data;
      final rawFarmers = results[1].data;

      if (rawProducts != null && rawProducts.isNotEmpty) {
        final fetchedProducts = rawProducts
            .whereType<Map<String, dynamic>>()
            .map(ProductModel.fromJson)
            .toList();
        state = state.copyWith(products: fetchedProducts);
      }

      if (rawFarmers != null && rawFarmers.isNotEmpty) {
        final fetchedFarmers = rawFarmers
            .whereType<Map<String, dynamic>>()
            .map(FarmerModel.fromJson)
            .toList();
        state = state.copyWith(farmers: fetchedFarmers);
      }
    } catch (_) {
      // Gracefully keep local/offline state when API is unreachable
    }
  }

  Future<ProductModel> addProduct({
    required String title,
    required String category,
    required double price,
    String unit = 'კგ',
    double stockQuantity = 50.0,
    int? discountPercent,
    double minOrderQuantity = 1.0,
    double? bulkDiscountMinQty,
    int? bulkDiscountPercent,
    String farmerId = 'farmer_2',
    String farmerName = 'გიორგის ფერმა',
    String? description,
    String? imageUrl,
    List<String>? images,
  }) async {
    final tempId = 'prod_${DateTime.now().millisecondsSinceEpoch}';
    final stockStatus = stockQuantity <= 0
        ? 'ამოწურულია'
        : stockQuantity < 20
            ? 'იწურება'
            : 'მარაგშია';
    final effectiveImages = (images != null && images.isNotEmpty)
        ? images
        : (imageUrl != null && imageUrl.isNotEmpty)
            ? [imageUrl]
            : const [
                'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop&q=80',
              ];
    final effectivePrimaryImage = imageUrl ?? effectiveImages.first;

    final newProduct = ProductModel(
      id: tempId,
      title: title,
      category: category,
      farmerId: farmerId,
      farmerName: farmerName,
      price: price,
      unit: unit,
      discountPercent: discountPercent,
      stockQuantity: stockQuantity,
      stockStatus: stockStatus,
      isAvailable: stockQuantity > 0,
      minOrderQuantity: minOrderQuantity,
      bulkDiscountMinQty: bulkDiscountMinQty,
      bulkDiscountPercent: bulkDiscountPercent,
      imageUrl: effectivePrimaryImage,
      images: effectiveImages,
      description:
          description ?? 'ახალი, ნატურალური $title პირდაპირ ფერმიდან.',
    );

    state = state.copyWith(products: [newProduct, ...state.products]);

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/api/products',
        data: {
          'title': title,
          'category': category,
          'farmerId': farmerId,
          'farmerName': farmerName,
          'pricePerUnit': price,
          'discountPercent': discountPercent ?? 0,
          'unit': unit,
          'stockQuantity': stockQuantity,
          'minOrderQuantity': minOrderQuantity,
          if (bulkDiscountMinQty != null) 'bulkDiscountMinQty': bulkDiscountMinQty,
          if (bulkDiscountPercent != null) 'bulkDiscountPercent': bulkDiscountPercent,
          if (description != null) 'description': description,
          'imageUrl': effectivePrimaryImage,
          'images': effectiveImages,
        },
      );
      if (response.data != null) {
        final serverProduct = ProductModel.fromJson(response.data!);
        state = state.copyWith(
          products: state.products
              .map((p) => p.id == tempId ? serverProduct : p)
              .toList(),
        );
        unawaited(refreshFromBackend());
        return serverProduct;
      }
    } catch (_) {}

    return newProduct;
  }

  Future<void> updateProduct(
    String productId, {
    String? title,
    String? category,
    double? price,
    int? discountPercent,
    String? unit,
    double? stockQuantity,
    double? minOrderQuantity,
    double? bulkDiscountMinQty,
    int? bulkDiscountPercent,
    bool? isAvailable,
    String? description,
    String? imageUrl,
    List<String>? images,
  }) async {
    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id != productId) return p;
        final newStock = stockQuantity ?? p.stockQuantity;
        final newStatus = newStock <= 0
            ? 'ამოწურულია'
            : newStock < 20
                ? 'იწურება'
                : 'მარაგშია';
        final nextImages = (images != null && images.isNotEmpty)
            ? images
            : (imageUrl != null ? [imageUrl] : p.images);
        return p.copyWith(
          title: title,
          category: category,
          price: price,
          discountPercent: discountPercent,
          unit: unit,
          stockQuantity: newStock,
          stockStatus: newStatus,
          minOrderQuantity: minOrderQuantity,
          bulkDiscountMinQty: bulkDiscountMinQty,
          bulkDiscountPercent: bulkDiscountPercent,
          isAvailable: isAvailable ?? (newStock > 0 ? p.isAvailable : false),
          description: description,
          imageUrl: imageUrl ?? (nextImages.isNotEmpty ? nextImages.first : p.imageUrl),
          images: nextImages,
        );
      }).toList(),
    );

    try {
      final api = ref.read(apiClientProvider);
      await api.patch(
        '/api/products/$productId',
        data: {
          if (title != null) 'title': title,
          if (category != null) 'category': category,
          if (price != null) 'pricePerUnit': price,
          if (discountPercent != null) 'discountPercent': discountPercent,
          if (unit != null) 'unit': unit,
          if (stockQuantity != null) 'stockQuantity': stockQuantity,
          if (minOrderQuantity != null) 'minOrderQuantity': minOrderQuantity,
          if (bulkDiscountMinQty != null) 'bulkDiscountMinQty': bulkDiscountMinQty,
          if (bulkDiscountPercent != null) 'bulkDiscountPercent': bulkDiscountPercent,
          if (isAvailable != null) 'isAvailable': isAvailable,
          if (description != null) 'description': description,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (images != null) 'images': images,
        },
      );
    } catch (_) {}
  }

  Future<double?> restockProduct(String productId, double addedQuantity) async {
    final target =
        state.products.where((p) => p.id == productId).firstOrNull;
    if (target == null || addedQuantity <= 0) return null;
    final newTotal = target.stockQuantity + addedQuantity;
    await updateProduct(
      productId,
      stockQuantity: newTotal,
      isAvailable: true,
    );
    return newTotal;
  }

  Future<void> deductStockForCartItems(List<CartItemModel> cartItems) async {
    for (final item in cartItems) {
      final match =
          state.products.where((p) => p.id == item.id).firstOrNull;
      if (match != null) {
        final remaining =
            (match.stockQuantity - item.quantity).clamp(0.0, 99999.0);
        await updateProduct(
          match.id,
          stockQuantity: remaining,
          isAvailable: remaining > 0,
        );
      }
    }
  }

  Future<void> deleteProduct(String productId) async {
    state = state.copyWith(
      products: state.products.where((p) => p.id != productId).toList(),
    );
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/api/products/$productId');
    } catch (_) {}
  }

  void updateFarmerDeliverySettings({
    required String farmerId,
    required bool isDeliveryEnabled,
    required String deliveryCity,
    required List<String> deliveryDays,
    required double deliveryFee,
    required Map<String, double> regionalDeliveryFees,
    required bool isPickupEnabled,
    String? location,
  }) {
    state = state.copyWith(
      farmers: state.farmers.map((f) {
        if (f.id == farmerId) {
          return f.copyWith(
            isDeliveryEnabled: isDeliveryEnabled,
            deliveryCity: deliveryCity,
            deliveryDays: deliveryDays,
            deliveryFee: deliveryFee,
            regionalDeliveryFees: regionalDeliveryFees,
            isPickupEnabled: isPickupEnabled,
            location: location ?? f.location,
          );
        }
        return f;
      }).toList(),
    );
  }
}

final marketplaceProvider =
    NotifierProvider<MarketplaceNotifier, MarketplaceState>(
  MarketplaceNotifier.new,
);

/// Computes smart similar products for a given [targetProduct]
final similarProductsProvider =
    Provider.family<List<ProductModel>, ProductModel>((ref, targetProduct) {
  final allProducts = ref.watch(marketplaceProvider).products;

  final candidates = allProducts.where((p) {
    if (p.id == targetProduct.id) return false;
    if (!p.isAvailable || p.stockQuantity <= 0) return false;
    return true;
  }).toList();

  final scored = <({ProductModel product, int score})>[];
  for (final p in candidates) {
    int score = 0;

    // Category match (highest relevance)
    final isSameCategory = p.category.toLowerCase().trim() ==
        targetProduct.category.toLowerCase().trim();
    if (isSameCategory) {
      score += 50;
    }

    // Same farmer bonus (prioritizes this farmer's products within category!)
    final isSameFarmer = p.farmerId == targetProduct.farmerId;
    if (isSameFarmer) {
      score += 35;
    }

    // Shared agro characteristics tags
    final sharedTags = p.effectiveAgroTags
        .where((t) => targetProduct.effectiveAgroTags.contains(t))
        .length;
    score += sharedTags * 8;

    // Rating bonus
    score += (p.rating * 2).toInt();

    // Price similarity bonus (within ±35% range)
    if (targetProduct.price > 0) {
      final ratio = p.price / targetProduct.price;
      if (ratio >= 0.65 && ratio <= 1.35) {
        score += 10;
      }
    }

    // Candidate must share category OR be from the same farmer
    if (isSameCategory || isSameFarmer) {
      scored.add((product: p, score: score));
    }
  }

  // Sort descending by score
  scored.sort((a, b) => b.score.compareTo(a.score));

  return scored.map((e) => e.product).take(8).toList();
});
