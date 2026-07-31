part 'puzzle_data.g.dart';

enum PuzzleDifficulty { easy, medium, hard }

class ChessPuzzle {
  const ChessPuzzle({
    required this.id,
    required this.sourceId,
    required this.number,
    required this.difficulty,
    required this.rating,
    required this.fen,
    required this.solution,
    required this.themes,
  });

  final String id;
  final String sourceId;
  final int number;
  final PuzzleDifficulty difficulty;
  final int rating;
  final String fen;
  final List<String> solution;
  final List<String> themes;

  String get positionSignature => fen.split(' ').take(4).join(' ');
  int get playerMoveGoal => (solution.length + 1) ~/ 2;

  String get label => switch (difficulty) {
        PuzzleDifficulty.easy => 'Easy',
        PuzzleDifficulty.medium => 'Medium',
        PuzzleDifficulty.hard => 'Hard',
      };

  String get title => '$label Puzzle ${number.toString().padLeft(2, '0')}';
}

class PuzzleCatalog {
  PuzzleCatalog._();

  static const int puzzlesPerDifficulty = 50;

  static const List<ChessPuzzle> all = _curatedPuzzles;

  static List<ChessPuzzle> forDifficulty(PuzzleDifficulty difficulty) {
    return all
        .where((ChessPuzzle puzzle) => puzzle.difficulty == difficulty)
        .toList(growable: false);
  }

  static ChessPuzzle byId(String id) {
    return all.firstWhere(
      (ChessPuzzle puzzle) => puzzle.id == id,
      orElse: () => all.first,
    );
  }

  static ChessPuzzle nextUnsolved(
    PuzzleDifficulty difficulty,
    Set<String> completedIds,
  ) {
    final List<ChessPuzzle> puzzles = forDifficulty(difficulty);
    return puzzles.firstWhere(
      (ChessPuzzle puzzle) => !completedIds.contains(puzzle.id),
      orElse: () => puzzles.first,
    );
  }

  static ChessPuzzle? nextAfter(String puzzleId) {
    final ChessPuzzle current = byId(puzzleId);
    final List<ChessPuzzle> puzzles = forDifficulty(current.difficulty);
    final int index = puzzles.indexWhere(
      (ChessPuzzle puzzle) => puzzle.id == current.id,
    );
    if (index < 0 || index == puzzles.length - 1) {
      return null;
    }
    return puzzles[index + 1];
  }
}
