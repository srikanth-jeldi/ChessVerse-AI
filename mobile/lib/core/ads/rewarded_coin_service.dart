import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_sdk_initializer.dart';
import '../analytics/app_analytics.dart';
import '../config/app_config.dart';
import '../diagnostics/app_diagnostics.dart';

enum RewardedCoinOutcome { earned, unavailable, dismissed }

class RewardedCoinService {
  RewardedCoinService._({bool hintReward = false}) : _hintReward = hintReward;
  @visibleForTesting
  RewardedCoinService.forTesting({bool hintReward = false})
    : _hintReward = hintReward;
  final bool _hintReward;
  static final RewardedCoinService instance = RewardedCoinService._();
  static final RewardedCoinService hints = RewardedCoinService._(
    hintReward: true,
  );
  String get _androidId => _hintReward
      ? AppConfig.admobAndroidHintRewardedId
      : AppConfig.admobAndroidRewardedId;
  RewardedAd? _ad;
  bool _loading = false;
  bool _showing = false;
  Completer<bool>? _loadCompleter;
  static const String _androidTest = 'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTest = 'ca-app-pub-3940256099942544/1712485313';

  String get _adUnitId => defaultTargetPlatform == TargetPlatform.android
      ? (kReleaseMode && _androidId.isNotEmpty ? _androidId : _androidTest)
      : (kReleaseMode && AppConfig.admobIosRewardedId.isNotEmpty
            ? AppConfig.admobIosRewardedId
            : _iosTest);

  bool get supported =>
      AdSdkInitializer.supported &&
      (!kReleaseMode ||
          (defaultTargetPlatform == TargetPlatform.android
              ? _androidId.isNotEmpty
              : !_hintReward && AppConfig.admobIosRewardedId.isNotEmpty));

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
    AppDiagnostics.log('ad_rewarded_load');
    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (_loadCompleter != loading) {
              unawaited(_dispose(ad));
              return;
            }
            _ad = ad;
            AppDiagnostics.log('ad_rewarded_loaded');
            _loading = false;
            _loadCompleter = null;
            if (!loading.isCompleted) loading.complete(true);
          },
          onAdFailedToLoad: (_) {
            if (_loadCompleter != loading) return;
            _loading = false;
            _loadCompleter = null;
            if (!loading.isCompleted) loading.complete(false);
          },
        ),
      ).timeout(timeout);
    } on Object catch (error, stack) {
      // The native method can stop responding before a load callback arrives.
      // A late failure must not clear an ad delivered by its callback or a
      // newer request's state.
      if (_loadCompleter == loading) {
        _loading = false;
        _loadCompleter = null;
        if (!loading.isCompleted) loading.complete(false);
      }
      await AppDiagnostics.recordError(
        error,
        stack,
        reason: 'Rewarded load failed',
      );
    }
    return loading.future.timeout(
      timeout,
      onTimeout: () {
        if (_loadCompleter == loading) {
          _loading = false;
          _loadCompleter = null;
          if (!loading.isCompleted) loading.complete(false);
        }
        return false;
      },
    );
  }

  Future<RewardedCoinOutcome> show({
    required String playerId,
    required String token,
  }) async {
    if (!supported || _showing) return RewardedCoinOutcome.unavailable;
    if (_ad == null) {
      final bool loaded = await load();
      if (!loaded || _ad == null) return RewardedCoinOutcome.unavailable;
    }
    // Another caller may have consumed this ad while we awaited the load.
    if (_showing || _ad == null) return RewardedCoinOutcome.unavailable;
    _showing = true;
    final completer = Completer<RewardedCoinOutcome>();
    final ad = _ad!;
    _ad = null;
    bool earned = false;
    unawaited(
      AppAnalytics.logProductEvent(
        token: token,
        name: 'rewarded_ad_started',
        context: _hintReward ? 'mistake_hint' : 'coin_shop',
      ),
    );
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (value) {
        AppDiagnostics.log('ad_rewarded_dismissed');
        unawaited(
          AppAnalytics.logProductEvent(
            token: token,
            name: earned ? 'rewarded_ad_completed' : 'rewarded_ad_dismissed',
            context: _hintReward ? 'mistake_hint' : 'coin_shop',
          ),
        );
        unawaited(
          _finishAd(value, () {
            if (!completer.isCompleted) {
              completer.complete(
                earned
                    ? RewardedCoinOutcome.earned
                    : RewardedCoinOutcome.dismissed,
              );
            }
          }),
        );
      },
      onAdFailedToShowFullScreenContent: (value, _) {
        unawaited(
          AppAnalytics.logProductEvent(
            token: token,
            name: 'rewarded_ad_dismissed',
            context: 'show_failed',
          ),
        );
        unawaited(
          _finishAd(value, () {
            if (!completer.isCompleted) {
              completer.complete(RewardedCoinOutcome.unavailable);
            }
          }),
        );
      },
    );
    try {
      if (!_hintReward)
        await ad.setServerSideOptions(
          ServerSideVerificationOptions(
            userId: playerId,
            customData: 'chessverse_coins_v1',
          ),
        );
      AppDiagnostics.log('ad_rewarded_show');
      await ad.show(
        onUserEarnedReward: (_, reward) {
          earned = true;
        },
      );
    } on Object catch (error, stack) {
      await _finishAd(ad, () {
        if (!completer.isCompleted)
          completer.complete(RewardedCoinOutcome.unavailable);
      });
      await AppDiagnostics.recordError(
        error,
        stack,
        reason: 'Rewarded show failed',
      );
      if (!completer.isCompleted) {
        completer.complete(RewardedCoinOutcome.unavailable);
      }
    }
    return completer.future;
  }

  Future<void> _finishAd(Ad ad, VoidCallback complete) async {
    final disposal = _dispose(ad);
    // Avoid overlapping WebView destruction and the next ad's construction.
    // A slow native cleanup must not hold the reward UI indefinitely, but
    // keep new ad loads blocked until that actual operation completes.
    unawaited(
      disposal.then((_) {
        _showing = false;
        unawaited(load());
      }),
    );
    await disposal.timeout(const Duration(seconds: 2), onTimeout: () {});
    complete();
  }

  static Future<void> _dispose(Ad ad) async {
    try {
      await ad.dispose();
    } on Object catch (error, stack) {
      await AppDiagnostics.recordError(
        error,
        stack,
        reason: 'Rewarded disposal failed',
      );
    }
  }
}
