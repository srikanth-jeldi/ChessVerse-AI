import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class EngineApi {
  const EngineApi();

  Future<Map<String, dynamic>> bestMove({
    required String fen,
    required int level,
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/v1/engine/best-move'),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, Object>{'fen': fen, 'level': level}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      throw const EngineApiException('Chess engine is unavailable.');
    }

    final Object? decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw const EngineApiException(
          'Chess engine returned an invalid response.');
    }
    final Map<String, dynamic> data =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EngineApiException(
        data['message'] as String? ?? 'Chess engine is unavailable.',
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> analyze({
    required String fen,
    required int level,
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/v1/engine/analyze'),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, Object>{'fen': fen, 'level': level}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      throw const EngineApiException('Chess analysis is unavailable.');
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> reviewMove({
    required String fen,
    required String playedMove,
    required int level,
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/v1/engine/review-move'),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, Object>{
              'fen': fen,
              'playedMove': playedMove,
              'level': level,
            }),
          )
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      throw const EngineApiException('AI move review is unavailable.');
    }
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final Object? decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw const EngineApiException(
          'Chess engine returned an invalid response.');
    }
    final Map<String, dynamic> data =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EngineApiException(
        data['message'] as String? ?? 'Chess engine is unavailable.',
      );
    }
    return data;
  }
}

class EngineApiException implements Exception {
  const EngineApiException(this.message);

  final String message;
}
