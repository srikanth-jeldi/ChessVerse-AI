import 'package:chessverse_ai/features/analysis/domain/ai_review_report.dart';
import 'package:chessverse_ai/features/analysis/domain/player_learning_profile.dart';
import 'package:chessverse_ai/features/puzzles/domain/puzzle_catalog.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('engine-backed reviews override heuristic labels and retain evidence',
      () {
    const SavedMoveReview reviewed = SavedMoveReview(
      ply: 1,
      fenBefore: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      playedMove: 'e2e4',
      bestMove: 'd2d4',
      classification: 'Inaccuracy',
      centipawnLoss: 48,
      evaluationBeforeCp: 22,
      evaluationAfterCp: -26,
      opponentThreat: 'e7e5',
      explanation: 'The move is playable, but d2d4 was more accurate.',
      principalVariation: <String>['d2d4', 'd7d5'],
    );

    final AiReviewReport report = AiReviewReport.fromMoves(
      const <String>['e2e4'],
      newestFirst: false,
      knownReviews: const <SavedMoveReview>[reviewed],
    );

    expect(report.insights.single.label, 'Inaccuracy');
    expect(report.insights.single.hasEngineEvidence, isTrue);
    expect(report.insights.single.bestMove, 'd2d4');
    expect(report.insights.single.opponentThreat, 'e7e5');
    expect(report.insights.single.principalVariation, <String>['d2d4', 'd7d5']);
    expect(report.insights.single.evaluationAfterCp, -26);
    expect(report.openingName, "King's Pawn Opening");
  });

  test('saved move-review JSON round-trips production evidence', () {
    const SavedMoveReview source = SavedMoveReview(
      ply: 7,
      fenBefore: '8/8/8/8/8/8/8/K6k w - - 0 1',
      playedMove: 'a1a2',
      bestMove: 'a1b2',
      classification: 'Mistake',
      centipawnLoss: 104,
      evaluationBeforeCp: 35,
      evaluationAfterCp: -69,
      opponentThreat: 'h1h2',
      explanation: 'King opposition was lost.',
      principalVariation: <String>['a1b2', 'h1g1'],
    );

    final SavedMoveReview restored = SavedMoveReview.fromJson(source.toJson());
    expect(restored.ply, source.ply);
    expect(restored.classification, source.classification);
    expect(restored.principalVariation, source.principalVariation);
    expect(restored.evaluationBeforeCp, 35);
    expect(restored.evaluationAfterCp, -69);
  });

  test('AI review builds chronological move insights and training plan', () {
    final AiReviewReport report = AiReviewReport.fromMoves(
      <String>['Qh5+', 'Nf3', 'e5', 'e4'],
      result: 'You won',
    );

    expect(report.insights.map((AiMoveInsight item) => item.notation),
        <String>['e4', 'e5', 'Nf3', 'Qh5+']);
    expect(report.insights.last.label, 'Power move');
    expect(report.accuracy, inInclusiveRange(0, 100));
    expect(report.turningPoint, contains('Qh5+'));
    expect(report.recommendedLesson, isNotEmpty);
  });

  test('AI review uses authoritative accuracy and turning point when supplied',
      () {
    final AiReviewReport report = AiReviewReport.fromMoves(
      <String>['e4'],
      knownAccuracy: 91,
      knownTurningPoint: 'Move 18 — missed fork',
    );

    expect(report.accuracy, 91);
    expect(report.turningPoint, 'Move 18 — missed fork');
  });

  test('AI review keeps only the three most important supplied mistakes', () {
    final AiReviewReport report = AiReviewReport.fromMoves(
      <String>['e4'],
      knownMistakes: const <String>['one', 'two', 'three', 'four'],
    );

    expect(report.importantMistakes, <String>['one', 'two', 'three']);
  });

  test('engine-reviewed mistakes drive the personal weakness profile', () {
    const SavedMoveReview blunder = SavedMoveReview(
      ply: 12,
      fenBefore: '8/8/8/8/8/8/4P3/4K2k w - - 0 6',
      playedMove: 'e2e3',
      bestMove: 'e2e4',
      classification: 'Blunder',
      coachingTheme: 'kingSafety',
      centipawnLoss: 220,
      opponentThreat: 'h1g1',
      explanation: 'The king is exposed.',
      principalVariation: <String>['e2e4'],
    );
    final PlayerLearningProfile profile = PlayerLearningProfile.fromGames(
      <SavedGameRecord>[
        SavedGameRecord(
          mode: 'Computer',
          result: 'Opponent wins',
          detail: 'Checkmate',
          moves: const <String>['e4'],
          playedAt: DateTime.utc(2026, 8, 20),
          whitePlayer: 'You',
          blackPlayer: 'AI',
          moveReviews: const <SavedMoveReview>[blunder],
        ),
      ],
    );
    expect(profile.primaryWeakness, ChessWeakness.kingSafety);
    expect(profile.scoreFor(ChessWeakness.kingSafety), 4);
  });

  test('adaptive plan uses a sixty-percent focus without duplicate puzzles',
      () {
    final List<ChessPuzzle> plan =
        PuzzleCatalog.adaptivePlan('kingSafety', <String>{});
    expect(plan, hasLength(10));
    expect(plan.map((ChessPuzzle item) => item.id).toSet(), hasLength(10));
    final Set<String> focusTags = <String>{
      'mate',
      'backRankMate',
      'kingsideAttack',
      'defensiveMove',
    };
    final int targeted = plan
        .take(6)
        .where((ChessPuzzle item) =>
            item.themes.any((String theme) => focusTags.contains(theme)))
        .length;
    expect(targeted, 6);
  });
}
