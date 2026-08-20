import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../online/data/online_match_api.dart';

class SocialPlayerDto {
  const SocialPlayerDto({required this.connectionId, required this.playerId,
    required this.username, required this.displayName, this.photoUrl,
    required this.country, required this.rating, this.gamesPlayed=0,
    this.wins=0,this.draws=0,this.losses=0,this.peakRating=1200,required this.online,
    required this.relationship});
  final String connectionId;
  final String playerId;
  final String username;
  final String displayName;
  final String? photoUrl;
  final String country;
  final int rating;
  final int gamesPlayed, wins, draws, losses, peakRating;
  final bool online;
  final String relationship;
  factory SocialPlayerDto.fromJson(Map<String, dynamic> json) => SocialPlayerDto(
    connectionId: json['connectionId'] as String? ?? '',
    playerId: json['playerId'] as String? ?? '',
    username: json['username'] as String? ?? '',
    displayName: json['displayName'] as String? ?? 'ChessVerseAI Player',
    photoUrl: json['photoUrl'] as String?,
    country: json['country'] as String? ?? 'Unknown',
    rating: (json['rating'] as num?)?.toInt() ?? 1200,
    gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
    wins: (json['wins'] as num?)?.toInt() ?? 0,
    draws: (json['draws'] as num?)?.toInt() ?? 0,
    losses: (json['losses'] as num?)?.toInt() ?? 0,
    peakRating: (json['peakRating'] as num?)?.toInt() ?? 1200,
    online: json['online'] as bool? ?? false,
    relationship: json['relationship'] as String? ?? 'FRIEND',
  );
}

class SocialChallengeDto {
  const SocialChallengeDto({required this.id, required this.opponentName,
    this.opponentPhotoUrl, required this.minutes, required this.roomCode,
    required this.matchId, required this.status, required this.incoming,
    required this.expiresAt});
  final String id;
  final String opponentName;
  final String? opponentPhotoUrl;
  final int minutes;
  final String roomCode;
  final String matchId;
  final String status;
  final bool incoming;
  final DateTime? expiresAt;
  factory SocialChallengeDto.fromJson(Map<String, dynamic> json) => SocialChallengeDto(
    id: json['id'] as String? ?? '', opponentName: json['opponentName'] as String? ?? 'Player',
    opponentPhotoUrl: json['opponentPhotoUrl'] as String?,
    minutes: (json['timeControlMinutes'] as num?)?.toInt() ?? 10,
    roomCode: json['roomCode'] as String? ?? '', matchId: json['matchId'] as String? ?? '',
    status: json['status'] as String? ?? 'PENDING', incoming: json['incoming'] as bool? ?? false,
    expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
  );
}

class SocialHubDto {
  const SocialHubDto({required this.friends, required this.incoming,
    required this.outgoing, required this.challenges});
  final List<SocialPlayerDto> friends;
  final List<SocialPlayerDto> incoming;
  final List<SocialPlayerDto> outgoing;
  final List<SocialChallengeDto> challenges;
  factory SocialHubDto.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) convert) =>
      (json[key] as List<dynamic>? ?? <dynamic>[]).whereType<Map<String, dynamic>>().map(convert).toList();
    return SocialHubDto(
      friends: list('friends', SocialPlayerDto.fromJson),
      incoming: list('incomingRequests', SocialPlayerDto.fromJson),
      outgoing: list('outgoingRequests', SocialPlayerDto.fromJson),
      challenges: list('challenges', SocialChallengeDto.fromJson),
    );
  }
}

class SocialApi {
  const SocialApi();
  Future<SocialHubDto> load(String token) async => SocialHubDto.fromJson(
    await _request(token, 'GET', '/api/v1/social'));
  Future<SocialHubDto> addFriend(String token, String username) async => SocialHubDto.fromJson(
    await _request(token, 'POST', '/api/v1/social/friends', body: <String, Object?>{'username': username}));
  Future<SocialHubDto> respond(String token, String connectionId, bool accept) async => SocialHubDto.fromJson(
    await _request(token, 'PUT', '/api/v1/social/friends/$connectionId?accept=$accept'));
  Future<SocialHubDto> remove(String token, String friendId) async => SocialHubDto.fromJson(
    await _request(token, 'DELETE', '/api/v1/social/friends/$friendId'));
  Future<SocialChallengeDto> challenge(String token, String friendId, int minutes) async => SocialChallengeDto.fromJson(
    await _request(token, 'POST', '/api/v1/social/challenges', body: <String, Object?>{'friendId': friendId, 'timeControlMinutes': minutes}));
  Future<OnlineMatchDto> acceptChallenge(String token, String id) async => OnlineMatchDto.fromJson(
    await _request(token, 'POST', '/api/v1/social/challenges/$id/accept'));
  Future<SocialHubDto> declineChallenge(String token, String id) async => SocialHubDto.fromJson(
    await _request(token, 'POST', '/api/v1/social/challenges/$id/decline'));

  Future<Map<String, dynamic>> _request(String token, String method, String path,
      {Map<String, Object?>? body}) async {
    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final Map<String, String> headers = <String, String>{'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
    try {
      final http.Response response = switch (method) {
        'POST' => await http.post(uri, headers: headers, body: body == null ? null : jsonEncode(body)).timeout(const Duration(seconds: 15)),
        'PUT' => await http.put(uri, headers: headers, body: body == null ? null : jsonEncode(body)).timeout(const Duration(seconds: 15)),
        'DELETE' => await http.delete(uri, headers: headers).timeout(const Duration(seconds: 15)),
        _ => await http.get(uri, headers: headers).timeout(const Duration(seconds: 15)),
      };
      final Object? decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final Map<String, dynamic> error = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        throw SocialException(error['message'] as String? ?? 'Social request failed.');
      }
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on SocialException { rethrow; }
    on TimeoutException { throw const SocialException('Request timed out. Try again.'); }
    catch (_) { throw const SocialException('Cannot reach ChessVerseAI social services.'); }
  }
}

class SocialException implements Exception { const SocialException(this.message); final String message; }
