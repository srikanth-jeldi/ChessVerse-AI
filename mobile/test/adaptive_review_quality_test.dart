import 'package:chessverse_ai/features/analysis/presentation/adaptive_ai_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI review board always uses the regular readable 3D pieces', () {
    expect(
      coachReviewPieceAsset('K'),
      'assets/pieces/staunton_white_king.png',
    );
    expect(
      coachReviewPieceAsset('n'),
      'assets/pieces/staunton_black_knight.png',
    );
    expect(coachReviewPieceAsset('Q'), isNot(contains('obsidian-regal')));
  });

  test('timeline coaching labels populate public move-quality buckets', () {
    expect(reviewQualityBucket('Best'), 'Best');
    expect(reviewQualityBucket('Power move'), 'Great');
    expect(reviewQualityBucket('Excellent'), 'Great');
    expect(reviewQualityBucket('Principled'), 'Good');
    expect(reviewQualityBucket('Tactical'), 'Good');
    expect(reviewQualityBucket('Playable'), 'Good');
    expect(reviewQualityBucket('Inaccuracy'), 'Inaccuracy');
    expect(reviewQualityBucket('Mistake'), 'Mistake');
    expect(reviewQualityBucket('Blunder'), 'Blunder');
  });
}
