import 'package:chessverse_ai/features/analysis/data/engine_candidates_api.dart';
import 'package:chessverse_ai/features/analysis/domain/mistake_lesson_engine.dart';
import 'package:chessverse_ai/features/analysis/domain/mistake_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'same-position alternatives require comparable scores and mate evidence',
    () {
      const best = EngineCandidateLine(
        move: 'e7e5',
        evaluationCp: 50,
        principalVariation: ['e7e5'],
      );
      const close = EngineCandidateLine(
        move: 'd7d5',
        evaluationCp: 35,
        principalVariation: ['d7d5'],
      );
      const bad = EngineCandidateLine(
        move: 'g7g5',
        evaluationCp: -200,
        principalVariation: ['g7g5'],
      );
      expect(isComparableLessonMove([best, close, bad], close), isTrue);
      expect(isComparableLessonMove([best, close, bad], bad), isFalse);
      const mate = EngineCandidateLine(
        move: 'e7e5',
        evaluationCp: 100000,
        mateIn: 2,
        principalVariation: ['e7e5'],
      );
      expect(isComparableLessonMove([mate, close], close), isFalse);
    },
  );
  test(
    'guided completion persists separately and never advances a due review',
    () {
      final now = DateTime.utc(2026, 10, 14);
      final original = MistakeReview(nextReview: now, updatedAt: now);
      final guided = MistakeReview.fromJson(
        original.recordAssisted(now).toJson(),
      );
      expect(guided.assistedCompletions, 1);
      expect(guided.successes, 0);
      expect(guided.stage, 0);
      expect(guided.due(now), isTrue);
      final clean = guided.record(true, now);
      expect(clean.stage, 1);
      expect(clean.assistedCompletions, 1);
    },
  );
  test('legacy progress defaults assisted count to zero', () {
    final now = DateTime.utc(2026).toIso8601String();
    expect(
      MistakeReview.fromJson({'nextReview': now, 'updatedAt': now})
          .assistedCompletions,
      0,
    );
  });
}
