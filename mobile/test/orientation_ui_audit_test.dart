import 'package:chessverse_ai/core/theme/app_theme.dart';
import 'package:chessverse_ai/features/auth/presentation/auth_screen.dart';
import 'package:chessverse_ai/features/home/presentation/home_dashboard_screen.dart';
import 'package:chessverse_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:chessverse_ai/features/profile/presentation/profile_screen.dart';
import 'package:chessverse_ai/features/puzzles/presentation/puzzle_academy_screen.dart';
import 'package:chessverse_ai/features/library/presentation/reference_screens.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (String name, Size size) in <(String, Size)>[
    ('portrait', const Size(390, 844)),
    ('landscape', const Size(844, 390)),
  ]) {
    testWidgets('onboarding is fully usable in $name', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: OnboardingScreen(onComplete: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to ChessVerseAI'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.getRect(find.text('Skip')).bottom, lessThan(size.height));
      expect(tester.getRect(find.text('Next')).bottom, lessThan(size.height));
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(PageView), Offset(-size.width * 0.75, 0));
      await tester.pumpAndSettle();
      expect(find.text('Daily checkmate'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(PageView), Offset(-size.width * 0.75, 0));
      await tester.pumpAndSettle();
      expect(find.text('Built for every screen'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(tester.getRect(find.text('Start')).bottom, lessThan(size.height));
      expect(tester.takeException(), isNull);
    });

    testWidgets('authentication is fully usable in $name', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: AuthScreen(onAuthenticated: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CHESSVERSEAI'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Login'), findsAtLeastNWidgets(1));
      expect(find.byType(TextField), findsAtLeastNWidgets(2));
      expect(tester.takeException(), isNull);

      final Finder guest = find.text('Continue as Guest Player');
      await tester.scrollUntilVisible(
        guest,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(guest, findsOneWidget);
      expect(tester.getRect(guest).bottom, lessThan(size.height));
      expect(tester.takeException(), isNull);
    });

    testWidgets('home dashboard is fully usable in $name', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: HomeDashboardScreen(
            playerName: 'Guest Player',
            onPlayVsAi: () {},
            onDailyChallenge: () {},
            onLocalGame: () {},
            onOnlineGame: () {},
            onAnalysis: () {},
            onPuzzles: () {},
            onSavedGames: () {},
            onLearnChess: () {},
            onProfile: () {},
            onSettings: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Play Online'), findsOneWidget);
      expect(find.text('Play Computer'), findsOneWidget);
      expect(find.text('Play with Friends'), findsOneWidget);
      expect(
          find.byKey(const ValueKey<String>('chess-puzzles')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('rankings')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('analysis')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('learn')), findsOneWidget);
      expect(tester.takeException(), isNull);

      if (name == 'portrait') {
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      } else {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey<String>('learn')),
          220,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byKey(const ValueKey<String>('learn')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('local chess game is fully usable in $name', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ChessVerseTheme.dark(),
          home: const GameScreen(
            initiallySignedIn: true,
            useRemoteEngine: false,
            initialGameMode: GameMode.local,
            initialPlayerName: 'Guest Player',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('square-e2')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('square-e4')), findsOneWidget);
      if (name == 'portrait') {
        expect(find.byTooltip('Daily challenge'), findsNothing);
        expect(find.byTooltip('Game controls'), findsNothing);
        expect(find.byIcon(Icons.tips_and_updates_outlined), findsOneWidget);
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey<String>('square-e2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('square-e4')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey<String>('square-e4')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('profile is fully usable in $name', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(playerName: 'Guest Player'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PLAYER PROFILE'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('ACCOUNT'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      if (tester.getRect(find.text('ACCOUNT')).bottom >= size.height) {
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -80),
        );
        await tester.pumpAndSettle();
      }
      expect(
          tester.getRect(find.text('ACCOUNT')).bottom, lessThan(size.height));
      expect(tester.takeException(), isNull);
    });

    testWidgets('puzzle academy is fully usable in $name', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
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

      expect(find.text('PUZZLE ACADEMY'), findsOneWidget);
      expect(find.text('EASY'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
      expect(find.text('HARD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('saved games is fully usable in $name', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SavedGamesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Games'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('White'), findsOneWidget);
      expect(find.text('Black'), findsOneWidget);
      expect(tester.getRect(find.text('All')).bottom, lessThan(size.height));
      expect(tester.takeException(), isNull);
    });
  }
}
