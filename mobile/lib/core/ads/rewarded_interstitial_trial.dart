import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../app_preferences.dart';
import '../analytics/app_analytics.dart';
import '../config/app_config.dart';
import '../diagnostics/app_diagnostics.dart';
import 'ad_sdk_initializer.dart';

/// Stable, installation-scoped 10% cohort. Never reassign on load failure.
class RewardedInterstitialTrial {
  static final instance = RewardedInterstitialTrial();
  static const _prefs = AppPreferences();
  static const _bucketKey = 'ads.rewardedInterstitial.v1.bucket';
  static int _sessionHintsUntil = 0;
  static const _rewardKey = 'ads.rewardedInterstitial.hintsUntil';
  static const testUnit = 'ca-app-pub-3940256099942544/5354046379';
  Future<bool>? _assignment;
  RewardedInterstitialAd? _ad;
  DateTime? _loadedAt;
  bool _loading = false;
  int _request = 0;
  bool isShowing = false;
  static bool inTreatment(int bucket) => bucket >= 0 && bucket < 10;
  bool get enabled =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      AppConfig.rewardedInterstitialTrial &&
      (!kReleaseMode ||
          (AppConfig.rewardedInterstitialId.isNotEmpty &&
              AppConfig.rewardedInterstitialId != testUnit));

  @visibleForTesting
  static void resetForTesting() {
    instance._ad = null;
    instance._assignment = null;
    instance._loadedAt = null;
    instance._loading = false;
    instance.isShowing = false;
    _sessionHintsUntil = 0;
  }

  Future<bool> treatment() async {
    if (!enabled) return false;
    return _assignment ??= _assign();
  }

  Future<bool> _assign() async {
    try {
      var bucket = int.tryParse(
        await _prefs.readString(_bucketKey, fallback: ''),
      );
      if (bucket == null || bucket < 0 || bucket >= 100) {
        bucket = Random.secure().nextInt(100);
        await _prefs.writeString(_bucketKey, '$bucket');
      }
      final selected = inTreatment(bucket);
      unawaited(
        AppAnalytics.logAdTrial('assigned', selected ? 'treatment' : 'control'),
      );
      return selected;
    } on Object {
      return false;
    }
  }

  static Future<bool> hintsUnlocked() async {
    if (DateTime.now().millisecondsSinceEpoch < _sessionHintsUntil) return true;
    try {
      final until =
          int.tryParse(await _prefs.readString(_rewardKey, fallback: '')) ?? 0;
      return DateTime.now().millisecondsSinceEpoch < until;
    } on Object {
      return false;
    }
  }

  bool get ready =>
      _ad != null &&
      _loadedAt != null &&
      DateTime.now().difference(_loadedAt!) < const Duration(hours: 1);

  Future<bool> load() async {
    if (!await treatment() || _loading || isShowing) return false;
    if (ready) return true;
    _loading = true;
    final request = ++_request;
    final done = Completer<bool>();
    final old = _ad;
    _ad = null;
    try {
      await old?.dispose();
      if (!await AdSdkInitializer.ensureReady()) return false;
      await RewardedInterstitialAd.load(
        adUnitId: kReleaseMode ? AppConfig.rewardedInterstitialId : testUnit,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (request != _request) {
              unawaited(ad.dispose());
              return;
            }
            _ad = ad;
            _loadedAt = DateTime.now();
            if (!done.isCompleted) done.complete(true);
          },
          onAdFailedToLoad: (error) {
            unawaited(AppAnalytics.logAdTrial('load_failed', 'treatment'));
            if (!done.isCompleted) done.complete(false);
          },
        ),
      ).timeout(const Duration(seconds: 12));
      return await done.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => false,
      );
    } on Object {
      return false;
    } finally {
      ++_request;
      _loading = false;
    }
  }

  /// Caller owns the shared ad lease, including the intro. No fallback ad.
  Future<void> show({
    required Future<bool> Function() intro,
    required VoidCallback onShown,
  }) async {
    if (!ready || isShowing) return;
    if (!await intro()) {
      unawaited(AppAnalytics.logAdTrial('intro_skipped', 'treatment'));
      return;
    }
    if (!ready) return;
    final ad = _ad!;
    _ad = null;
    isShowing = true;
    final done = Completer<void>();
    Future<void>? finishFuture;
    Future<void>? rewardFuture;
    Future<void> finish() => finishFuture ??= () async {
      try {
        await rewardFuture;
        await ad.dispose();
      } on Object catch (error, stack) {
        await AppDiagnostics.recordError(
          error,
          stack,
          reason: 'Rewarded interstitial disposal failed',
        );
      } finally {
        isShowing = false;
        if (!done.isCompleted) done.complete();
      }
    }();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        onShown();
        unawaited(AppAnalytics.logAdTrial('displayed', 'treatment'));
      },
      onAdDismissedFullScreenContent: (_) {
        unawaited(finish());
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        unawaited(AppAnalytics.logAdTrial('show_failed', 'treatment'));
        unawaited(finish());
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, reward) {
          // Duplicate SDK callbacks cannot extend the entitlement twice.
          rewardFuture ??= _grantHints();
        },
      );
    } on Object {
      await finish();
    }
    await done.future;
  }

  Future<void> _grantHints() async {
    _sessionHintsUntil = DateTime.now()
        .add(const Duration(hours: 24))
        .millisecondsSinceEpoch;
    try {
      await _prefs.writeString(_rewardKey, '$_sessionHintsUntil');
      unawaited(AppAnalytics.logAdTrial('reward_earned', 'treatment'));
    } on Object catch (error, stack) {
      await AppDiagnostics.recordError(
        error,
        stack,
        reason: 'Hint entitlement persistence failed',
      );
    }
  }
}
