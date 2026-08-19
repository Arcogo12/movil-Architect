import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  /// Override en build/run:
  /// `--dart-define=API_BASE=http://10.0.2.2:8000`
  static const apiBaseFromDefine = String.fromEnvironment('API_BASE');

  /// Emulador Android (localhost del PC = 10.0.2.2).
  static const defaultEmulatorUrl = 'http://10.0.2.2:8000';

  static const defaultLocalUrl = 'http://localhost:8000';

  /// Prioridad:
  /// 1) `--dart-define=API_BASE`
  /// 2) Android → emulador / Docker local (`10.0.2.2:8000`)
  /// 3) iOS / web / desktop → localhost
  static String defaultServerUrl() {
    final fromDefine = apiBaseFromDefine.trim();
    if (fromDefine.isNotEmpty) {
      return normalizeBaseUrl(fromDefine);
    }
    if (kIsWeb) return defaultLocalUrl;
    if (Platform.isAndroid) return defaultEmulatorUrl;
    return defaultLocalUrl;
  }

  static bool isRemoteTunnelUrl(String url) {
    final normalized = normalizeBaseUrl(url);
    return normalized.contains('ngrok') ||
        normalized.contains('trycloudflare.com') ||
        normalized.contains('cloudflare');
  }

  /// URLs antiguas (túnel / LAN) que deben volver al Docker local.
  static bool isLegacyDevUrl(String url) {
    final normalized = normalizeBaseUrl(url);
    return isRemoteTunnelUrl(normalized) ||
        normalized == 'http://127.0.0.1:8000' ||
        normalized == 'http://192.168.0.116:8000' ||
        (normalized.startsWith('http://192.168.') &&
            normalized != defaultEmulatorUrl);
  }

  static String normalizeBaseUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) {
      return defaultServerUrl();
    }
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
