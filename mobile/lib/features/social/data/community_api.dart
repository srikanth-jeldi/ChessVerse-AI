import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/config/app_config.dart';
import 'social_api.dart';

class ClubDto {
  const ClubDto(
      {required this.id,
      required this.name,
      required this.description,
      required this.members,
      required this.ratingRequirement,
      required this.joined});
  final String id, name, description;
  final int members, ratingRequirement;
  final bool joined;
  factory ClubDto.fromJson(Map<String, dynamic> j) => ClubDto(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? 'Club',
      description: j['description'] as String? ?? '',
      members: (j['members'] as num?)?.toInt() ?? 0,
      ratingRequirement: (j['ratingRequirement'] as num?)?.toInt() ?? 0,
      joined: j['joined'] as bool? ?? false);
}

class TournamentDto {
  const TournamentDto(
      {required this.id,
      required this.name,
      required this.description,
      required this.minutes,
      required this.players,
      required this.capacity,
      required this.status,
      required this.joined,
      this.entryCoins = 100,
      this.prizePool = 0,
      this.startsAt,
      this.endsAt});
  final String id, name, description, status;
  final int minutes, players, capacity, entryCoins, prizePool;
  final bool joined;
  final DateTime? startsAt, endsAt;
  factory TournamentDto.fromJson(Map<String, dynamic> j) => TournamentDto(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? 'Tournament',
      description: j['description'] as String? ?? '',
      minutes: (j['timeControlMinutes'] as num?)?.toInt() ?? 10,
      players: (j['players'] as num?)?.toInt() ?? 0,
      capacity: (j['capacity'] as num?)?.toInt() ?? 0,
      status: j['status'] as String? ?? 'OPEN',
      joined: j['joined'] as bool? ?? false,
      entryCoins: (j['entryCoins'] as num?)?.toInt() ?? 100,
      prizePool: (j['prizePool'] as num?)?.toInt() ?? 0,
      startsAt: DateTime.tryParse(j['startsAt'] as String? ?? '')?.toLocal(),
      endsAt: DateTime.tryParse(j['endsAt'] as String? ?? '')?.toLocal());
}

