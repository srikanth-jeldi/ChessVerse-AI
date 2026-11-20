import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/daily_challenge/presentation/daily_challenge_screen.dart';
import 'package:chessverse_ai/features/daily_challenge/widgets/daily_puzzle_streak.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daily puzzle has a shared 24-hour UTC window', () {
    expect(
      dailyPuzzleTimeRemaining(DateTime.utc(2026, 11, 20)),
      const Duration(hours: 24),
    );
    expect(
      dailyPuzzleTimeRemaining(DateTime.parse('2026-11-21T05:29:59+05:30')),
      const Duration(seconds: 1),
    );
  });

  for (final Size viewport in <Size>[
    const Size(360, 640),
    const Size(1200, 800),
  ]) {
    testWidgets(
      'daily puzzle and streak are reachable at ${viewport.width}px',
      (WidgetTester tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var starts = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => DailyChallengeScreen(
                onPlay: () => starts++,
                onOpenStreak: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        DailyStreakScreen(onPractice: () => starts++),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('Time left today'), findsOneWidget);
        final Finder streak = find.text('View Daily Streak');
        await tester.ensureVisible(streak);
        await tester.tap(streak);
        await tester.pumpAndSettle();
        expect(find.text('Daily Streak'), findsOneWidget);
        final Finder play = find.text('Play Daily Challenge');
        await tester.ensureVisible(play);
        await tester.tap(play);
        expect(starts, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
