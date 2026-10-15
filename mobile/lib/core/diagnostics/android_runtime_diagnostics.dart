import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A bounded, optional snapshot. Never initializes WebView or delays startup.
abstract final class AndroidRuntimeDiagnostics {
  static const _channel = MethodChannel(
    'com.epitomehub.chessverse/runtime_diagnostics',
  );
  static const _keys = {
    'android_render_mode',
    'android_api',
    'webview_provider',
    'webview_version',
  };

  static Future<Map<String, String>> read() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return {};
    try {
      final values = await _channel
          .invokeMapMethod<String, Object?>('read')
          .timeout(const Duration(seconds: 2));
      return {
        for (final entry in (values ?? <String, Object?>{}).entries)
          if (_keys.contains(entry.key) && entry.value is String)
            entry.key: (entry.value as String).substring(
              0,
              (entry.value as String).length.clamp(0, 128),
            ),
      };
    } on Object {
      // A diagnostic query must never create a new crash or retry loop.
      return {};
    }
  }
}
