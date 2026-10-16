import 'dart:async';

import 'package:chessverse_ai/core/ads/ad_sdk_initializer.dart';
import 'package:chessverse_ai/core/ads/post_match_ad_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const environment = MethodChannel('com.epitomehub.chessverse/ad_environment');
  late PostMatchAdService service;
  late List<int> ids;
  late bool failLoad;

  late bool deliverLoaded;
  Completer<void>? pendingLoad;
  Completer<void>? pendingDispose;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AdSdkInitializer.resetForTesting();
    service = PostMatchAdService.forTesting();
    ids = [];
    failLoad = false;

    deliverLoaded = false;
    pendingLoad = null;
    pendingDispose = null;
    FlutterSecureStorage.setMockInitialValues({});
    messenger.setMockMethodCallHandler(environment, (_) async => false);
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      if (call.method == 'MobileAds#initialize') {
        return InitializationStatus(<String, AdapterStatus>{});
      }
      if (call.method == 'disposeAd' && pendingDispose != null) {
        await pendingDispose!.future;
      }
      if (call.method == 'loadInterstitialAd') {
        final id = (call.arguments as Map)['adId'] as int;
        ids.add(id);
        if (failLoad) throw PlatformException(code: 'load_failed');
        final shouldDeliver = deliverLoaded;
        if (pendingLoad != null) await pendingLoad!.future;
        if (shouldDeliver) {
          scheduleMicrotask(() {
            final ad = instanceManager.adFor(id) as InterstitialAd;
            ad.adLoadCallback.onAdLoaded(ad);
          });
        }
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
    'post-match completion and next load wait for native disposal',
    () async {
      deliverLoaded = true;
      await service.load();
      final ad = instanceManager.adFor(ids.single) as InterstitialAd;
      final shown = service.showAfterMatch('three');
      await Future<void>.delayed(Duration.zero);
      pendingDispose = Completer<void>();
      ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
      await Future<void>.delayed(Duration.zero);
      expect(await service.load(), false);
      expect(ids, hasLength(1));
      pendingDispose!.complete();
      await shown;
      await Future<void>.delayed(Duration.zero);
      expect(ids, hasLength(2));
    },
  );

  test(
    'first match shows once and subsequent match respects cooldown',
    () async {
      deliverLoaded = true;
      await service.load();
      final ad = instanceManager.adFor(ids.single) as InterstitialAd;
      final shown = service.showAfterMatch('first');
      await Future<void>.delayed(Duration.zero);
      expect(service.isShowing, isTrue);
      ad.fullScreenContentCallback!.onAdShowedFullScreenContent!(ad);
      ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
      await shown;
      await Future<void>.delayed(Duration.zero);
      await service.showAfterMatch('first');
      await service.showAfterMatch('second');
      expect(service.isShowing, isFalse);
      expect(service.isReady, isTrue);
    },
  );

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

  test('concurrent callers wait for one native load callback', () async {
    final first = service.load();
    await Future<void>.delayed(Duration.zero);
    final second = service.load();
    bool completed = false;
    unawaited(first.then((_) => completed = true));
    await Future<void>.delayed(Duration.zero);
    expect(ids, hasLength(1));
    expect(completed, isFalse);
    final ad = instanceManager.adFor(ids.single) as InterstitialAd;
    ad.adLoadCallback.onAdLoaded(ad);
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(service.isReady, isTrue);
  });
  test('callback timeout permits retry and disposes stale loaded ad', () async {
    expect(
      await service.load(timeout: const Duration(milliseconds: 5)),
      isFalse,
    );
    expect(service.isLoading, isFalse);
    final stale = instanceManager.adFor(ids.single) as InterstitialAd;
    stale.adLoadCallback.onAdLoaded(stale);
    await Future<void>.delayed(Duration.zero);
    expect(service.isReady, isFalse);
    deliverLoaded = true;
    expect(await service.load(), isTrue);
  });

  test(
    'unresponsive native load times out and late callback cannot replace retry',
    () async {
      pendingLoad = Completer<void>();
      expect(
        await service.load(timeout: const Duration(milliseconds: 10)),
        isFalse,
      );
      expect(service.isLoading, isFalse);
      final stale = instanceManager.adFor(ids.single) as InterstitialAd;
      final blocked = pendingLoad!;
      pendingLoad = null;
      deliverLoaded = true;
      expect(await service.load(), isTrue);
      stale.adLoadCallback.onAdLoaded(stale);
      blocked.complete();
      await Future<void>.delayed(Duration.zero);
      expect(service.isReady, isTrue);
      expect(service.isLoading, isFalse);
    },
  );
}
