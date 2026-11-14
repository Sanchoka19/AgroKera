import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return {'p1', 'p3'};
  }

  void toggle(String productId) {
    if (state.contains(productId)) {
      final updated = Set<String>.from(state)..remove(productId);
      state = updated;
    } else {
      final updated = Set<String>.from(state)..add(productId);
      state = updated;
    }
  }

  bool isFavorite(String productId) => state.contains(productId);

  void clear() {
    state = {};
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

