import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class PlayerRatingDto {
  const PlayerRatingDto({
    required this.playerId,
    required this.displayName,
    required this.country,
    required this.rating,
    required this.peakRating,
    required this.gamesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.globalRank,
    required this.countryRank,
  });

  final String playerId;
  final String displayName;
  final String country;
  final int rating;
  final int peakRating;
  final int gamesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int globalRank;
  final int countryRank;

  factory PlayerRatingDto.fromJson(Map<String, dynamic> json) =>
      PlayerRatingDto(
        playerId: json['playerId'] as String? ?? '',
        displayName: json['displayName'] as String? ?? 'ChessVerseAI Player',
        country: json['country'] as String? ?? 'Unknown',
        rating: (json['rating'] as num?)?.toInt() ?? 1200,
        peakRating: (json['peakRating'] as num?)?.toInt() ?? 1200,
        gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        draws: (json['draws'] as num?)?.toInt() ?? 0,
        losses: (json['losses'] as num?)?.toInt() ?? 0,
        globalRank: (json['globalRank'] as num?)?.toInt() ?? 1,
        countryRank: (json['countryRank'] as num?)?.toInt() ?? 1,
      );
}

class LeaderboardEntryDto {
  const LeaderboardEntryDto({
    required this.rank,
    required this.playerId,
    required this.displayName,
    required this.country,
    required this.rating,
    required this.gamesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.you,
  });

  final int rank;
  final String playerId;
  final String displayName;
  final String country;
  final int rating;
  final int gamesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final bool you;

  factory LeaderboardEntryDto.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntryDto(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        playerId: json['playerId'] as String? ?? '',
        displayName: json['displayName'] as String? ?? 'ChessVerseAI Player',
        country: json['country'] as String? ?? 'Unknown',
        rating: (json['rating'] as num?)?.toInt() ?? 1200,
        gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        draws: (json['draws'] as num?)?.toInt() ?? 0,
        losses: (json['losses'] as num?)?.toInt() ?? 0,
        you: json['you'] as bool? ?? false,
      );
}

class LeaderboardDto {
  const LeaderboardDto({
    required this.scope,
    required this.country,
    required this.you,
    required this.entries,
  });

  final String scope;
  final String? country;
  final PlayerRatingDto you;
  final List<LeaderboardEntryDto> entries;

  factory LeaderboardDto.fromJson(Map<String, dynamic> json) => LeaderboardDto(
        scope: json['scope'] as String? ?? 'global',
        country: json['country'] as String?,
        you: PlayerRatingDto.fromJson(
          json['you'] as Map<String, dynamic>? ?? <String, dynamic>{},
        ),
        entries: (json['entries'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(LeaderboardEntryDto.fromJson)
            .toList(growable: false),
      );
}

class LeaderboardApi {
  const LeaderboardApi();

  Future<LeaderboardDto> load(
    String token, {
    required String scope,
    String? country,
  }) async {
    final Map<String, String> query = <String, String>{'scope': scope};
    if (country != null && country.isNotEmpty) query['country'] = country;
    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/leaderboard')
        .replace(queryParameters: query);
    return LeaderboardDto.fromJson(await _request(token, 'GET', uri));
  }

  Future<PlayerRatingDto> syncCountry(String token, String country) async {
    final Uri uri =
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/leaderboard/me/country');
    return PlayerRatingDto.fromJson(
      await _request(token, 'PUT', uri, body: <String, Object?>{
        'country': country,
      }),
    );
  }

  Future<Map<String, dynamic>> _request(
    String token,
    String method,
    Uri uri, {
    Map<String, Object?>? body,
  }) async {
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    try {
      final http.Response response = method == 'PUT'
          ? await http
              .put(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15))
          : await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
      final Object? decoded =
          response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final Map<String, dynamic> error =
            decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        throw LeaderboardException(
          error['message'] as String? ?? 'Leaderboard request failed.',
        );
      }
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on LeaderboardException {
      rethrow;
    } on TimeoutException {
      throw const LeaderboardException('Leaderboard request timed out.');
    } catch (_) {
      throw const LeaderboardException(
        'Cannot reach the ChessVerseAI leaderboard.',
      );
    }
  }
}

class LeaderboardException implements Exception {
  const LeaderboardException(this.message);
  final String message;
}
