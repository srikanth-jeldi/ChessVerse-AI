import 'dart:async';

import 'package:chessverse_ai/core/diagnostics/android_runtime_diagnostics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(
    'com.epitomehub.chessverse/runtime_diagnostics',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('only bounded runtime fields are retained', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {
        'android_render_mode': 'texture',
        'android_api': '33',
        'webview_provider': 'com.google.android.webview',
        'webview_version': 'x' * 200,
        'unexpected_field': 'not collected',
      },
    );
    final values = await AndroidRuntimeDiagnostics.read();
    expect(values.keys, hasLength(4));
    expect(values['android_render_mode'], 'texture');
    expect(values['webview_version']!.length, 128);
    expect(values.containsKey('unexpected_field'), isFalse);
  });

  test('missing platform implementation is harmless', () async {
    expect(await AndroidRuntimeDiagnostics.read(), isEmpty);
  });

  test('stalled query returns without waiting for native completion', () async {
    final pending = Completer<Map<String, String>>();
    messenger.setMockMethodCallHandler(channel, (_) => pending.future);
    expect(await AndroidRuntimeDiagnostics.read(), isEmpty);
    pending.complete({'android_render_mode': 'surface'});
    await Future<void>.delayed(Duration.zero);
  });

  test('other platforms never invoke the Android channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return {};
    });
    expect(await AndroidRuntimeDiagnostics.read(), isEmpty);
    expect(calls, 0);
  });
}
