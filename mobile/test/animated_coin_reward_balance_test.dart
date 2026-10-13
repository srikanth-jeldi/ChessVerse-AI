import 'package:chessverse_ai/core/widgets/animated_coin_reward_balance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget balance(int coins, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(
      body: Center(child: AnimatedCoinRewardBalance(balance: coins)),
    ),
  ),
);

void main() {
  testWidgets('credit animates once; refresh and spending do not reward', (
    tester,
  ) async {
    await tester.pumpWidget(balance(260));
    expect(find.text('+260'), findsNothing);
    await tester.pumpWidget(balance(290));
    expect(find.text('+30'), findsOneWidget);
    expect(find.text('260'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('260'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('290'), findsOneWidget);
    expect(find.text('+30'), findsNothing);
    await tester.pumpWidget(balance(290));
    expect(find.byKey(const ValueKey('coin-reward-gain')), findsNothing);
    await tester.pumpWidget(balance(190));
    expect(find.text('190'), findsOneWidget);
    expect(find.byKey(const ValueKey('coin-reward-gain')), findsNothing);
    await tester.pumpWidget(balance(220));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion updates balance immediately', (tester) async {
    await tester.pumpWidget(balance(260, reduceMotion: true));
    await tester.pumpWidget(balance(290, reduceMotion: true));
    expect(find.text('290'), findsOneWidget);
    expect(find.byKey(const ValueKey('coin-reward-gain')), findsNothing);
  });
}
