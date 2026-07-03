import 'package:flutter/material.dart';
import 'package:movil_architect/core/app_services.dart';
import 'package:movil_architect/core/config/app_config.dart';
import 'package:movil_architect/core/network/api_exception.dart';
import 'package:movil_architect/core/network/api_client.dart';
import 'package:movil_architect/core/storage/settings_storage.dart';
import 'package:movil_architect/core/theme/theme_service.dart';
import 'package:movil_architect/services/mobile_api_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    SettingsStorage? settingsStorage,
    ApiClient? apiClient,
    MobileApiService? mobileApiService,
    ThemeService? themeService,
  })  : _settingsStorage =
            settingsStorage ?? AppServices.instance.settingsStorage,
        _apiClient = apiClient ?? AppServices.instance.apiClient,
        _mobileApiService =
            mobileApiService ?? AppServices.instance.mobileApiService,
        _themeService = themeService ?? AppServices.instance.themeService;

  final SettingsStorage _settingsStorage;
  final ApiClient _apiClient;
  final MobileApiService _mobileApiService;
  final ThemeService _themeService;

  final TextEditingController urlController = TextEditingController();

  bool _isLoading = false;
  bool _isTesting = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  bool get isTesting => _isTesting;
  bool get isDarkMode => _themeService.isDarkMode;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load() async {
    final url = await _settingsStorage.getServerUrl();
    urlController.text = url;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    await _themeService.setDarkMode(enabled);
    notifyListeners();
  }
  Future<bool> save() async {
    final normalized = AppConfig.normalizeBaseUrl(urlController.text);
    if (normalized.isEmpty) {
      _errorMessage = 'Ingresa una URL válida.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _apiClient.setBaseUrl(normalized);
      final health = await _mobileApiService.health();
      if (!health.ok) {
        _errorMessage = 'La URL respondió pero el servicio no está listo.';
        return false;
      }
      _successMessage = 'Servidor configurado correctamente.';
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo conectar con esa URL.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> testConnection() async {
    _isTesting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _apiClient.setBaseUrl(AppConfig.normalizeBaseUrl(urlController.text));
      final health = await _mobileApiService.health();
      _successMessage = health.ok
          ? 'Conexión exitosa (${health.version})'
          : 'El servidor no está listo.';
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No se pudo conectar al servidor.';
    } finally {
      _isTesting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }
}
