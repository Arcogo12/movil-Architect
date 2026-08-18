import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  /// Override en build/run:
  /// `--dart-define=API_BASE=https://tu-url.ngrok-free.dev`
  static const apiBaseFromDefine = String.fromEnvironment('API_BASE');

  /// URL pública de prueba compartida (Cloudflare Tunnel). Sin slash final.
  static const sharedNgrokUrl =
      'https://arkansas-vision-custom-sunday.trycloudflare.com';

  /// Emulador Android (localhost del PC = 10.0.2.2).
  static const defaultEmulatorUrl = 'http://10.0.2.2:8000';

  /// Default para dispositivo físico / APK compartida = túnel HTTPS.
  static const defaultPhysicalUrl = sharedNgrokUrl;

  static const defaultLocalUrl = 'http://localhost:8000';

  /// Prioridad:
  /// 1) `--dart-define=API_BASE`
  /// 2) Android debug → emulador (`10.0.2.2:8000`)
  /// 3) iOS / Android release → túnel
  /// 4) web/desktop → localhost
  static String defaultServerUrl() {
    final fromDefine = apiBaseFromDefine.trim();
    if (fromDefine.isNotEmpty) {
      return normalizeBaseUrl(fromDefine);
    }
    if (kIsWeb) return defaultLocalUrl;
    if (Platform.isAndroid && kDebugMode) return defaultEmulatorUrl;
    if (Platform.isAndroid || Platform.isIOS) return defaultPhysicalUrl;
    return defaultLocalUrl;
  }

  /// URLs antiguas de LAN que conviene migrar al default actual.
  /// No incluye el emulador: `10.0.2.2` es válido en desarrollo.
  static bool isLegacyDevUrl(String url) {
    final normalized = normalizeBaseUrl(url);
    return normalized == defaultLocalUrl ||
        normalized == 'http://127.0.0.1:8000' ||
        normalized == 'http://192.168.0.116:8000' ||
        normalized == 'https://ninth-occultist-capture.ngrok-free.dev' ||
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
