import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('quick chat stays right of the clock on narrow phones',
      (tester) async {
    for (final width in [320.0, 360.0, 412.0]) {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: Directionality(
          textDirection: direction,
          child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                height: 48,
                child: OnlineQuickChatPlayerRow(
                  playerRail: const Row(children: [
                    Expanded(
                        child: Text('A long player display name',
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                    SizedBox(
                        width: 76,
                        child: Text('09:22', key: ValueKey('clock'))),
                  ]),
                  action: IconButton(
                      key: const ValueKey('chat'),
                      onPressed: () {},
                      icon: const Icon(Icons.emoji_emotions_outlined)),
                ),
              )),
        ))));
        final clock = tester.getRect(find.byKey(const ValueKey('clock')));
        final chat = tester.getRect(find.byKey(const ValueKey('chat')));
        expect(clock.overlaps(chat), isFalse, reason: '$width $direction');
        expect(chat.right, lessThanOrEqualTo(width));
        expect(chat.width, 48);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
