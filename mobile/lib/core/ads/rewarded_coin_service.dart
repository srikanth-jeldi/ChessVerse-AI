import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_sdk_initializer.dart';
import '../config/app_config.dart';

class RewardedCoinService {
  RewardedCoinService._();
  static final RewardedCoinService instance = RewardedCoinService._();
  RewardedAd? _ad;
  bool _loading = false;
  bool _showing = false;
  static const String _androidTest = 'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTest = 'ca-app-pub-3940256099942544/1712485313';

  String get _adUnitId => defaultTargetPlatform == TargetPlatform.android
      ? (kReleaseMode && AppConfig.admobAndroidRewardedId.isNotEmpty
            ? AppConfig.admobAndroidRewardedId
            : _androidTest)
      : (kReleaseMode && AppConfig.admobIosRewardedId.isNotEmpty
            ? AppConfig.admobIosRewardedId
            : _iosTest);

  bool get supported =>
      AdSdkInitializer.supported &&
      (!kReleaseMode ||
          (defaultTargetPlatform == TargetPlatform.android
              ? AppConfig.admobAndroidRewardedId.isNotEmpty
              : AppConfig.admobIosRewardedId.isNotEmpty));

  Future<void> load() async {
    if (!supported || _loading || _showing || _ad != null) return;
    _loading = true;
    if (!await AdSdkInitializer.ensureReady()) {
      _loading = false;
      return;
    }
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) {
          _loading = false;
        },
      ),
    );
  }

  Future<bool> show({required String playerId}) async {
    if (!supported || _showing) return false;
    if (_ad == null) {
      await load();
      return false;
    }
    _showing = true;
    final completer = Completer<bool>();
    final ad = _ad!;
    _ad = null;
    bool earned = false;
    ad.setServerSideOptions(
      ServerSideVerificationOptions(
        userId: playerId,
        customData: 'chessverse_coins_v1',
      ),
    );
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (value) {
        value.dispose();
        _showing = false;
        if (!completer.isCompleted) completer.complete(earned);
        unawaited(load());
      },
      onAdFailedToShowFullScreenContent: (value, _) {
        value.dispose();
        _showing = false;
        if (!completer.isCompleted) completer.complete(false);
        unawaited(load());
      },
    );
    ad.show(
      onUserEarnedReward: (_, reward) {
        earned = true;
      },
    );
    return completer.future;
  }
}
