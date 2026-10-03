import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('game survives rotation and resizing with system insets', (
    WidgetTester tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({'settings.language': 'en'});
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const configurations = <(Size, FakeViewPadding)>[
      (Size(390, 844), FakeViewPadding(top: 32, bottom: 24)),
      (Size(844, 390), FakeViewPadding(left: 44, right: 24, bottom: 24)),
      (Size(844, 390), FakeViewPadding(left: 24, right: 44, bottom: 24)),
      (Size(1280, 800), FakeViewPadding(top: 24, bottom: 24)),
      (Size(1024, 768), FakeViewPadding(top: 24, bottom: 24)),
      (Size(1400, 1000), FakeViewPadding(top: 24, bottom: 24)),
      (Size(800, 1280), FakeViewPadding(top: 24, bottom: 24)),
      (Size(600, 800), FakeViewPadding(top: 24, bottom: 24)),
      (Size(390, 844), FakeViewPadding(top: 32, bottom: 24)),
    ];

    tester.view.physicalSize = configurations.first.$1;
    tester.view.padding = configurations.first.$2;
    tester.view.viewPadding = configurations.first.$2;
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initiallySignedIn: true,
          useRemoteEngine: false,
          initialGameMode: GameMode.local,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('square-e2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('square-e4')));
    await tester.pump(const Duration(milliseconds: 450));

    final gameState = tester.state(find.byType(GameScreen));
    for (final (size, padding) in configurations) {
      tester.view.physicalSize = size;
      tester.view.padding = padding;
      tester.view.viewPadding = padding;
      await tester.pump();

      expect(tester.state(find.byType(GameScreen)), same(gameState));
      final board = tester.getRect(find.byType(ChessBoard));
      expect(board.width, greaterThan(100));
      expect(board.left, greaterThanOrEqualTo(padding.left));
      expect(board.right, lessThanOrEqualTo(size.width - padding.right));
      expect(board.top, greaterThanOrEqualTo(padding.top));
      expect(board.bottom, lessThanOrEqualTo(size.height - padding.bottom));
      final back = find.byTooltip('Back to Home');
      if (back.evaluate().isNotEmpty) {
        expect(tester.getRect(back).left, greaterThanOrEqualTo(padding.left));
        expect(tester.getRect(back).top, greaterThanOrEqualTo(padding.top));
      }
      expect(tester.takeException(), isNull, reason: 'Window $size');
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
