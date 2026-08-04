import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/app_config.dart';
import 'online_socket_connector.dart';

class OnlineMoveDto {
  const OnlineMoveDto({required this.ply, required this.uci});

  final int ply;
  final String uci;

  factory OnlineMoveDto.fromJson(Map<String, dynamic> json) {
    return OnlineMoveDto(
      ply: (json['ply'] as num?)?.toInt() ?? 0,
      uci: (json['uci'] as String? ?? '').toLowerCase(),
    );
  }
}

class OnlineMatchDto {
  const OnlineMatchDto({
    required this.id,
    required this.roomCode,
    required this.status,
    required this.yourColor,
    required this.activeColor,
    required this.whitePlayerName,
    required this.blackPlayerName,
    this.whitePlayerPhotoUrl,
    this.blackPlayerPhotoUrl,
    required this.fen,
    required this.moves,
    this.whiteTimeMs = 600000,
    this.blackTimeMs = 600000,
    this.serverNow,
    this.turnStartedAt,
    this.disconnectedColor,
    this.disconnectDeadline,
    this.result,
    this.resultReason,
    this.drawOfferedByColor,
    this.rematchRequestedByYou = false,
    this.rematchMatchId,
    this.ratingBefore,
    this.ratingAfter,
    this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.durationSeconds,
    this.updatedAt,
  });

  final String id;
  final String roomCode;
  final String status;
  final String yourColor;
  final String activeColor;
  final String? whitePlayerName;
  final String? blackPlayerName;
  final String? whitePlayerPhotoUrl;
  final String? blackPlayerPhotoUrl;
  final String fen;
  final List<OnlineMoveDto> moves;
  final int whiteTimeMs;
  final int blackTimeMs;
  final DateTime? serverNow;
  final DateTime? turnStartedAt;
  final String? disconnectedColor;
  final DateTime? disconnectDeadline;
  final String? result;
  final String? resultReason;
  final String? drawOfferedByColor;
  final bool rematchRequestedByYou;
  final String? rematchMatchId;
  final int? ratingBefore;
  final int? ratingAfter;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? durationSeconds;
  final DateTime? updatedAt;

  bool get isActive => status == 'ACTIVE';
  int get plyCount => moves.length;
  bool get whiteToMove => activeColor == 'WHITE';
  bool get isYourTurn => isActive && activeColor == yourColor;
  String get scoreLabel => switch (result) {
        '1-0' => '1 - 0',
        '0-1' => '0 - 1',
        '1/2-1/2' => '1/2 - 1/2',
        _ => '',
      };
  String get perspectiveScoreLabel {
    if (result == '1/2-1/2') return '1/2 - 1/2';
    final bool userIsWhite = yourColor.toUpperCase() == 'WHITE';
    final bool userWon =
        (result == '1-0' && userIsWhite) || (result == '0-1' && !userIsWhite);
    if (result == '1-0' || result == '0-1') {
      return userWon ? '1 - 0' : '0 - 1';
    }
    return '';
  }

  bool get opponentDisconnected =>
      disconnectedColor != null &&
      disconnectedColor!.toUpperCase() != yourColor.toUpperCase();

  int get disconnectSecondsRemaining {
    final DateTime? deadline = disconnectDeadline;
    final DateTime reference = serverNow ?? DateTime.now().toUtc();
    if (deadline == null) return 0;
    return ((deadline.difference(reference).inMilliseconds + 999) ~/ 1000)
        .clamp(0, 15);
  }

