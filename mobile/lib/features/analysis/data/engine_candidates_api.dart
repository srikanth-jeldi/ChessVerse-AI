import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class EngineCandidateLine {
  const EngineCandidateLine({
    required this.move,
    required this.evaluationCp,
    required this.principalVariation,
    this.mateIn,
  });

  final String move;
  final int evaluationCp;
  final int? mateIn;
  final List<String> principalVariation;

  factory EngineCandidateLine.fromJson(Map<String, dynamic> json) =>
      EngineCandidateLine(
        move: json['move'] as String,
        evaluationCp: (json['evaluationCp'] as num).toInt(),
        mateIn: (json['mateIn'] as num?)?.toInt(),
        principalVariation:
            (json['principalVariation'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<String>()
                .toList(growable: false),
      );
}

class EngineCandidatesApi {
  const EngineCandidatesApi();

  static final Map<String, List<EngineCandidateLine>> _cache =
      <String, List<EngineCandidateLine>>{};
  static final Map<String, Future<List<EngineCandidateLine>>> _inFlight =
      <String, Future<List<EngineCandidateLine>>>{};

  Future<List<EngineCandidateLine>> analyze(
    String token, {
    required String fen,
  }) {
    final String key = fen.trim();
    final List<EngineCandidateLine>? cached = _cache[key];
    if (cached != null) return Future<List<EngineCandidateLine>>.value(cached);
    return _inFlight.putIfAbsent(key, () async {
      try {
        final List<EngineCandidateLine> result = await _request(
          token,
          fen: key,
          level: 8,
        );
        _cache[key] = result;
        return result;
      } on EngineCandidatesApiException catch (error) {
        if (!error.retryable) rethrow;
        final List<EngineCandidateLine> result = await _request(
          token,
          fen: key,
          level: 5,
        );
        _cache[key] = result;
        return result;
      } on TimeoutException {
        final List<EngineCandidateLine> result = await _request(
          token,
          fen: key,
          level: 5,
        );
        _cache[key] = result;
        return result;
      } finally {
        _inFlight.remove(key);
      }
    });
  }

  Future<List<EngineCandidateLine>> _request(
    String token, {
    required String fen,
    required int level,
  }) async {
    final http.Response response = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/api/v1/engine/analyze'),
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{'fen': fen, 'level': level}),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EngineCandidatesApiException(response.statusCode);
    }
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return const <EngineCandidateLine>[];
    return (decoded['candidates'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(EngineCandidateLine.fromJson)
        .take(5)
        .toList(growable: false);
  }
}

class EngineCandidatesApiException implements Exception {
  const EngineCandidatesApiException(this.statusCode);

  final int statusCode;

  bool get retryable =>
      statusCode == 408 ||
      statusCode == 429 ||
      statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 504;
}
