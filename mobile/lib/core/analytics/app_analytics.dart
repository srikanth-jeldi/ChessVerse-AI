import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';

/// Privacy-safe product analytics for the release funnel.
///
/// Never add names, email addresses, auth tokens, chat text, match IDs, or
/// other user-provided values to these events.
abstract final class AppAnalytics {
  static bool _ready = false;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
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
