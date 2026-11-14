import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    unawaited(Future.microtask(restoreFavorites));
    return {'p1', 'p3'};
  }

  Future<void> restoreFavorites() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.readFavoritesJson();
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        state = decoded.map((e) => e.toString()).toSet();
      }
    } catch (_) {}
  }

  void _persistFavorites() {
    final jsonStr = jsonEncode(state.toList());
    unawaited(ref.read(secureStorageProvider).saveFavoritesJson(jsonStr));
  }

  void toggle(String productId) {
    if (state.contains(productId)) {
      final updated = Set<String>.from(state)..remove(productId);
      state = updated;
    } else {
      final updated = Set<String>.from(state)..add(productId);
      state = updated;
    }
    _persistFavorites();
  }

  bool isFavorite(String productId) => state.contains(productId);

  void clear() {
    state = {};
    _persistFavorites();
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

