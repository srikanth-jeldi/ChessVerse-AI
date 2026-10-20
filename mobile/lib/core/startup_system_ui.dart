import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Optional window styling, called only after the first frame.
abstract final class StartupSystemUi {
  static const _runtime = MethodChannel(
    'com.epitomehub.chessverse/runtime_diagnostics',
  );

  static Future<void> configure() async {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Target SDK 36 already enforces edge-to-edge on Android 15+.
        // Avoid a redundant window/inset mutation during surface startup.
        // This lightweight query must not inspect or initialize WebView.
        final api = await _runtime
            .invokeMethod<int>('sdkInt')
            .timeout(const Duration(seconds: 2));
        // Unknown platform state is not a reason to mutate the window.
        if (api == null || api >= 35) return;
      }
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)
          .timeout(const Duration(seconds: 2));
    } on Object {
      // Cosmetic configuration must never fail startup or schedule retries.
    }
  }
}
