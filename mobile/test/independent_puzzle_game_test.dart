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
}
