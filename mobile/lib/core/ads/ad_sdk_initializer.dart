import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../diagnostics/app_diagnostics.dart';
import '../network/network_health_controller.dart';

/// Starts the native ad/WebView stack only after a user reaches an ad-backed
/// feature. Keeping it out of app startup reduces cold-start ANR exposure.
abstract final class AdSdkInitializer {
  // Only an explicitly opted-in debug build may exercise Google test ads on
  // an emulator/Test Lab device. Release traffic always retains suppression.
  static const bool debugTestAds =
      kDebugMode && bool.fromEnvironment('ENABLE_ADMOB_TEST_ADS');
  static Future<bool>? _initialization;
  static Future<void>? _nativeInitialization;
  static final ValueNotifier<bool> _ready = ValueNotifier(false);
  static ValueListenable<bool> get readiness => _ready;
  static Timer? _nativeDeadline;
  static int _generation = 0;
  static const MethodChannel _environment = MethodChannel(
    'com.epitomehub.chessverse/ad_environment',
  );

  @visibleForTesting
  static void resetForTesting() {
    ++_generation;
    _nativeDeadline?.cancel();
    _nativeDeadline = null;
    _ready.value = false;
    _initialization = null;
    _nativeInitialization = null;
  }

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<bool> ensureReady() {
    if (!supported) return Future<bool>.value(false);
    // Do not start WebView/ad work while the app is hidden or known offline.
    // The next foreground/network request retries; no device model is blocked.
    if (!_canRequest) return Future<bool>.value(false);
    if (_ready.value) return Future<bool>.value(true);
    return _initialization ??= _initialize();
  }

  static bool get _canRequest {
    final state = WidgetsBinding.instance.lifecycleState;
    return (state == null || state == AppLifecycleState.resumed) &&
        NetworkHealthController.instance.health != NetworkHealth.offline;
  }

  static Future<bool> _initialize() async {
    var waitingForNative = false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final bool? suppress = await _environment
            .invokeMethod<bool>('suppressAds')
            .timeout(const Duration(seconds: 2));
        // Unknown environments fail closed. Automated environments only run
        // test ads when this debug build explicitly opts in above.
        if (suppress == null || (suppress && !debugTestAds)) return false;
      }
      if (!_canRequest) {
        _initialization = null;
        return false;
      }
      // Future.timeout does not cancel Android's initialization. Reuse that
      // operation after a caller times out instead of starting it again.
      waitingForNative = true;
      final native = _nativeInitialization ??= _startNativeInitialization();
      await native.timeout(const Duration(seconds: 8));
      return _canRequest;
    } on TimeoutException catch (error, stack) {
      // The SDK's documented initialization window is up to 30 seconds.
      // Release this caller after eight seconds, but retain the one native
      // operation and notify mounted slots if it completes later. A separate
      // deadline still reports genuinely stalled initialization.
      _initialization = null;
      if (waitingForNative) {
        AppDiagnostics.log('ad_sdk_wait_deferred');
      } else {
        unawaited(
          AppDiagnostics.recordError(
            error,
            stack,
            reason: 'Ad environment check timed out',
          ),
        );
      }
      return false;
    } on Object catch (error, stack) {
      // Let a later explicit ad request retry after transient SDK failures.
      _initialization = null;
      if (!waitingForNative) {
        unawaited(
          AppDiagnostics.recordError(
            error,
            stack,
            reason: 'Ad environment check failed',
          ),
        );
      }
      return false;
    }
  }

  static Future<void> _startNativeInitialization() async {
    AppDiagnostics.log('ad_sdk_initialize');
    final generation = _generation;
    final watch = Stopwatch()..start();
    _nativeDeadline = Timer(const Duration(seconds: 35), () {
      if (generation != _generation || _ready.value) return;
      unawaited(
        AppDiagnostics.recordError(
          TimeoutException(
            'Native ad SDK still pending after its initialization window',
            const Duration(seconds: 35),
          ),
          StackTrace.current,
          reason: 'Ad SDK initialization stalled',
        ),
      );
    });
    try {
      await MobileAds.instance.initialize();
      if (generation != _generation) return;
      _nativeDeadline?.cancel();
      _nativeDeadline = null;
      AppDiagnostics.log('ad_sdk_ready', {
        'elapsedMs': watch.elapsedMilliseconds,
      });
      _ready.value = true;
    } on Object catch (error, stack) {
      // A completed failure may retry; a still-running operation must not.
      if (generation == _generation) {
        _nativeDeadline?.cancel();
        _nativeDeadline = null;
        _nativeInitialization = null;
        // Also retain failures arriving after the caller's eight-second wait.
        unawaited(
          AppDiagnostics.recordError(
            error,
            stack,
            reason: 'Ad SDK initialization failed',
          ),
        );
      }
      rethrow;
    }
  }
}
