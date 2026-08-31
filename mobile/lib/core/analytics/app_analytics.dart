import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Privacy-safe product analytics for the release funnel.
///
/// Never add names, email addresses, auth tokens, chat text, match IDs, or
/// other user-provided values to these events.
abstract final class AppAnalytics {
  static bool _ready = false;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await FirebaseAnalytics.instance
          .setAnalyticsCollectionEnabled(!kDebugMode);
      _ready = !kDebugMode;
    } on Object {
      _ready = false;
    }
  }

  static Future<void> logAuthentication({required bool guest}) async {
    if (!_ready) return;
    await _safeLog(
      guest ? 'guest_session_started' : 'login_completed',
      <String, Object>{'method': guest ? 'guest' : 'account'},
    );
  }

  static Future<void> logGameStarted({
    required String mode,
    required bool guest,
  }) async {
    if (!_ready) return;
    await _safeLog('game_started', <String, Object>{
      'mode': _safeEnum(mode),
      'player_type': guest ? 'guest' : 'account',
    });
  }

  static Future<void> _safeLog(
    String name,
    Map<String, Object> parameters,
  ) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } on Object {
      // Analytics must never interrupt authentication or gameplay.
    }
  }

  static String _safeEnum(String value) {
    final String normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9_]+'), '_');
    if (normalized.isEmpty) return 'unknown';
    return normalized.length <= 40 ? normalized : normalized.substring(0, 40);
  }
}
