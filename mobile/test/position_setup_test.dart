import 'package:chessverse_ai/features/play/presentation/position_creator_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/features/analysis/domain/pgn_position_reconstructor.dart';

void main() {
  test('black setup retains side independently of player colour and plies', () {
    const setup = PositionSetup(
      pieces: {'e1': 'wK', 'e8': 'bK', 'a7': 'bP'},
      humanWhite: true,
      whiteToMove: false,
    );
    expect(setup.initialFen, '4k3/p7/8/8/8/8/8/4K3 b - - 0 1');
    expect(positionWhiteToMove(setup.initialFen, 0), isFalse);
    expect(positionWhiteToMove(setup.initialFen, 1), isTrue);
    expect(positionWhiteToMove(setup.initialFen, 2), isFalse);
    expect(
      replayUciLine(setup.initialFen, [
        'a7a6',
        'e1d1',
      ], requireLegalMoves: true).length,
      3,
    );
  });
  test('only the side to move may already be in check', () {
    expect(
      setupHasNonMovingKingInCheck('4k3/8/8/8/8/8/4R3/4K3 w - - 0 1'),
      isTrue,
    );
    expect(
      setupHasNonMovingKingInCheck('4k3/8/8/8/8/8/4R3/4K3 b - - 0 1'),
      isFalse,
    );
  });
  test('position creator preserves the exact custom board as initial FEN', () {
    const PositionSetup setup = PositionSetup(
      pieces: <String, String>{'a1': 'wK', 'd4': 'wQ', 'h8': 'bK'},
      humanWhite: true,
    );

    expect(setup.initialFen, '7k/8/8/8/3Q4/8/8/K7 w - - 0 1');
  });

  test(
    'position creator FEN preserves every selected piece and its colour',
    () {
      const PositionSetup setup = PositionSetup(
        pieces: <String, String>{
          'e1': 'wK',
          'a2': 'wP',
          'c6': 'bN',
          'e8': 'bK',
        },
        humanWhite: false,
      );

      expect(setup.initialFen, '4k3/8/2n5/8/8/8/P7/4K3 w - - 0 1');
    },
  );
}
