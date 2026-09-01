import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _result({
  required String title,
  required int coinsEarned,
}) {
  return MaterialApp(
    home: Scaffold(
      body: GameResultOverlay(
        title: title,
        detail: 'Online match complete',
        scoreLabel: '1-0',
        accuracy: null,
        turningPoint: null,
        entryCoins: 100,
        rewardPoolCoins: 200,
        coinsEarned: coinsEarned,
        onNewGame: () {},
        onDismiss: () {},
        onReview: () {},
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
}
