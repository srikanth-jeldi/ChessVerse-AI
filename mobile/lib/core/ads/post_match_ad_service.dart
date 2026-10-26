import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_sdk_initializer.dart';
import 'full_screen_ad_gate.dart';
import 'rewarded_interstitial_trial.dart';
import '../analytics/app_analytics.dart';
import '../app_preferences.dart';
import '../config/app_config.dart';
import '../diagnostics/app_diagnostics.dart';

class PostMatchAdService {
  PostMatchAdService._() : _now = DateTime.now;
  @visibleForTesting
  PostMatchAdService.forTesting({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static final PostMatchAdService instance = PostMatchAdService._();
  static const String _shownKey = 'ads.interstitial.shown';
  static const String _dayKey = 'ads.interstitial.day';
  static const String _matchesKey = 'ads.interstitial.matches';
  static const String _lastShownKey = 'ads.interstitial.lastShown';
  static const String _androidTest = 'ca-app-pub-3940256099942544/1033173712';
  static const String _iosTest = 'ca-app-pub-3940256099942544/4411468910';

  String get _adUnitId => defaultTargetPlatform == TargetPlatform.android
      ? (kReleaseMode && AppConfig.admobAndroidInterstitialId.isNotEmpty
            ? AppConfig.admobAndroidInterstitialId
            : _androidTest)
      : (kReleaseMode && AppConfig.admobIosInterstitialId.isNotEmpty
            ? AppConfig.admobIosInterstitialId
            : _iosTest);

  final DateTime Function() _now;
  static const Duration _maxAdAge = Duration(hours: 1);
  DateTime? _loadedAt;
  InterstitialAd? _ad;
  bool _loading = false;
  bool _showing = false;
  Object? _lease;
  Completer<bool>? _loadCompleter;
  int _shownToday = 0;
  DateTime _day = DateTime.now().toUtc();
  DateTime? _lastShownAt;
  int _completedMatchesSinceLastAd = 0;
  bool _stateLoaded = false;
  final AppPreferences _preferences = const AppPreferences();
  final Set<String> _handledMatches = <String>{};
  final Map<String, Future<bool>> _puzzleCompletions = {};
  Future<void> _puzzleQueue = Future<void>.value();

  /// Count each solved attempt once, persist across launches, and offer an ad
  /// only at every third completion. Display still obeys the shared ad caps.
  Future<bool> recordPuzzleCompletion(String attemptId) =>
      _puzzleCompletions.putIfAbsent(attemptId, () {
        final result = Completer<bool>();
        _puzzleQueue = _puzzleQueue.then((_) async {
          try {
            final raw = await _preferences.readString(
              'ads.puzzle.completions',
              fallback: '0',
            );
            final count = ((int.tryParse(raw) ?? 0) % 3 + 1) % 3;
            await _preferences.writeString('ads.puzzle.completions', '$count');
            result.complete(count == 0);
          } catch (_) {
            // Storage failure must never prevent the next puzzle.
            result.complete(false);
          }
        });
        return result.future;
      });

  bool get supported =>
      AdSdkInitializer.supported &&
      (!kReleaseMode ||
          (defaultTargetPlatform == TargetPlatform.android
              ? AppConfig.admobAndroidInterstitialId.isNotEmpty
              : AppConfig.admobIosInterstitialId.isNotEmpty));

  bool get isReady =>
      _ad != null &&
      _loadedAt != null &&
      _now().difference(_loadedAt!) < _maxAdAge;
  bool get isLoading => _loading;
  bool get isShowing => _lease != null || _showing;

  Future<bool> load({Duration timeout = const Duration(seconds: 12)}) async {
    if (!supported || _showing) return false;
    if (isReady) return true;
    if (_loading) {
      return (_loadCompleter?.future ?? Future<bool>.value(false)).timeout(
        timeout,
        onTimeout: () => false,
      );
    }
    _loading = true;
    final Completer<bool> loading = Completer<bool>();
    _loadCompleter = loading;
    final expired = _ad;
    if (expired != null) {
      _ad = null;
      _loadedAt = null;
      AppDiagnostics.log('ad_interstitial_expired');
      await _dispose(expired);
    }
    if (!await AdSdkInitializer.ensureReady()) {
      _loading = false;
      _loadCompleter = null;
      if (!loading.isCompleted) loading.complete(false);
      return false;
    }
    AppDiagnostics.log('ad_interstitial_load');
    try {
      await InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (_loadCompleter != loading) {
              unawaited(_dispose(ad));
              return;
            }
            _ad = ad;
            _loadedAt = _now();
            AppDiagnostics.log('ad_interstitial_loaded');
            _loading = false;
            _loadCompleter = null;
            if (!loading.isCompleted) loading.complete(true);
          },
          onAdFailedToLoad: (error) {
            AppDiagnostics.log('ad_interstitial_load_failed', {
              'code': error.code,
            });
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
        reason: 'Interstitial load failed',
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

  /// Load while the result is visible, before the player chooses to continue.
  /// Never wait for an ad on the navigation path or request one during cooldown.
  Future<bool> prepareForMatchResult({bool allowRewardedTrial = false}) async {
    if (isShowing) return false;
    if (allowRewardedTrial &&
        await RewardedInterstitialTrial.instance.treatment()) {
      await _loadState();
      _resetDailyCounter();
      if (_shownToday >= 2 ||
          (_lastShownAt != null &&
              _now().toUtc().difference(_lastShownAt!) <
                  const Duration(minutes: 5))) {
        return false;
      }
      return RewardedInterstitialTrial.instance.load();
    }
    if (!supported) return false;
    await _loadState();
    _resetDailyCounter();
    if (_shownToday >= 12 ||
        (_lastShownAt != null &&
            _now().toUtc().difference(_lastShownAt!) <
                const Duration(minutes: 5))) {
      return false;
    }
    return load();
  }

  Future<void> showAfterMatch(
    String matchId, {
    Future<bool> Function()? rewardedIntro,
  }) async {
    if (isShowing || _handledMatches.contains(matchId)) return;
    final lease = FullScreenAdGate.acquire();
    if (lease == null) return;
    _lease = lease;
    _handledMatches.add(matchId);
    try {
      await _showAfterMatch(rewardedIntro);
    } finally {
      // A timed-out native display keeps its lease until actual dismissal.
      if (!_showing) {
        FullScreenAdGate.release(lease);
        _lease = null;
      }
    }
  }

  Future<void> _showAfterMatch(Future<bool> Function()? rewardedIntro) async {
    final treatment =
        rewardedIntro != null &&
        await RewardedInterstitialTrial.instance.treatment();
    if (!treatment && !supported) return;
    await _loadState();
    _resetDailyCounter();
    _completedMatchesSinceLastAd++;
    final DateTime now = _now().toUtc();
    final bool cooledDown =
        _lastShownAt == null ||
        now.difference(_lastShownAt!) >= const Duration(minutes: 5);
    if (_shownToday >= (treatment ? 2 : 12) || !cooledDown) {
      AppDiagnostics.log('ad_interstitial_skipped', {
        'reason': _shownToday >= (treatment ? 2 : 12)
            ? 'daily_cap'
            : 'cooldown',
      });
      await _persistState();
      return;
    }

    if (treatment) {
      await RewardedInterstitialTrial.instance.show(
        intro: rewardedIntro,
        onShown: () {
          _resetDailyCounter();
          _shownToday++;
          _lastShownAt = _now().toUtc();
          unawaited(_persistState());
        },
      );
      // Skip, no-fill and display failure never fall back to another ad.
      return;
    }
    final InterstitialAd? ad = _ad;
    if (ad == null || !isReady) {
      // Never hold the post-match navigation while waiting for network demand.
      AppDiagnostics.log('ad_interstitial_skipped', {'reason': 'not_ready'});
      unawaited(load());
      await _persistState();
      return;
    }
    _ad = null;
    _showing = true;
    final Completer<void> done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        // Failed display attempts must not consume the impression cap or
        // restart the match/cooldown requirements.
        _resetDailyCounter();
        _shownToday++;
        if (RewardedInterstitialTrial.instance.enabled) {
          unawaited(AppAnalytics.logAdTrial('displayed', 'control'));
        }
        _completedMatchesSinceLastAd = 0;
        _lastShownAt = _now().toUtc();
        unawaited(_persistState());
      },
      onAdDismissedFullScreenContent: (InterstitialAd value) {
        AppDiagnostics.log('ad_interstitial_dismissed');
        unawaited(_finishAd(value, done));
      },
      onAdImpression: (_) => AppDiagnostics.log('ad_interstitial_impression'),
      onAdFailedToShowFullScreenContent: (InterstitialAd value, error) {
        AppDiagnostics.log('ad_interstitial_show_failed', {'code': error.code});
        unawaited(_finishAd(value, done));
      },
    );
    try {
      AppDiagnostics.log('ad_interstitial_show');
      await ad.show();
    } on Object catch (error, stack) {
      await _finishAd(ad, done);
      await AppDiagnostics.recordError(
        error,
        stack,
        reason: 'Interstitial show failed',
      );
      if (!done.isCompleted) done.complete();
    }
    await done.future.timeout(const Duration(seconds: 45), onTimeout: () {});
  }

  Future<void> _finishAd(Ad ad, Completer<void> done) async {
    final disposal = _dispose(ad);
    unawaited(
      disposal.then((_) {
        _showing = false;
        FullScreenAdGate.release(_lease);
        _lease = null;
        unawaited(load());
      }),
    );
    await disposal.timeout(const Duration(seconds: 2), onTimeout: () {});
    if (!done.isCompleted) done.complete();
  }

  static Future<void> _dispose(Ad ad) async {
    try {
      await ad.dispose();
    } on Object catch (error, stack) {
      await AppDiagnostics.recordError(
        error,
        stack,
        reason: 'Interstitial disposal failed',
      );
    }
  }

  void _resetDailyCounter() {
    final DateTime now = _now().toUtc();
    if (now.year == _day.year &&
        now.month == _day.month &&
        now.day == _day.day) {
      return;
    }
    _day = now;
    _shownToday = 0;
  }

  Future<void> _loadState() async {
    if (_stateLoaded) return;
    final DateTime now = _now().toUtc();
    try {
      final String storedDay = await _preferences.readString(
        _dayKey,
        fallback: '',
      );
      final String today = _dateKey(now);
      if (storedDay == today) {
        _shownToday =
            int.tryParse(
              await _preferences.readString(_shownKey, fallback: '0'),
            ) ??
            0;
        _completedMatchesSinceLastAd =
            int.tryParse(
              await _preferences.readString(_matchesKey, fallback: '0'),
            ) ??
            0;
        final int? lastShownMillis = int.tryParse(
          await _preferences.readString(_lastShownKey, fallback: ''),
        );
        if (lastShownMillis != null) {
          _lastShownAt = DateTime.fromMillisecondsSinceEpoch(
            lastShownMillis,
            isUtc: true,
          );
        }
      } else {
        _day = now;
        _shownToday = 0;
        _completedMatchesSinceLastAd = 0;
        _lastShownAt = null;
      }
    } on Object {
      // Ads must never break match completion when secure storage is
      // unavailable. Keep enforcing the same limits for this app session.
      _day = now;
    }
    _stateLoaded = true;
  }

  Future<void> _persistState() async {
    try {
      await Future.wait(<Future<void>>[
        _preferences.writeString(_dayKey, _dateKey(_day)),
        _preferences.writeString(_shownKey, _shownToday.toString()),
        _preferences.writeString(
          _matchesKey,
          _completedMatchesSinceLastAd.toString(),
        ),
        _preferences.writeString(
          _lastShownKey,
          _lastShownAt?.millisecondsSinceEpoch.toString() ?? '',
        ),
      ]);
    } on Object {
      // Keep the in-memory safety limits active if persistence is unavailable.
    }
  }

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
