import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config/app_config.dart';
import '../features/auth/data/auth_session_store.dart';
import 'local_game_archive.dart';

class ComputerGameDraft {
  const ComputerGameDraft(
      {required this.id, required this.updatedAt, required this.state});
  final String id;
  final DateTime updatedAt;
  final Map<String, dynamic> state;
  String get whiteName => state['whiteName'] as String;
  String get blackName => state['blackName'] as String;
  int get plyCount => (state['moves'] as List).length;
  double get level => (state['level'] as num).toDouble();
  bool get humanWhite => state['humanWhite'] as bool;
  Map<String, dynamic> toJson() => {
        'id': id,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'state': state
      };
  factory ComputerGameDraft.fromJson(Map<String, dynamic> json) {
    final state = Map<String, dynamic>.from(json['state'] as Map);
    if (state['version'] != 1 ||
        state['pieces'] is! Map ||
        state['moves'] is! List ||
        state['humanWhite'] is! bool ||
        state['level'] is! num ||
        state['whiteSeconds'] is! int ||
        state['blackSeconds'] is! int ||
        state['whiteName'] is! String ||
        state['blackName'] is! String) {
      throw const FormatException('Invalid saved computer game');
    }
    void validatePosition(Map data) {
      final pieces = data['pieces'];
      if (pieces is! Map ||
          pieces.length > 32 ||
          pieces.entries.any((e) =>
              e.key is! String ||
              !RegExp(r'^[a-h][1-8]$').hasMatch(e.key as String) ||
              e.value is! String ||
              !RegExp(r'^[wb][KQRBNP]$').hasMatch(e.value as String)) ||
          data['moves'] is! List ||
          (data['moves'] as List).any((m) => m is! String) ||
          data['whiteSeconds'] is! int ||
          data['blackSeconds'] is! int) {
        throw const FormatException('Invalid saved position');
      }
    }

    validatePosition(state);
    if (state['result'] == null &&
        ((state['pieces'] as Map).values.where((p) => p == 'wK').length != 1 ||
            (state['pieces'] as Map).values.where((p) => p == 'bK').length !=
                1)) {
      throw const FormatException('Saved game is missing a king');
    }
    for (final row in state['history'] as List? ?? []) {
      if (row is! Map) throw const FormatException('Invalid undo history');
      validatePosition(row);
    }
    return ComputerGameDraft(
        id: json['id'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        state: state);
  }
}

class ComputerGameConflict implements Exception {}

/// Server-backed single slot. The captured bearer token binds every queued write
/// to the original account, even if the user signs out while a save is pending.
class ComputerGameStore {
  @visibleForTesting
  static http.Client client = http.Client();
  static final revision = ValueNotifier<int>(0);
  static Future<void> _pending = Future.value();
  static final Map<String, int> _versions = {};
  static Future<String> activeOwner() async =>
      (await const AuthSessionStore().read())?.token ?? '';
  static Future<T> _serial<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static Future<Map<String, dynamic>> _request(String token,
      [Map<String, dynamic>? body]) async {
    if (token.isEmpty) throw StateError('Sign in to sync My Games');
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/computer-game');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    final response = await (body == null
            ? client.get(uri, headers: headers)
            : client.put(uri, headers: headers, body: jsonEncode(body)))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 409) throw ComputerGameConflict();
    if (response.statusCode != 200) {
      throw StateError('Saved game sync unavailable');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<List<ComputerGameDraft>> load(String owner) =>
      _serial(() async {
        final data = await _request(owner);
        return data['draft'] == null
            ? []
            : [
                ComputerGameDraft.fromJson(
                    Map<String, dynamic>.from(data['draft'] as Map))
              ];
      });

  /// Call after replacement confirmation, before opening the board. A revision
  /// bump transfers control; any stale device can no longer overwrite this slot.
  static Future<void> prepare(String owner, ComputerGameDraft? draft,
          {ComputerGameDraft? replacing}) =>
      _serial(() async {
        final data = await _request(owner);
        if (jsonEncode(data['draft']) !=
            jsonEncode((draft ?? replacing)?.toJson())) {
          throw ComputerGameConflict();
        }
        final result = await _request(
            owner, {'revision': data['revision'], 'draft': draft?.toJson()});
        _versions[owner] = (result['revision'] as num).toInt();
        revision.value++;
      });
  static Future<void> save(String owner, ComputerGameDraft draft) =>
      _serial(() async {
        final version = _versions[owner];
        if (version == null) throw ComputerGameConflict();
        final result = await _request(
            owner, {'revision': version, 'draft': draft.toJson()});
        _versions[owner] = (result['revision'] as num).toInt();
        revision.value++;
      });
  static Future<void> finish(String owner, ComputerGameDraft draft) =>
      _serial(() async {
        final version = _versions[owner];
        if (version == null) return;
        final response = await client
            .post(
                Uri.parse(
                    '${AppConfig.apiBaseUrl}/api/v1/computer-game/finish'),
                headers: {
                  'Authorization': 'Bearer $owner',
                  'Content-Type': 'application/json'
                },
                body:
                    jsonEncode({'revision': version, 'draft': draft.toJson()}))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 409) throw ComputerGameConflict();
        if (response.statusCode != 200) {
          throw StateError('Could not sync finished game');
        }
        final result = jsonDecode(response.body) as Map;
        _versions[owner] = (result['revision'] as num).toInt();
        revision.value++;
      });
  static Future<List<ComputerGameDraft>> history(String owner) async {
    final localGames = List<SavedGameRecord>.from(LocalGameArchive.games);
    final response = await client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/computer-game/history'),
        headers: {
          'Authorization': 'Bearer $owner'
        }).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('History sync unavailable');
    }
    final saved = (jsonDecode(response.body) as List)
        .map((row) =>
            ComputerGameDraft.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    final missing = localGames
        .where((g) =>
            g.mode == 'Play vs AI' &&
            !saved.any((d) =>
                d.whiteName == g.whitePlayer &&
                d.blackName == g.blackPlayer &&
                d.updatedAt.difference(g.playedAt).inSeconds.abs() < 120 &&
                (d.state['moves'] as List).reversed.join(',') ==
                    g.moves.join(',')))
        .map((g) => ComputerGameDraft(
                id: 'legacy-${g.playedAt.microsecondsSinceEpoch}',
                updatedAt: g.playedAt,
                state: {
                  'version': 1,
                  'pieces': <String, String>{},
                  'moves': g.moves.reversed.toList(),
                  'whiteName': g.whitePlayer,
                  'blackName': g.blackPlayer,
                  'humanWhite': true,
                  'level': 0,
                  'whiteSeconds': 0,
                  'blackSeconds': 0,
                  'result': g.result,
                  'detail': g.detail,
                  'outcome': g.playerOutcome,
                  'reviews': g.moveReviews.map((r) => r.toJson()).toList(),
                }))
        .toList();
    for (int start = 0; start < missing.length; start += 25) {
      final batch = missing.skip(start).take(25).toList();
      final uploaded = await client
          .post(
              Uri.parse(
                  '${AppConfig.apiBaseUrl}/api/v1/computer-game/history/import'),
              headers: {
                'Authorization': 'Bearer $owner',
                'Content-Type': 'application/json'
              },
              body: jsonEncode(batch.map((d) => d.toJson()).toList()))
          .timeout(const Duration(seconds: 15));
      if (uploaded.statusCode != 200) {
        throw StateError('Could not sync older games');
      }
      saved.addAll(batch);
    }
    return saved;
  }
}
