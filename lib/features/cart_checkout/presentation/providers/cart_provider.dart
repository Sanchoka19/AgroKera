import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cart_item_model.dart';

class CartNotifier extends Notifier<List<CartItemModel>> {
  @override
  List<CartItemModel> build() {
    return _sampleItems;
  }

  static const List<CartItemModel> _sampleItems = [
    CartItemModel(
      id: 'cart_1',
      title: 'ვარდისფერი პომიდორი',
      packageText: '10კგ პატარა ყუთი',
      farmerName: 'ფერმა: მწვანე ველი',
      pricePerUnit: 10.00,
      unit: 'კგ',
      imageUrl:
          'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=500&auto=format&fit=crop&q=80',
      quantity: 5,
      weightKg: 2.0,
    ),
    CartItemModel(
      id: 'cart_2',
      title: 'ადიგენის კარტოფილი',
      packageText: 'სუფთა მოსავალი',
      farmerName: 'ფერმა: მწვანე ველი',
      pricePerUnit: 1.50,
      unit: 'კგ',
      imageUrl:
          'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500&auto=format&fit=crop&q=80',
      quantity: 10,
      weightKg: 1.8,
    ),
  ];

  void addItem(CartItemModel newItem) {
    final existingIndex = state.indexWhere((item) => item.id == newItem.id);
    if (existingIndex != -1) {
      final existing = state[existingIndex];
      final updated = existing.copyWith(quantity: existing.quantity + newItem.quantity);
      final list = List<CartItemModel>.from(state);
      list[existingIndex] = updated;
      state = list;
    } else {
      state = [...state, newItem];
    }
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
  }

  void increment(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();
  }

  void decrement(String id) {
    state = state.map((item) {
      if (item.id == id) {
        final newQty = item.quantity - 1;
        if (newQty <= 0) return null;
        return item.copyWith(quantity: newQty);
      }
      return item;
    }).whereType<CartItemModel>().toList();
  }

  void clearCart() {
    state = [];
  }

  void restoreSampleItems() {
    state = _sampleItems;
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
