import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const defaultEmulatorUrl = 'http://10.0.2.2:8000';
  static const defaultLocalUrl = 'http://localhost:8000';

  static String defaultServerUrl() {
    if (kIsWeb) return defaultLocalUrl;
    if (Platform.isAndroid) return defaultEmulatorUrl;
    return defaultLocalUrl;
  }

  static String normalizeBaseUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return defaultServerUrl();
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
