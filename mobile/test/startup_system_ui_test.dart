import 'dart:async';

import 'package:chessverse_ai/core/startup_system_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const runtime = MethodChannel(
    'com.epitomehub.chessverse/runtime_diagnostics',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final windowCalls = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    windowCalls.clear();
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      windowCalls.add(call);
      return null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(runtime, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final api in [35, 36]) {
    test(
      'Android $api does not reconfigure the enforced window mode',
      () async {
        messenger.setMockMethodCallHandler(runtime, (call) async {
          fail('Android startup must not cross the runtime channel');
        });
        await StartupSystemUi.configure();
        expect(windowCalls, isEmpty);
      },
    );
  }

  test('Android 14 leaves window styling to the activity', () async {
    messenger.setMockMethodCallHandler(runtime, (_) async => fail('No startup JNI query'));
    await StartupSystemUi.configure();
    expect(windowCalls, isEmpty);
  });

  test('missing native implementation leaves window unchanged', () async {
    await StartupSystemUi.configure();
    expect(windowCalls, isEmpty);
  });

  test('stalled API query is bounded and never mutates the window', () async {
    final pending = Completer<int>();
    messenger.setMockMethodCallHandler(runtime, (_) => pending.future);
    var completed = false;
    final task = StartupSystemUi.configure().then((_) => completed = true);
    await task;
    expect(completed, isTrue);
    pending.complete(34);
    await Future<void>.delayed(Duration.zero);
    expect(windowCalls, isEmpty);
  });

  test('iOS retains styling without Android query', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    messenger.setMockMethodCallHandler(runtime, (_) async {
      fail('Android runtime must not be queried on iOS');
    });
    await StartupSystemUi.configure();
    expect(windowCalls.single.method, 'SystemChrome.setEnabledSystemUIMode');
  });
}
