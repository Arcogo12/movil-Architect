import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:movil_architect/core/config/app_config.dart';
import 'package:movil_architect/core/storage/secure_storage_service.dart';

class SettingsStorage {
  SettingsStorage({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService();

  final SecureStorageService _secureStorage;

  /// Respaldo en memoria si el plugin nativo aún no está listo.
  String? _memoryUrl;
  bool? _memoryDarkMode;

  Future<String> getServerUrl() async {
    if (_memoryUrl != null && _memoryUrl!.isNotEmpty) {
      return _memoryUrl!;
    }

    try {
      final saved = await _secureStorage.getServerUrl();
      if (saved != null && saved.isNotEmpty) {
        final normalized = AppConfig.normalizeBaseUrl(saved);
        // Migrar URLs LAN antiguas. En Android debug no pisar el emulador.
        final preferEmulator = !kIsWeb &&
            Platform.isAndroid &&
            kDebugMode &&
            (AppConfig.isLegacyDevUrl(normalized) ||
                normalized == AppConfig.sharedNgrokUrl ||
                normalized.contains('trycloudflare.com') ||
                normalized.contains('ngrok'));

        if (preferEmulator && normalized != AppConfig.defaultEmulatorUrl) {
          final next = AppConfig.defaultEmulatorUrl;
          await saveServerUrl(next);
          return next;
        }

        if (!kIsWeb &&
            (Platform.isAndroid || Platform.isIOS) &&
            AppConfig.isLegacyDevUrl(normalized) &&
            normalized != AppConfig.defaultEmulatorUrl) {
          final next = AppConfig.defaultServerUrl();
          await saveServerUrl(next);
          return next;
        }
        _memoryUrl = normalized;
        return _memoryUrl!;
      }
    } catch (_) {
      // MissingPluginException u otro fallo de plataforma: usar default.
    }

    return AppConfig.defaultServerUrl();
  }

  Future<void> saveServerUrl(String url) async {
    final normalized = AppConfig.normalizeBaseUrl(url);
    _memoryUrl = normalized;

    try {
      await _secureStorage.saveServerUrl(normalized);
    } catch (_) {
      // Se conserva al menos en memoria durante la sesión.
    }
  }

  Future<bool> isDarkModeEnabled() async {
    if (_memoryDarkMode != null) return _memoryDarkMode!;

    try {
      final saved = await _secureStorage.getDarkMode();
      if (saved != null) {
        _memoryDarkMode = saved;
        return saved;
      }
    } catch (_) {}

    return false;
  }

  Future<void> saveDarkMode(bool enabled) async {
    _memoryDarkMode = enabled;
    try {
      await _secureStorage.saveDarkMode(enabled);
    } catch (_) {}
  }
}
