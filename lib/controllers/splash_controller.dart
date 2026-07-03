import 'package:flutter/material.dart';
import 'package:movil_architect/core/app_services.dart';
import 'package:movil_architect/core/network/api_exception.dart';
import 'package:movil_architect/services/auth_service.dart';
import 'package:movil_architect/services/mobile_api_service.dart';

enum SplashStatus { loading, readyDashboard, readyLogin, serverError }

class SplashController extends ChangeNotifier {
  SplashController({
    AuthService? authService,
    MobileApiService? mobileApiService,
  })  : _authService = authService ?? AppServices.instance.authService,
        _mobileApiService =
            mobileApiService ?? AppServices.instance.mobileApiService;

  final AuthService _authService;
  final MobileApiService _mobileApiService;

  SplashStatus _status = SplashStatus.loading;
  String? _errorMessage;

  SplashStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> bootstrap() async {
    _status = SplashStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final health = await _mobileApiService.health();
      if (!health.ok) {
        _status = SplashStatus.serverError;
        _errorMessage = 'El servidor respondió pero no está listo.';
        notifyListeners();
        return;
      }

      final hasToken = await _authService.hasToken();
      if (!hasToken) {
        _status = SplashStatus.readyLogin;
        notifyListeners();
        return;
      }

      final me = await _mobileApiService.me();
      _authService.updateSession(
        user: me.user,
        subscription: me.subscription,
      );
      _status = SplashStatus.readyDashboard;
    } on ApiException catch (error) {
      if (await _authService.hasToken()) {
        await _authService.logout();
      }
      _status = SplashStatus.serverError;
      _errorMessage = error.message;
    } catch (_) {
      _status = SplashStatus.serverError;
      _errorMessage = 'No se pudo conectar al servidor.';
    }

    notifyListeners();
  }
}
