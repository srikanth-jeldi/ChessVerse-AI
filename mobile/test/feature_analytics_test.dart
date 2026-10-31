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

  test('same board on the next IST day counts as playing again', () {
    final tracker = PlayActivityTracker();
    expect(
      tracker.acceptHumanMove(at: DateTime.parse('2026-10-30T18:29:58Z')),
      isTrue,
    );
    expect(
      tracker.acceptHumanMove(at: DateTime.parse('2026-10-30T18:29:59Z')),
      isFalse,
    );
    expect(
      tracker.acceptHumanMove(at: DateTime.parse('2026-10-30T18:30:00Z')),
      isTrue,
    );
  });
}
