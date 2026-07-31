import 'package:chessverse_ai/features/puzzles/domain/puzzle_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog contains 50 unique puzzles per difficulty', () {
    expect(PuzzleCatalog.all, hasLength(150));
    expect(
      PuzzleCatalog.all.map((ChessPuzzle puzzle) => puzzle.id).toSet(),
      hasLength(150),
    );
    expect(
      PuzzleCatalog.all
          .map((ChessPuzzle puzzle) => puzzle.positionSignature)
          .toSet(),
      hasLength(150),
      reason: 'Every catalog entry must map to an independent board layout.',
    );
    expect(
      PuzzleCatalog.all.map((ChessPuzzle puzzle) => puzzle.sourceId).toSet(),
      hasLength(150),
    );
    for (final ChessPuzzle puzzle in PuzzleCatalog.all) {
      expect(puzzle.fen.split(' '), hasLength(6));
      expect(puzzle.fen.split(' ')[1], 'w');
      expect(puzzle.solution, isNotEmpty);
      expect(puzzle.solution.length.isOdd, isTrue);
      expect(
        puzzle.solution.every(
          (String move) => RegExp(r'^[a-h][1-8][a-h][1-8]$').hasMatch(move),
        ),
        isTrue,
      );
      expect(puzzle.themes, contains('mate'));
      expect(puzzle.playerMoveGoal, (puzzle.solution.length + 1) ~/ 2);
    }
    for (final PuzzleDifficulty difficulty in PuzzleDifficulty.values) {
      expect(PuzzleCatalog.forDifficulty(difficulty), hasLength(50));
    }
  });

  test('next unsolved advances independently inside a category', () {
    final ChessPuzzle next = PuzzleCatalog.nextUnsolved(
      PuzzleDifficulty.easy,
      <String>{'easy-001', 'easy-002', 'medium-001'},
    );
    expect(next.id, 'easy-003');
  });

  test('next puzzle stays inside its category and stops after level 50', () {
    expect(PuzzleCatalog.nextAfter('medium-001')?.id, 'medium-002');
    expect(PuzzleCatalog.nextAfter('medium-050'), isNull);
  });
}
