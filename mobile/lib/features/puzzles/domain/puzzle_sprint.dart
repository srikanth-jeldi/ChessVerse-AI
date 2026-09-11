import 'puzzle_catalog.dart';

enum PuzzleSprintMode { rush, survival, mateInOne }

class PuzzleSprintRules {
  const PuzzleSprintRules({
    required this.duration,
    required this.startingLives,
    required this.mateInOneOnly,
  });

  final Duration? duration;
  final int startingLives;
  final bool mateInOneOnly;

  static PuzzleSprintRules forMode(PuzzleSprintMode mode) => switch (mode) {
    PuzzleSprintMode.rush => const PuzzleSprintRules(
      duration: Duration(minutes: 3),
      startingLives: 3,
      mateInOneOnly: false,
    ),
    PuzzleSprintMode.survival => const PuzzleSprintRules(
      duration: null,
      startingLives: 3,
      mateInOneOnly: false,
    ),
    PuzzleSprintMode.mateInOne => const PuzzleSprintRules(
      duration: Duration(minutes: 1),
      startingLives: 3,
      mateInOneOnly: true,
    ),
  };
}

class PuzzleSprintSession {
  PuzzleSprintSession({
    required this.mode,
    required this.startedAt,
    Iterable<ChessPuzzle> catalog = PuzzleCatalog.all,
  }) : _queue = _buildQueue(mode, catalog),
       lives = PuzzleSprintRules.forMode(mode).startingLives;

  final PuzzleSprintMode mode;
  final DateTime startedAt;
  final List<ChessPuzzle> _queue;
  int score = 0;
  int attempted = 0;
  int lives;
  int _index = 0;

  PuzzleSprintRules get rules => PuzzleSprintRules.forMode(mode);
  ChessPuzzle? get current =>
      isFinished ? null : _queue[_index % _queue.length];

  Duration remainingAt(DateTime now) {
    final Duration? duration = rules.duration;
    if (duration == null) return Duration.zero;
    final Duration remaining = duration - now.difference(startedAt);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isTimedOutAt(DateTime now) =>
      rules.duration != null && remainingAt(now) == Duration.zero;

  bool get isFinished => _queue.isEmpty || lives <= 0;

  void recordResult({required bool solved}) {
    if (isFinished) return;
    attempted++;
    if (solved) {
      score++;
      _index++;
    } else {
      lives--;
    }
  }

  static List<ChessPuzzle> _buildQueue(
    PuzzleSprintMode mode,
    Iterable<ChessPuzzle> catalog,
  ) {
    final List<ChessPuzzle> result = catalog
        .where(
          (ChessPuzzle puzzle) =>
              mode != PuzzleSprintMode.mateInOne || puzzle.playerMoveGoal == 1,
        )
        .toList(growable: false);
    result.sort((ChessPuzzle a, ChessPuzzle b) => a.rating.compareTo(b.rating));
    return result;
  }
}
