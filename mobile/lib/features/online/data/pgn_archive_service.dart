import '../../../core/local_game_archive.dart';

class PgnArchiveService {
  const PgnArchiveService();

  String exportGames(Iterable<SavedGameRecord> games) =>
      games.map(_exportGame).join('\n\n');

  List<SavedGameRecord> importGames(String source) {
    final String normalized = source.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty)
      throw const FormatException('The PGN file is empty.');
    final List<String> chunks = normalized
        .split(RegExp(r'\n\s*\n(?=\s*\[Event\s)', multiLine: true))
        .where((String value) => value.trim().isNotEmpty)
        .toList(growable: false);
    final List<SavedGameRecord> games = <SavedGameRecord>[];
    for (final String chunk in chunks) {
      final Map<String, String> headers = <String, String>{};
      for (final RegExpMatch match in RegExp(
        r'^\[([A-Za-z0-9_]+)\s+"((?:\\.|[^"])*)"\]\s*$',
        multiLine: true,
      ).allMatches(chunk)) {
        headers[match.group(1)!] = match.group(2)!.replaceAll(r'\"', '"');
      }
      String movesText = chunk.replaceAll(
        RegExp(r'^\s*\[[^\n]*\]\s*$', multiLine: true),
        ' ',
      );
      movesText = movesText
          .replaceAll(RegExp(r'\{[^}]*\}', dotAll: true), ' ')
          .replaceAll(RegExp(r';[^\n]*'), ' ')
          .replaceAll(RegExp(r'\([^()]*\)'), ' ')
          .replaceAll(RegExp(r'\$\d+'), ' ');
      final List<String> moves = movesText
          .split(RegExp(r'\s+'))
          .map(
            (String token) =>
                token.replaceFirst(RegExp(r'^\d+\.(?:\.\.)?'), ''),
          )
          .where(
            (String token) =>
                token.isNotEmpty &&
                !RegExp(r'^\d+\.{1,3}$').hasMatch(token) &&
                !const <String>{'1-0', '0-1', '1/2-1/2', '*'}.contains(token),
          )
          .toList(growable: false);
      if (moves.isEmpty) continue;
      final String result = headers['Result'] ?? _resultToken(movesText) ?? '*';
      games.add(
        SavedGameRecord(
          mode: 'Imported PGN',
          result: result,
          detail:
              'Imported from ${headers['Site'] ?? 'PGN file'} for ChessVerseAI Coach review',
          moves: moves,
          playedAt: _date(headers['UTCDate'] ?? headers['Date']),
          whitePlayer: headers['White'] ?? 'White',
          blackPlayer: headers['Black'] ?? 'Black',
          openingEco: headers['ECO'],
          openingName: headers['Opening'],
          initialFen: headers['FEN'] ??
              'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        ),
      );
    }
    if (games.isEmpty) {
      throw const FormatException(
        'No playable games were found in this PGN file.',
      );
    }
    return games;
  }

  String _exportGame(SavedGameRecord game) {
    final DateTime date = game.playedAt.toUtc();
    final String result = _pgnResult(game.result);
    final StringBuffer out = StringBuffer()
      ..writeln('[Event "ChessVerseAI Game"]')
      ..writeln('[Site "ChessVerseAI"]')
      ..writeln(
        '[Date "${date.year.toString().padLeft(4, '0')}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}"]',
      )
      ..writeln('[White "${_escape(game.whitePlayer)}"]')
      ..writeln('[Black "${_escape(game.blackPlayer)}"]')
      ..writeln('[Result "$result"]');
    if (game.openingEco?.isNotEmpty == true)
      out.writeln('[ECO "${_escape(game.openingEco!)}"]');
    if (game.openingName?.isNotEmpty == true)
      out.writeln('[Opening "${_escape(game.openingName!)}"]');
    if (game.initialFen?.isNotEmpty == true &&
        game.initialFen !=
            'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1') {
      out
        ..writeln('[SetUp "1"]')
        ..writeln('[FEN "${_escape(game.initialFen!)}"]');
    }
    out.writeln();
    for (int index = 0; index < game.moves.length; index++) {
      if (index.isEven) out.write('${index ~/ 2 + 1}. ');
      out.write('${game.moves[index]} ');
    }
    out.write(result);
    return out.toString().trim();
  }

  String _escape(String value) =>
      value.replaceAll('\\', r'\\').replaceAll('"', r'\"');

  String _pgnResult(String value) {
    if (const <String>{'1-0', '0-1', '1/2-1/2', '*'}.contains(value))
      return value;
    final String lower = value.toLowerCase();
    if (lower.contains('white') || lower.contains('you win')) return '1-0';
    if (lower.contains('black') || lower.contains('opponent wins'))
      return '0-1';
    if (lower.contains('draw') || lower.contains('stalemate')) return '1/2-1/2';
    return '*';
  }

  String? _resultToken(String value) =>
      RegExp(r'(1-0|0-1|1/2-1/2|\*)\s*$').firstMatch(value)?.group(1);

  DateTime _date(String? value) {
    final RegExpMatch? match = RegExp(r'^(\d{4})[.-](\d{2})[.-](\d{2})')
        .firstMatch(value ?? '');
    if (match == null || match.group(1)!.contains('?'))
      return DateTime.now().toUtc();
    return DateTime.utc(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }
}
