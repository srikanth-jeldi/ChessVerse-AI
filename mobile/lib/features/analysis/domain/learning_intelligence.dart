import '../../../core/local_game_archive.dart';
import 'ai_review_report.dart';
import 'player_learning_profile.dart';

class DailyPlanItem {
  const DailyPlanItem(this.title, this.detail, this.minutes);
  final String title;
  final String detail;
  final int minutes;
}

class ProgressTrendPoint {
  const ProgressTrendPoint(this.label, this.accuracy);
  final String label;
  final int accuracy;
}

class WeeklyProgressReport {
  const WeeklyProgressReport({
    required this.games,
    required this.wins,
    required this.reviewedMoves,
    required this.averageAccuracy,
    required this.accuracyChange,
    required this.strongestSkill,
    required this.focusArea,
  });
  final int games;
  final int wins;
  final int reviewedMoves;
  final int averageAccuracy;
  final int accuracyChange;
  final String strongestSkill;
  final String focusArea;
}

class LearningIntelligence {
  const LearningIntelligence({
    required this.profile,
    required this.weekly,
    required this.dailyPlan,
    required this.trend,
    required this.openingRecommendation,
    required this.weaknessHistory,
  });

  final PlayerLearningProfile profile;
  final WeeklyProgressReport weekly;
  final List<DailyPlanItem> dailyPlan;
  final List<ProgressTrendPoint> trend;
  final String openingRecommendation;
  final Map<String, List<int>> weaknessHistory;

  factory LearningIntelligence.fromGames(
    List<SavedGameRecord> games, {
    DateTime? now,
    Map<String, int> cloudScores = const <String, int>{},
  }) {
    final DateTime anchor = (now ?? DateTime.now()).toUtc();
    final PlayerLearningProfile profile = PlayerLearningProfile.fromGames(
      games,
      cloudScores: cloudScores,
    );
    final List<SavedGameRecord> current = games
        .where((SavedGameRecord game) => !game.playedAt
            .toUtc()
            .isBefore(anchor.subtract(const Duration(days: 7))))
        .toList(growable: false);
    final List<SavedGameRecord> previous = games.where((SavedGameRecord game) {
      final DateTime date = game.playedAt.toUtc();
      return date.isBefore(anchor.subtract(const Duration(days: 7))) &&
          !date.isBefore(anchor.subtract(const Duration(days: 14)));
    }).toList(growable: false);
    final int currentAccuracy = _averageAccuracy(current);
    final int previousAccuracy = _averageAccuracy(previous);
    final List<SavedGameRecord> chronological =
        games.take(12).toList().reversed.toList();
    final List<ProgressTrendPoint> trend = <ProgressTrendPoint>[
      for (int index = 0; index < chronological.length; index++)
        ProgressTrendPoint(
            'G${index + 1}', _gameAccuracy(chronological[index])),
    ];
    final Map<String, int> openings = <String, int>{};
    for (final SavedGameRecord game in games.take(20)) {
      final String opening = recognizeOpening(game.moves);
      if (!opening.startsWith('Unclassified') &&
          !opening.startsWith('Opening not')) {
        openings[opening] = (openings[opening] ?? 0) + 1;
      }
    }
    final String? familiar = openings.isEmpty
        ? null
        : openings.entries
            .reduce((MapEntry<String, int> a, MapEntry<String, int> b) =>
                b.value > a.value ? b : a)
            .key;
    final String openingRecommendation = familiar == null
        ? 'Build a simple repertoire: King’s Pawn as White and Caro-Kann against 1.e4.'
        : 'Your most familiar opening is $familiar. Review its first 8 moves, then add one response to the opponent’s main alternative.';
    final String focus =
        PlayerLearningProfile.labelFor(profile.primaryWeakness);
    final List<DailyPlanItem> plan = <DailyPlanItem>[
      DailyPlanItem('Targeted puzzles', '5 positions focused on $focus.', 8),
      DailyPlanItem('Mistake replay',
          'Retry the biggest Stockfish swing from your latest game.', 5),
      DailyPlanItem('Slow practice game',
          'Use checks, captures, threats, then compare two candidates.', 12),
    ];
    return LearningIntelligence(
      profile: profile,
      weekly: WeeklyProgressReport(
        games: current.length,
        wins: current
            .where((SavedGameRecord game) => game.playerOutcome == 'win')
            .length,
        reviewedMoves: current.fold<int>(
            0,
            (int total, SavedGameRecord game) =>
                total + game.moveReviews.length),
        averageAccuracy: currentAccuracy,
        accuracyChange:
            previous.isEmpty ? 0 : currentAccuracy - previousAccuracy,
        strongestSkill: PlayerLearningProfile.labelFor(profile.strongestSkill),
        focusArea: focus,
      ),
      dailyPlan: plan,
      trend: trend,
      openingRecommendation: openingRecommendation,
      weaknessHistory: _weaknessHistory(games, anchor),
    );
  }
}

int _gameAccuracy(SavedGameRecord game) {
  if (game.moveReviews.isEmpty) return 0;
  final int total = game.moveReviews.fold<int>(
      0,
      (int sum, SavedMoveReview review) =>
          sum + (100 - (review.centipawnLoss / 3).round()).clamp(0, 100));
  return (total / game.moveReviews.length).round();
}

int _averageAccuracy(List<SavedGameRecord> games) {
  final List<int> values =
      games.map(_gameAccuracy).where((int v) => v > 0).toList();
  return values.isEmpty
      ? 0
      : (values.reduce((int a, int b) => a + b) / values.length).round();
}

Map<String, List<int>> _weaknessHistory(
    List<SavedGameRecord> games, DateTime anchor) {
  final Map<String, List<int>> history = <String, List<int>>{
    for (final ChessWeakness weakness in ChessWeakness.values)
      PlayerLearningProfile.labelFor(weakness): List<int>.filled(4, 0),
  };
  for (final SavedGameRecord game in games) {
    final int age = anchor.difference(game.playedAt.toUtc()).inDays;
    if (age < 0 || age >= 28) continue;
    final int bucket = 3 - (age ~/ 7);
    for (final SavedMoveReview review in game.moveReviews.where(
        (SavedMoveReview r) => const <String>{
              'Inaccuracy',
              'Mistake',
              'Blunder'
            }.contains(r.classification))) {
      final String label = switch (review.coachingTheme) {
        'opening' => 'Opening',
        'kingSafety' => 'King safety',
        'hangingPieces' => 'Piece safety',
        'missedCaptures' => 'Capture scan',
        'timeManagement' => 'Time management',
        'endgame' => 'Endgame',
        'tactics' => 'Tactical vision',
        _ => 'Calculation',
      };
      history[label]![bucket] += review.centipawnLoss >= 160 ? 2 : 1;
    }
  }
  return history;
}
