import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );

  static const bool arenaPreview = bool.fromEnvironment('ARENA_PREVIEW');

  static void validate() {
    final Uri? apiUri = Uri.tryParse(apiBaseUrl);
    if (apiUri == null || !apiUri.hasScheme || apiUri.host.isEmpty) {
      throw StateError('API_BASE_URL must be an absolute URL.');
    }

    if (kReleaseMode && apiUri.scheme != 'https') {
      throw StateError('Release builds require an HTTPS API_BASE_URL.');
    }
  }
}
