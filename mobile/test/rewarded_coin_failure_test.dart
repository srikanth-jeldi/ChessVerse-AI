import 'dart:async';

import 'package:chessverse_ai/core/ads/ad_sdk_initializer.dart';
import 'package:chessverse_ai/core/ads/rewarded_coin_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const environment = MethodChannel('com.epitomehub.chessverse/ad_environment');
  late RewardedCoinService service;
  late List<int> ids;
  late bool failLoad;
  late bool failShow;
  late bool deliverLoaded;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AdSdkInitializer.resetForTesting();
    service = RewardedCoinService.forTesting();
    ids = [];
    failLoad = false;
    failShow = false;
    deliverLoaded = false;
    messenger.setMockMethodCallHandler(environment, (_) async => false);
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      if (call.method == 'MobileAds#initialize') {
        return InitializationStatus(<String, AdapterStatus>{});
      }
      if (call.method == 'loadRewardedAd') {
        final id = (call.arguments as Map)['adId'] as int;
        ids.add(id);
        if (failLoad) throw PlatformException(code: 'load_failed');
        if (deliverLoaded) {
          scheduleMicrotask(() {
            final ad = instanceManager.adFor(id) as RewardedAd;
            ad.rewardedAdLoadCallback.onAdLoaded(ad);
          });
        }
      }
      if (call.method == 'showAdWithoutView' && failShow) {
        throw PlatformException(code: 'show_failed');
      }
      return null;
    });
  });
  tearDown(() async {
    for (final id in ids) {
      await instanceManager.adFor(id)?.dispose();
    }
    messenger.setMockMethodCallHandler(environment, null);
    messenger.setMockMethodCallHandler(instanceManager.channel, null);
    AdSdkInitializer.resetForTesting();
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'platform load failure releases loading state and allows retry',
    () async {
      failLoad = true;
      expect(await service.load(), isFalse);
      expect(service.isLoading, isFalse);
      failLoad = false;
      deliverLoaded = true;
      expect(await service.load(), isTrue);
    },
  );

  test('callback timeout permits retry and disposes stale loaded ad', () async {
    expect(
      await service.load(timeout: const Duration(milliseconds: 5)),
      isFalse,
    );
    expect(service.isLoading, isFalse);
    final stale = instanceManager.adFor(ids.single) as RewardedAd;
    stale.rewardedAdLoadCallback.onAdLoaded(stale);
    await Future<void>.delayed(Duration.zero);
    expect(service.isReady, isFalse);
    deliverLoaded = true;
    expect(await service.load(), isTrue);
  });

  test('failed show returns unavailable and allows another load', () async {
    deliverLoaded = true;
    failShow = true;
    expect(await service.load(), isTrue);
    expect(
      await service.show(playerId: 'test', token: ''),
      RewardedCoinOutcome.unavailable,
    );
    expect(await service.load(), isTrue);
  });
}
