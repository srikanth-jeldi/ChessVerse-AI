import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class CloudAnalysisPly {
  const CloudAnalysisPly({
    required this.ply,
    required this.fenBefore,
    required this.playedMove,
    required this.bestMove,
    required this.classification,
    required this.centipawnLoss,
    required this.coachingTheme,
    required this.evaluationBeforeCp,
    required this.evaluationAfterCp,
    required this.mateBefore,
    required this.mateAfter,
    required this.principalVariation,
    required this.depth,
  });

  final int ply;
  final String fenBefore;
  final String playedMove;
  final String bestMove;
  final String classification;
  final int centipawnLoss;
  final String coachingTheme;
  final int evaluationBeforeCp;
  final int evaluationAfterCp;
  final int? mateBefore;
  final int? mateAfter;
  final List<String> principalVariation;
  final int depth;

  factory CloudAnalysisPly.fromJson(Map<String, dynamic> json) =>
      CloudAnalysisPly(
        ply: (json['ply'] as num).toInt(),
        fenBefore: json['fenBefore'] as String,
        playedMove: json['playedMove'] as String,
        bestMove: json['bestMove'] as String,
        classification: json['classification'] as String,
        centipawnLoss: (json['centipawnLoss'] as num).toInt(),
        coachingTheme: json['coachingTheme'] as String? ?? 'calculation',
        evaluationBeforeCp: (json['evaluationBeforeCp'] as num).toInt(),
        evaluationAfterCp: (json['evaluationAfterCp'] as num).toInt(),
        mateBefore: (json['mateBefore'] as num?)?.toInt(),
        mateAfter: (json['mateAfter'] as num?)?.toInt(),
        principalVariation:
            (json['principalVariation'] as List<dynamic>? ?? <dynamic>[])
                .whereType<String>()
                .toList(growable: false),
        depth: (json['depth'] as num).toInt(),
      );
}

class CloudAnalysisJob {
  const CloudAnalysisJob({
    required this.id,
    required this.status,
    required this.totalPlies,
    required this.analyzedPlies,
    required this.attemptCount,
    this.errorMessage,
    this.openingEco,
    this.openingName,
    this.bookPlies = 0,
    this.firstDeviationPly,
    this.plies = const <CloudAnalysisPly>[],
  });

  final String id;
  final String status;
  final int totalPlies;
  final int analyzedPlies;
  final int attemptCount;
  final String? errorMessage;
  final String? openingEco;
  final String? openingName;
  final int bookPlies;
  final int? firstDeviationPly;
  final List<CloudAnalysisPly> plies;

  factory CloudAnalysisJob.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> job =
        (json['job'] as Map<String, dynamic>?) ?? json;
    return CloudAnalysisJob(
      id: job['id'] as String,
      status: job['status'] as String,
      totalPlies: (job['totalPlies'] as num).toInt(),
      analyzedPlies: (job['analyzedPlies'] as num).toInt(),
      attemptCount: (job['attemptCount'] as num).toInt(),
      errorMessage: job['errorMessage'] as String?,
      openingEco: job['openingEco'] as String?,
      openingName: job['openingName'] as String?,
      bookPlies: (job['bookPlies'] as num?)?.toInt() ?? 0,
      firstDeviationPly: (job['firstDeviationPly'] as num?)?.toInt(),
      plies: (json['plies'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CloudAnalysisPly.fromJson)
          .toList(growable: false),
    );
  }
}

class AnalysisWindowTrend {
  const AnalysisWindowTrend(
      {required this.games,
      required this.moves,
      required this.averageAccuracy,
      required this.averageCentipawnLoss,
      required this.mistakes,
      required this.blunders});
  final int games;
  final int moves;
  final int averageAccuracy;
  final int averageCentipawnLoss;
  final int mistakes;
  final int blunders;
  factory AnalysisWindowTrend.fromJson(Map<String, dynamic> json) =>
      AnalysisWindowTrend(
          games: (json['games'] as num).toInt(),
          moves: (json['moves'] as num).toInt(),
          averageAccuracy: (json['averageAccuracy'] as num).toInt(),
          averageCentipawnLoss: (json['averageCentipawnLoss'] as num).toInt(),
          mistakes: (json['mistakes'] as num).toInt(),
          blunders: (json['blunders'] as num).toInt());
}

