// ignore_for_file: use_null_aware_elements

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_categories.dart';
import '../../../../core/network/api_client.dart';
import '../../../cart_checkout/data/models/cart_item_model.dart';
import '../../../orders/domain/models/farmer_order_model.dart';
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
    return MarketplaceState(
      products: MockData.products,
      farmers: MockData.farmers,
      categories: AppCategories.categories,
      isSyncing: !isFlutterTestEnv,
    );
  }

  Future<void> refreshFromBackend() async {
    state = state.copyWith(isSyncing: true);
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

      List<ProductModel>? newProducts;
      List<FarmerModel>? newFarmers;

      if (rawProducts != null) {
        newProducts = rawProducts
            .whereType<Map<String, dynamic>>()
            .map(ProductModel.fromJson)
            .toList();
      }

      if (rawFarmers != null) {
        newFarmers = rawFarmers
            .whereType<Map<String, dynamic>>()
            .map(FarmerModel.fromJson)
            .toList();
      }

      state = state.copyWith(
        products: newProducts,
        farmers: newFarmers,
        isSyncing: false,
      );
    } catch (_) {
      // Gracefully finish syncing when API is unreachable
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<ProductModel> addProduct({
    required String title,
    required String category,
    required double price,
    double? originalPrice,
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
      originalPrice: originalPrice,
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
    double? originalPrice,
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
          originalPrice: originalPrice,
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
          if (originalPrice != null) 'originalPrice': originalPrice,
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

  /// Restores deducted stock back to inventory when an order is cancelled
  Future<void> restoreStockForOrderItems(List<FarmerOrderItem> items) async {
    for (final item in items) {
      final match = state.products.where((p) =>
          (item.productId != null && p.id == item.productId) ||
          p.title.trim().toLowerCase() == item.name.trim().toLowerCase()).firstOrNull;

      if (match != null) {
        double qtyToRestore = item.quantity;
        if (qtyToRestore <= 1.0 && item.quantityText.isNotEmpty) {
          final digits = RegExp(r'(\d+(?:\.\d+)?)')
              .firstMatch(item.quantityText)
              ?.group(1);
          if (digits != null) {
            qtyToRestore = double.tryParse(digits) ?? item.quantity;
          }
        }
        final newStock = match.stockQuantity + qtyToRestore;
        await updateProduct(
          match.id,
          stockQuantity: newStock,
          isAvailable: true,
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

  static String normalizeDayName(String d) {
    const map = {
      'ორშ': 'ორშაბათი',
      'სამ': 'სამშაბათი',
      'ოთხ': 'ოთხშაბათი',
      'ხუთ': 'ხუთშაბათი',
      'პარ': 'პარასკევი',
      'შაბ': 'შაბათი',
      'კვი': 'კვირა',
    };
    final trimmed = d.trim();
    return map[trimmed] ?? trimmed;
  }

  static int weekdayOrderIndex(String day) {
    const order = [
      'ორშაბათი',
      'სამშაბათი',
      'ოთხშაბათი',
      'ხუთშაბათი',
      'პარასკევი',
      'შაბათი',
      'კვირა',
    ];
    final idx = order.indexOf(normalizeDayName(day));
    return idx >= 0 ? idx : 99;
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
    bool updateAllDemoFarmers = false,
  }) {
    final cleanDays = deliveryDays.map(normalizeDayName).toSet().toList();
    cleanDays.sort((a, b) => weekdayOrderIndex(a).compareTo(weekdayOrderIndex(b)));

    final exists = state.farmers.any((f) => f.id == farmerId);
    List<FarmerModel> updatedFarmers;

    if (exists) {
      updatedFarmers = state.farmers.map((f) {
        if (f.id == farmerId ||
            (updateAllDemoFarmers && (f.id == 'farmer_1' || f.id == 'farmer_2'))) {
          return f.copyWith(
            isDeliveryEnabled: isDeliveryEnabled,
            deliveryCity: deliveryCity,
            deliveryDays: cleanDays,
            deliveryFee: deliveryFee,
            regionalDeliveryFees: regionalDeliveryFees,
            isPickupEnabled: isPickupEnabled,
            location: location ?? f.location,
          );
        }
        return f;
      }).toList();
    } else {
      final newFarmer = FarmerModel(
        id: farmerId,
        farmName: 'ჩემი მეურნეობა',
        farmerName: 'ფერმერი',
        location: location ?? 'კახეთი',
        rating: 5.0,
        reviewCount: 0,
        totalRatings: 0,
        isDeliveryEnabled: isDeliveryEnabled,
        deliveryCity: deliveryCity,
        deliveryDays: cleanDays,
        deliveryFee: deliveryFee,
        regionalDeliveryFees: regionalDeliveryFees,
        isPickupEnabled: isPickupEnabled,
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
        coverUrl:
            'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80',
        about: 'ნატურალური ქართული პროდუქცია პირდაპირ მეურნეობიდან.',
      );

      var list = [...state.farmers, newFarmer];
      if (updateAllDemoFarmers) {
        list = list.map((f) {
          if (f.id == 'farmer_1' || f.id == 'farmer_2') {
            return f.copyWith(
              isDeliveryEnabled: isDeliveryEnabled,
              deliveryCity: deliveryCity,
              deliveryDays: cleanDays,
              deliveryFee: deliveryFee,
              regionalDeliveryFees: regionalDeliveryFees,
              isPickupEnabled: isPickupEnabled,
              location: location ?? f.location,
            );
          }
          return f;
        }).toList();
      }
      updatedFarmers = list;
    }

    state = state.copyWith(farmers: updatedFarmers);
  }
}

final marketplaceProvider =
    NotifierProvider<MarketplaceNotifier, MarketplaceState>(
  MarketplaceNotifier.new,
);

/// Filtered marketplace products visible for browsing and buying:
/// Excludes the authenticated farmer's own products so they do not see
/// their own listings while shopping on the marketplace.
final buyerProductsProvider = Provider<List<ProductModel>>((ref) {
  final allProducts = ref.watch(marketplaceProvider).availableProducts;
  final authState = ref.watch(authStateProvider);

  if (authState.role == UserRole.farmer) {
    return allProducts.where((p) => !p.isOwnedBy(authState)).toList();
  }
  return allProducts;
});

/// Computes smart similar products for a given [targetProduct]
final similarProductsProvider =
    Provider.family<List<ProductModel>, ProductModel>((ref, targetProduct) {
  final allProducts = ref.watch(buyerProductsProvider);

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
