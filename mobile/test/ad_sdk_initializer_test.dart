import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:chessverse_ai/core/ads/ad_sdk_initializer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const environment = MethodChannel('com.epitomehub.chessverse/ad_environment');
  final ads = instanceManager.channel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late int adCalls;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AdSdkInitializer.resetForTesting();
    adCalls = 0;
    messenger.setMockMethodCallHandler(ads, (call) async {
      adCalls++;
      return InitializationStatus(<String, AdapterStatus>{});
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(environment, null);
    messenger.setMockMethodCallHandler(ads, null);
    AdSdkInitializer.resetForTesting();
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'automated environment never initializes ads, including repeat calls',
    () async {
      messenger.setMockMethodCallHandler(environment, (_) async => true);
      expect(await AdSdkInitializer.ensureReady(), isFalse);
      expect(await AdSdkInitializer.ensureReady(), isFalse);
      expect(adCalls, 0);
    },
  );

  test('physical non-test device can initialize ads', () async {
    messenger.setMockMethodCallHandler(environment, (_) async => false);
    expect(await AdSdkInitializer.ensureReady(), isTrue);
    expect(adCalls, greaterThan(0));
  });

  test(
    'failed environment check prevents requests and permits a retry',
    () async {
      messenger.setMockMethodCallHandler(environment, (_) async {
        throw PlatformException(code: 'unavailable');
      });
      expect(await AdSdkInitializer.ensureReady(), isFalse);
      expect(adCalls, 0);
      messenger.setMockMethodCallHandler(environment, (_) async => false);
      expect(await AdSdkInitializer.ensureReady(), isTrue);
    },
  );
}
