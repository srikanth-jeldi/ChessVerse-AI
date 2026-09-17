import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Cinematic loading fits portrait and landscape screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    final font = FontLoader('ChessVerseSerif')
      ..addFont(rootBundle.load('assets/fonts/ChessVerseSerif.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in <Size>[
      const Size(390, 844),
      const Size(320, 568),
      const Size(844, 390),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        const MaterialApp(home: ChessVerseLoadingScreen()),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(ChessVerseLoadingScreen));
        await precacheImage(
          const AssetImage('assets/branding/loading-cinematic-v1.webp'),
          context,
        );
        await precacheImage(
          const AssetImage('assets/branding/app_icon.png'),
          context,
        );
      });
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Preparing your board'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(ChessVerseLoadingScreen),
        matchesGoldenFile(
          'goldens/loading_${size.width.toInt()}x${size.height.toInt()}.png',
        ),
      );
    }
  }, tags: 'golden');
}
