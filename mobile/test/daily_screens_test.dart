import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/daily_challenge/presentation/daily_challenge_screen.dart';
import 'package:chessverse_ai/features/daily_challenge/widgets/daily_puzzle_streak.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('24-hour attempt survives midnight and reopening', () async {
    FlutterSecureStorage.setMockInitialValues({});
    await LocalGameArchive.init();
    final opened = DateTime.utc(2026, 11, 20, 22, 30);
    final afterMidnight = DateTime.utc(2026, 11, 21, 2, 30);
    final expiry = DateTime.utc(2026, 11, 21, 22, 30);
    expect(LocalGameArchive.dailyAttemptRemainingAt(opened), isNull);
    LocalGameArchive.beginDailyPuzzleAttempt(now: opened);
    expect(
      LocalGameArchive.dailyAttemptRemainingAt(opened),
      const Duration(hours: 24),
    );
    LocalGameArchive.beginDailyPuzzleAttempt(now: afterMidnight);
    await LocalGameArchive.init();
    expect(
      LocalGameArchive.dailyAttemptRemainingAt(afterMidnight),
      const Duration(hours: 20),
    );
    expect(
      LocalGameArchive.dailyPuzzleDateForAttempt(afterMidnight),
      DateTime.utc(2026, 11, 20),
    );
    expect(LocalGameArchive.dailyAttemptRemainingAt(expiry), isNull);
    expect(
      LocalGameArchive.dailyPuzzleDateForAttempt(expiry),
      DateTime.utc(2026, 11, 21),
    );
    await LocalGameArchive.clearDeviceUserData();
  });

  test(
    'completed puzzle does not lock out the next attempt after expiry',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'chessverse_daily_attempt_started_utc': '2026-11-20T22:30:00Z',
        'chessverse_last_daily_completion_utc': '2026-11-21T02:30:00Z',
        'chessverse_completed_daily_challenges': '2026-11-20-v8-medium-001',
      });
      await LocalGameArchive.init();
      expect(
        LocalGameArchive.isDailyChallengeLockedAt(
          DateTime.utc(2026, 11, 21, 3),
        ),
        isTrue,
      );
      expect(
        LocalGameArchive.isDailyChallengeLockedAt(
          DateTime.utc(2026, 11, 21, 22, 30),
        ),
        isFalse,
      );
      await LocalGameArchive.clearDeviceUserData();
    },
  );

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
        var puzzlesOpened = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => DailyChallengeScreen(
                onPlay: () => starts++,
                onOpenPuzzles: () => puzzlesOpened++,
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
        expect(find.text('24 hours from first open'), findsOneWidget);
        final Finder artwork = find.byKey(
          const ValueKey<String>('daily-challenge-artwork'),
        );
        expect(tester.getSize(artwork).aspectRatio, closeTo(2 / 3, .01));
        final Finder menu = find.byTooltip('Daily menu');
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.text('How Daily Challenge works'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Puzzle Academy'));
        await tester.pumpAndSettle();
        expect(puzzlesOpened, 1);
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
