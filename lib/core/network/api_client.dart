import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movil_architect/core/storage/secure_storage_service.dart';
import 'package:movil_architect/core/storage/settings_storage.dart';

class ApiClient {
  ApiClient({
    required SettingsStorage settingsStorage,
    required SecureStorageService secureStorage,
    Dio? dio,
  })  : _settingsStorage = settingsStorage,
        _secureStorage = secureStorage,
        _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(minutes: 3)
      ..sendTimeout = const Duration(minutes: 3)
      ..headers = {'Accept': 'application/json'};

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _secureStorage.clearToken();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final SettingsStorage _settingsStorage;
  final SecureStorageService _secureStorage;
  final Dio _dio;

  VoidCallback? onUnauthorized;

  Dio get dio => _dio;

  Future<void> refreshBaseUrl() async {
    final url = await _settingsStorage.getServerUrl();
    _dio.options.baseUrl = url;
  }

  Future<void> setBaseUrl(String url) async {
    await _settingsStorage.saveServerUrl(url);
    _dio.options.baseUrl = url;
  }
}
