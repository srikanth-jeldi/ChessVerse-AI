import 'dart:async';

import 'package:chessverse_ai/core/ads/ad_sdk_initializer.dart';
import 'package:chessverse_ai/core/ads/banner_ad_slot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  for (final leaveScreen in [false, true]) {
    testWidgets(
      'late SDK completion loads only a mounted banner: leave=$leaveScreen',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        const environment = MethodChannel(
          'com.epitomehub.chessverse/ad_environment',
        );
        final ads = instanceManager.channel;
        final messenger = tester.binding.defaultBinaryMessenger;
        final pending = Completer<InitializationStatus>();
        var bannerLoads = 0;
        AdSdkInitializer.resetForTesting();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        messenger.setMockMethodCallHandler(environment, (_) async => false);
        messenger.setMockMethodCallHandler(ads, (call) async {
          if (call.method == 'MobileAds#initialize') return pending.future;
          if (call.method == 'loadBannerAd') bannerLoads++;
          return null;
        });
        try {
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: BannerAdSlot())),
          );
          await tester.pump();
          await tester.pump(const Duration(seconds: 9));
          expect(bannerLoads, 0);
          if (leaveScreen) await tester.pumpWidget(const SizedBox());
          pending.complete(InitializationStatus(<String, AdapterStatus>{}));
          await tester.pump();
          await tester.pump();
          expect(bannerLoads, leaveScreen ? 0 : 1);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          AdSdkInitializer.resetForTesting();
          messenger.setMockMethodCallHandler(environment, null);
          messenger.setMockMethodCallHandler(ads, null);
          debugDefaultTargetPlatformOverride = null;
        }
      },
      skip: !const bool.fromEnvironment('ENABLE_ADMOB_TEST_ADS'),
    );
  }
}
