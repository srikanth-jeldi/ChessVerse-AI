import 'dart:async';

import 'package:chessverse_ai/core/ads/ad_sdk_initializer.dart';
import 'package:chessverse_ai/core/ads/full_screen_ad_gate.dart';
import 'package:chessverse_ai/core/ads/post_match_ad_service.dart';
import 'package:chessverse_ai/core/ads/rewarded_coin_service.dart';
import 'package:chessverse_ai/core/ads/rewarded_interstitial_trial.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const environment = MethodChannel('com.epitomehub.chessverse/ad_environment');
  final ads = <Ad>[];
  final methods = <String>[];
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AdSdkInitializer.resetForTesting();
    RewardedInterstitialTrial.resetForTesting();
    RewardedInterstitialTrial.enabledOverride = true;
    FlutterSecureStorage.setMockInitialValues({
      'settings.ads.rewardedInterstitial.v1.bucket': '4',
    });
    ads.clear();
    methods.clear();
    messenger.setMockMethodCallHandler(environment, (_) async => false);
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      methods.add(call.method);
      if (call.method == 'MobileAds#initialize') {
        return InitializationStatus(<String, AdapterStatus>{});
      }
      if (call.method.startsWith('load')) {
        final id = (call.arguments as Map)['adId'] as int;
        scheduleMicrotask(() {
          final ad = instanceManager.adFor(id)!;
          ads.add(ad);
          if (ad is RewardedInterstitialAd) {
            ad.rewardedInterstitialAdLoadCallback.onAdLoaded(ad);
          }
          if (ad is InterstitialAd) ad.adLoadCallback.onAdLoaded(ad);
          if (ad is RewardedAd) ad.rewardedAdLoadCallback.onAdLoaded(ad);
        });
      }
      return null;
    });
  });
  tearDown(() async {
    for (final ad in List<Ad>.of(ads)) {
      await ad.dispose();
    }
    messenger.setMockMethodCallHandler(instanceManager.channel, null);
    messenger.setMockMethodCallHandler(environment, null);
    debugDefaultTargetPlatformOverride = null;
    RewardedInterstitialTrial.resetForTesting();
  });
  test('treatment no-fill never shows a ready standard interstitial', () async {
    final service = PostMatchAdService.forTesting();
    await service.load();
    var intros = 0;
    await service.showAfterMatch(
      'no-fill',
      rewardedIntro: () async {
        intros++;
        return true;
      },
    );
    expect(intros, 0);
    expect(methods.where((m) => m == 'showAdWithoutView'), isEmpty);
  });
  test('two daily displays block treatment before intro or load', () async {
    final now = DateTime.now().toUtc();
    final day =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    FlutterSecureStorage.setMockInitialValues({
      'settings.ads.rewardedInterstitial.v1.bucket': '4',
      'settings.ads.interstitial.day': day,
      'settings.ads.interstitial.shown': '2',
    });
    final service = PostMatchAdService.forTesting();
    expect(
      await service.prepareForMatchResult(allowRewardedTrial: true),
      false,
    );
    var intros = 0;
    await service.showAfterMatch(
      'cap',
      rewardedIntro: () async {
        intros++;
        return true;
      },
    );
    expect(intros, 0);
    expect(methods.where((m) => m == 'showAdWithoutView'), isEmpty);
  });
  test(
    'failed rewarded display releases lease without reward or fallback',
    () async {
      final service = PostMatchAdService.forTesting();
      await service.prepareForMatchResult(allowRewardedTrial: true);
      final shown = service.showAfterMatch(
        'failed',
        rewardedIntro: () async => true,
      );
      await Future<void>.delayed(Duration.zero);
      final ad = ads.whereType<RewardedInterstitialAd>().single;
      ad.fullScreenContentCallback!.onAdFailedToShowFullScreenContent!(
        ad,
        AdError(1, 'test', 'failed'),
      );
      await shown;
      expect(await RewardedInterstitialTrial.hintsUnlocked(), false);
      expect(methods.where((m) => m == 'showAdWithoutView').length, 1);
      final lease = FullScreenAdGate.acquire();
      expect(lease, isNotNull);
      FullScreenAdGate.release(lease);
    },
  );
  test('exactly ten percent of stable buckets enter treatment', () {
    expect(
      List.generate(
        100,
        (i) => i,
      ).where(RewardedInterstitialTrial.inTreatment).length,
      10,
    );
    expect(RewardedInterstitialTrial.inTreatment(-1), false);
  });
  test('assignment is preserved across service instances', () async {
    expect(await RewardedInterstitialTrial().treatment(), true);
    expect(await RewardedInterstitialTrial().treatment(), true);
    FlutterSecureStorage.setMockInitialValues({
      'settings.ads.rewardedInterstitial.v1.bucket': '75',
    });
    expect(await RewardedInterstitialTrial().treatment(), false);
  });
  test('skip consumes match opportunity without fallback or reward', () async {
    final service = PostMatchAdService.forTesting();
    await service.load(); // Standard ad ready too: must never be shown.
    await service.prepareForMatchResult(allowRewardedTrial: true);
    var intros = 0;
    Future<bool> skip() async {
      intros++;
      return false;
    }

    await service.showAfterMatch('skip', rewardedIntro: skip);
    await service.showAfterMatch('skip', rewardedIntro: skip);
    expect(intros, 1);
    expect(methods.where((m) => m == 'showAdWithoutView'), isEmpty);
    expect(await RewardedInterstitialTrial.hintsUnlocked(), false);
    final lease = FullScreenAdGate.acquire();
    expect(lease, isNotNull);
    FullScreenAdGate.release(lease);
  });
  test('intro locks other full screen ads; reward delivered once; cooldown enforced', () async {
    final service = PostMatchAdService.forTesting();
    await service.prepareForMatchResult(allowRewardedTrial: true);
    final intro = Completer<bool>();
    final shown = service.showAfterMatch(
      'reward',
      rewardedIntro: () => intro.future,
    );
    await Future<void>.delayed(Duration.zero);
    final other = RewardedCoinService.forTesting();
    await other.load();
    expect(
      await other.show(playerId: '', token: ''),
      RewardedCoinOutcome.unavailable,
    );
    expect(FullScreenAdGate.acquire(), isNull);
    intro.complete(true);
    await Future<void>.delayed(Duration.zero);
    final ad = ads.whereType<RewardedInterstitialAd>().last;
    ad.fullScreenContentCallback!.onAdShowedFullScreenContent!(ad);
    ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'hints'));
    ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'hints'));
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    await shown;
    expect(await RewardedInterstitialTrial.hintsUnlocked(), true);
    var intros = 0;
    await service.showAfterMatch(
      'next',
      rewardedIntro: () async {
        intros++;
        return true;
      },
    );
    expect(intros, 0);
    expect(methods.where((m) => m == 'showAdWithoutView').length, 1);
    final lease = FullScreenAdGate.acquire();
    expect(lease, isNotNull);
    FullScreenAdGate.release(lease);
  });
}
