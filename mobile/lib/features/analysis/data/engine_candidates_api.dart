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

  Future<List<EngineCandidateLine>> analyze(
    String token, {
    required String fen,
  }) async {
    final http.Response response = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/api/v1/engine/analyze'),
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{'fen': fen, 'level': 8}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Candidate analysis unavailable');
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
