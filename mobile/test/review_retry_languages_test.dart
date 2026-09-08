import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/coach_localizations.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('retry sub-screen renders the selected locale on narrow phones',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final language in AppLanguageController.supported
        .where((language) => language.code != 'system')) {
      final copy = CoachLocalizations(language.code);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
        body: ReviewedPositionRetryDialog(
          key: ValueKey(language.code),
          fen: '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1',
          initialPieces: const {
            'e1': ChessPiece('K', true),
            'e8': ChessPiece('K', false),
            'e2': ChessPiece('P', true)
          },
          whiteToMove: true,
          bestMove: 'e2e4',
          explanation: '',
          progressLabel: 'POSITION BEFORE MOVE 13',
          languageCode: language.code,
        ),
      )));
      await tester.pump();
      expect(find.text(copy.text('positionBefore', {'move': '13'})),
          findsOneWidget,
          reason: language.code);
      expect(find.text(copy.text('retry')), findsOneWidget,
          reason: language.code);
      expect(find.text(copy.text('back')), findsOneWidget,
          reason: language.code);
      expect(tester.takeException(), isNull, reason: language.code);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
