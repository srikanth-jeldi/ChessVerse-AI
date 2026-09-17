import 'package:chessverse_ai/features/tutorial/presentation/academy_continue_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Next lesson keeps the arrow trailing with long text and large type',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var presses = 0;
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Directionality(
                textDirection: direction,
                child: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AcademyContinueButton(
                      label: 'Next lesson',
                      title: 'The pawn captures diagonally',
                      onPressed: () => presses++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final title = tester.getRect(find.text('The pawn captures diagonally'));
        final arrow = tester.getRect(find.byIcon(Icons.arrow_forward_rounded));
        if (direction == TextDirection.ltr) {
          expect(arrow.left, greaterThan(title.right));
        } else {
          expect(arrow.right, lessThan(title.left));
        }
        await tester.tap(find.byType(FilledButton));
      }
      expect(presses, 2);
    },
  );
}
