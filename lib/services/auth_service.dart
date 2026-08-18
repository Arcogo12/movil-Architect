import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movil_architect/core/network/api_client.dart';
import 'package:movil_architect/core/network/api_exception.dart';
import 'package:movil_architect/core/storage/secure_storage_service.dart';
import 'package:movil_architect/models/auth_models.dart';

class AuthService extends ChangeNotifier {
  AuthService({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  UserModel? _currentUser;
  SubscriptionModel? _subscription;

  UserModel? get currentUser => _currentUser;
  SubscriptionModel? get subscription => _subscription;

  VoidCallback? onSessionExpired;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final auth = AuthResponse.fromJson(response.data ?? {});
      await _persistSession(auth);
      return auth;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final payload = <String, dynamic>{
        'email': email.trim(),
        'password': password,
      };
      final name = fullName?.trim();
      if (name != null && name.isNotEmpty) {
        payload['full_name'] = name;
      }

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: payload,
      );
      final auth = AuthResponse.fromJson(response.data ?? {});
      await _persistSession(auth);
      return auth;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<bool> hasToken() async {
    final token = await _secureStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _secureStorage.clearToken();
    _currentUser = null;
    _subscription = null;
    notifyListeners();
  }

  void handleUnauthorized() {
    _currentUser = null;
    _subscription = null;
    notifyListeners();
    onSessionExpired?.call();
  }

  Future<void> _persistSession(AuthResponse auth) async {
    await _secureStorage.saveToken(auth.accessToken);
    _currentUser = auth.user;
    _subscription = auth.subscription;
    notifyListeners();
  }

  void updateSession({required UserModel user, SubscriptionModel? subscription}) {
    _currentUser = user;
    _subscription = subscription;
    notifyListeners();
  }
}
