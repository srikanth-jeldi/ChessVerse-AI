import 'package:chessverse_ai/core/store_review_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requests after two consecutive Android wins', () {
    expect(
      isStoreReviewEligible(
        isAndroid: true,
        consecutiveWins: 2,
        alreadyRequested: false,
      ),
      isTrue,
    );
  });

  test('does not request too early, after losses, or more than once', () {
    expect(
      isStoreReviewEligible(
        isAndroid: true,
        consecutiveWins: 1,
        alreadyRequested: false,
      ),
      isFalse,
    );
    expect(
      isStoreReviewEligible(
        isAndroid: true,
        consecutiveWins: 0,
        alreadyRequested: false,
      ),
      isFalse,
    );
    expect(
      isStoreReviewEligible(
        isAndroid: true,
        consecutiveWins: 10,
        alreadyRequested: true,
      ),
      isFalse,
    );
    expect(
      isStoreReviewEligible(
        isAndroid: false,
        consecutiveWins: 10,
        alreadyRequested: false,
      ),
      isFalse,
    );
  });
}
