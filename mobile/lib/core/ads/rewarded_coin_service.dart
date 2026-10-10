import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_sdk_initializer.dart';
import '../analytics/app_analytics.dart';
import '../config/app_config.dart';

class RewardedCoinService {
  RewardedCoinService._();
  static final RewardedCoinService instance = RewardedCoinService._();
  RewardedAd? _ad;
  bool _loading = false;
  bool _showing = false;
  Completer<bool>? _loadCompleter;
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

  bool get isReady => _ad != null;
  bool get isLoading => _loading;

  Future<bool> load({Duration timeout = const Duration(seconds: 12)}) async {
    if (!supported || _showing) return false;
    if (_ad != null) return true;
    if (_loading) {
      return (_loadCompleter?.future ?? Future<bool>.value(false)).timeout(
        timeout,
        onTimeout: () => false,
      );
    }
    _loading = true;
    final Completer<bool> loading = Completer<bool>();
    _loadCompleter = loading;
    if (!await AdSdkInitializer.ensureReady()) {
      _loading = false;
      _loadCompleter = null;
      if (!loading.isCompleted) loading.complete(false);
      return false;
    }
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          _loadCompleter = null;
          if (!loading.isCompleted) loading.complete(true);
        },
        onAdFailedToLoad: (_) {
          _loading = false;
          _loadCompleter = null;
          if (!loading.isCompleted) loading.complete(false);
        },
      ),
    );
    return loading.future.timeout(timeout, onTimeout: () => false);
  }

  Future<bool> show({required String playerId, required String token}) async {
    if (!supported || _showing) return false;
    if (_ad == null) {
      final bool loaded = await load();
      if (!loaded || _ad == null) return false;
    }
    _showing = true;
    final completer = Completer<bool>();
    final ad = _ad!;
    _ad = null;
    bool earned = false;
    unawaited(
      AppAnalytics.logProductEvent(
        token: token,
        name: 'rewarded_ad_started',
        context: 'coin_shop',
      ),
    );
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
        unawaited(
          AppAnalytics.logProductEvent(
            token: token,
            name: earned ? 'rewarded_ad_completed' : 'rewarded_ad_dismissed',
            context: 'coin_shop',
          ),
        );
        if (!completer.isCompleted) completer.complete(earned);
        unawaited(load());
      },
      onAdFailedToShowFullScreenContent: (value, _) {
        value.dispose();
        _showing = false;
        unawaited(
          AppAnalytics.logProductEvent(
            token: token,
            name: 'rewarded_ad_dismissed',
            context: 'show_failed',
          ),
        );
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