  factory OnlineMatchDto.fromJson(Map<String, dynamic> json) {
    return OnlineMatchDto(
      id: json['id'] as String? ?? '',
      roomCode: json['roomCode'] as String? ?? '',
      status: (json['status'] as String? ?? 'WAITING').toUpperCase(),
      yourColor: (json['yourColor'] as String? ?? 'white').toUpperCase(),
      activeColor: (json['activeColor'] as String? ?? 'white').toUpperCase(),
      whitePlayerName: json['whitePlayerName'] as String?,
      blackPlayerName: json['blackPlayerName'] as String?,
      whitePlayerPhotoUrl: json['whitePlayerPhotoUrl'] as String?,
      blackPlayerPhotoUrl: json['blackPlayerPhotoUrl'] as String?,
      fen: json['fen'] as String? ?? '',
      moves: (json['moves'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(OnlineMoveDto.fromJson)
          .toList(growable: false),
      whiteTimeMs: (json['whiteTimeMs'] as num?)?.toInt() ?? 600000,
      blackTimeMs: (json['blackTimeMs'] as num?)?.toInt() ?? 600000,
      serverNow: DateTime.tryParse(json['serverNow'] as String? ?? ''),
      turnStartedAt: DateTime.tryParse(json['turnStartedAt'] as String? ?? ''),
      disconnectedColor: json['disconnectedColor'] as String?,
      disconnectDeadline:
          DateTime.tryParse(json['disconnectDeadline'] as String? ?? ''),
      result: json['result'] as String?,
      resultReason: json['resultReason'] as String?,
      drawOfferedByColor: json['drawOfferedByColor'] as String?,
      rematchRequestedByYou: json['rematchRequestedByYou'] as bool? ?? false,
      rematchMatchId: json['rematchMatchId'] as String?,
      ratingBefore: (json['ratingBefore'] as num?)?.toInt(),
      ratingAfter: (json['ratingAfter'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
      finishedAt: DateTime.tryParse(json['finishedAt'] as String? ?? ''),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

class OnlineMatchApi {
  const OnlineMatchApi();

  Future<int> onlinePlayerCount() async {
    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/online/presence');
    try {
      final http.Response response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      final Object? decoded =
          response.body.isEmpty ? null : jsonDecode(response.body);
      final Map<String, dynamic> json =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OnlineMatchException(
          json['message'] as String? ?? 'Online presence request failed.',
          statusCode: response.statusCode,
        );
      }
      return (json['onlinePlayers'] as num?)?.toInt() ?? 0;
    } on OnlineMatchException {
      rethrow;
    } on TimeoutException {
      throw const OnlineMatchException(
        'The ChessVerseAI server took too long to respond.',
      );
    } catch (_) {
      throw const OnlineMatchException(
        'Cannot reach the ChessVerseAI online server. Check your connection.',
      );
    }
  }

  Future<OnlineMatchDto> randomMatch(String token) =>
      _request(token, 'POST', '/api/v1/online/queue');

  Future<OnlineMatchDto> createRoom(String token) =>
      _request(token, 'POST', '/api/v1/online/rooms');

  Future<OnlineMatchDto> joinRoom(String token, String roomCode) => _request(
        token,
        'POST',
        '/api/v1/online/rooms/join',
        body: <String, Object?>{'roomCode': roomCode.trim().toUpperCase()},
      );

  Future<OnlineMatchDto> reconnect(String token) =>
      _request(token, 'GET', '/api/v1/online/matches/current');

  Future<OnlineMatchDto> getMatch(String token, String matchId) =>
      _request(token, 'GET', '/api/v1/online/matches/$matchId');

  Future<OnlineMatchDto> cancelWaiting(String token, String matchId) =>
      _request(token, 'DELETE', '/api/v1/online/matches/$matchId/waiting');

  Future<OnlineMatchDto> submitMove(
    String token,
    String matchId, {
    required String uci,
    required int expectedPly,
  }) =>
      _request(
        token,
        'POST',
        '/api/v1/online/matches/$matchId/moves',
        body: <String, Object?>{
          'uci': uci.toLowerCase(),
          'expectedPly': expectedPly,
        },
      );

  Future<OnlineMatchDto> resign(String token, String matchId) =>
      _request(token, 'POST', '/api/v1/online/matches/$matchId/resign');

  Future<OnlineMatchDto> offerDraw(String token, String matchId) =>
      _request(token, 'POST', '/api/v1/online/matches/$matchId/draw');

  Future<OnlineMatchDto> respondDraw(
    String token,
    String matchId, {
    required bool accept,
  }) =>
      _request(
        token,
        'POST',
        '/api/v1/online/matches/$matchId/draw/respond',
        body: <String, Object?>{'accept': accept},
      );

  Future<OnlineMatchDto> requestRematch(String token, String matchId) =>
      _request(token, 'POST', '/api/v1/online/matches/$matchId/rematch');

  Future<List<OnlineMatchDto>> history(String token) async {
    final Object? decoded =
        await _requestJson(token, 'GET', '/api/v1/online/matches/history');
    return (decoded as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(OnlineMatchDto.fromJson)
        .toList(growable: false);
  }

  WebSocketChannel openMatchChannel(String token, String matchId) {
    final Uri api = Uri.parse(AppConfig.apiBaseUrl);
    final Uri socketUri = api.replace(
      scheme: api.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/matches/$matchId',
      query: null,
      fragment: null,
    );
    return connectOnlineSocket(socketUri, token);
  }

  Future<OnlineMatchDto> _request(
    String token,
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final Object? decoded = await _requestJson(token, method, path, body: body);
    final Map<String, dynamic> json =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    return OnlineMatchDto.fromJson(json);
  }

  Future<Object?> _requestJson(
    String token,
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    try {
      final http.Response response = await switch (method) {
        'GET' => http.get(uri, headers: headers),
        'DELETE' => http.delete(uri, headers: headers),
        _ => http.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          ),
      }
          .timeout(const Duration(seconds: 15));
      final Object? decoded =
          response.body.isEmpty ? null : jsonDecode(response.body);
      final Map<String, dynamic> json =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OnlineMatchException(
          json['message'] as String? ?? 'Online play request failed.',
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on OnlineMatchException {
      rethrow;
    } on TimeoutException {
      throw const OnlineMatchException(
        'The ChessVerseAI server took too long to respond.',
      );
    } catch (_) {
      throw const OnlineMatchException(
        'Cannot reach the ChessVerseAI online server. Check your connection.',
      );
    }
  }
}

class OnlineMatchException implements Exception {
  const OnlineMatchException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
}
