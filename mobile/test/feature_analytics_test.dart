import 'package:chessverse_ai/core/analytics/app_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppAnalytics.featureRecorder = null);

  test('repeated human moves emit once until a new attempt', () {
    final tracker = PlayActivityTracker();
    expect(tracker.acceptHumanMove(), isTrue);
    expect(tracker.acceptHumanMove(), isFalse);
    tracker.reset();
    expect(tracker.acceptHumanMove(), isTrue);
  });

  test('feature payload contains categories only and schema version', () async {
    Map<String, Object>? captured;
    AppAnalytics.featureRecorder = (name, parameters) async {
      expect(name, 'imported_review_viewed');
      captured = parameters;
    };
    await AppAnalytics.logFeature(
      FeatureEvent.imported_review_viewed,
      format: 'PGN',
    );
    expect(captured, {'tracking_version': 2, 'format': 'pgn'});
  });

  test('analytics transport failure does not fail feature action', () async {
    AppAnalytics.featureRecorder = (_, _) async => throw StateError('offline');
    await expectLater(
      AppAnalytics.logFeature(FeatureEvent.game_completed, mode: 'computer'),
      completes,
    );
  });
}
