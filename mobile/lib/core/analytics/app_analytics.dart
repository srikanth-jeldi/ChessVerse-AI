import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../../features/auth/data/auth_session_store.dart';
import '../diagnostics/firebase_bootstrap.dart';

/// Privacy-safe product analytics for the release funnel.
///
/// Never add names, email addresses, auth tokens, chat text, match IDs, or
/// other user-provided values to these events.
abstract final class AppAnalytics {
  static bool _ready = false;
  static Future<void> logAdTrial(String event, String arm) async {
    if (!_ready) return;
    if (event == 'assigned') {
      try {
        await FirebaseAnalytics.instance.setUserProperty(
          name: 'post_match_ad_trial_arm',
          value: arm,
        );
      } on Object {
        /* Analytics must not interrupt play. */
      }
    }
    await _safeLog('post_match_ad_trial', {
      'experiment': 'rewarded_interstitial_v1',
      'event': event,
      'arm': arm,
    });
  }

  @visibleForTesting
  static Future<void> Function(String, Map<String, Object>)? featureRecorder;

  /// Fixed event names and categorical metadata only; never chess files or IDs.
  static Future<void> logFeature(
    FeatureEvent event, {
    String? mode,
    String? format,
    bool? assisted,
  }) async {
    final parameters = <String, Object>{
      'tracking_version': 2,
      if (mode != null) 'mode': _safeEnum(mode),
      if (format != null) 'format': _safeEnum(format),
      if (assisted != null) 'assisted': assisted ? 1 : 0,
    };
    if (kDebugMode && featureRecorder != null) {
      try {
        await featureRecorder!(event.name, parameters);
      } on Object {
        // Test failures in the analytics transport must not interrupt play.
      }
      return;
    }
    await Future.wait<void>([
      if (_ready) _safeLog(event.name, parameters),
      if (!kDebugMode) _logFeatureToServer(event, mode ?? format ?? 'unknown'),
    ]);
  }

  static Future<void> _logFeatureToServer(
    FeatureEvent event,
    String context,
  ) async {
    try {
      final session = await const AuthSessionStore().read();
      if (session != null && !session.isExpired) {
        await _safeServerLog(session.token, event.name, _safeEnum(context));
      }
    } on Object {
      // Reporting must not interrupt play, including while offline.
    }
  }

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await FirebaseBootstrap.ensureReady();
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
        !kDebugMode,
      );
      _ready = !kDebugMode;
    } on Object {
      _ready = false;
    }
  }

  static Future<void> logAuthentication({
    required bool guest,
    String? token,
  }) async {
    await Future.wait(<Future<void>>[
      if (_ready)
        _safeLog(
          guest ? 'guest_session_started' : 'login_completed',
          <String, Object>{'method': guest ? 'guest' : 'account'},
        ),
      if (token != null)
        _safeServerLog(token, 'session_started', guest ? 'guest' : 'account'),
    ]);
  }

  static Future<void> logGameStarted({
    required String mode,
    required bool guest,
    String? token,
  }) async {
    final String safeMode = _safeEnum(mode);
    await Future.wait(<Future<void>>[
      if (_ready)
        _safeLog('game_started', <String, Object>{
          'mode': safeMode,
          'player_type': guest ? 'guest' : 'account',
        }),
      if (token != null) _safeServerLog(token, 'game_started', safeMode),
    ]);
  }

  static Future<void> logProductEvent({
    required String token,
    required String name,
    String context = '',
  }) => _safeServerLog(token, name, _safeEnum(context));

  static Future<void> _safeServerLog(
    String token,
    String name,
    String context,
  ) async {
    try {
      await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/v1/analytics/events'),
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, Object>{
              'id': const Uuid().v4(),
              'name': name,
              'context': context,
            }),
          )
          .timeout(const Duration(seconds: 3));
    } on Object {
      // First-party analytics must never interrupt authentication or gameplay.
    }
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
    final String normalized = value.trim().toLowerCase().replaceAll(
      RegExp('[^a-z0-9_]+'),
      '_',
    );
    if (normalized.isEmpty) return 'unknown';
    return normalized.length <= 40 ? normalized : normalized.substring(0, 40);
  }
}

// Names are the reporting contract in Firebase/GA4.
// ignore_for_file: constant_identifier_names
enum FeatureEvent {
  chat_opened,
  chat_message_sent,
  ai_coach_question,
  feature_opened,
  club_puzzle_viewed,
  club_puzzle_completed,
  club_puzzle_hint,
  club_puzzle_solution_viewed,
  game_first_move,
  game_completed,
  import_completed,
  imported_review_viewed,
  saved_review_viewed,
  puzzles_viewed,
  puzzle_first_move,
  puzzle_completed,
  mistake_bank_viewed,
  mistake_practice_started,
  mistake_practice_completed,
}

/// Deduplicates accepted human moves within a board visit/attempt. A resumed
/// visit may emit again, allowing daily unique players to include resumed play.
class PlayActivityTracker {
  bool _played = false;
  DateTime? _playedDay;

  bool acceptHumanMove({DateTime? at}) {
    final now = (at ?? DateTime.now()).toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final day = DateTime.utc(now.year, now.month, now.day);
    if (_played && _playedDay == day) return false;
    _played = true;
    _playedDay = day;
    return true;
  }

  void reset() => _played = false;
}
