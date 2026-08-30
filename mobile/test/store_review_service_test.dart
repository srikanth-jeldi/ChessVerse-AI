import 'package:chessverse_ai/core/store_review_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requests only after a positive third Android game', () {
    expect(
      isStoreReviewEligible(
        isAndroid: true,
        positiveOutcome: true,
        completedGames: 3,
        alreadyRequested: false,
      ),
      isTrue,
    );
  });

  test('does not request too early, after losses, or more than once', () {
    expect(
      isStoreReviewEligible(
        isAndroid: true,
        positiveOutcome: true,
        completedGames: 2,
        alreadyRequested: false,
      ),
      isFalse,
    );
    expect(
      isStoreReviewEligible(
        isAndroid: true,
        positiveOutcome: false,
        completedGames: 10,
        alreadyRequested: false,
      ),
      isFalse,
    );
    expect(
      isStoreReviewEligible(
        isAndroid: true,
        positiveOutcome: true,
        completedGames: 10,
        alreadyRequested: true,
      ),
      isFalse,
    );
    expect(
      isStoreReviewEligible(
        isAndroid: false,
        positiveOutcome: true,
        completedGames: 10,
        alreadyRequested: false,
      ),
      isFalse,
    );
  });
}
