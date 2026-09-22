import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _result({
  required String title,
  required int coinsEarned,
  bool showScore = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: GameResultOverlay(
        title: title,
        detail: 'Online match complete',
        scoreLabel: '1-0',
        showScore: showScore,
        accuracy: null,
        turningPoint: null,
        entryCoins: 100,
        rewardPoolCoins: 200,
        coinsEarned: coinsEarned,
        onNewGame: () {},
        onDismiss: () {},
        onReview: () {},
        onShare: () async {},
        onExport: () async => (
          pgn: '[Event "ChessVerseAI Game"]\n\n1. e4 e5 *',
          fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('winner sees the full coin-pool reward', (tester) async {
    await tester.pumpWidget(_result(title: 'You win', coinsEarned: 200));
    await tester.pumpAndSettle();

    expect(find.text('+200 COINS WON'), findsOneWidget);
    expect(find.text('100 + 100 = 200 coin pool'), findsOneWidget);
  });

  testWidgets('draw sees the entry refund', (tester) async {
    await tester.pumpWidget(_result(title: 'Draw', coinsEarned: 0));
    await tester.pumpAndSettle();

    expect(find.text('100 COINS REFUNDED'), findsOneWidget);
    expect(find.text('Draw refund completed'), findsOneWidget);
  });

  testWidgets('loss does not show a zero-coin reward card', (tester) async {
    await tester.pumpWidget(_result(title: 'Opponent wins', coinsEarned: 0));
    await tester.pumpAndSettle();

    expect(find.text('0 COINS WON'), findsNothing);
    expect(find.text('100 + 100 = 200 coin pool'), findsNothing);
    expect(find.byIcon(Icons.monetization_on_rounded), findsNothing);
  });

  testWidgets('daily challenge completion does not show a match score', (
    tester,
  ) async {
    await tester.pumpWidget(
      _result(title: 'Challenge complete', coinsEarned: 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Challenge complete'), findsOneWidget);
    expect(find.text('1-0'), findsNothing);
  });

  testWidgets('puzzle completion never shows a match score', (tester) async {
    await tester.pumpWidget(
      _result(title: 'Puzzle complete', coinsEarned: 0, showScore: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Puzzle complete'), findsOneWidget);
    expect(find.text('1-0'), findsNothing);
  });

  testWidgets('finished game exposes PGN and FEN export', (tester) async {
    await tester.pumpWidget(_result(title: 'You win', coinsEarned: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('export-game-data')));
    await tester.pumpAndSettle();

    expect(find.text('Game export'), findsOneWidget);
    expect(find.text('PGN • COMPLETE GAME'), findsOneWidget);
    expect(find.text('FEN • FINAL POSITION'), findsOneWidget);
    expect(find.textContaining('[Event "ChessVerseAI Game"]'), findsOneWidget);
  });
}
