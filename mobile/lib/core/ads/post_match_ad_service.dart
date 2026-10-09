import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_sdk_initializer.dart';
import '../app_preferences.dart';
import '../config/app_config.dart';

class PostMatchAdService {
  PostMatchAdService._();

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

  Future<void> load() async {
    if (!supported || _loading || _ad != null) return;
    _loading = true;
    if (!await AdSdkInitializer.ensureReady()) {
      _loading = false;
      return;
    }
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) => _loading = false,
      ),
    );
  }

  Future<void> showAfterMatch(String matchId) async {
    if (!supported || !_handledMatches.add(matchId)) return;
    await _loadState();
    _resetDailyCounter();
    _completedMatchesSinceLastAd++;
    if (_completedMatchesSinceLastAd < 3) {
      await _persistState();
      unawaited(load());
      return;
    }
    final DateTime now = DateTime.now().toUtc();
    final bool cooledDown =
        _lastShownAt == null ||
        now.difference(_lastShownAt!) >= const Duration(minutes: 5);
    if (_shownToday >= 12 || !cooledDown) {
      await _persistState();
      unawaited(load());
      return;
    }
    if (_ad == null) await load();
    final InterstitialAd? ad = _ad;
    if (ad == null) return;
    _ad = null;
    final Completer<void> done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd value) {
        value.dispose();
        if (!done.isCompleted) done.complete();
        unawaited(load());
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd value, _) {
        value.dispose();
        if (!done.isCompleted) done.complete();
        unawaited(load());
      },
    );
    _shownToday++;
    _completedMatchesSinceLastAd = 0;
    _lastShownAt = now;
    await _persistState();
    ad.show();
    await done.future.timeout(const Duration(seconds: 45), onTimeout: () {});
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
