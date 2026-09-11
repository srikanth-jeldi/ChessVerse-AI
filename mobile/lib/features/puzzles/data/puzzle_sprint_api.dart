import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/puzzle_sprint.dart';

class PuzzleSprintResultDto {
  const PuzzleSprintResultDto({
    required this.id,
    required this.playerName,
    required this.mode,
    required this.score,
    required this.attempted,
    required this.durationSeconds,
    required this.playedAt,
  });

  final String id;
  final String playerName;
  final String mode;
  final int score;
  final int attempted;
  final int durationSeconds;
  final DateTime playedAt;

  factory PuzzleSprintResultDto.fromJson(Map<String, dynamic> json) =>
      PuzzleSprintResultDto(
        id: json['id'] as String? ?? '',
        playerName: json['playerName'] as String? ?? 'Player',
        mode: json['mode'] as String? ?? 'RUSH',
        score: (json['score'] as num?)?.toInt() ?? 0,
        attempted: (json['attempted'] as num?)?.toInt() ?? 0,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        playedAt:
            DateTime.tryParse(json['playedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class PuzzleSprintApi {
  const PuzzleSprintApi();

  Future<void> record(
    String token, {
    required PuzzleSprintMode mode,
    required int score,
    required int attempted,
    required int durationSeconds,
  }) async {
    await _request(
      token,
      'POST',
      '',
      body: <String, Object>{
        'mode': _mode(mode),
        'score': score,
        'attempted': attempted,
        'durationSeconds': durationSeconds,
      },
    );
  }

  Future<List<PuzzleSprintResultDto>> history(String token) async =>
      _list(await _request(token, 'GET', '/history'));

  Future<List<PuzzleSprintResultDto>> leaderboard(
    String token,
    PuzzleSprintMode mode,
  ) async =>
      _list(await _request(token, 'GET', '/leaderboard?mode=${_mode(mode)}'));

  List<PuzzleSprintResultDto> _list(Object? value) =>
      (value as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PuzzleSprintResultDto.fromJson)
          .toList(growable: false);

  Future<Object?> _request(
    String token,
    String method,
    String path, {
    Map<String, Object>? body,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/puzzle-sprints$path',
    );
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final http.Response response = method == 'POST'
        ? await http.post(uri, headers: headers, body: jsonEncode(body))
        : await http.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Puzzle Sprint sync failed.');
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  String _mode(PuzzleSprintMode mode) => switch (mode) {
    PuzzleSprintMode.rush => 'RUSH',
    PuzzleSprintMode.survival => 'SURVIVAL',
    PuzzleSprintMode.mateInOne => 'MATE_IN_ONE',
  };
}
