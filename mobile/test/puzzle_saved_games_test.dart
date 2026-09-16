import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Puzzle Academy attempts are not added to saved games', () async {
    final int savedGamesBefore = LocalGameArchive.games.length;

    LocalGameArchive.addGame(
      SavedGameRecord(
        mode: 'Puzzle Academy',
        result: 'Puzzle complete',
        detail: 'Practice complete',
        moves: const <String>['e2e4'],
        playedAt: DateTime.utc(2026, 9, 16),
        whitePlayer: 'Guest Player',
        blackPlayer: 'Puzzle Defense',
      ),
    );

    expect(LocalGameArchive.games.length, savedGamesBefore);
  });
}
