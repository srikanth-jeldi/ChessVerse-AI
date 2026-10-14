import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';
import '../diagnostics/app_diagnostics.dart';
import 'ad_sdk_initializer.dart';

/// Compact banner reserved for non-gameplay screens.
///
/// The slot collapses completely when an ad is unavailable, so a failed ad
/// request can never leave an empty strip or block navigation.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  static const bool _enableDebugAds = bool.fromEnvironment(
    'ENABLE_ADMOB_TEST_ADS',
  );
  static const String _androidTest = 'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTest = 'ca-app-pub-3940256099942544/2934735716';

  BannerAd? _ad;
  bool _loaded = false;

  bool get _platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _productionId => defaultTargetPlatform == TargetPlatform.android
      ? AppConfig.admobAndroidBannerId
      : AppConfig.admobIosBannerId;

  bool get _supported =>
      _platformSupported &&
      (kReleaseMode ? _productionId.isNotEmpty : _enableDebugAds);

  String get _adUnitId {
    if (kReleaseMode) return _productionId;
    return defaultTargetPlatform == TargetPlatform.android
        ? _androidTest
        : _iosTest;
  }

  @override
  void initState() {
    super.initState();
    if (_supported) _load();
  }

  Future<void> _load() async {
    if (!await AdSdkInitializer.ensureReady() || !mounted) return;
    AppDiagnostics.log('ad_banner_load');
    final BannerAd ad = BannerAd(
      size: AdSize.banner,
      adUnitId: _adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad value) {
          if (!mounted) {
            unawaited(_disposeAd(value));
            return;
          }
          setState(() => _loaded = true);
          AppDiagnostics.log('ad_banner_loaded');
        },
        onAdFailedToLoad: (Ad value, LoadAdError _) {
          unawaited(_disposeAd(value));
          _ad = null;
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    _ad = ad;
    try {
      await ad.load();
    } on Object catch (error, stack) {
      _ad = null;
      await _disposeAd(ad);
      if (mounted) setState(() => _loaded = false);
      await AppDiagnostics.recordError(
        error,
        stack,
        reason: 'Banner load failed',
      );
    }
  }

  @override
  void dispose() {
    final ad = _ad;
    if (ad != null) unawaited(_disposeAd(ad));
    super.dispose();
  }

  static Future<void> _disposeAd(Ad ad) async {
    try {
      await ad.dispose();
    } on Object catch (error, stack) {
      await AppDiagnostics.recordError(
        error,
        stack,
        reason: 'Banner disposal failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final BannerAd? ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: ColoredBox(
        color: const Color(0xFF030A12),
        child: SizedBox(
          height: ad.size.height.toDouble(),
          width: double.infinity,
          child: Center(
            child: SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
          ),
        ),
      ),
    );
  }
}
