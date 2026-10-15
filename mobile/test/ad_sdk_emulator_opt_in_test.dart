import 'package:chessverse_ai/core/ads/ad_sdk_initializer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const environment = MethodChannel('com.epitomehub.chessverse/ad_environment');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var calls = 0;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AdSdkInitializer.resetForTesting();
    calls = 0;
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      if (call.method == 'MobileAds#initialize') calls++;
      return InitializationStatus(<String, AdapterStatus>{});
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    AdSdkInitializer.resetForTesting();
    messenger.setMockMethodCallHandler(environment, null);
    messenger.setMockMethodCallHandler(instanceManager.channel, null);
  });
  test('emulator SDK access requires explicit debug test-ad opt-in', () async {
    messenger.setMockMethodCallHandler(environment, (_) async => true);
    expect(await AdSdkInitializer.ensureReady(), AdSdkInitializer.debugTestAds);
    expect(calls, AdSdkInitializer.debugTestAds ? 1 : 0);
  });
  test(
    'unknown environment remains blocked even with test-ad opt-in',
    () async {
      messenger.setMockMethodCallHandler(environment, (_) async => null);
      expect(await AdSdkInitializer.ensureReady(), isFalse);
      expect(calls, 0);
    },
  );
}
