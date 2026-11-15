import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../marketplace/data/models/product_model.dart';
import '../../data/models/cart_item_model.dart';

sealed class AddToCartResult {
  const AddToCartResult();
}

class AddToCartSuccess extends AddToCartResult {
  final int requestedQuantity;
  final int addedQuantity;
  final int totalInCart;
  final int maxStock;
  bool get isCapped => addedQuantity < requestedQuantity;

  const AddToCartSuccess({
    required this.requestedQuantity,
    required this.addedQuantity,
    required this.totalInCart,
    required this.maxStock,
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

  /// Clean Domain action to add a product to the cart with stock and limit enforcement.
  AddToCartResult addProduct(ProductModel product, int quantity) {
    final auth = ref.read(authStateProvider);
    if (auth.isOwnerOfProduct(product)) {
      return const AddToCartOwnerForbidden();
    }

    if (!product.isAvailable || product.stockQuantity <= 0) {
      return const AddToCartOutOfStock();
    }

    final maxStock = product.stockQuantity.toInt();
    final existingIndex = state.indexWhere((item) => item.id == product.id);
    final currentInCart =
        existingIndex != -1 ? state[existingIndex].quantity : 0;

    if (currentInCart >= maxStock) {
      return AddToCartAlreadyMax(maxStock);
    }

    final targetTotal = currentInCart + quantity;
    final clampedTotal = targetTotal.clamp(1, maxStock);
    final actuallyAdded = clampedTotal - currentInCart;

    if (actuallyAdded <= 0) {
      return AddToCartAlreadyMax(maxStock);
    }

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
      weightKg: clampedTotal.toDouble(),
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

  int addItem(CartItemModel newItem) {
    final auth = ref.read(authStateProvider);
    if (auth.isOwnerOfCartItem(newItem)) {
      return 0;
    }
    final existingIndex = state.indexWhere((item) => item.id == newItem.id);
    final maxAvailable = newItem.stockQuantity.toInt().clamp(1, 99999);
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
      final clampedQty = newItem.quantity.clamp(1, maxAvailable);
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

extension CartListX on List<CartItemModel> {
  double get subtotal => fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalWeight => fold(0.0, (sum, item) => sum + (item.weightKg * item.quantity));
  int get totalItemCount => fold(0, (sum, item) => sum + item.quantity);
  bool get isMinimumMet => subtotal >= 30.0;
  
  double get deliveryFee => subtotal >= 150.0 || isEmpty ? 0.0 : 10.0;
  double get heavyFee => totalWeight > 25.0 ? 5.0 : 0.0;
  double get platformFee => isEmpty ? 0.0 : 10.0;
  double get grandTotal => subtotal + deliveryFee + heavyFee + platformFee;
}

