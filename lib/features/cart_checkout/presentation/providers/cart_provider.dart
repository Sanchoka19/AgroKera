import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../marketplace/data/models/farmer_model.dart';
import '../../../marketplace/data/models/product_model.dart';
import '../../../marketplace/presentation/providers/marketplace_provider.dart';
import '../../data/models/cart_item_model.dart';

sealed class AddToCartResult {
  const AddToCartResult();
}

class AddToCartSuccess extends AddToCartResult {
  final int requestedQuantity;
  final int addedQuantity;
  final int totalInCart;
  final int maxStock;
  final bool minOrderAdjusted;
  final int? remainingForBulkDiscount;
  final int? bulkDiscountPercent;
  final bool bulkDiscountApplied;

  bool get isCapped => addedQuantity < requestedQuantity && !minOrderAdjusted;
  bool get hasBulkUpsell =>
      !bulkDiscountApplied &&
      remainingForBulkDiscount != null &&
      remainingForBulkDiscount! > 0 &&
      bulkDiscountPercent != null;

  const AddToCartSuccess({
    required this.requestedQuantity,
    required this.addedQuantity,
    required this.totalInCart,
    required this.maxStock,
    this.minOrderAdjusted = false,
    this.remainingForBulkDiscount,
    this.bulkDiscountPercent,
    this.bulkDiscountApplied = false,
  });
}

class AddToCartDifferentFarmer extends AddToCartResult {
  final String currentFarmerName;
  final String newFarmerName;
  final ProductModel product;
  final int quantity;

  const AddToCartDifferentFarmer({
    required this.currentFarmerName,
    required this.newFarmerName,
    required this.product,
    required this.quantity,
  });
}

class AddToCartAlreadyMax extends AddToCartResult {
  final int maxStock;
  const AddToCartAlreadyMax(this.maxStock);
}

class AddToCartOutOfStock extends AddToCartResult {
  const AddToCartOutOfStock();
}

class AddToCartOwnerForbidden extends AddToCartResult {
  const AddToCartOwnerForbidden();
}

sealed class CartValidationResult {
  const CartValidationResult();
}

class CartValidationValid extends CartValidationResult {
  const CartValidationValid();
}

class CartValidationContainsOwnProduct extends CartValidationResult {
  final String productTitle;
  const CartValidationContainsOwnProduct(this.productTitle);
}

class CartValidationOutOfStock extends CartValidationResult {
  final String productTitle;
  const CartValidationOutOfStock(this.productTitle);
}

class CartValidationExceedsStock extends CartValidationResult {
  final String productTitle;
  final int availableStock;
  final String unit;

  const CartValidationExceedsStock({
    required this.productTitle,
    required this.availableStock,
    required this.unit,
  });
}

/// Domain ownership check extension for cart items
extension AuthStateCartOwnership on AuthState {
  bool isOwnerOfCartItem(CartItemModel item) {
    return isOwner(
      farmerId: item.farmerId,
      farmName: item.farmerName,
      farmerName: item.farmerName,
    );
  }
}

class CartNotifier extends Notifier<List<CartItemModel>> {
  @override
  List<CartItemModel> build() {
    unawaited(Future.microtask(restoreCart));
    return const [];
  }

