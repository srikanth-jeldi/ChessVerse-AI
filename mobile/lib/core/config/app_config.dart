import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const String environmentName = String.fromEnvironment(
    'CHESSVERSE_ENV',
    defaultValue: 'local',
  );

  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Release artifacts must never silently call the phone's own localhost.
  /// CI can still override this value for staging with API_BASE_URL.
  static String get apiBaseUrl => _configuredApiBaseUrl.isNotEmpty
      ? _configuredApiBaseUrl
      : kReleaseMode
          ? 'https://api.chessverseai.com'
          : 'http://127.0.0.1:8080';

  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'http://127.0.0.1:8090',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '823774384869-32hoj2oa79ftoe9geq78h4iklcnmd0rl.apps.googleusercontent.com',
  );

  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue:
        '823774384869-a820693rjfthu04ltg72b9a5jifkirt8.apps.googleusercontent.com',
  );

  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: 'replace-google-ios-client-id.apps.googleusercontent.com',
  );

  static const String appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: 'com.epitomehub.chessverse.signin',
  );

  static const String appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: 'https://api.chessverse.example/api/auth/apple/callback',
  );

  static const String facebookAppId = String.fromEnvironment(
    'FACEBOOK_APP_ID',
    defaultValue: '27409411982074524',
  );

  static const String facebookClientToken = String.fromEnvironment(
    'FACEBOOK_CLIENT_TOKEN',
    defaultValue: 'aea3ed77a1ce5ca76b7d630df081e5d9',
  );

  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://chessverseai.com/privacy',
  );

  static const String termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://chessverseai.com/terms',
  );

  static const String dataDeletionUrl = String.fromEnvironment(
    'DATA_DELETION_URL',
    defaultValue: 'https://chessverseai.com/data-deletion',
  );

  static const bool arenaPreview = bool.fromEnvironment('ARENA_PREVIEW');

  static bool get usesDummySocialConfig =>
      googleWebClientId.startsWith('replace-') ||
      googleAndroidClientId.startsWith('replace-') ||
      googleIosClientId.startsWith('replace-') ||
      facebookAppId.startsWith('replace-') ||
      facebookClientToken.startsWith('replace-');

  static void validate() {
    final Uri? apiUri = Uri.tryParse(apiBaseUrl);
    if (apiUri == null || !apiUri.hasScheme || apiUri.host.isEmpty) {
      throw StateError('API_BASE_URL must be an absolute URL.');
    }

    final Uri? webUri = Uri.tryParse(webBaseUrl);
    if (webUri == null || !webUri.hasScheme || webUri.host.isEmpty) {
      throw StateError('WEB_BASE_URL must be an absolute URL.');
    }

    if (kReleaseMode &&
        apiUri.scheme != 'https' &&
        !_isLocalDevHost(apiUri.host)) {
      throw StateError('Release builds require an HTTPS API_BASE_URL.');
    }
  }

  static bool _isLocalDevHost(String host) {
    final String normalized = host.toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '10.0.2.2' ||
        normalized.startsWith('192.168.') ||
        normalized.startsWith('10.');
  }
}
