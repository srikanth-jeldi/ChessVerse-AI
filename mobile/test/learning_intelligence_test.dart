import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/analysis/domain/learning_intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

SavedGameRecord game(DateTime playedAt, int loss, {String theme = 'tactics'}) =>
    SavedGameRecord(
      mode: 'Play vs AI',
      result: 'You win',
      detail: 'Checkmate',
      moves: const <String>['e2e4', 'e7e5', 'g1f3'],
      playedAt: playedAt,
      whitePlayer: 'Player',
      blackPlayer: 'AI',
      playerOutcome: 'win',
      moveReviews: <SavedMoveReview>[
        SavedMoveReview(
          ply: 1,
          fenBefore: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          playedMove: 'e2e4',
          bestMove: 'e2e4',
          classification: loss > 70 ? 'Mistake' : 'Great',
          coachingTheme: theme,
          centipawnLoss: loss,
          opponentThreat: 'e7e5',
          explanation: 'Engine evidence.',
          principalVariation: const <String>['e2e4', 'e7e5'],
        ),
      ],
    );

void main() {
  test('builds weekly comparison, daily plan, openings, and trends', () {
    final DateTime now = DateTime.utc(2026, 8, 27, 12);
    final LearningIntelligence intelligence = LearningIntelligence.fromGames(
      <SavedGameRecord>[
        game(now.subtract(const Duration(days: 1)), 30),
        game(now.subtract(const Duration(days: 3)), 60),
        game(now.subtract(const Duration(days: 9)), 120),
      ],
      now: now,
    );

    expect(intelligence.weekly.games, 2);
    expect(intelligence.weekly.wins, 2);
    expect(intelligence.weekly.reviewedMoves, 2);
    expect(intelligence.weekly.accuracyChange, greaterThan(0));
    expect(intelligence.dailyPlan, hasLength(3));
    expect(intelligence.trend, hasLength(3));
    expect(intelligence.openingRecommendation, contains("King's Pawn"));
  });

  test('retains four weekly weakness buckets', () {
    final DateTime now = DateTime.utc(2026, 8, 27, 12);
    final LearningIntelligence intelligence = LearningIntelligence.fromGames(
      <SavedGameRecord>[
        game(now.subtract(const Duration(days: 2)), 180, theme: 'kingSafety'),
        game(now.subtract(const Duration(days: 16)), 100, theme: 'kingSafety'),
      ],
      now: now,
    );
    expect(intelligence.weaknessHistory['King safety'], hasLength(4));
    expect(intelligence.weaknessHistory['King safety']!.last, 2);
  });
}
