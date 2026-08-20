import '../../../core/local_game_archive.dart';

enum ChessWeakness {
  opening,
  kingSafety,
  hangingPieces,
  missedCaptures,
  timeManagement,
  endgame,
  tactics,
  calculation,
}

class PlayerLearningProfile {
  const PlayerLearningProfile(this.scores);

  final Map<ChessWeakness, int> scores;

  factory PlayerLearningProfile.fromGames(
    List<SavedGameRecord> games, {
    Map<String, int> cloudScores = const <String, int>{},
  }) {
    final Map<ChessWeakness, int> scores = <ChessWeakness, int>{
      for (final ChessWeakness weakness in ChessWeakness.values) weakness: 0,
    };
    for (final SavedGameRecord game in games.take(20)) {
      final List<String> moves = game.moves;
      final List<SavedMoveReview> reviewedMistakes = game.moveReviews
          .where((SavedMoveReview review) => const <String>{
                'Inaccuracy',
                'Mistake',
                'Blunder'
              }.contains(review.classification))
          .toList(growable: false);
      if (reviewedMistakes.isNotEmpty) {
        for (final SavedMoveReview review in reviewedMistakes) {
          final ChessWeakness weakness =
              _weaknessForTheme(review.coachingTheme);
          final int weight = review.centipawnLoss >= 160
              ? 4
              : review.centipawnLoss >= 70
                  ? 2
                  : 1;
          scores[weakness] = scores[weakness]! + weight;
        }
        continue;
      }
      final String result = game.result.toLowerCase();
      final bool loss = result.contains('opponent') ||
          result.contains('black wins') ||
          result.contains('white wins');
      final bool castled = moves.any(
        (String move) => move.contains('O-O') || move.contains('0-0'),
      );
      final int captures =
          moves.where((String move) => move.contains('x')).length;
      if (loss && moves.length < 24) {
        scores[ChessWeakness.opening] = scores[ChessWeakness.opening]! + 3;
      }
      if (!castled && moves.length >= 12) {
        scores[ChessWeakness.kingSafety] =
            scores[ChessWeakness.kingSafety]! + 2;
      }
      if (loss && captures >= 5) {
        scores[ChessWeakness.hangingPieces] =
            scores[ChessWeakness.hangingPieces]! + 2;
      }
      if (captures < (moves.length / 10).floor()) {
        scores[ChessWeakness.missedCaptures] =
            scores[ChessWeakness.missedCaptures]! + 1;
      }
      if (result.contains('time')) {
        scores[ChessWeakness.timeManagement] =
            scores[ChessWeakness.timeManagement]! + 4;
      }
      if (loss && moves.length >= 36) {
        scores[ChessWeakness.endgame] = scores[ChessWeakness.endgame]! + 3;
      }
    }
    for (final ChessWeakness weakness in ChessWeakness.values) {
      final int remote = cloudScores[weakness.name] ?? 0;
      if (remote > scores[weakness]!) scores[weakness] = remote;
    }
    return PlayerLearningProfile(scores);
  }

  ChessWeakness get primaryWeakness {
    return scores.entries
        .reduce(
          (MapEntry<ChessWeakness, int> a, MapEntry<ChessWeakness, int> b) =>
              b.value > a.value ? b : a,
        )
        .key;
  }

  ChessWeakness get strongestSkill {
    return scores.entries
        .reduce(
          (MapEntry<ChessWeakness, int> a, MapEntry<ChessWeakness, int> b) =>
              b.value < a.value ? b : a,
        )
        .key;
  }

  int scoreFor(ChessWeakness weakness) => scores[weakness] ?? 0;

  static String labelFor(ChessWeakness weakness) => switch (weakness) {
        ChessWeakness.opening => 'Opening',
        ChessWeakness.kingSafety => 'King safety',
        ChessWeakness.hangingPieces => 'Piece safety',
        ChessWeakness.missedCaptures => 'Capture scan',
        ChessWeakness.timeManagement => 'Time management',
        ChessWeakness.endgame => 'Endgame',
        ChessWeakness.tactics => 'Tactical vision',
        ChessWeakness.calculation => 'Calculation',
      };

  String get recommendedLesson => switch (primaryWeakness) {
        ChessWeakness.opening => 'Develop with purpose',
        ChessWeakness.kingSafety => 'Castling safely',
        ChessWeakness.hangingPieces => 'Protect every piece',
        ChessWeakness.missedCaptures => 'Checks, captures and threats',
        ChessWeakness.timeManagement => 'Choose candidate moves',
        ChessWeakness.endgame => 'Promoting a pawn',
        ChessWeakness.tactics => 'Knight forks',
        ChessWeakness.calculation => 'Checks, captures and threats',
      };

  String get recommendationReason => switch (primaryWeakness) {
        ChessWeakness.opening =>
          'Your recent games became difficult early. Build the centre, develop once, and castle before attacking.',
        ChessWeakness.kingSafety =>
          'Your king often stayed in the centre. This 5-minute lesson trains safe castling decisions.',
        ChessWeakness.hangingPieces =>
          'Material swings decided recent games. Train a safety scan before every move.',
        ChessWeakness.missedCaptures =>
          'You are leaving tactical opportunities on the board. Scan checks, captures, and threats in order.',
        ChessWeakness.timeManagement =>
          'Time pressure affected your results. Learn a short candidate-move routine for faster decisions.',
        ChessWeakness.endgame =>
          'Your longest games need a cleaner finish. Activate the king and learn pawn promotion technique.',
        ChessWeakness.tactics =>
          'Engine-reviewed mistakes show missed tactical resources. Train forcing checks, captures, forks, and pins.',
        ChessWeakness.calculation =>
          'Your positions need a more consistent candidate-move check. Compare two forcing lines before committing.',
      };

  static ChessWeakness _weaknessForTheme(String theme) => switch (theme) {
        'opening' => ChessWeakness.opening,
        'kingSafety' => ChessWeakness.kingSafety,
        'hangingPieces' => ChessWeakness.hangingPieces,
        'missedCaptures' => ChessWeakness.missedCaptures,
        'timeManagement' => ChessWeakness.timeManagement,
        'endgame' => ChessWeakness.endgame,
        'tactics' => ChessWeakness.tactics,
        _ => ChessWeakness.calculation,
      };
}
