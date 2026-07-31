import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('independent puzzle never opens the daily challenge lock flow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialGameMode: GameMode.puzzle,
          initialPuzzleId: 'easy-001',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('PUZZLE TRAINING'), findsOneWidget);
    expect(find.textContaining('Easy Puzzle 01'), findsWidgets);
    expect(find.textContaining('Next challenge unlocks'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a legal non-solution puzzle move is played before feedback', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialGameMode: GameMode.puzzle,
          initialPuzzleId: 'easy-001',
        ),
      ),
    );
    await tester.pump();

    // Easy 001 expects e1-h1. The white king move f6-e6 is legal chess but
    // is not the curated solution; it must still be shown on the board.
    await tester.tap(find.byKey(const ValueKey<String>('square-f6')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-e6')));
    await tester.pump();

    expect(find.textContaining('Legal move played'), findsWidgets);
    expect(find.textContaining('Tap Try again'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('online matchmaking never paints a chess board underneath', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialGameMode: GameMode.online,
        ),
      ),
    );

    expect(find.byType(ChessBoard), findsNothing);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
