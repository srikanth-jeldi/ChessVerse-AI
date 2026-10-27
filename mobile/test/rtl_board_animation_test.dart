import 'package:chessverse_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in ['en', 'ar', 'he', 'fa', 'ur']) {
    for (final flipped in [false, true]) {
      testWidgets('$language board animation flipped=$flipped', (tester) async {
        String? tapped;
        Widget scene(bool moved) => MaterialApp(
          home: Directionality(
            textDirection: language == 'en'
                ? TextDirection.ltr
                : TextDirection.rtl,
            child: Material(
              child: Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: ChessBoard(
                    pieces: {moved ? 'e4' : 'e2': const ChessPiece('P', true)},
                    selectedSquare: null,
                    legalTargets: const {},
                    lastFromSquare: moved ? 'e2' : null,
                    lastToSquare: moved ? 'e4' : null,
                    lastMovedPiece: moved ? const ChessPiece('P', true) : null,
                    lastCaptureSquare: null,
                    moveSequence: moved ? 1 : 0,
                    checkedKingSquare: null,
                    decisiveSquare: null,
                    coachArrowFrom: null,
                    coachArrowTo: null,
                    flipped: flipped,
                    showCoordinates: true,
                    coordinatesOnMobile: true,
                    palette: boardPalettes[BoardSkin.royalWalnut]!,
                    onSquareTap: (square) => tapped = square,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(scene(false));
        final from = tester.getTopLeft(find.byKey(const ValueKey('square-e2')));
        final to = tester.getTopLeft(find.byKey(const ValueKey('square-e4')));
        final a = tester.getTopLeft(find.byKey(const ValueKey('square-a1')));
        final h = tester.getTopLeft(find.byKey(const ValueKey('square-h1')));
        expect(a.dx < h.dx, !flipped);
        await tester.tap(find.byKey(const ValueKey('square-e2')));
        expect(tapped, 'e2');
        await tester.pumpWidget(scene(true));
        final moving = find.byKey(const ValueKey('moving-piece-true-P'));
        expect(tester.getTopLeft(moving), from);
        await tester.pump(const Duration(milliseconds: 180));
        expect(tester.getTopLeft(moving).dx, closeTo(from.dx, 0.01));
        await tester.pump(const Duration(milliseconds: 180));
        expect((tester.getTopLeft(moving) - to).distance, lessThan(0.01));
        await tester.pump(const Duration(seconds: 1));
        expect(moving, findsNothing);
        expect(
          tester
              .widget<BoardSquare>(find.byKey(const ValueKey('square-e4')))
              .piece
              ?.code,
          'P',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
