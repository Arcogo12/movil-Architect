import 'package:movil_architect/core/network/api_client.dart';
import 'package:movil_architect/core/storage/secure_storage_service.dart';
import 'package:movil_architect/core/storage/settings_storage.dart';
import 'package:movil_architect/core/theme/theme_service.dart';
import 'package:movil_architect/services/auth_service.dart';
import 'package:movil_architect/services/home_project_service.dart';
import 'package:movil_architect/services/mobile_api_service.dart';

class AppServices {
  AppServices._();

  static final AppServices instance = AppServices._();

  late final SettingsStorage settingsStorage;
  late final SecureStorageService secureStorage;
  late final ApiClient apiClient;
  late final AuthService authService;
  late final MobileApiService mobileApiService;
  late final HomeProjectService homeProjectService;
  late final ThemeService themeService;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    settingsStorage = SettingsStorage();
    secureStorage = SecureStorageService();
    themeService = ThemeService();
    apiClient = ApiClient(
      settingsStorage: settingsStorage,
      secureStorage: secureStorage,
    );
    authService = AuthService(
      apiClient: apiClient,
      secureStorage: secureStorage,
    );
    mobileApiService = MobileApiService(apiClient: apiClient);
    homeProjectService = HomeProjectService(apiClient: apiClient);

    apiClient.onUnauthorized = authService.handleUnauthorized;

    await apiClient.refreshBaseUrl();
    await themeService.init(settingsStorage);
    _initialized = true;
  }
}
