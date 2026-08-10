import 'package:chessverse_ai/features/analysis/domain/ai_review_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
