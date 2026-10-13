import 'package:chessverse_ai/core/widgets/coin_reward_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('video status wraps above bottom banner at large text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const message =
        'No video is available right now. Try again later. No coins were added.';
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            bottomNavigationBar: const SizedBox(
              key: ValueKey('banner'),
              height: 70,
            ),
            body: const SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CoinRewardNotice(message: message),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text(message), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomLeft(find.byType(CoinRewardNotice)).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('banner'))).dy),
    );
  });
}
