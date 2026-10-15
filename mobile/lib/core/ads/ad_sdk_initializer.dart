import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../diagnostics/app_diagnostics.dart';

/// Starts the native ad/WebView stack only after a user reaches an ad-backed
/// feature. Keeping it out of app startup reduces cold-start ANR exposure.
abstract final class AdSdkInitializer {
  // Only an explicitly opted-in debug build may exercise Google test ads on
  // an emulator/Test Lab device. Release traffic always retains suppression.
  static const bool debugTestAds =
      kDebugMode && bool.fromEnvironment('ENABLE_ADMOB_TEST_ADS');
  static Future<bool>? _initialization;
  static Future<void>? _nativeInitialization;
  static const MethodChannel _environment = MethodChannel(
    'com.epitomehub.chessverse/ad_environment',
  );

  @visibleForTesting
  static void resetForTesting() {
    _initialization = null;
    _nativeInitialization = null;
  }

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
        // Unknown environments fail closed. Automated environments only run
        // test ads when this debug build explicitly opts in above.
        if (suppress == null || (suppress && !debugTestAds)) return false;
      }
      // Future.timeout does not cancel Android's initialization. Reuse that
      // operation after a caller times out instead of starting it again.
      final native = _nativeInitialization ??= _startNativeInitialization();
      await native.timeout(const Duration(seconds: 8));
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

  static Future<void> _startNativeInitialization() async {
    AppDiagnostics.log('ad_sdk_initialize');
    try {
      await MobileAds.instance.initialize();
    } on Object {
      // A completed failure may retry; a still-running operation must not.
      _nativeInitialization = null;
      rethrow;
    }
  }
}
