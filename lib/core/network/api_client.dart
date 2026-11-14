import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';

/// Resolves the appropriate API Base URL depending on host platform
String resolveDefaultApiBaseUrl() {
  const envUrl = String.fromEnvironment('AGROKERA_API_URL');
  if (envUrl.isNotEmpty) return envUrl;
  if (kIsWeb) return 'http://localhost:3001';
  try {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001';
    }
  } catch (_) {}
  return 'http://localhost:3001';
}

bool get _isFlutterTestEnv {
  if (kIsWeb) return false;
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

/// Core Dio HTTP Client connected to the AgroKera Neon API
class ApiClient {
  final Dio _dio;
  final SecureStorageService storage;
  final bool _hasCustomDio;

  ApiClient({
    required this.storage,
    Dio? dio,
  })  : _hasCustomDio = dio != null,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: resolveDefaultApiBaseUrl(),
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 8),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_isFlutterTestEnv && !_hasCustomDio) {
            return handler.reject(
              DioException(
                requestOptions: options,
                message: 'Skipped live network call in widget test environment',
              ),
            );
          }
          final token = await storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Never _throwInTestEnv(String path) {
    throw DioException(
      requestOptions: RequestOptions(path: path),
      message: 'Skipped live network call in widget test environment',
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (_isFlutterTestEnv && !_hasCustomDio) _throwInTestEnv(path);
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
  }) async {
    if (_isFlutterTestEnv && !_hasCustomDio) _throwInTestEnv(path);
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
  }) async {
    if (_isFlutterTestEnv && !_hasCustomDio) _throwInTestEnv(path);
    return _dio.patch<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) async {
    if (_isFlutterTestEnv && !_hasCustomDio) _throwInTestEnv(path);
    return _dio.delete<T>(path);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage: storage);
});