class RecommendationDimension {
  const RecommendationDimension(
      {required this.dimension,
      required this.value,
      required this.recommendations,
      required this.accepted,
      required this.resolved,
      required this.improved,
      required this.successPercent});
  final String dimension;
  final String value;
  final int recommendations;
  final int accepted;
  final int resolved;
  final int improved;
  final int successPercent;
  factory RecommendationDimension.fromJson(Map<String, dynamic> json) =>
      RecommendationDimension(
          dimension: json['dimension'] as String,
          value: json['value'] as String,
          recommendations: (json['recommendations'] as num).toInt(),
          accepted: (json['accepted'] as num).toInt(),
          resolved: (json['resolved'] as num).toInt(),
          improved: (json['improved'] as num).toInt(),
          successPercent: (json['successPercent'] as num).toInt());
}

class AnalysisTrends {
  const AnalysisTrends(this.windows, this.recommendationOutcomes);
  final Map<String, AnalysisWindowTrend> windows;
  final List<RecommendationDimension> recommendationOutcomes;
  factory AnalysisTrends.fromJson(Map<String, dynamic> json) => AnalysisTrends(
      (json['windows'] as Map<String, dynamic>).map(
          (String key, dynamic value) => MapEntry(key,
              AnalysisWindowTrend.fromJson(value as Map<String, dynamic>))),
      (json['recommendationOutcomes'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(RecommendationDimension.fromJson)
          .toList(growable: false));
}

class GameAnalysisApi {
  const GameAnalysisApi();

  Future<CloudAnalysisJob> create(
    String token, {
    required String initialFen,
    required List<String> moves,
    required String clientRequestId,
    int depth = 16,
    String? playerColor,
    String? timeControl,
  }) =>
      _request(
        'POST',
        '/api/v1/analysis/jobs',
        token,
        body: <String, dynamic>{
          'initialFen': initialFen,
          'clientRequestId': clientRequestId,
          'moves': moves,
          'depth': depth,
          if (playerColor != null) 'playerColor': playerColor,
          if (timeControl != null) 'timeControl': timeControl,
        },
      );

  Future<CloudAnalysisJob> results(String token, String id) =>
      _request('GET', '/api/v1/analysis/jobs/$id/results', token);

  Future<CloudAnalysisJob> retry(String token, String id) =>
      _request('POST', '/api/v1/analysis/jobs/$id/retry', token);

  Future<Map<String, int>> weaknessHistory(String token,
      {int limit = 100}) async {
    try {
      final http.Response response = await http.get(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/api/v1/analysis/jobs/weakness-history?limit=$limit'),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      final Object? decoded = jsonDecode(response.body);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded is! Map<String, dynamic>) {
        throw const GameAnalysisApiException(
            'Weakness history could not be loaded.');
      }
      final Map<String, dynamic> counts =
          decoded['categoryCounts'] as Map<String, dynamic>? ??
              <String, dynamic>{};
      return counts.map((String key, dynamic value) =>
          MapEntry<String, int>(key, (value as num).toInt()));
    } on GameAnalysisApiException {
      rethrow;
    } catch (_) {
      throw const GameAnalysisApiException('Could not reach weakness history.');
    }
  }

  Future<AnalysisTrends> trends(String token) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/analysis/jobs/trends'),
        headers: <String, String>{'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      final Object? decoded = jsonDecode(response.body);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded is! Map<String, dynamic>) {
        throw const GameAnalysisApiException(
            'Analysis trends could not be loaded.');
      }
      return AnalysisTrends.fromJson(decoded);
    } on GameAnalysisApiException {
      rethrow;
    } catch (_) {
      throw const GameAnalysisApiException('Could not reach analysis trends.');
    }
  }

  Future<CloudAnalysisJob> _request(
    String method,
    String path,
    String token, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
      final Map<String, String> headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final http.Response response = method == 'GET'
          ? await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 20))
          : await http
              .post(uri,
                  headers: headers,
                  body: body == null ? null : jsonEncode(body))
              .timeout(const Duration(seconds: 20));
      final Object? decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final String message = decoded is Map<String, dynamic>
            ? decoded['message'] as String? ?? 'Analysis request failed.'
            : 'Analysis request failed.';
        throw GameAnalysisApiException(message);
      }
      return CloudAnalysisJob.fromJson(decoded! as Map<String, dynamic>);
    } on TimeoutException {
      throw const GameAnalysisApiException('Analysis request timed out.');
    } on GameAnalysisApiException {
      rethrow;
    } catch (_) {
      throw const GameAnalysisApiException(
          'Could not reach the analysis service.');
    }
  }
}

class GameAnalysisApiException implements Exception {
  const GameAnalysisApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
