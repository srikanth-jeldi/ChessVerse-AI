import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class OnlineMoveDto {
  const OnlineMoveDto({
    required this.ply,
    required this.uci,
    required this.playerId,
  });

  final int ply;
  final String uci;
  final String playerId;

  factory OnlineMoveDto.fromJson(Map<String, dynamic> json) => OnlineMoveDto(
        ply: (json['ply'] as num).toInt(),
        uci: json['uci'] as String,
        playerId: json['playerId'] as String,
      );
}

class OnlineMatchDto {
  const OnlineMatchDto({
    required this.id,
    required this.roomCode,
    required this.status,
    required this.yourColor,
    required this.activeColor,
    required this.plyCount,
    required this.whitePlayerName,
    required this.blackPlayerName,
    required this.moves,
  });

  final String id;
  final String roomCode;
  final String status;
  final String yourColor;
  final String activeColor;
  final int plyCount;
  final String? whitePlayerName;
  final String? blackPlayerName;
  final List<OnlineMoveDto> moves;

  bool get isActive => status.toLowerCase() == 'active';
  bool get isWaiting => status.toLowerCase() == 'waiting';

  factory OnlineMatchDto.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawMoves =
        json['moves'] as List<dynamic>? ?? const <dynamic>[];
    return OnlineMatchDto(
      id: json['id'] as String,
      roomCode: json['roomCode'] as String,
      status: json['status'] as String,
      yourColor: json['yourColor'] as String,
      activeColor: json['activeColor'] as String,
      plyCount: (json['plyCount'] as num).toInt(),
      whitePlayerName: json['whitePlayerName'] as String?,
      blackPlayerName: json['blackPlayerName'] as String?,
      moves: rawMoves
          .map(
            (dynamic item) =>
                OnlineMoveDto.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false)
        ..sort((OnlineMoveDto a, OnlineMoveDto b) => a.ply.compareTo(b.ply)),
    );
  }
}

class OnlineMatchApi {
  const OnlineMatchApi({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<OnlineMatchDto> createRoom(String token) =>
      _request('POST', '/api/online/rooms', token);

  Future<OnlineMatchDto> joinRoom(String token, String roomCode) => _request(
        'POST',
        '/api/online/rooms/join',
        token,
        body: <String, dynamic>{'roomCode': roomCode.trim().toUpperCase()},
      );

  Future<OnlineMatchDto> randomMatch(String token) =>
      _request('POST', '/api/online/matchmaking/random', token);

  Future<OnlineMatchDto> reconnect(String token) =>
      _request('GET', '/api/online/reconnect', token);

  Future<OnlineMatchDto> getMatch(String token, String matchId) =>
      _request('GET', '/api/online/matches/$matchId', token);

  Future<OnlineMatchDto> submitMove(
    String token,
    String matchId, {
    required String uci,
    required int expectedPly,
  }) =>
      _request(
        'POST',
        '/api/online/matches/$matchId/moves',
        token,
        body: <String, dynamic>{'uci': uci, 'expectedPly': expectedPly},
      );

  Future<OnlineMatchDto> _request(
    String method,
    String path,
    String token, {
    Map<String, dynamic>? body,
  }) async {
    final http.Client client = _client ?? http.Client();
    try {
      final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
      final Map<String, String> headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      final http.Response response = await (method == 'GET'
              ? client.get(uri, headers: headers)
              : client.post(
                  uri,
                  headers: headers,
                  body: body == null ? null : jsonEncode(body),
                ))
          .timeout(const Duration(seconds: 15));
      final dynamic decoded =
          response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final String message = decoded is Map<String, dynamic>
            ? (decoded['message'] ??
                    decoded['error'] ??
                    'Online request failed')
                .toString()
            : 'Online request failed (${response.statusCode})';
        throw OnlineMatchException(message);
      }
      return OnlineMatchDto.fromJson(decoded as Map<String, dynamic>);
    } on TimeoutException {
      throw const OnlineMatchException(
        'The server took too long to respond. Please try again.',
      );
    } on FormatException {
      throw const OnlineMatchException('The server returned an invalid reply.');
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}

class OnlineMatchException implements Exception {
  const OnlineMatchException(this.message);

  final String message;

  @override
  String toString() => message;
}
