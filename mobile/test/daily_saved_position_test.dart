import 'dart:convert';

import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/analysis/domain/ai_review_report.dart';
import 'package:chessverse_ai/features/analysis/domain/pgn_position_reconstructor.dart';
import 'package:chessverse_ai/features/puzzles/domain/puzzle_catalog.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

SavedGameRecord record(String mode, String? fen, List<String> moves) =>
    SavedGameRecord(
      mode: mode,
      result: 'Challenge complete',
      detail: 'Practice complete',
      moves: moves,
      playedAt: DateTime.utc(2026, 11, 1),
      whitePlayer: 'Player',
      blackPlayer: 'Puzzle Defense',
      initialFen: fen,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('daily archive round trip retains every actual review position', () {
    final checked = <String>{};
    for (final hard in [false, true]) {
      for (var day = 0; day < 200; day++) {
        final puzzle = dailyPuzzleForDate(
          DateTime.utc(2026, 1, 1).add(Duration(days: day)),
          hard: hard,
        );
        if (!checked.add(puzzle.id)) continue;
        final saved = SavedGameRecord.fromJson(
          jsonDecode(
            jsonEncode(
              record('Daily Checkmate', puzzle.fen, puzzle.solution).toJson(),
            ),
          ) as Map<String, dynamic>,
        );
        expect(LocalGameArchive.excludeFromSavedGames(saved), isFalse);
        final report = AiReviewReport.fromMoves(
          saved.moves,
          newestFirst: false,
          initialFen: saved.initialFen,
        );
        final actualPositions = replayUciLine(
          puzzle.fen,
          puzzle.solution,
          requireLegalMoves: true,
        );
        expect(
          report.insights.map((move) => move.fenBefore).toList(),
          actualPositions.take(puzzle.solution.length).toList(),
          reason: puzzle.id,
        );
      }
    }
    expect(checked.length, greaterThan(1));
  });

  test(
    'legacy broken daily entries are removed without losing normal games',
    () async {
      final puzzle = dailyPuzzleForDate(DateTime.utc(2026, 11, 1));
      final valid = record('Daily Checkmate', puzzle.fen, puzzle.solution);
      FlutterSecureStorage.setMockInitialValues({
        'chessverse_saved_games_v1': jsonEncode([
          record('Daily Checkmate', null, ['d1d7']).toJson(),
          record('Daily Checkmate', standardInitialFen, ['d1d7']).toJson(),
          record('Puzzle Academy', puzzle.fen, puzzle.solution).toJson(),
          valid.toJson(),
          record('Play vs AI', null, ['e2e4']).toJson(),
        ]),
      });
      await LocalGameArchive.init();
      expect(LocalGameArchive.games.map((game) => game.mode), [
        'Daily Checkmate',
        'Play vs AI',
      ]);
      expect(LocalGameArchive.games.first.initialFen, puzzle.fen);
      final before = LocalGameArchive.games.length;
      LocalGameArchive.addGame(record('Daily Checkmate', null, ['d1d7']));
      expect(LocalGameArchive.games.length, before);
    },
  );
}
