import 'package:flutter/foundation.dart';

class AppConfig {
  static const _definedApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const useDemoData = bool.fromEnvironment(
    'USE_DEMO_DATA',
    defaultValue: false,
  );

  static String get apiBaseUrl {
    if (_definedApiBaseUrl.isNotEmpty) return _definedApiBaseUrl;

    if (kIsWeb) return 'http://localhost:4000';

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }

    return 'http://localhost:4000';
  }
}
