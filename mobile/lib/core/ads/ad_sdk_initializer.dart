import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../diagnostics/app_diagnostics.dart';

/// Starts the native ad/WebView stack only after a user reaches an ad-backed
/// feature. Keeping it out of app startup reduces cold-start ANR exposure.
abstract final class AdSdkInitializer {
  static Future<bool>? _initialization;
  static const MethodChannel _environment = MethodChannel(
    'com.epitomehub.chessverse/ad_environment',
  );

  @visibleForTesting
  static void resetForTesting() => _initialization = null;

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<bool> ensureReady() {
    if (!supported) return Future<bool>.value(false);
    return _initialization ??= _initialize();
  }

  static Future<bool> _initialize() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final bool? suppress = await _environment
            .invokeMethod<bool>('suppressAds')
            .timeout(const Duration(seconds: 2));
        // No SDK initialization or ad requests until Android confirms that
        // this is outside the supported automated test environments.
        if (suppress != false) return false;
      }
      AppDiagnostics.log('ad_sdk_initialize');
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 8));
      AppDiagnostics.log('ad_sdk_ready');
      return true;
    } on Object catch (error, stack) {
      // Let a later explicit ad request retry after transient SDK failures.
      _initialization = null;
      await AppDiagnostics.recordError(
        error,
        stack,
        reason: 'Ad SDK initialization failed',
      );
      return false;
    }
  }
}
