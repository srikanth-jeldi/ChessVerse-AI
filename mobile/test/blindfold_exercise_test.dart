import 'package:chessverse_ai/features/tutorial/domain/blindfold_exercise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('square colours follow a1 dark orientation', () {
    expect(BlindfoldCatalog.isLightSquare('a1'), isFalse);
    expect(BlindfoldCatalog.isLightSquare('e4'), isTrue);
    expect(BlindfoldCatalog.isLightSquare('h8'), isFalse);
  });

  test('knight visualization returns only eight legal board targets', () {
    expect(BlindfoldCatalog.knightTargets('f3'), contains('e5'));
    expect(BlindfoldCatalog.knightTargets('f3'), isNot(contains('f5')));
    expect(BlindfoldCatalog.knightTargets('d4'), hasLength(8));
    expect(BlindfoldCatalog.knightTargets('a1'), hasLength(2));
  });

  test('every exercise has one valid answer', () {
    for (final BlindfoldExercise exercise in BlindfoldCatalog.exercises) {
      expect(exercise.options.where(exercise.isCorrect), hasLength(1));
    }
  });
}
