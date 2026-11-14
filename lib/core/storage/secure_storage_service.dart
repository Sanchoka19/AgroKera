import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistent secure storage for user session, JWT token, and role data
class SecureStorageService {
  static const _tokenKey = 'agrokera_auth_token';
  static const _userIdKey = 'agrokera_user_id';
  static const _farmerIdKey = 'agrokera_farmer_id';
  static const _roleKey = 'agrokera_user_role';
  static const _nameKey = 'agrokera_user_name';
  static const _phoneKey = 'agrokera_user_phone';
  static const _emailKey = 'agrokera_user_email';
  static const _kycStatusKey = 'agrokera_kyc_status';
  static const _cartJsonKey = 'agrokera_cart_json';
  static const _favoritesJsonKey = 'agrokera_favorites_json';

  final FlutterSecureStorage _storage;

  const SecureStorageService([
    this._storage = const FlutterSecureStorage(),
  ]);

  Future<void> saveSession({
    required String token,
    required String userId,
    String? farmerId,
    required String role,
    required String name,
    required String phone,
    String? email,
    String kycStatus = 'VERIFIED',
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _tokenKey, value: token),
        _storage.write(key: _userIdKey, value: userId),
        if (farmerId != null) _storage.write(key: _farmerIdKey, value: farmerId),
        _storage.write(key: _roleKey, value: role),
        _storage.write(key: _nameKey, value: name),
        _storage.write(key: _phoneKey, value: phone),
        if (email != null) _storage.write(key: _emailKey, value: email),
        _storage.write(key: _kycStatusKey, value: kycStatus),
      ]);
    } catch (_) {
      // Ignore platform channel errors in widget tests
    }
  }

  Future<Map<String, String?>> readSession() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _tokenKey),
        _storage.read(key: _userIdKey),
        _storage.read(key: _farmerIdKey),
        _storage.read(key: _roleKey),
        _storage.read(key: _nameKey),
        _storage.read(key: _phoneKey),
        _storage.read(key: _emailKey),
        _storage.read(key: _kycStatusKey),
      ]);
      return {
        'token': results[0],
        'userId': results[1],
        'farmerId': results[2],
        'role': results[3],
        'name': results[4],
        'phone': results[5],
        'email': results[6],
        'kycStatus': results[7],
      };
    } catch (_) {
      return {};
    }
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateKycStatus(String status) async {
    try {
      await _storage.write(key: _kycStatusKey, value: status);
    } catch (_) {}
  }

  Future<void> clearSession() async {
    try {
      await Future.wait([
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _farmerIdKey),
        _storage.delete(key: _roleKey),
        _storage.delete(key: _nameKey),
        _storage.delete(key: _phoneKey),
        _storage.delete(key: _emailKey),
        _storage.delete(key: _kycStatusKey),
      ]);
    } catch (_) {}
  }

  Future<void> saveCartJson(String json) async {
    try {
      await _storage.write(key: _cartJsonKey, value: json);
    } catch (_) {}
  }

  Future<String?> readCartJson() async {
    try {
      return await _storage.read(key: _cartJsonKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFavoritesJson(String json) async {
    try {
      await _storage.write(key: _favoritesJsonKey, value: json);
    } catch (_) {}
  }

  Future<String?> readFavoritesJson() async {
    try {
      return await _storage.read(key: _favoritesJsonKey);
    } catch (_) {
      return null;
    }
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService();
});

