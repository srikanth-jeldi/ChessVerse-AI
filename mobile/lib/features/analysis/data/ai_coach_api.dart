import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class AiCoachAnswer {
  const AiCoachAnswer({
    required this.interactionId,
    required this.answer,
    required this.remainingToday,
    required this.cacheHit,
  });

  final String interactionId;
  final String answer;
  final int remainingToday;
  final bool cacheHit;

  factory AiCoachAnswer.fromJson(Map<String, dynamic> json) => AiCoachAnswer(
        interactionId: json['interactionId'] as String,
        answer: json['answer'] as String,
        remainingToday: (json['remainingToday'] as num).toInt(),
        cacheHit: json['cacheHit'] as bool? ?? false,
      );
}

class AiCoachImpact {
  const AiCoachImpact({
    required this.analyzedGames,
    required this.measuredMoves,
    required this.improvementPercent,
    required this.helpfulPercent,
    required this.enoughEvidence,
    required this.evidenceMessage,
  });
  final int analyzedGames;
  final int measuredMoves;
  final int improvementPercent;
  final int helpfulPercent;
  final bool enoughEvidence;
  final String evidenceMessage;

  factory AiCoachImpact.fromJson(Map<String, dynamic> json) => AiCoachImpact(
        analyzedGames: (json['analyzedGames'] as num).toInt(),
        measuredMoves: (json['measuredMoves'] as num).toInt(),
        improvementPercent: (json['improvementPercent'] as num).toInt(),
        helpfulPercent: (json['helpfulPercent'] as num).toInt(),
        enoughEvidence: json['enoughEvidence'] as bool,
        evidenceMessage: json['evidenceMessage'] as String,
      );
}

class AiCoachApi {
  const AiCoachApi();

  Future<AiCoachAnswer> ask(
    String token, {
    required String fen,
    required String playedMove,
    required String question,
  }) async {
    try {
      final http.Response response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/v1/coach/ask'),
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'fen': fen,
              'playedMove': playedMove,
              'question': question,
            }),
          )
          .timeout(const Duration(seconds: 20));
      final Object? decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiCoachApiException(decoded is Map<String, dynamic>
            ? decoded['message'] as String? ?? 'AI Coach could not answer.'
            : 'AI Coach could not answer.');
      }
      return AiCoachAnswer.fromJson(decoded! as Map<String, dynamic>);
    } on TimeoutException {
      throw const AiCoachApiException('AI Coach took too long. Try again.');
    } on AiCoachApiException {
      rethrow;
    } catch (_) {
      throw const AiCoachApiException('Could not reach AI Coach.');
    }
  }

  Future<void> feedback(String token, String interactionId, bool helpful) async {
    await http
        .patch(
          Uri.parse('${AppConfig.apiBaseUrl}/api/v1/coach/interactions/$interactionId/feedback'),
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, bool>{'helpful': helpful}),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<AiCoachImpact> impact(String token) async {
    final http.Response response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/coach/impact'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    final Object? decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300 ||
        decoded is! Map<String, dynamic>) {
      throw const AiCoachApiException('AI improvement evidence is unavailable.');
    }
    return AiCoachImpact.fromJson(decoded);
  }
}

class AiCoachApiException implements Exception {
  const AiCoachApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
