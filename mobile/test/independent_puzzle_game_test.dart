import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'settings.language': 'en'});
  });
  testWidgets(
    'solved puzzle keeps board visible, opens details on demand and advances',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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
      await tester.tap(find.byKey(const ValueKey('square-e1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('square-h1')));
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.byKey(const ValueKey('completed-challenge-actions')),
        findsNothing,
      );
      expect(find.byType(GameResultOverlay), findsNothing);
      await tester.tap(find.byKey(const ValueKey('square-h1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('square-h3')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.byKey(const ValueKey('completed-challenge-actions')),
        findsOneWidget,
      );
      expect(find.byType(ChessBoard), findsOneWidget);
      expect(find.byType(GameResultOverlay), findsNothing);
      expect(find.byType(OnlineVictoryCelebration), findsNothing);
      await tester.tap(find.byKey(const ValueKey('view-challenge-result')));
      await tester.pump();
      final result = tester.widget<GameResultOverlay>(
        find.byType(GameResultOverlay),
      );
      expect(result.showCelebration, isFalse);
      expect(result.showScore, isFalse);
      result.onDismiss();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('next-completed-puzzle')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.byKey(const ValueKey('completed-challenge-actions')),
        findsNothing,
      );
      expect(find.byType(ChessBoard), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
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
    await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
    await tester.pump();
    expect(find.text('Challenge missed'), findsNothing);
    expect(find.byKey(const ValueKey<String>('square-e1')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('square-e2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a legal non-solution move ends the tactic with try again', (
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

    // Easy 001 expects e1-h1. The rook move e1-e2 is legal chess but is not
    // the forcing puzzle line, so this attempt must end instead of free play.
    await tester.tap(find.byKey(const ValueKey<String>('square-e1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-e2')));
    await tester.pump();

    expect(find.text('Challenge missed'), findsOneWidget);
    expect(find.text('Try again'), findsWidgets);
    expect(find.text('AI Review My Game'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('share-game-result')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('export-game-data')),
      findsNothing,
    );
    expect(find.text('Draw'), findsNothing);
    final OutlinedButton hint = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Piece hint'),
    );
    expect(hint.onPressed, isNull);
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
