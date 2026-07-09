import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const String environmentName = String.fromEnvironment(
    'CHESSVERSE_ENV',
    defaultValue: 'local',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );

  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'http://127.0.0.1:8090',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: 'replace-google-web-client-id.apps.googleusercontent.com',
  );

  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: 'replace-google-android-client-id.apps.googleusercontent.com',
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
    defaultValue: 'replace-facebook-app-id',
  );

  static const String facebookClientToken = String.fromEnvironment(
    'FACEBOOK_CLIENT_TOKEN',
    defaultValue: 'replace-facebook-client-token',
  );

  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://chessverse.example/privacy',
  );

  static const String termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://chessverse.example/terms',
  );

  static const String dataDeletionUrl = String.fromEnvironment(
    'DATA_DELETION_URL',
    defaultValue: 'https://chessverse.example/data-deletion',
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

    if (kReleaseMode && apiUri.scheme != 'https') {
      throw StateError('Release builds require an HTTPS API_BASE_URL.');
    }
  }
}