  Future<void> restoreCart() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.readCartJson();
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        state = decoded
            .whereType<Map>()
            .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
  }

  void _persistCart() {
    final jsonStr = jsonEncode(state.map((e) => e.toJson()).toList());
    unawaited(ref.read(secureStorageProvider).saveCartJson(jsonStr));
  }

  /// Clean Domain action to add a product to the cart with single-farmer enforcement,
  /// stock, minimum order quantity, and bulk discount logic.
  AddToCartResult addProduct(
    ProductModel product,
    int quantity, {
    bool forceReplaceFarmer = false,
  }) {
    final auth = ref.read(authStateProvider);
    if (auth.isOwnerOfProduct(product)) {
      return const AddToCartOwnerForbidden();
    }

    if (!product.isAvailable || product.stockQuantity <= 0) {
      return const AddToCartOutOfStock();
    }

    // 1. Single-Vendor Cart constraint (Wolt / Glovo model)
    if (state.isNotEmpty) {
      final firstItem = state.first;
      final isDifferentFarmer = (firstItem.farmerId != null &&
              product.farmerId.isNotEmpty &&
              firstItem.farmerId != product.farmerId) ||
          (firstItem.farmerName.isNotEmpty &&
              product.farmerName.isNotEmpty &&
              firstItem.farmerName != product.farmerName);

      if (isDifferentFarmer) {
        if (!forceReplaceFarmer) {
          return AddToCartDifferentFarmer(
            currentFarmerName: firstItem.farmerName.isNotEmpty
                ? firstItem.farmerName
                : 'სხვა მეურნეობა',
            newFarmerName: product.farmerName.isNotEmpty
                ? product.farmerName
                : 'ახალი მეურნეობა',
            product: product,
            quantity: quantity,
          );
        } else {
          // Clear cart for the new farmer
          state = [];
        }
      }
    }

    final maxStock = product.stockQuantity.toInt();
    final existingIndex = state.indexWhere((item) => item.id == product.id);
    final currentInCart =
        existingIndex != -1 ? state[existingIndex].quantity : 0;

    if (currentInCart >= maxStock) {
      return AddToCartAlreadyMax(maxStock);
    }

    // 3. Minimum order quantity enforcement
    final minLimit = product.minOrderQuantity.toInt().clamp(1, 99999);
    bool minOrderAdjusted = false;
    int effectiveAddQuantity = quantity;

    if (currentInCart == 0 && effectiveAddQuantity < minLimit) {
      effectiveAddQuantity = minLimit;
      minOrderAdjusted = true;
    }

    final targetTotal = currentInCart + effectiveAddQuantity;
    final clampedTotal = targetTotal.clamp(minLimit, maxStock);
    final actuallyAdded = clampedTotal - currentInCart;

    if (actuallyAdded <= 0) {
      return AddToCartAlreadyMax(maxStock);
    }

    // 4. Bulk discount calculation
    int? remainingForBulk;
    int? bulkPercent;
    bool bulkApplied = false;

    if (product.hasBulkDiscount) {
      final bulkMin = product.bulkDiscountMinQty!.toInt();
      bulkPercent = product.bulkDiscountPercent;
      if (clampedTotal >= bulkMin) {
        bulkApplied = true;
      } else {
        remainingForBulk = bulkMin - clampedTotal;
      }
    }

    // 2. Unit logistics weight based on packaging/measurement unit
    final unitWeight = CartItemModel.resolveDefaultUnitWeight(product.unit);

    final cartItem = CartItemModel(
      id: product.id,
      title: product.title,
      packageText: '${product.unit} შეფუთვა',
      farmerName: product.farmerName,
      farmerId: product.farmerId,
      pricePerUnit: product.price,
      unit: product.unit,
      imageUrl: product.imageUrl,
      quantity: clampedTotal,
      weightKg: unitWeight,
      minOrderQuantity: product.minOrderQuantity,
      stockQuantity: product.stockQuantity,
      bulkDiscountMinQty: product.bulkDiscountMinQty,
      bulkDiscountPercent: product.bulkDiscountPercent,
    );

    if (existingIndex != -1) {
      final list = List<CartItemModel>.from(state);
      list[existingIndex] = cartItem;
      state = list;
    } else {
      state = [...state, cartItem];
    }
    _persistCart();

    return AddToCartSuccess(
      requestedQuantity: quantity,
      addedQuantity: actuallyAdded,
      totalInCart: clampedTotal,
      maxStock: maxStock,
      minOrderAdjusted: minOrderAdjusted,
      remainingForBulkDiscount: remainingForBulk,
      bulkDiscountPercent: bulkPercent,
      bulkDiscountApplied: bulkApplied,
    );
  }

  /// Validates cart items against current real-time marketplace inventory.
  /// Automatically clamps cart quantities to available stock if needed.
  CartValidationResult validateAndSyncStock(List<ProductModel> products) {
    final auth = ref.read(authStateProvider);
    for (final item in state) {
      if (auth.isOwnerOfCartItem(item)) {
        return CartValidationContainsOwnProduct(item.title);
      }
      final product = products.where((p) => p.id == item.id).firstOrNull;
      if (product != null) {
        if (!product.isAvailable || product.stockQuantity <= 0) {
          return CartValidationOutOfStock(item.title);
        }
        if (item.quantity > product.stockQuantity) {
          updateQuantity(item.id, product.stockQuantity.toInt());
          return CartValidationExceedsStock(
            productTitle: item.title,
            availableStock: product.stockQuantity.toInt(),
            unit: item.unit,
          );
        }
      }
    }
    return const CartValidationValid();
  }

  /// Consolidates item addition, respecting ownership, single-farmer policy, and bounds.
  int addItem(CartItemModel newItem, {bool forceReplaceFarmer = false}) {
    final auth = ref.read(authStateProvider);
    if (auth.isOwnerOfCartItem(newItem)) {
      return 0;
    }

    // Single-Farmer check
    if (state.isNotEmpty) {
      final firstItem = state.first;
      final isDifferentFarmer = (firstItem.farmerId != null &&
              newItem.farmerId != null &&
              firstItem.farmerId != newItem.farmerId) ||
          (firstItem.farmerName.isNotEmpty &&
              newItem.farmerName.isNotEmpty &&
              firstItem.farmerName != newItem.farmerName);

      if (isDifferentFarmer) {
        if (!forceReplaceFarmer) {
          return 0;
        } else {
          state = [];
        }
      }
    }

    final existingIndex = state.indexWhere((item) => item.id == newItem.id);
    final minLimit = newItem.minOrderQuantity.toInt().clamp(1, 99999);
    final maxAvailable = newItem.stockQuantity.toInt().clamp(minLimit, 99999);

    if (existingIndex != -1) {
      final existing = state[existingIndex];
      final targetQty = existing.quantity + newItem.quantity;
      final clampedQty = targetQty.clamp(1, maxAvailable);
      final added = clampedQty - existing.quantity;
      if (added <= 0) {
        return 0;
      }
      final updated = existing.copyWith(
        quantity: clampedQty,
        stockQuantity: newItem.stockQuantity,
      );
      final list = List<CartItemModel>.from(state);
      list[existingIndex] = updated;
      state = list;
      _persistCart();
      return added;
    } else {
      final effectiveQuantity =
          newItem.quantity < minLimit ? minLimit : newItem.quantity;
      final clampedQty = effectiveQuantity.clamp(minLimit, maxAvailable);
      state = [...state, newItem.copyWith(quantity: clampedQty)];
      _persistCart();
      return clampedQty;
    }
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _persistCart();
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    state = state.map((item) {
      if (item.id == id) {
        final minLimit = item.minOrderQuantity.toInt().clamp(1, 99999);
        final maxLimit = item.stockQuantity.toInt().clamp(minLimit, 99999);
        final clamped = quantity.clamp(minLimit, maxLimit);
        return item.copyWith(quantity: clamped);
      }
      return item;
    }).toList();
    _persistCart();
  }

  bool increment(String id) {
    bool incremented = false;
    state = state.map((item) {
      if (item.id == id) {
        final maxLimit = item.stockQuantity.toInt().clamp(1, 99999);
        if (item.quantity >= maxLimit) {
          return item;
        }
        incremented = true;
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();
    if (incremented) {
      _persistCart();
    }
    return incremented;
  }

  void decrement(String id) {
    state = state.map((item) {
      if (item.id == id) {
        final minLimit = item.minOrderQuantity.toInt().clamp(1, 99999);
        if (item.quantity <= minLimit) {
          return item;
        }
        final newQty = item.quantity - 1;
        return item.copyWith(quantity: newQty);
      }
      return item;
    }).toList();
    _persistCart();
  }

  void clearCart() {
    state = [];
    _persistCart();
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItemModel>>(
  CartNotifier.new,
);

/// Provider to retrieve the FarmerModel associated with current items in Single-Vendor Cart
final cartFarmerProvider = Provider<FarmerModel?>((ref) {
  final cart = ref.watch(cartProvider);
  if (cart.isEmpty) return null;
  final first = cart.first;
  final marketplace = ref.watch(marketplaceProvider);
  for (final f in marketplace.farmers) {
    if (first.farmerId != null && f.id == first.farmerId) return f;
    if (f.farmerName == first.farmerName || f.farmName == first.farmerName) {
      return f;
    }
  }
  return marketplace.farmers.isNotEmpty ? marketplace.farmers.first : null;
});

/// Logistics delivery vehicle category determined by cart total logistics weight
enum DeliveryVehicleType {
  standardCourier, // <= 20 kg (მოპედი / მსუბუქი კურიერი) -> 0 ₾
  passengerCar,    // 20.01 - 60 kg (მსუბუქი ავტომობილი) -> +8 ₾
  cargoVan,        // 60.01 - 250 kg (სატვირთო / მინივენი) -> +45 ₾
  exceededLimit,   // > 250 kg (საკურიერო მიტანის ლიმიტი გადაჭარბებულია)
}

extension CartListX on List<CartItemModel> {
  static const double standardWeightLimit = 20.0;
  static const double carWeightLimit = 60.0;
  static const double maxDeliveryWeightLimit = 250.0;

  double get subtotal => fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalWeight => fold(0.0, (sum, item) => sum + item.totalWeight);
  int get totalItemCount => fold(0, (sum, item) => sum + item.quantity);
  bool get isMinimumMet => subtotal >= 30.0;
  
  DeliveryVehicleType get vehicleType {
    if (totalWeight > maxDeliveryWeightLimit) return DeliveryVehicleType.exceededLimit;
    if (totalWeight > carWeightLimit) return DeliveryVehicleType.cargoVan;
    if (totalWeight > standardWeightLimit) return DeliveryVehicleType.passengerCar;
    return DeliveryVehicleType.standardCourier;
  }

  bool get isWeightLimitExceeded => vehicleType == DeliveryVehicleType.exceededLimit;

  bool get isHeavyOrder =>
      vehicleType == DeliveryVehicleType.passengerCar ||
      vehicleType == DeliveryVehicleType.cargoVan;

  String get vehicleLabel {
    switch (vehicleType) {
      case DeliveryVehicleType.standardCourier:
        return 'სტანდარტული კურიერი';
      case DeliveryVehicleType.passengerCar:
        return 'მსუბუქი ავტომობილი';
      case DeliveryVehicleType.cargoVan:
        return 'სატვირთო / მინივენი';
      case DeliveryVehicleType.exceededLimit:
        return 'ლიმიტი გადაჭარბებულია';
    }
  }

  double get deliveryFee => subtotal >= 150.0 || isEmpty ? 0.0 : 10.0;

  double get heavyFee {
    if (isEmpty) return 0.0;
    switch (vehicleType) {
      case DeliveryVehicleType.standardCourier:
        return 0.0;
      case DeliveryVehicleType.passengerCar:
        return 8.0;
      case DeliveryVehicleType.cargoVan:
        return 45.0;
      case DeliveryVehicleType.exceededLimit:
        return 0.0;
    }
  }

  double get platformFee => isEmpty ? 0.0 : 10.0;
  double get grandTotal => subtotal + deliveryFee + heavyFee + platformFee;

  /// Calculates dynamic delivery fee based on the farmer and delivery region
  double deliveryFeeForFarmer(FarmerModel? farmer, {String? regionCity}) {
    if (isEmpty) return 0.0;
    if (subtotal >= 150.0) return 0.0;
    if (farmer != null) {
      if (!farmer.isDeliveryEnabled) return 0.0;
      if (regionCity != null) {
        final lower = regionCity.toLowerCase();
        for (final entry in farmer.regionalDeliveryFees.entries) {
          if (lower.contains(entry.key.toLowerCase())) {
            return entry.value;
          }
        }
      }
      return farmer.deliveryFee;
    }
    return deliveryFee;
  }
}

