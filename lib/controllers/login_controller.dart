import 'package:flutter/material.dart';
import 'package:movil_architect/core/app_services.dart';
import 'package:movil_architect/core/network/api_exception.dart';
import 'package:movil_architect/models/user_credentials.dart';
import 'package:movil_architect/services/auth_service.dart';

class LoginController extends ChangeNotifier {
  LoginController({AuthService? authService})
      : _authService = authService ?? AppServices.instance.authService;

  final AuthService _authService;

  final TextEditingController emailController = TextEditingController(
    text: 'admin@architect.local',
  );
  final TextEditingController passwordController = TextEditingController(
    text: 'admin123',
  );

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool get obscurePassword => _obscurePassword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  UserCredentials get credentials => UserCredentials(
        email: emailController.text,
        password: passwordController.text,
      );

  Future<bool> login() async {
    final user = credentials;

    if (!user.isValid) {
      _errorMessage = 'Ingresa correo y contraseña.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AppServices.instance.apiClient.refreshBaseUrl();
      await _authService.login(
        email: user.email,
        password: user.password,
      );
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo iniciar sesión. Intenta de nuevo.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
