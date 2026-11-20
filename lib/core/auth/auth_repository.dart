import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../network/api_client.dart';
import 'auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

/// Thin remote data source for authentication & profile endpoints.
///
/// Methods throw on network/server errors; callers decide on offline fallbacks.
class AuthRepository {
  final ApiClient _api;

  const AuthRepository(this._api);

  Future<Map<String, dynamic>?> login({
    required String name,
    String? phone,
    required String email,
    String? password,
    bool? isGoogleAuth,
    String? farmName,
    required UserRole role,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {
        'name': name,
        'phone': ?phone,
        'email': email,
        'password': ?password,
        'isGoogleAuth': ?isGoogleAuth,
        'farmName': ?farmName,
        'role': role.apiValue,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>?> register({
    required String name,
    String? phone,
    required String email,
    String? password,
    String? farmName,
    String? region,
    String? city,
    String? address,
    String? coverUrl,
    required UserRole role,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'fullName': name,
        'phoneNumber': ?phone,
        'email': email,
        'password': ?password,
        'farmName': ?farmName,
        'region': ?region,
        'city': ?city,
        'address': ?address,
        'coverUrl': ?coverUrl,
        'role': role.apiValue,
      },
    );
    return response.data;
  }

  Future<void> sendEmailOtp(String email) async {
    await _api.post('/api/auth/send-otp', data: {'email': email.trim()});
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    await _api.post('/api/auth/verify-otp', data: {
      'email': email.trim(),
      'code': code.trim(),
    });
  }

  Future<void> syncFcmToken({
    required String userId,
    required String fcmToken,
  }) async {
    if (isFlutterTestEnv) return;
    try {
      await _api.post('/api/users/fcm-token', data: {
        'userId': userId,
        'fcmToken': fcmToken,
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/api/profile/$userId',
    );
    return response.data;
  }

  Future<void> patchProfile(String userId, Map<String, dynamic> data) async {
    await _api.patch('/api/profile/$userId', data: data);
  }

  /// Uploads an image as base64 and returns the remote URL (if any).
  Future<String?> uploadImage(XFile file, {required String folder}) async {
    final bytes = await file.readAsBytes();
    final response = await _api.post<Map<String, dynamic>>(
      '/api/upload',
      data: {
        'fileName': file.name,
        'base64Data': base64Encode(bytes),
        'contentType': 'image/jpeg',
        'folder': folder,
      },
    );
    final url = response.data?['url'] as String?;
    return (url != null && url.isNotEmpty) ? url : null;
  }
}

