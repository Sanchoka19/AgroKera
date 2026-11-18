import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agrokera/core/network/api_client.dart';
import 'package:agrokera/core/storage/secure_storage_service.dart';
import 'package:agrokera/features/profile/domain/models/user_address_model.dart';

/// Repository for persisting, fetching and syncing delivery/farm addresses.
class AddressRepository {
  final SecureStorageService _storage;
  final ApiClient _api;

  const AddressRepository(this._storage, this._api);

  /// Loads saved addresses from persistent secure storage
  Future<List<UserAddress>> loadAddresses() async {
    try {
      final jsonStr = await _storage.readAddressesJson();
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      final list = decoded
          .map((e) => UserAddress.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Persists list of addresses to secure storage
  Future<void> saveAddresses(List<UserAddress> addresses) async {
    try {
      final encoded = jsonEncode(addresses.map((a) => a.toJson()).toList());
      await _storage.saveAddressesJson(encoded);
    } catch (_) {}
  }

  /// Loads active address string, falling back to default address or empty string
  Future<String> loadActiveAddress() async {
    try {
      final saved = await _storage.readActiveAddress();
      if (saved != null && saved.trim().isNotEmpty) {
        return saved.trim();
      }
      final list = await loadAddresses();
      if (list.isNotEmpty) {
        final def = list.firstWhere((a) => a.isDefault, orElse: () => list.first);
        return def.formattedAddress;
      }
    } catch (_) {}
    return '';
  }

  /// Saves active address string
  Future<void> saveActiveAddress(String address) async {
    try {
      await _storage.saveActiveAddress(address.trim());
    } catch (_) {}
  }

  /// Clears stored delivery addresses from persistent storage
  Future<void> clearAddresses() async {
    await _storage.clearAddresses();
  }

  /// Synchronizes address with the remote backend user profile if authenticated
  Future<void> syncAddressWithBackend({
    required String? userId,
    required String address,
  }) async {
    if (userId == null || userId.isEmpty) return;
    try {
      await _api.patch('/api/profile/$userId', data: {'address': address});
    } catch (_) {
      // Offline fallback: persistent local storage remains authoritative
    }
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(
    ref.watch(secureStorageProvider),
    ref.watch(apiClientProvider),
  );
});