class TournamentDetailDto {
  const TournamentDetailDto(
      {required this.id,
      required this.name,
      required this.description,
      required this.minutes,
      required this.players,
      required this.capacity,
      required this.status,
      required this.joined,
      this.entryCoins = 100,
      this.prizePool = 0,
      required this.currentRound,
      required this.rounds,
      this.startsAt,
      this.endsAt,
      this.champion});
  final String id, name, description, status;
  final int minutes, players, capacity, entryCoins, prizePool, currentRound;
  final bool joined;
  final DateTime? startsAt, endsAt;
  final TournamentPlayerDto? champion;
  final List<TournamentRoundDto> rounds;
  factory TournamentDetailDto.fromJson(Map<String, dynamic> j) =>
      TournamentDetailDto(
          id: j['id'] as String? ?? '',
          name: j['name'] as String? ?? 'Tournament',
          description: j['description'] as String? ?? '',
          minutes: (j['timeControlMinutes'] as num?)?.toInt() ?? 10,
          players: (j['players'] as num?)?.toInt() ?? 0,
          capacity: (j['capacity'] as num?)?.toInt() ?? 0,
          status: j['status'] as String? ?? 'OPEN',
          joined: j['joined'] as bool? ?? false,
          entryCoins: (j['entryCoins'] as num?)?.toInt() ?? 100,
          prizePool: (j['prizePool'] as num?)?.toInt() ?? 0,
          currentRound: (j['currentRound'] as num?)?.toInt() ?? 0,
          startsAt:
              DateTime.tryParse(j['startsAt'] as String? ?? '')?.toLocal(),
          endsAt: DateTime.tryParse(j['endsAt'] as String? ?? '')?.toLocal(),
          champion: j['champion'] is Map<String, dynamic>
              ? TournamentPlayerDto.fromJson(
                  j['champion'] as Map<String, dynamic>)
              : null,
          rounds: (j['rounds'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(TournamentRoundDto.fromJson)
              .toList());
}

class TournamentPlayerDto {
  const TournamentPlayerDto(this.id, this.name, this.photoUrl);
  final String id, name;
  final String? photoUrl;
  factory TournamentPlayerDto.fromJson(Map<String, dynamic> j) =>
      TournamentPlayerDto(j['id'] as String? ?? '',
          j['displayName'] as String? ?? 'Player', j['photoUrl'] as String?);
}

class TournamentPairingDto {
  const TournamentPairingDto(this.board, this.white, this.black, this.matchId,
      this.winner, this.status);
  final int board;
  final TournamentPlayerDto? white, black, winner;
  final String? matchId;
  final String status;
  factory TournamentPairingDto.fromJson(
          Map<String, dynamic> j) =>
      TournamentPairingDto(
          (j['board'] as num?)?.toInt() ?? 0,
          j['white'] is Map<String, dynamic>
              ? TournamentPlayerDto.fromJson(j['white'] as Map<String, dynamic>)
              : null,
          j['black'] is Map<String, dynamic>
              ? TournamentPlayerDto.fromJson(j['black'] as Map<String, dynamic>)
              : null,
          j['matchId'] as String?,
          j['winner'] is Map<String, dynamic>
              ? TournamentPlayerDto.fromJson(
                  j['winner'] as Map<String, dynamic>)
              : null,
          j['status'] as String? ?? 'ACTIVE');
}

class TournamentRoundDto {
  const TournamentRoundDto(this.number, this.status, this.pairings);
  final int number;
  final String status;
  final List<TournamentPairingDto> pairings;
  factory TournamentRoundDto.fromJson(
          Map<String, dynamic> j) =>
      TournamentRoundDto(
          (j['number'] as num?)?.toInt() ?? 0,
          j['status'] as String? ?? 'ACTIVE',
          (j['pairings'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(TournamentPairingDto.fromJson)
              .toList());
}

class ConversationDto {
  const ConversationDto(
      {required this.playerId,
      required this.displayName,
      this.photoUrl,
      required this.online,
      required this.lastMessage,
      required this.unread});
  final String playerId, displayName, lastMessage;
  final String? photoUrl;
  final bool online;
  final int unread;
  factory ConversationDto.fromJson(Map<String, dynamic> j) => ConversationDto(
      playerId: j['playerId'] as String? ?? '',
      displayName: j['displayName'] as String? ?? 'Player',
      photoUrl: j['photoUrl'] as String?,
      online: j['online'] as bool? ?? false,
      lastMessage: j['lastMessage'] as String? ?? '',
      unread: (j['unread'] as num?)?.toInt() ?? 0);
}

class MessageDto {
  const MessageDto(
      {required this.id,
      required this.senderId,
      required this.recipientId,
      required this.body,
      required this.mine,
      required this.sentAt,
      required this.delivered,
      required this.seen,
      this.attachmentName,
      this.attachmentType,
      this.attachmentSize,
      this.pending = false});
  final String id, senderId, recipientId, body;
  final bool mine, delivered, seen, pending;
  final String? attachmentName, attachmentType;
  final int? attachmentSize;
  final DateTime sentAt;
  factory MessageDto.fromJson(Map<String, dynamic> j) => MessageDto(
      id: j['id'] as String? ?? '',
      senderId: j['senderId'] as String? ?? '',
      recipientId: j['recipientId'] as String? ?? '',
      body: j['body'] as String? ?? '',
      mine: j['mine'] as bool? ?? false,
      sentAt: DateTime.tryParse(j['sentAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      delivered: j['delivered'] as bool? ?? false,
      seen: j['seen'] as bool? ?? false,
      attachmentName: j['attachmentName'] as String?,
      attachmentType: j['attachmentType'] as String?,
      attachmentSize: (j['attachmentSize'] as num?)?.toInt());
}

class CommunityDto {
  const CommunityDto(
      {required this.clubs,
      required this.tournaments,
      required this.conversations,
      required this.fairPlayScore,
      this.circuitPoints = 0});
  final List<ClubDto> clubs;
  final List<TournamentDto> tournaments;
  final List<ConversationDto> conversations;
  final int fairPlayScore;
  final int circuitPoints;
  factory CommunityDto.fromJson(Map<String, dynamic> j) {
    List<T> items<T>(String k, T Function(Map<String, dynamic>) f) =>
        (j[k] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(f)
            .toList();
    return CommunityDto(
        clubs: items('clubs', ClubDto.fromJson),
        tournaments: items('tournaments', TournamentDto.fromJson),
        conversations: items('conversations', ConversationDto.fromJson),
        fairPlayScore: (j['fairPlayScore'] as num?)?.toInt() ?? 100,
        circuitPoints: (j['circuitPoints'] as num?)?.toInt() ?? 0);
  }
}

class CommunityApi {
  const CommunityApi();
  Future<CommunityDto> load(String token) async =>
      CommunityDto.fromJson(await _request(token, 'GET', '/api/v1/community'));
  Future<CommunityDto> club(String token, String id, bool join) async =>
      CommunityDto.fromJson(await _request(
          token, 'PUT', '/api/v1/community/clubs/$id?join=$join'));
  Future<CommunityDto> tournament(String token, String id, bool join) async =>
      CommunityDto.fromJson(await _request(
          token, 'PUT', '/api/v1/community/tournaments/$id?join=$join'));
  Future<TournamentDetailDto> tournamentDetail(String token, String id) async =>
      TournamentDetailDto.fromJson(
          await _request(token, 'GET', '/api/v1/community/tournaments/$id'));
  Future<List<MessageDto>> messages(String token, String friendId) async =>
      (await _requestList(token, 'GET', '/api/v1/community/messages/$friendId'))
          .whereType<Map<String, dynamic>>()
          .map(MessageDto.fromJson)
          .toList();
  Future<MessageDto> send(
          String token, String recipientId, String body) async =>
      MessageDto.fromJson(await _request(
          token, 'POST', '/api/v1/community/messages',
          body: <String, Object?>{'recipientId': recipientId, 'body': body}));
  Future<void> markDelivered(String token) async =>
      _raw(token, 'POST', '/api/v1/community/messages/delivered', null);
  Future<MessageDto> sendAttachment(String token, String recipientId,
      String name, List<int> bytes, String? mimeType, String body) async {
    try {
      final request = http.MultipartRequest(
          'POST',
          Uri.parse(
              '${AppConfig.apiBaseUrl}/api/v1/community/messages/attachments'))
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['recipientId'] = recipientId
        ..fields['body'] = body
        ..files.add(http.MultipartFile.fromBytes('file', bytes,
            filename: name,
            contentType: mimeType == null ? null : MediaType.parse(mimeType)));
      final response =
          await request.send().timeout(const Duration(seconds: 30));
      final text = await response.stream.bytesToString();
      final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded is Map<String, dynamic>
            ? decoded['message'] as String?
            : null;
        throw SocialException(error ?? 'Attachment upload failed.');
      }
      return MessageDto.fromJson(decoded as Map<String, dynamic>);
    } on SocialException {
      rethrow;
    } on TimeoutException {
      throw const SocialException('Attachment upload timed out.');
    } catch (_) {
      throw const SocialException('Cannot upload this attachment.');
    }
  }

  Future<List<int>> attachmentBytes(String token, String messageId) async {
    final response = await http.get(
      Uri.parse(
          '${AppConfig.apiBaseUrl}/api/v1/community/messages/$messageId/attachment'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const SocialException('Attachment could not be downloaded.');
    }
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> _request(
      String token, String method, String path,
      {Map<String, Object?>? body}) async {
    final Object value = await _raw(token, method, path, body);
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }

  Future<List<dynamic>> _requestList(
      String token, String method, String path) async {
    final Object value = await _raw(token, method, path, null);
    return value is List<dynamic> ? value : <dynamic>[];
  }

  Future<Object> _raw(String token, String method, String path,
      Map<String, Object?>? body) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      final response = method == 'POST'
          ? await http
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15))
          : method == 'PUT'
              ? await http
                  .put(uri, headers: headers)
                  .timeout(const Duration(seconds: 15))
              : await http
                  .get(uri, headers: headers)
                  .timeout(const Duration(seconds: 15));
      final Object decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final e =
            decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        throw SocialException(
            e['message'] as String? ?? 'Community request failed.');
      }
      return decoded;
    } on SocialException {
      rethrow;
    } on TimeoutException {
      throw const SocialException('Community request timed out.');
    } catch (_) {
      throw const SocialException(
          'Cannot reach ChessVerseAI community services.');
    }
  }
}
