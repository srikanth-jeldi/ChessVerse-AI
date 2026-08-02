import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chessverse_ai/core/widgets/chessverse_app_backdrop.dart';

void main() {
  for (final Size viewport in <Size>[
    const Size(360, 640),
    const Size(800, 1280),
    const Size(1440, 900),
  ]) {
    testWidgets('global backdrop fills ${viewport.width}x${viewport.height}',
        (WidgetTester tester) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ChessVerseAppBackdrop(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(child: Text('Content remains visible')),
            ),
          ),
        ),
      );

      expect(
        find.byKey(ChessVerseAppBackdrop.backdropKey),
        findsOneWidget,
      );
      expect(find.text('Content remains visible'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
