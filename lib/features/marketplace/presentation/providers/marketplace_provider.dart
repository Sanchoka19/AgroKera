// ignore_for_file: use_null_aware_elements

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/constants/app_categories.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/offline_queue/offline_mutation.dart';
import '../../../../core/network/offline_queue/offline_queue_store.dart';
import '../../../../core/network/offline_queue/offline_sync_coordinator.dart';
import '../../../../core/storage/cache/local_cache_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
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
    unawaited(Future.microtask(() async {
      if (!ref.mounted) return;
      await _loadCachedMarketplaceData();
      if (!ref.mounted) return;
      await _loadPersistedDeliverySettings();
      _setupSyncListener();
      if (!ref.mounted) return;
      await refreshFromBackend();
    }));
    return MarketplaceState(
      products: MockData.products,
      farmers: MockData.farmers,
      categories: AppCategories.categories,
      isSyncing: !isFlutterTestEnv,
    );
  }

  void _setupSyncListener() {
    try {
      ref.read(offlineSyncCoordinatorProvider).addOnSyncCompletedListener(() {
        if (ref.mounted) {
          unawaited(refreshFromBackend());
        }
      });
    } catch (_) {}
  }

  Future<void> _loadCachedMarketplaceData() async {
    try {
      final cache = ref.read(localCacheServiceProvider);
      final rawProducts = await cache.readEntityList(LocalCacheService.productsKey);
      final rawFarmers = await cache.readEntityList(LocalCacheService.farmersKey);
      if (!ref.mounted) return;

      List<ProductModel>? cachedProducts;
      List<FarmerModel>? cachedFarmers;

      if (rawProducts != null && rawProducts.isNotEmpty) {
        cachedProducts = rawProducts.map(ProductModel.fromJson).toList();
      }
      if (rawFarmers != null && rawFarmers.isNotEmpty) {
        cachedFarmers = rawFarmers.map(FarmerModel.fromJson).toList();
      }

      if (cachedProducts != null || cachedFarmers != null) {
        state = state.copyWith(
          products: cachedProducts ?? state.products,
          farmers: cachedFarmers ?? state.farmers,
        );
      }
    } catch (_) {}
  }

  void _persistCurrentProducts() {
    try {
      unawaited(
        ref.read(localCacheServiceProvider).saveEntityList(
          LocalCacheService.productsKey,
          state.products.map((p) => p.toJson()).toList(),
        ),
      );
    } catch (_) {}
  }

  Future<void> _loadPersistedDeliverySettings() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final persistedConfigs = await storage.readAllFarmerDeliverySettings();
      if (!ref.mounted || persistedConfigs.isEmpty) return;

      final updatedFarmers = state.farmers.map((farmer) {
        final saved = persistedConfigs[farmer.id] ??
            (farmer.id == 'farmer_1' ? persistedConfigs['farmer_2'] : null) ??
            (farmer.id == 'farmer_2' ? persistedConfigs['farmer_1'] : null);
        if (saved != null) {
          return _applyDeliverySettingsToFarmer(farmer, saved);
        }
        return farmer;
      }).toList();

      if (!ref.mounted) return;
      state = state.copyWith(farmers: updatedFarmers);
    } catch (_) {}
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
      if (!ref.mounted) return;

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
        final auth = ref.read(authStateProvider);
        final storage = ref.read(secureStorageProvider);
        final persistedConfigs = await storage.readAllFarmerDeliverySettings();
        if (!ref.mounted) return;

        newFarmers = rawFarmers
            .whereType<Map<String, dynamic>>()
            .map((json) {
              var farmer = FarmerModel.fromJson(json);
              if (auth.isAuthenticated &&
                  auth.isFarmer &&
                  ((auth.farmerId != null && farmer.id == auth.farmerId) ||
                      (auth.farmName != null && farmer.farmName == auth.farmName))) {
                farmer = farmer.copyWith(
                  avatarUrl: (auth.userAvatarUrl != null &&
                          auth.userAvatarUrl!.trim().isNotEmpty)
                      ? auth.userAvatarUrl
                      : farmer.avatarUrl,
                  coverUrl: (auth.farmCoverUrl != null &&
                          auth.farmCoverUrl!.trim().isNotEmpty)
                      ? auth.farmCoverUrl
                      : farmer.coverUrl,
                );
              }

              final saved = persistedConfigs[farmer.id] ??
                  (farmer.id == 'farmer_1' ? persistedConfigs['farmer_2'] : null) ??
                  (farmer.id == 'farmer_2' ? persistedConfigs['farmer_1'] : null);
              if (saved != null) {
                farmer = _applyDeliverySettingsToFarmer(farmer, saved);
              }

              return farmer;
            })
            .toList();
      }

      if (!ref.mounted) return;
      if (newProducts != null) {
        unawaited(
          ref.read(localCacheServiceProvider).saveEntityList(
            LocalCacheService.productsKey,
            newProducts.map((p) => p.toJson()).toList(),
          ),
        );
      }
      if (newFarmers != null) {
        unawaited(
          ref.read(localCacheServiceProvider).saveEntityList(
            LocalCacheService.farmersKey,
            newFarmers.map((f) => f.toJson()).toList(),
          ),
        );
      }
      state = state.copyWith(
        products: newProducts,
        farmers: newFarmers,
        isSyncing: false,
      );
    } catch (_) {
      // Gracefully finish syncing when API is unreachable
      if (ref.mounted) {
        state = state.copyWith(isSyncing: false);
      }
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
    final isBelowMin = stockQuantity > 0 && stockQuantity < minOrderQuantity;
    final stockStatus = stockQuantity <= 0
        ? 'ამოწურულია'
        : isBelowMin
            ? 'მარაგი ამოიწურა'
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
      isAvailable: stockQuantity >= minOrderQuantity && stockQuantity > 0,
      minOrderQuantity: minOrderQuantity,
      bulkDiscountMinQty: bulkDiscountMinQty,
      bulkDiscountPercent: bulkDiscountPercent,
      imageUrl: effectivePrimaryImage,
      images: effectiveImages,
      description:
          description ?? 'ახალი, ნატურალური $title პირდაპირ ფერმიდან.',
    );

    state = state.copyWith(products: [newProduct, ...state.products]);
    _persistCurrentProducts();

    final postData = {
      'title': title,
      'category': category,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'pricePerUnit': price,
      if (originalPrice != null) 'originalPrice': originalPrice,
      'discountPercent': discountPercent ?? 0,
      'unit': unit,
      'stockQuantity': stockQuantity,
      'minOrderQuantity': minOrderQuantity,
      if (bulkDiscountMinQty != null) 'bulkDiscountMinQty': bulkDiscountMinQty,
      if (bulkDiscountPercent != null) 'bulkDiscountPercent': bulkDiscountPercent,
      if (description != null) 'description': description,
      'imageUrl': effectivePrimaryImage,
      'images': effectiveImages,
    };

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/api/products',
        data: postData,
      );
      if (response.data != null) {
        final serverProduct = ProductModel.fromJson(response.data!);
        state = state.copyWith(
          products: state.products
              .map((p) => p.id == tempId ? serverProduct : p)
              .toList(),
        );
        _persistCurrentProducts();
        unawaited(refreshFromBackend());
        return serverProduct;
      }
    } catch (_) {
      try {
        final queueStore = ref.read(offlineQueueStoreProvider);
        await queueStore.enqueue(
          OfflineMutation(
            id: 'add_$tempId',
            endpoint: '/api/products',
            method: 'POST',
            payload: postData,
            timestamp: DateTime.now(),
            description: 'ახალი პროდუქტის დამატება: $title',
          ),
        );
      } catch (_) {}
    }

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
        final newMinOrder = minOrderQuantity ?? p.minOrderQuantity;
        final isBelowMin = newStock > 0 && newStock < newMinOrder;
        final isExhausted = newStock <= 0 || isBelowMin;
        final newStatus = newStock <= 0
            ? 'ამოწურულია'
            : isBelowMin
                ? 'მარაგი ამოიწურა'
                : newStock < 20
                    ? 'იწურება'
                    : 'მარაგშია';
        final nextImages = (images != null && images.isNotEmpty)
            ? images
            : (imageUrl != null ? [imageUrl] : p.images);
        final baseAvailable = isAvailable ?? (newStock > 0 ? p.isAvailable : false);
        final effectiveAvailable = baseAvailable && !isExhausted;
        return p.copyWith(
          title: title,
          category: category,
          price: price,
          originalPrice: originalPrice,
          discountPercent: discountPercent,
          unit: unit,
          stockQuantity: newStock,
          stockStatus: newStatus,
          minOrderQuantity: newMinOrder,
          bulkDiscountMinQty: bulkDiscountMinQty,
          bulkDiscountPercent: bulkDiscountPercent,
          isAvailable: effectiveAvailable,
          description: description,
          imageUrl: imageUrl ?? (nextImages.isNotEmpty ? nextImages.first : p.imageUrl),
          images: nextImages,
        );
      }).toList(),
    );

    final patchData = {
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
    };
    _persistCurrentProducts();

    try {
      final api = ref.read(apiClientProvider);
      await api.patch(
        '/api/products/$productId',
        data: patchData,
      );
    } catch (_) {
      try {
        final queueStore = ref.read(offlineQueueStoreProvider);
        await queueStore.enqueue(
          OfflineMutation(
            id: 'update_${productId}_${DateTime.now().millisecondsSinceEpoch}',
            endpoint: '/api/products/$productId',
            method: 'PATCH',
            payload: patchData,
            timestamp: DateTime.now(),
            description: 'პროდუქტის განახლება: $productId',
          ),
        );
      } catch (_) {}
    }
  }

  Future<double?> restockProduct(String productId, double addedQuantity) async {
    final target =
        state.products.where((p) => p.id == productId).firstOrNull;
    if (target == null || addedQuantity <= 0) return null;
    final newTotal = target.stockQuantity + addedQuantity;
    final isAvailable = newTotal >= target.minOrderQuantity && newTotal > 0;
    await updateProduct(
      productId,
      stockQuantity: newTotal,
      isAvailable: isAvailable,
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
        final isAvailable = remaining >= match.minOrderQuantity && remaining > 0;
        await updateProduct(
          match.id,
          stockQuantity: remaining,
          isAvailable: isAvailable,
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
    _persistCurrentProducts();

    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/api/products/$productId');
    } catch (_) {
      try {
        final queueStore = ref.read(offlineQueueStoreProvider);
        await queueStore.enqueue(
          OfflineMutation(
            id: 'delete_${productId}_${DateTime.now().millisecondsSinceEpoch}',
            endpoint: '/api/products/$productId',
            method: 'DELETE',
            payload: const {},
            timestamp: DateTime.now(),
            description: 'პროდუქტის წაშლა: $productId',
          ),
        );
      } catch (_) {}
    }
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

  static FarmerModel _applyDeliverySettingsToFarmer(
    FarmerModel farmer,
    Map<String, dynamic> settings,
  ) {
    final isDeliveryEnabled = settings['isDeliveryEnabled'] as bool?;
    final deliveryCity = settings['deliveryCity'] as String?;
    final deliveryFee = (settings['deliveryFee'] as num?)?.toDouble();
    final isPickupEnabled = settings['isPickupEnabled'] as bool?;
    final location = settings['location'] as String?;

    List<String>? cleanDays;
    if (settings['deliveryDays'] is List) {
      cleanDays = (settings['deliveryDays'] as List)
          .map((e) => normalizeDayName(e.toString()))
          .toSet()
          .toList();
      cleanDays.sort(
        (a, b) => weekdayOrderIndex(a).compareTo(weekdayOrderIndex(b)),
      );
    }

    Map<String, double>? regionalFees;
    if (settings['regionalDeliveryFees'] is Map) {
      regionalFees = (settings['regionalDeliveryFees'] as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
    }

    return farmer.copyWith(
      isDeliveryEnabled: isDeliveryEnabled ?? farmer.isDeliveryEnabled,
      deliveryCity: deliveryCity ?? farmer.deliveryCity,
      deliveryDays: cleanDays ?? farmer.deliveryDays,
      deliveryFee: deliveryFee ?? farmer.deliveryFee,
      regionalDeliveryFees: regionalFees ?? farmer.regionalDeliveryFees,
      isPickupEnabled: isPickupEnabled ?? farmer.isPickupEnabled,
      location: (location != null && location.trim().isNotEmpty)
          ? location.trim()
          : farmer.location,
    );
  }

  Future<void> updateFarmerDeliverySettings({
    required String farmerId,
    required bool isDeliveryEnabled,
    required String deliveryCity,
    required List<String> deliveryDays,
    required double deliveryFee,
    required Map<String, double> regionalDeliveryFees,
    required bool isPickupEnabled,
    String? location,
    bool updateAllDemoFarmers = false,
  }) async {
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
        rating: 0.0,
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

    final payload = <String, dynamic>{
      'isDeliveryEnabled': isDeliveryEnabled,
      'deliveryCity': deliveryCity,
      'deliveryDays': cleanDays,
      'deliveryFee': deliveryFee,
      'regionalDeliveryFees': regionalDeliveryFees,
      'isPickupEnabled': isPickupEnabled,
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
    };

    try {
      if (!ref.mounted) return;
      final storage = ref.read(secureStorageProvider);
      await storage.saveFarmerDeliverySettings(
        farmerId: farmerId,
        settings: payload,
      );
      if (updateAllDemoFarmers) {
        if (!ref.mounted) return;
        await storage.saveFarmerDeliverySettings(
          farmerId: 'farmer_1',
          settings: payload,
        );
        if (!ref.mounted) return;
        await storage.saveFarmerDeliverySettings(
          farmerId: 'farmer_2',
          settings: payload,
        );
      }
    } catch (_) {}

    try {
      if (!ref.mounted) return;
      final auth = ref.read(authStateProvider);
      final api = ref.read(apiClientProvider);
      final targetProfileId = auth.farmerId ?? auth.userId ?? farmerId;
      if (targetProfileId.isNotEmpty) {
        await api.patch('/api/profile/$targetProfileId', data: {
          'isDeliveryEnabled': isDeliveryEnabled,
          'deliveryFee': deliveryFee,
          'city': deliveryCity,
          'deliveryCity': deliveryCity,
          'deliveryDays': cleanDays,
          'regionalDeliveryFees': regionalDeliveryFees,
          if (location != null && location.trim().isNotEmpty)
            'address': location.trim(),
        });
      }
    } catch (_) {}
  }

  void updateFarmerLocation({
    required String farmerId,
    required String location,
  }) {
    final clean = location.trim();
    if (clean.isEmpty) return;

    final exists = state.farmers.any((f) => f.id == farmerId);
    List<FarmerModel> updatedFarmers;
    if (exists) {
      updatedFarmers = state.farmers.map((f) {
        if (f.id == farmerId) {
          return f.copyWith(location: clean);
        }
        return f;
      }).toList();
    } else {
      final newFarmer = FarmerModel(
        id: farmerId,
        farmName: 'ჩემი მეურნეობა',
        farmerName: 'ფერმერი',
        location: clean,
        rating: 0.0,
        reviewCount: 0,
        totalRatings: 0,
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
        coverUrl:
            'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=1000&auto=format&fit=crop&q=80',
        about: 'ნატურალური ქართული პროდუქცია პირდაპირ მეურნეობიდან.',
      );
      updatedFarmers = [...state.farmers, newFarmer];
    }
    state = state.copyWith(farmers: updatedFarmers);
  }

  void updateFarmerNames({
    required String? farmerId,
    String? farmName,
    String? farmerName,
  }) {
    if (farmerId == null || farmerId.isEmpty) return;
    final cleanFarm = farmName?.trim();
    final cleanFarmer = farmerName?.trim();
    if ((cleanFarm == null || cleanFarm.isEmpty) &&
        (cleanFarmer == null || cleanFarmer.isEmpty)) {
      return;
    }

    final updatedFarmers = state.farmers.map((f) {
      if (f.id == farmerId) {
        return f.copyWith(
          farmName: (cleanFarm != null && cleanFarm.isNotEmpty)
              ? cleanFarm
              : f.farmName,
          farmerName: (cleanFarmer != null && cleanFarmer.isNotEmpty)
              ? cleanFarmer
              : f.farmerName,
        );
      }
      return f;
    }).toList();

    final updatedProducts = (cleanFarm != null && cleanFarm.isNotEmpty)
        ? state.products.map((p) {
            if (p.farmerId == farmerId) {
              return p.copyWith(farmerName: cleanFarm);
            }
            return p;
          }).toList()
        : state.products;

    state = state.copyWith(
      farmers: updatedFarmers,
      products: updatedProducts,
    );
  }

  void updateFarmerMedia({
    required String? farmerId,
    String? avatarUrl,
    String? coverUrl,
  }) {
    if (farmerId == null || farmerId.isEmpty) return;
    final cleanAvatar = avatarUrl?.trim();
    final cleanCover = coverUrl?.trim();
    if ((cleanAvatar == null || cleanAvatar.isEmpty) &&
        (cleanCover == null || cleanCover.isEmpty)) {
      return;
    }

    final updatedFarmers = state.farmers.map((f) {
      if (f.id == farmerId) {
        return f.copyWith(
          avatarUrl: (cleanAvatar != null && cleanAvatar.isNotEmpty)
              ? cleanAvatar
              : f.avatarUrl,
          coverUrl: (cleanCover != null && cleanCover.isNotEmpty)
              ? cleanCover
              : f.coverUrl,
        );
      }
      return f;
    }).toList();

    state = state.copyWith(farmers: updatedFarmers);
  }

  /// Updates farmer rating and review count from new reviews
  void updateFarmerRating({
    required String farmerId,
    required double newRating,
    required int newReviewCount,
  }) {
    final updatedFarmers = state.farmers.map((f) {
      if (f.id == farmerId) {
        return f.copyWith(
          rating: newRating,
          reviewCount: newReviewCount,
          totalRatings: newReviewCount,
        );
      }
      return f;
    }).toList();

    final updatedProducts = state.products.map((p) {
      if (p.farmerId == farmerId) {
        return p.copyWith(
          rating: newRating,
          reviewCount: newReviewCount,
        );
      }
      return p;
    }).toList();

    state = state.copyWith(
      farmers: updatedFarmers,
      products: updatedProducts,
    );
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
    if (p.isOutOfStock) return false;
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
