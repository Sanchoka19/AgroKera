import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';

/// Persistent secure storage for user session, JWT token, and role data
class SecureStorageService {
  static final Map<String, String> _testMemoryStore = {};
  static const _tokenKey = 'agrokera_auth_token';
  static const _userIdKey = 'agrokera_user_id';
  static const _farmerIdKey = 'agrokera_farmer_id';
  static const _farmNameKey = 'agrokera_farm_name';
  static const _farmCoverKey = 'agrokera_farm_cover';
  static const _userAvatarKey = 'agrokera_user_avatar';
  static const _roleKey = 'agrokera_user_role';
  static const _nameKey = 'agrokera_user_name';
  static const _phoneKey = 'agrokera_user_phone';
  static const _emailKey = 'agrokera_user_email';
  static const _kycStatusKey = 'agrokera_kyc_status';
  static const _cartJsonKey = 'agrokera_cart_json';
  static const _favoritesJsonKey = 'agrokera_favorites_json';
  static const _reportedPaymentOrdersKey = 'agrokera_reported_payment_orders';
  static const _activeAddressKey = 'agrokera_active_address';
  static const _farmLocationKey = 'agrokera_farm_location';
  static const _farmLandmarkKey = 'agrokera_farm_landmark';
  static const _addressesJsonKey = 'agrokera_addresses_json';
  static const _notificationSettingsKey = 'agrokera_notification_settings_json';

  final FlutterSecureStorage _storage;

  const SecureStorageService([
    this._storage = const FlutterSecureStorage(),
  ]);

  Future<void> _write(String key, String value) async {
    if (isFlutterTestEnv) {
      _testMemoryStore[key] = value;
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<String?> _read(String key) async {
    if (isFlutterTestEnv) {
      return _testMemoryStore[key];
    }
    return await _storage.read(key: key);
  }

  Future<void> _delete(String key) async {
    if (isFlutterTestEnv) {
      _testMemoryStore.remove(key);
      return;
    }
    await _storage.delete(key: key);
  }

  Future<void> saveSession({
    required String token,
    required String userId,
    String? farmerId,
    String? farmName,
    String? farmCoverUrl,
    String? userAvatarUrl,
    required String role,
    required String name,
    required String phone,
    String? email,
    String kycStatus = 'VERIFIED',
  }) async {
    try {
      await Future.wait([
        _write(_tokenKey, token),
        _write(_userIdKey, userId),
        if (farmerId != null)
          _write(_farmerIdKey, farmerId)
        else
          _delete(_farmerIdKey),
        if (farmName != null)
          _write(_farmNameKey, farmName)
        else
          _delete(_farmNameKey),
        if (farmCoverUrl != null)
          _write(_farmCoverKey, farmCoverUrl)
        else
          _delete(_farmCoverKey),
        if (userAvatarUrl != null)
          _write(_userAvatarKey, userAvatarUrl)
        else
          _delete(_userAvatarKey),
        _write(_roleKey, role),
        _write(_nameKey, name),
        _write(_phoneKey, phone),
        if (email != null) _write(_emailKey, email),
        _write(_kycStatusKey, kycStatus),
      ]);
    } catch (_) {
      // Ignore platform channel errors in widget tests
    }
  }

  Future<Map<String, String?>> readSession() async {
    try {
      final results = await Future.wait([
        _read(_tokenKey),
        _read(_userIdKey),
        _read(_farmerIdKey),
        _read(_roleKey),
        _read(_nameKey),
        _read(_phoneKey),
        _read(_emailKey),
        _read(_kycStatusKey),
        _read(_farmNameKey),
        _read(_farmCoverKey),
        _read(_userAvatarKey),
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
        'farmName': results[8],
        'farmCoverUrl': results[9],
        'userAvatarUrl': results[10],
      };
    } catch (_) {
      return {};
    }
  }

  Future<String?> getToken() async {
    try {
      return await _read(_tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateKycStatus(String status) async {
    try {
      await _write(_kycStatusKey, status);
    } catch (_) {}
  }

  Future<void> clearSession() async {
    try {
      await Future.wait([
        _delete(_tokenKey),
        _delete(_userIdKey),
        _delete(_farmerIdKey),
        _delete(_farmNameKey),
        _delete(_farmCoverKey),
        _delete(_userAvatarKey),
        _delete(_roleKey),
        _delete(_nameKey),
        _delete(_phoneKey),
        _delete(_emailKey),
        _delete(_kycStatusKey),
        _delete(_activeAddressKey),
        _delete(_addressesJsonKey),
      ]);
    } catch (_) {}
  }

  Future<void> saveCartJson(String json) async {
    try {
      await _write(_cartJsonKey, json);
    } catch (_) {}
  }

  Future<String?> readCartJson() async {
    try {
      return await _read(_cartJsonKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFavoritesJson(String json) async {
    try {
      await _write(_favoritesJsonKey, json);
    } catch (_) {}
  }

  Future<String?> readFavoritesJson() async {
    try {
      return await _read(_favoritesJsonKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveReportedPaymentOrderIds(Set<String> ids) async {
    try {
      await _write(
        _reportedPaymentOrdersKey,
        ids.join(','),
      );
    } catch (_) {}
  }

  Future<Set<String>> readReportedPaymentOrderIds() async {
    try {
      final raw = await _read(_reportedPaymentOrdersKey);
      if (raw == null || raw.trim().isEmpty) return {};
      return raw.split(',').where((id) => id.trim().isNotEmpty).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> saveOrderMessagesJson(String orderId, String json) async {
    try {
      await _write(
        'agrokera_order_chat_$orderId',
        json,
      );
    } catch (_) {}
  }

  Future<String?> readOrderMessagesJson(String orderId) async {
    try {
      return await _read('agrokera_order_chat_$orderId');
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveAddress(String address) async {
    try {
      await _write(_activeAddressKey, address);
    } catch (_) {}
  }

  Future<String?> readActiveAddress() async {
    try {
      return await _read(_activeAddressKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFarmLocation(String location) async {
    try {
      await _write(_farmLocationKey, location);
    } catch (_) {}
  }

  Future<String?> readFarmLocation() async {
    try {
      return await _read(_farmLocationKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFarmLandmark(String landmark) async {
    try {
      await _write(_farmLandmarkKey, landmark);
    } catch (_) {}
  }

  Future<String?> readFarmLandmark() async {
    try {
      return await _read(_farmLandmarkKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAddressesJson(String json) async {
    try {
      await _write(_addressesJsonKey, json);
    } catch (_) {}
  }

  Future<String?> readAddressesJson() async {
    try {
      return await _read(_addressesJsonKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveNotificationSettingsJson(String json) async {
    try {
      await _write(_notificationSettingsKey, json);
    } catch (_) {}
  }

  Future<String?> readNotificationSettingsJson() async {
    try {
      return await _read(_notificationSettingsKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAddresses() async {
    try {
      await Future.wait([
        _delete(_activeAddressKey),
        _delete(_addressesJsonKey),
      ]);
    } catch (_) {}
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService();
});

