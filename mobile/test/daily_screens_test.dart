import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/core/widgets/desktop_app_sidebar.dart';
import 'package:chessverse_ai/features/daily_challenge/presentation/daily_challenge_screen.dart';
import 'package:chessverse_ai/features/daily_challenge/widgets/daily_puzzle_streak.dart';
import 'package:chessverse_ai/features/puzzles/presentation/puzzle_academy_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
        LocalGameArchive.dailyChallengeRemainingAt(
          DateTime.utc(2026, 11, 21, 3),
        ),
        const Duration(hours: 19, minutes: 30),
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

  testWidgets('completed challenge and all menu items are in Telugu', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      FlutterSecureStorage.setMockInitialValues({
        'chessverse_last_daily_completion_utc': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toUtc()
            .toIso8601String(),
      });
      await LocalGameArchive.init();
      await UiCopy.load('te');
    });
    addTearDown(() async {
      await UiCopy.load('en');
      await LocalGameArchive.clearDeviceUserData();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('te'),
        supportedLocales: const [Locale('en'), Locale('te')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: DailyChallengeScreen(
          onPlay: () {},
          onOpenStreak: () {},
          onOpenPuzzles: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ఛాలెంజ్ పూర్తయింది'), findsOneWidget);
    expect(find.text('తదుపరి పజిల్‌కు మిగిలిన సమయం'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^23:5[45]:\d{2}$')), findsOneWidget);
    expect(find.text('ఈరోజు ఛాలెంజ్ చూడండి'), findsOneWidget);
    expect(find.text('Challenge complete'), findsNothing);

    await tester.tap(find.byTooltip('డైలీ ఛాలెంజ్ మెనూ'));
    await tester.pumpAndSettle();
    expect(find.text('డైలీ స్ట్రీక్'), findsOneWidget);
    expect(find.text('పజిల్ అకాడమీ'), findsOneWidget);
    expect(find.text('Puzzle Academy'), findsNothing);
    await tester.tap(find.text('డైలీ ఛాలెంజ్ నియమాలు'));
    await tester.pumpAndSettle();
    final Finder dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.textContaining('24 గంటల')),
      findsOneWidget,
    );
    await tester.tap(find.text('అయింది'));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('a newer synced completion replaces an expired local attempt', () async {
    FlutterSecureStorage.setMockInitialValues({
      'chessverse_daily_attempt_started_utc': '2026-11-19T09:00:00Z',
    });
    await LocalGameArchive.init();
    await LocalGameArchive.mergeCloudSnapshot({
      'lastDailyCompletedAt': '2026-11-20T23:30:00Z',
      'completedDailyChallengeIds': ['2026-11-20-v8-medium-001'],
    });
    final now = DateTime.utc(2026, 11, 21, 2, 30);
    expect(LocalGameArchive.isDailyChallengeLockedAt(now), isTrue);
    expect(
      LocalGameArchive.dailyChallengeRemainingAt(now),
      const Duration(hours: 21),
    );
    expect(
      LocalGameArchive.dailyPuzzleDateForAttempt(now),
      DateTime.utc(2026, 11, 20),
    );
    await LocalGameArchive.clearDeviceUserData();
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
        final sidebar = find.byType(DesktopAppSidebar);
        final showSidebar = kIsWeb && viewport.width >= 700;
        expect(sidebar, showSidebar ? findsOneWidget : findsNothing);
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
        expect(sidebar, showSidebar ? findsOneWidget : findsNothing);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        expect(find.text('Daily Challenge'), findsOneWidget);
        expect(find.text('Puzzle Academy'), findsOneWidget);
        await tester.tap(find.text('How Daily Challenge works'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        final Finder play = find.text('Play Daily Challenge');
        await tester.ensureVisible(play);
        await tester.tap(play);
        expect(starts, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        var walletOpened = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: PuzzleAcademyScreen(
              showPrimaryNavigation: false,
              onDailyChallenge: () => starts++,
              onDailyStreak: () {},
              walletAction: IconButton(
                tooltip: 'Coins',
                onPressed: () => walletOpened++,
                icon: const Icon(Icons.monetization_on_outlined),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final wallet = find.byTooltip('Coins');
        expect(tester.getRect(wallet).overlaps(tester.getRect(menu)), isFalse);
        await tester.tap(wallet);
        expect(walletOpened, 1);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        final items = find.descendant(
          of: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
          matching: find.byType(Text),
        );
        expect(tester.widgetList<Text>(items).map((text) => text.data), [
          'Daily Challenge',
          'Daily Streak',
          'Puzzle Academy',
          'How Daily Challenge works',
        ]);
        await tester.tap(items.first);
        await tester.pumpAndSettle();
        expect(starts, 2);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
