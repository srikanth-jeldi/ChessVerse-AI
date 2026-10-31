import 'dart:convert';

import 'package:http/http.dart' as http;

class PublicGameImport {
  PublicGameImport({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  void close() => _client.close();

  static String gameKey(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        !{'chess.com', 'www.chess.com'}.contains(uri.host.toLowerCase())) {
      throw const FormatException('Paste a public Chess.com game link.');
    }
    final match =
        RegExp(r'^/(?:analysis/)?game/(live|daily)/(\d+)/?$')
            .firstMatch(uri.path) ??
        RegExp(r'^/(live|daily)/game/(\d+)/?$').firstMatch(uri.path);
    if (match == null) {
      throw const FormatException(
        'This game link format is not supported. Import a PGN file instead.',
      );
    }
    return '${match[1]}/${match[2]}';
  }

  Future<String> fetch({
    required String link,
    required String username,
    required DateTime month,
  }) async {
    final key = gameKey(link);
    final player = username.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{2,50}$').hasMatch(player)) {
      throw const FormatException(
        'Enter the Chess.com username of either player.',
      );
    }
    // Only documented public archives. Never fetch a user-supplied host or redirect.
    final uri = Uri.https(
      'api.chess.com',
      '/pub/player/${player.toLowerCase()}/games/${month.year}/${month.month.toString().padLeft(2, '0')}',
    );
    final request = http.Request('GET', uri)..followRedirects = false;
    request.headers['Accept'] = 'application/json';
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 429) {
      throw const FormatException('Chess.com is busy. Please try again later.');
    }
    if (response.statusCode != 200) {
      throw const FormatException(
        'Public game archive unavailable. Check the player and month, or import PGN.',
      );
    }
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 20),
    )) {
      if (bytes.length + chunk.length > 15000000) {
        throw const FormatException(
          'This archive is too large. Import the game as PGN instead.',
        );
      }
      bytes.addAll(chunk);
    }
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! Map || data['games'] is! List) {
      throw const FormatException('The public archive response is invalid.');
    }
    for (final game in data['games'] as List) {
      if (game is! Map || game['url'] is! String) continue;
      String candidate;
      try {
        candidate = gameKey(game['url'] as String);
      } on FormatException {
        continue;
      }
      if (candidate != key) continue;
      if (game['rules'] != 'chess') {
        throw const FormatException(
          'Only standard chess games can be imported.',
        );
      }
      final pgn = game['pgn'];
      if (pgn is String && pgn.trim().isNotEmpty && pgn.length <= 1000000) {
        return pgn;
      }
    }
    throw const FormatException(
      'Game not found in this player’s monthly archive. Check the month; recent games may appear later.',
    );
  }
}
