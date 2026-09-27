import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Starts the native ad/WebView stack only after a user reaches an ad-backed
/// feature. Keeping it out of app startup reduces cold-start ANR exposure.
abstract final class AdSdkInitializer {
  static Future<bool>? _initialization;

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
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 8));
      return true;
    } on Object {
      // Let a later explicit ad request retry after transient SDK failures.
      _initialization = null;
      return false;
    }
  }
}
