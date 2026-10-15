import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_sdk_initializer.dart';
import '../app_preferences.dart';
import '../config/app_config.dart';
import '../diagnostics/app_diagnostics.dart';

class PostMatchAdService {
  PostMatchAdService._();
  @visibleForTesting
  PostMatchAdService.forTesting();

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

  InterstitialAd? _ad;
  bool _loading = false;
  Completer<bool>? _loadCompleter;
  int _shownToday = 0;
  DateTime _day = DateTime.now().toUtc();
  DateTime? _lastShownAt;
  int _completedMatchesSinceLastAd = 0;
  bool _stateLoaded = false;
  final AppPreferences _preferences = const AppPreferences();
  final Set<String> _handledMatches = <String>{};

  bool get supported =>
      AdSdkInitializer.supported &&
      (!kReleaseMode ||
          (defaultTargetPlatform == TargetPlatform.android
              ? AppConfig.admobAndroidInterstitialId.isNotEmpty
              : AppConfig.admobIosInterstitialId.isNotEmpty));

  bool get isReady => _ad != null;
  bool get isLoading => _loading;

  Future<bool> load({Duration timeout = const Duration(seconds: 12)}) async {
    if (!supported) return false;
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
            AppDiagnostics.log('ad_interstitial_loaded');
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

  Future<void> showAfterMatch(String matchId) async {
    if (!supported || !_handledMatches.add(matchId)) return;
    await _loadState();
    _resetDailyCounter();
    _completedMatchesSinceLastAd++;
    if (_completedMatchesSinceLastAd < 3) {
      AppDiagnostics.log('ad_interstitial_skipped', {'reason': 'match_count'});
      await _persistState();
      unawaited(load());
      return;
    }
    final DateTime now = DateTime.now().toUtc();
    final bool cooledDown =
        _lastShownAt == null ||
        now.difference(_lastShownAt!) >= const Duration(minutes: 5);
    if (_shownToday >= 12 || !cooledDown) {
      AppDiagnostics.log('ad_interstitial_skipped', {
        'reason': _shownToday >= 12 ? 'daily_cap' : 'cooldown',
      });
      await _persistState();
      unawaited(load());
      return;
    }

    final InterstitialAd? ad = _ad;
    if (ad == null) {
      // Never hold the post-match navigation while waiting for network demand.
      AppDiagnostics.log('ad_interstitial_skipped', {'reason': 'not_ready'});
      unawaited(load());
      await _persistState();
      return;
    }
    _ad = null;
    final Completer<void> done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        // Failed display attempts must not consume the impression cap or
        // restart the match/cooldown requirements.
        _resetDailyCounter();
        _shownToday++;
        _completedMatchesSinceLastAd = 0;
        _lastShownAt = DateTime.now().toUtc();
        unawaited(_persistState());
      },
      onAdDismissedFullScreenContent: (InterstitialAd value) {
        unawaited(_dispose(value));
        AppDiagnostics.log('ad_interstitial_dismissed');
        if (!done.isCompleted) done.complete();
        unawaited(load());
      },
      onAdImpression: (_) => AppDiagnostics.log('ad_interstitial_impression'),
      onAdFailedToShowFullScreenContent: (InterstitialAd value, error) {
        AppDiagnostics.log('ad_interstitial_show_failed', {'code': error.code});
        unawaited(_dispose(value));
        if (!done.isCompleted) done.complete();
        unawaited(load());
      },
    );
    try {
      AppDiagnostics.log('ad_interstitial_show');
      await ad.show();
    } on Object catch (error, stack) {
      await _dispose(ad);
      await AppDiagnostics.recordError(
        error,
        stack,
        reason: 'Interstitial show failed',
      );
      if (!done.isCompleted) done.complete();
    }
    await done.future.timeout(const Duration(seconds: 45), onTimeout: () {});
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
    final DateTime now = DateTime.now().toUtc();
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
    final DateTime now = DateTime.now().toUtc();
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
