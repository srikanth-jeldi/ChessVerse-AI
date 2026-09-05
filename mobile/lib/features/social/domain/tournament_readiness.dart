import '../../../core/local_game_archive.dart';
import '../../analysis/domain/player_learning_profile.dart';

class TournamentReadiness {
  const TournamentReadiness({
    required this.gamesAnalysed,
    required this.score,
    required this.confidence,
    required this.headline,
    required this.openingInsight,
    required this.timeAdvice,
    required this.recommendedLesson,
    required this.timeControlAdvice,
  });

  final int gamesAnalysed;
  final int? score;
  final String confidence;
  final String headline;
  final String openingInsight;
  final String timeAdvice;
  final String recommendedLesson;
  final String timeControlAdvice;

  factory TournamentReadiness.fromGames(List<SavedGameRecord> allGames) {
    final List<SavedGameRecord> games = allGames
        .where((game) => const <String>{'win', 'draw', 'loss'}
            .contains(game.playerOutcome?.toLowerCase()))
        .take(10)
        .toList(growable: false);
    final PlayerLearningProfile profile =
        PlayerLearningProfile.fromGames(games);
    final String lesson = profile.recommendedLesson;
    if (games.length < 3) {
      return TournamentReadiness(
        gamesAnalysed: games.length,
        score: null,
        confidence: 'BUILDING PROFILE',
        headline:
            'Complete ${3 - games.length} more tracked game${3 - games.length == 1 ? '' : 's'} for a reliable readiness score.',
        openingInsight:
            'Opening evidence is still limited. Develop pieces, control the centre and castle early.',
        timeAdvice:
            'Play one 10+0 practice game and finish with at least two minutes available.',
        recommendedLesson: lesson,
        timeControlAdvice: '10+0 practice recommended before entering',
      );
    }

    int performanceTotal = 0;
    int timeoutLosses = 0;
    int reviews = 0;
    int weightedErrors = 0;
    final Map<String, int> openings = <String, int>{};
    for (final SavedGameRecord game in games) {
      performanceTotal += switch (game.playerOutcome?.toLowerCase()) {
        'win' => 100,
        'draw' => 60,
        _ => 25,
      };
      if (game.detail.toLowerCase().contains('time') ||
          game.result.toLowerCase().contains('time')) {
        timeoutLosses++;
      }
      final String? opening = game.openingName;
      if (opening != null && opening.trim().isNotEmpty) {
        openings[opening] = (openings[opening] ?? 0) + 1;
      }
      for (final SavedMoveReview review in game.moveReviews) {
        reviews++;
        weightedErrors += switch (review.classification) {
          'Blunder' => 3,
          'Mistake' => 2,
          'Inaccuracy' => 1,
          _ => 0,
        };
      }
    }
    final double performance = performanceTotal / games.length;
    final double decisionQuality = reviews == 0
        ? 60
        : (100 - (weightedErrors / reviews * 24)).clamp(20, 100);
    final double clockDiscipline =
        (100 - timeoutLosses / games.length * 100).clamp(20, 100);
    final int score =
        (performance * .45 + decisionQuality * .35 + clockDiscipline * .20)
            .round()
            .clamp(0, 100);
    final ChessWeakness focus = profile.primaryWeakness;
    final String? familiarOpening = openings.isEmpty
        ? null
        : (openings.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;
    final String openingInsight = focus == ChessWeakness.opening
        ? 'Opening is your main risk. Review the first 8 moves and avoid moving the same piece repeatedly.'
        : familiarOpening == null
            ? 'No repeated opening found yet. Use a simple development plan and castle early.'
            : '$familiarOpening is your most familiar setup. Review its main reply before the event.';
    final String timeAdvice = timeoutLosses == 0
        ? 'No recent timeout loss detected. Keep a two-minute reserve for the finish.'
        : '$timeoutLosses of ${games.length} recent games ended on time. Use a 20-second candidate-move limit.';
    return TournamentReadiness(
      gamesAnalysed: games.length,
      score: score,
      confidence: games.length >= 7 ? 'HIGH CONFIDENCE' : 'EARLY ESTIMATE',
      headline: score >= 75
          ? 'Tournament ready—protect your clock and play your familiar positions.'
          : score >= 55
              ? 'Nearly ready—complete the recommended warm-up before joining.'
              : 'Preparation advised—train the primary weakness before tournament play.',
      openingInsight: openingInsight,
      timeAdvice: timeAdvice,
      recommendedLesson: lesson,
      timeControlAdvice: timeoutLosses == 0
          ? 'You are ready for 10+0 rapid'
          : 'Play two 10+0 practice games before entering',
    );
  }
}
