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
    expect(find.textContaining('Next challenge unlocks'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a legal non-solution puzzle move gets a defense reply', (
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

    // Easy 001 expects e1-h1. The rook move e1-e2 is legal chess, keeps the
    // game live, and must switch to free exploration with a black reply.
    await tester.tap(find.byKey(const ValueKey<String>('square-e1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-e2')));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Incorrect puzzle move'), findsNothing);
    expect(find.textContaining('Next challenge unlocks'), findsNothing);
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
