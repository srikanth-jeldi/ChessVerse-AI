import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chessverse_ai/core/theme/app_theme.dart';
import 'package:chessverse_ai/features/home/presentation/home_dashboard_screen.dart';

void main() {
  Widget app({
    required VoidCallback onOnline,
    required VoidCallback onComputer,
    int? onlinePlayerCount,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: HomeDashboardScreen(
        playerName: 'Test Player',
        onlinePlayerCount: onlinePlayerCount,
        onPlayVsAi: onComputer,
        onDailyChallenge: () {},
        onLocalGame: () {},
        onOnlineGame: onOnline,
        onAnalysis: () {},
        onPuzzles: () {},
        onSavedGames: () {},
        onLearnChess: () {},
        onProfile: () {},
        onSettings: () {},
      ),
    );
  }

  testWidgets('home waits for a game selection before launching', (
    WidgetTester tester,
  ) async {
    int onlineLaunches = 0;
    int computerLaunches = 0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        onOnline: () => onlineLaunches++,
        onComputer: () => computerLaunches++,
      ),
    );
    await tester.pumpAndSettle();

    expect(onlineLaunches, 0);
    expect(computerLaunches, 0);
    expect(find.text('CHOOSE YOUR NEXT MOVE'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('play-online')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('play-online')));
    await tester.pump();
    expect(onlineLaunches, 1);
    expect(computerLaunches, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home renders without overflow at compact phone width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(onOnline: () {}, onComputer: () {}));
    await tester.pumpAndSettle();

    expect(find.text('Play Online'), findsOneWidget);
    expect(find.text('Play with Friends'), findsOneWidget);
    expect(find.text('Learn'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.bySemanticsLabel('ChessVerseAI'), findsOneWidget);
  });

  testWidgets('home uses the navigation rail on tablet and web widths', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(onOnline: () {}, onComputer: () {}));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Puzzles'), findsNWidgets(2));
    expect(find.text('Rankings'), findsOneWidget);
    expect(find.text('Play Online'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('play-computer')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home makes it clear that presence excludes the current player', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        onOnline: () {},
        onComputer: () {},
        onlinePlayerCount: 0,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No other players online'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
