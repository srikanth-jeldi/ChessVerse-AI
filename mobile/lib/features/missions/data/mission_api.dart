import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class PlayerMission {
  const PlayerMission({
    required this.code,
    required this.cadence,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.rewardCoins,
    required this.completed,
    required this.claimed,
    required this.resetsAt,
  });

  final String code, cadence, title, description;
  final int progress, target, rewardCoins;
  final bool completed, claimed;
  final DateTime? resetsAt;

  factory PlayerMission.fromJson(Map<String, dynamic> json) => PlayerMission(
        code: json['code'] as String? ?? '',
        cadence: json['cadence'] as String? ?? 'DAILY',
        title: json['title'] as String? ?? 'Mission',
        description: json['description'] as String? ?? '',
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        target: (json['target'] as num?)?.toInt() ?? 1,
        rewardCoins: (json['rewardCoins'] as num?)?.toInt() ?? 0,
        completed: json['completed'] as bool? ?? false,
        claimed: json['claimed'] as bool? ?? false,
        resetsAt:
            DateTime.tryParse(json['resetsAt'] as String? ?? '')?.toLocal(),
      );
}

class MissionBoard {
  const MissionBoard({required this.daily, required this.weekly});
  final List<PlayerMission> daily, weekly;

  factory MissionBoard.fromJson(Map<String, dynamic> json) {
    List<PlayerMission> parse(String key) =>
        (json[key] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(PlayerMission.fromJson)
            .toList(growable: false);
    return MissionBoard(daily: parse('daily'), weekly: parse('weekly'));
  }
}

class MissionApi {
  const MissionApi();

  Future<MissionBoard> load(String token) async {
    final Map<String, dynamic> json = await _request(
      token,
      'GET',
      '/api/v1/progression/missions',
    );
    return MissionBoard.fromJson(json);
  }

  Future<MissionBoard> claim(String token, String code) async {
    final Map<String, dynamic> json = await _request(
      token,
      'POST',
      '/api/v1/progression/missions/${Uri.encodeComponent(code)}/claim',
    );
    return MissionBoard.fromJson(
      json['missions'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> _request(
    String token,
    String method,
    String path,
  ) async {
    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final http.Response response = await (method == 'POST'
            ? http.post(uri, headers: headers)
            : http.get(uri, headers: headers))
        .timeout(const Duration(seconds: 12));
    final Object? decoded =
        response.body.isEmpty ? null : jsonDecode(response.body);
    final Map<String, dynamic> json =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          json['message'] as String? ?? 'Mission service unavailable.');
    }
    return json;
  }
}
