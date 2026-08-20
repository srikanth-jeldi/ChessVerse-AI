import 'package:chessverse_ai/core/theme/app_theme.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/puzzles/presentation/puzzle_academy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rotated phone keeps the mobile puzzle composition', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(932, 430);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const PuzzleAcademyScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('puzzle-mobile-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('puzzle-wide-layout')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('puzzle academy launches the selected difficulty', (
    WidgetTester tester,
  ) async {
    String? selectedDifficulty;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: PuzzleAcademyScreen(
          onStartPuzzle: (String difficulty) async {
            selectedDifficulty = difficulty;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose your challenge'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('puzzle-easy')), findsOneWidget);
    expect(selectedDifficulty, isNull);

    await tester.tap(find.byKey(const ValueKey<String>('puzzle-easy')));
    await tester.pumpAndSettle();
    expect(find.text('EASY · 50 PUZZLES'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('puzzle-level-easy-001')),
    );
    await tester.pumpAndSettle();
    expect(selectedDifficulty, 'easy-001');
    expect(tester.takeException(), isNull);
  });

  testWidgets('puzzle academy has no compact-phone overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const PuzzleAcademyScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FEATURED PUZZLE'), findsOneWidget);
    expect(find.text('Easy Tactics'), findsOneWidget);
    expect(find.text('0/50'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop training CTA opens real progress insights', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const PuzzleAcademyScreen(showPrimaryNavigation: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('VIEW INSIGHTS'), findsOneWidget);
    expect(find.text('Accuracy'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('view-training-insights')),
    );
    await tester.pumpAndSettle();

    expect(find.text('TRAINING INSIGHTS'), findsOneWidget);
    expect(find.text('COMPLETION'), findsOneWidget);
    expect(find.text('REMAINING'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('continue-recommended-puzzles')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('puzzle progress refreshes when the game route returns', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: PuzzleAcademyScreen(
          onStartPuzzle: (String puzzleId) async {
            LocalGameArchive.markPuzzleSolved(puzzleId);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Finder hardCategory =
        find.byKey(const ValueKey<String>('puzzle-hard'));
    await tester.ensureVisible(hardCategory);
    await tester.pumpAndSettle();
    await tester.tap(hardCategory);
    await tester.pumpAndSettle();
    final Finder level50 =
        find.byKey(const ValueKey<String>('puzzle-level-hard-050'));
    await tester.ensureVisible(level50);
    await tester.pumpAndSettle();
    await tester.tap(level50);
    await tester.pumpAndSettle();

    expect(find.text('1 puzzles completed'), findsOneWidget);
    expect(find.text('1/50'), findsOneWidget);
  });
}
