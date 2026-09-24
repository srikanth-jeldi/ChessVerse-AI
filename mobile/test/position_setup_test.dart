import 'package:chessverse_ai/features/play/presentation/position_creator_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
