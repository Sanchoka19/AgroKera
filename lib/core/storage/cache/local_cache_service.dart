import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../network/api_client.dart';
import '../secure_storage_service.dart';

/// Modular, isolated caching service for offline entities.
///
/// Ensures offline reads are instant (Single Source of Truth)
/// without network bottlenecks or spinners on cold start.
class LocalCacheService {
  final SecureStorageService _storage;
  final Map<String, String> _memoryCache = {};

  static const String productsKey = 'agrokera_cache_products';
  static const String farmersKey = 'agrokera_cache_farmers';
  static const String ordersKey = 'agrokera_cache_orders';

  LocalCacheService(this._storage);

  /// Saves a list of JSON-serializable models under [cacheKey]
  Future<void> saveEntityList(
    String cacheKey,
    List<Map<String, dynamic>> items,
  ) async {
    final encoded = jsonEncode(items);
    _memoryCache[cacheKey] = encoded;
    await _writeRaw(cacheKey, encoded);
  }

  /// Reads a cached list of JSON-serializable models from [cacheKey]
  Future<List<Map<String, dynamic>>?> readEntityList(String cacheKey) async {
    final raw = await _readRaw(cacheKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Updates or inserts a single entity inside a cached list identified by [idKey]
  Future<void> upsertEntityInList(
    String cacheKey,
    Map<String, dynamic> item, {
    String idKey = 'id',
  }) async {
    final list = await readEntityList(cacheKey) ?? [];
    final id = item[idKey];
    final index = list.indexWhere((e) => e[idKey] == id);
    if (index >= 0) {
      list[index] = item;
    } else {
      list.insert(0, item);
    }
    await saveEntityList(cacheKey, list);
  }

  /// Removes a single entity from a cached list by [id]
  Future<void> removeEntityFromList(
    String cacheKey,
    dynamic id, {
    String idKey = 'id',
  }) async {
    final list = await readEntityList(cacheKey);
    if (list == null || list.isEmpty) return;
    list.removeWhere((e) => e[idKey] == id);
    await saveEntityList(cacheKey, list);
  }

  /// Clears a cached entity bucket
  Future<void> clear(String cacheKey) async {
    _memoryCache.remove(cacheKey);
    await _deleteRaw(cacheKey);
  }

  // --- Internal key-value persistence ---

  Future<void> _writeRaw(String key, String value) async {
    _memoryCache[key] = value;
    if (isFlutterTestEnv) return;
    // Persist via secure storage with cache prefix
    await _storage.saveGenericString('cache_$key', value);
  }

  Future<String?> _readRaw(String key) async {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    if (isFlutterTestEnv) return null;
    final value = await _storage.readGenericString('cache_$key');
    if (value != null) {
      _memoryCache[key] = value;
    }
    return value;
  }

  Future<void> _deleteRaw(String key) async {
    _memoryCache.remove(key);
    if (isFlutterTestEnv) return;
    await _storage.deleteGenericString('cache_$key');
  }
}

/// Riverpod provider for LocalCacheService
final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return LocalCacheService(storage);
});
