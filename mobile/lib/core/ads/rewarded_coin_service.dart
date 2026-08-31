import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedCoinService {
  RewardedCoinService._();
  static final RewardedCoinService instance = RewardedCoinService._();
  RewardedAd? _ad;
  bool _loading = false;
  static const String _androidTest = 'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTest = 'ca-app-pub-3940256099942544/1712485313';

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  Future<void> initialize() async {
    if (!supported) return;
    await MobileAds.instance.initialize();
    unawaited(load());
  }

  Future<void> load() async {
    if (!supported || _loading || _ad != null) return;
    _loading = true;
    RewardedAd.load(
        adUnitId: defaultTargetPlatform == TargetPlatform.android
            ? _androidTest
            : _iosTest,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        }, onAdFailedToLoad: (_) {
          _loading = false;
        }));
  }

  Future<bool> show({required String playerId}) async {
    if (!supported) return false;
    if (_ad == null) {
      await load();
      return false;
    }
    final completer = Completer<bool>();
    final ad = _ad!;
    _ad = null;
    ad.setServerSideOptions(ServerSideVerificationOptions(
        userId: playerId, customData: 'chessverse_coins_v1'));
    ad.fullScreenContentCallback =
        FullScreenContentCallback(onAdDismissedFullScreenContent: (value) {
      value.dispose();
      if (!completer.isCompleted) completer.complete(false);
      unawaited(load());
    }, onAdFailedToShowFullScreenContent: (value, _) {
      value.dispose();
      if (!completer.isCompleted) completer.complete(false);
      unawaited(load());
    });
    ad.show(onUserEarnedReward: (_, reward) {
      if (!completer.isCompleted) completer.complete(true);
    });
    return completer.future;
  }
}
