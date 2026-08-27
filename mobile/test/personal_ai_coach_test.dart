import 'package:chessverse_ai/features/analysis/domain/ai_review_report.dart';
import 'package:chessverse_ai/features/analysis/domain/personal_ai_coach.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const AiMoveInsight insight = AiMoveInsight(
    number: 14,
    notation: 'f2f3',
    side: 'White',
    phase: 'Middlegame',
    label: 'Blunder',
    explanation: 'The move weakens the king.',
    bestMove: 'g1f3',
    opponentThreat: 'd8h4',
    centipawnLoss: 286,
    coachingTheme: 'kingSafety',
    principalVariation: <String>['g1f3', 'd7d5', 'e2e3'],
  );

  test('coach answers are grounded in engine evidence', () {
    final String why = PersonalAiCoach.answer(insight, CoachQuestion.whyBad);
    final String plan = PersonalAiCoach.answer(insight, CoachQuestion.bestPlan);
    final String threat =
        PersonalAiCoach.answer(insight, CoachQuestion.opponentThreat);

    expect(why, contains('286 centipawn'));
    expect(why, contains('king safety'));
    expect(plan, contains('g1 → f3'));
    expect(threat, contains('d8 → h4'));
    expect(threat, contains('g1 → f3'));
  });

  test('coach supplies all interactive follow-up labels', () {
    expect(CoachQuestion.values, hasLength(5));
    for (final CoachQuestion question in CoachQuestion.values) {
      expect(PersonalAiCoach.label(question), isNotEmpty);
      expect(PersonalAiCoach.answer(insight, question), isNotEmpty);
    }
  });
}
