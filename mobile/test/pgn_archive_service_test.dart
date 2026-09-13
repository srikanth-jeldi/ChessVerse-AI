import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/online/data/pgn_archive_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const PgnArchiveService service = PgnArchiveService();

  test('imports a Chess.com-style PGN for AI review', () {
    final List<SavedGameRecord> games = service.importGames('''
[Event "Live Chess"]
[Site "Chess.com"]
[Date "2026.09.14"]
[White "Srikanth"]
[Black "Opponent"]
[Result "1-0"]

1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 {A comment} 1-0
''');

    expect(games, hasLength(1));
    expect(games.single.mode, 'Imported PGN');
    expect(games.single.whitePlayer, 'Srikanth');
    expect(games.single.moves, <String>['e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'a6']);
  });

  test('exports all games with portable PGN headers', () {
    final String pgn = service.exportGames(<SavedGameRecord>[
      SavedGameRecord(
        mode: 'Imported PGN',
        result: '1-0',
        detail: 'Imported',
        moves: const <String>['e4', 'e5', 'Nf3'],
        playedAt: DateTime.utc(2026, 9, 14),
        whitePlayer: 'White',
        blackPlayer: 'Black',
      ),
    ]);

    expect(pgn, contains('[Site "ChessVerseAI"]'));
    expect(pgn, contains('1. e4 e5 2. Nf3 1-0'));
  });
}
