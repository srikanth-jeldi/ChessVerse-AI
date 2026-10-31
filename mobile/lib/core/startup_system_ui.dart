import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Optional window styling, called only after the first frame.
abstract final class StartupSystemUi {
  static Future<void> configure() async {
    // Android already supplies the window/inset policy through the activity
    // theme and target SDK. Even a diagnostic sdkInt query crosses JNI here:
    // build 324's PC no-focused-window ANR was sampled in that startup call.
    // Keep optional styling off this startup path, including older Android.
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) return;
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)
          .timeout(const Duration(seconds: 2));
    } on Object {
      // Cosmetic configuration must never fail startup or schedule retries.
    }
  }
}
