import 'package:chessverse_ai/features/analysis/domain/pgn_position_reconstructor.dart';
import 'package:chessverse_ai/features/analysis/presentation/animated_practice_pieces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    String fen, {
    bool flipped = false,
    bool reduced = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Center(
            child: SizedBox(
              width: 320,
              height: 320,
              child: AnimatedPracticePieces(
                fen: fen,
                flipped: flipped,
                pieceBuilder: (token) => Text(token),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Positioned piece(WidgetTester tester, String square) =>
      tester.widget(find.byKey(ValueKey('practice-piece-$square')));

  for (final flipped in [false, true]) {
    testWidgets('player, reply and reverse preview animate flipped=$flipped', (
      tester,
    ) async {
      final positions = replayUciLine(standardInitialFen, ['e2e4', 'e7e5']);
      await show(tester, positions[0], flipped: flipped);
      final source = piece(tester, 'e2').top!;
      await show(tester, positions[1], flipped: flipped);
      expect(piece(tester, 'e4').top, source);
      await tester.pump(const Duration(milliseconds: 80));
      final mid = piece(tester, 'e4').top!;
      await tester.pumpAndSettle();
      final end = piece(tester, 'e4').top!;
      expect(
        mid,
        inExclusiveRange(
          source < end ? source : end,
          source > end ? source : end,
        ),
      );
      final replyStart = piece(tester, 'e7').top;
      await show(tester, positions[2], flipped: flipped);
      expect(piece(tester, 'e5').top, replyStart);
      await tester.pumpAndSettle();
      await show(tester, positions[1], flipped: flipped);
      expect(piece(tester, 'e7').top, flipped ? 160 : 120);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('saved queen practice animates its long diagonal', (tester) async {
    const fen = 'Qn2kbnr/4p1p1/p1P4p/5p2/8/3P4/PP3KBP/RNBQ2NR w kq - 0 12';
    final next = replayUciLine(fen, ['d1h5'], requireLegalMoves: true);
    expect(next, hasLength(2));
    await show(tester, fen);
    await show(tester, next.last);
    expect(piece(tester, 'h5').left, 120);
    await tester.pump(const Duration(milliseconds: 80));
    expect(piece(tester, 'h5').left, inExclusiveRange(120, 280));
    await tester.pumpAndSettle();
  });

  testWidgets('castling moves both pieces and reset snaps', (tester) async {
    const fen = 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1';
    final next = replayUciLine(fen, ['e1g1']).last;
    await show(tester, fen);
    await show(tester, next);
    expect(piece(tester, 'g1').left, 160);
    expect(piece(tester, 'f1').left, 280);
    await tester.pumpAndSettle();
    expect(piece(tester, 'g1').left, 240);
    expect(piece(tester, 'f1').left, 200);
    await show(tester, standardInitialFen);
    expect(piece(tester, 'e1').left, 160);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('capture, promotion and en passant finish with correct pieces', (
    tester,
  ) async {
    for (final entry in <(String, String, String)>[
      ('4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1', 'e4d5', 'P'),
      ('4k3/P7/8/8/8/8/8/4K3 w - - 0 1', 'a7a8q', 'Q'),
      ('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1', 'e5d6', 'P'),
    ]) {
      await show(tester, entry.$1);
      await tester.pumpAndSettle();
      final origin = piece(tester, entry.$2.substring(0, 2));
      final next = replayUciLine(entry.$1, [
        entry.$2,
      ], requireLegalMoves: true).last;
      await show(tester, next);
      final moved = piece(tester, entry.$2.substring(2, 4));
      expect(moved.left, origin.left);
      expect(moved.top, origin.top);
      await tester.pumpAndSettle();
      expect(find.text(entry.$3), findsOneWidget);
      expect(find.text('p'), findsNothing);
    }
  });

  testWidgets('reduced motion skips animation and overlay ignores taps', (
    tester,
  ) async {
    await show(tester, standardInitialFen, reduced: true);
    await show(
      tester,
      replayUciLine(standardInitialFen, ['e2e4']).last,
      reduced: true,
    );
    expect(piece(tester, 'e4').top, 160);
    expect(tester.hasRunningAnimations, isFalse);
    expect(
      tester
          .widget<IgnorePointer>(
            find.descendant(
              of: find.byType(AnimatedPracticePieces),
              matching: find.byType(IgnorePointer),
            ),
          )
          .ignoring,
      isTrue,
    );
  });
}
