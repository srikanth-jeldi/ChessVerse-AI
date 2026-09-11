import 'package:chessverse_ai/features/puzzles/domain/puzzle_catalog.dart';
import 'package:chessverse_ai/features/puzzles/domain/puzzle_sprint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime start = DateTime.utc(2026, 9, 10, 10);

  test('rush lasts three minutes and tracks real outcomes', () {
    final PuzzleSprintSession session = PuzzleSprintSession(
      mode: PuzzleSprintMode.rush,
      startedAt: start,
    );
    session.recordResult(solved: true);
    session.recordResult(solved: false);
    expect(session.score, 1);
    expect(session.attempted, 2);
    expect(session.lives, 2);
    expect(
      session.remainingAt(start.add(const Duration(minutes: 2))),
      const Duration(minutes: 1),
    );
    expect(session.isTimedOutAt(start.add(const Duration(minutes: 3))), isTrue);
  });

  test('survival ends after three misses and has no timer', () {
    final PuzzleSprintSession session = PuzzleSprintSession(
      mode: PuzzleSprintMode.survival,
      startedAt: start,
    );
    for (int i = 0; i < 3; i++) {
      session.recordResult(solved: false);
    }
    expect(session.isFinished, isTrue);
    expect(
      session.remainingAt(start.add(const Duration(days: 1))),
      Duration.zero,
    );
  });

  test('mate-in-one queue contains only one-player-move puzzles', () {
    final PuzzleSprintSession session = PuzzleSprintSession(
      mode: PuzzleSprintMode.mateInOne,
      startedAt: start,
      catalog: PuzzleCatalog.all,
    );
    expect(session.current, isNotNull);
    expect(session.current!.playerMoveGoal, 1);
  });
}
