import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class PostMatchAdService {
  PostMatchAdService._();

  static final PostMatchAdService instance = PostMatchAdService._();
  static const String _androidTest = 'ca-app-pub-3940256099942544/1033173712';
  static const String _iosTest = 'ca-app-pub-3940256099942544/4411468910';

  InterstitialAd? _ad;
  bool _loading = false;
  int _completedMatches = 0;
  int _shownToday = 0;
  DateTime _day = DateTime.now().toUtc();
  DateTime? _lastShownAt;
  final Set<String> _handledMatches = <String>{};

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> load() async {
    if (!supported || _loading || _ad != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: defaultTargetPlatform == TargetPlatform.android
          ? _androidTest
          : _iosTest,
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
    _resetDailyCounter();
    _completedMatches++;
    final DateTime now = DateTime.now().toUtc();
    final bool cooledDown = _lastShownAt == null ||
        now.difference(_lastShownAt!) >= const Duration(minutes: 3);
    if (_completedMatches.isOdd || _shownToday >= 6 || !cooledDown) {
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
    _lastShownAt = now;
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
}
