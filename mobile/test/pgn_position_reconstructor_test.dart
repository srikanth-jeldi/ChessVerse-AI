import 'package:chessverse_ai/features/analysis/domain/pgn_position_reconstructor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reconstructs exact positions before SAN moves', () {
    final positions = reconstructFenBeforeMoves(<String>[
      'e4',
      'e5',
      'Nf3',
      'Nc6',
      'Bb5',
    ]);

    expect(positions, hasLength(5));
    expect(positions.first, standardInitialFen);
    expect(
      positions[1],
      'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
    );
    expect(
      positions[4],
      'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
    );
  });

  test('supports captures, castling, disambiguation and promotion', () {
    final positions = reconstructFenBeforeMoves(<String>[
      'e4',
      'd5',
      'exd5',
      'Qxd5',
      'Nc3',
      'Qd8',
      'Nf3',
      'Nf6',
      'Bc4',
      'e6',
      'O-O',
      'Be7',
    ]);
    expect(positions.every((String? fen) => fen != null), isTrue);
    expect(positions.last, contains(' b kq '));

    final promotion = reconstructFenBeforeMoves(<String>[
      'a8=Q',
    ], initialFen: '7k/P7/8/8/8/8/8/7K w - - 0 1');
    expect(promotion.single, '7k/P7/8/8/8/8/8/7K w - - 0 1');

    final coordinatePromotion = reconstructFenBeforeMoves(<String>[
      'a7a8=Q',
      'Kh7',
    ], initialFen: '7k/P7/8/8/8/8/8/7K w - - 0 1');
    expect(coordinatePromotion.every((String? fen) => fen != null), isTrue);
    expect(coordinatePromotion.last, startsWith('Q6k/'));
  });

  test('offers five practical candidate moves from an imported position', () {
    final candidates = coachMoveCandidates(standardInitialFen, limit: 5);

    expect(candidates, hasLength(5));
    expect(candidates.map((candidate) => candidate.move).toSet(), hasLength(5));
    expect(
      candidates.every(
        (candidate) =>
            RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$').hasMatch(candidate.move),
      ),
      isTrue,
    );
  });

  test('keeps reconstructing when SAN has a pinned pseudo-candidate', () {
    final positions = reconstructFenBeforeMoves(<String>[
      'Nd4',
      'Ka7',
    ], initialFen: 'k3r3/8/8/8/8/5N2/4N3/4K3 w - - 0 1');

    expect(positions, hasLength(2));
    expect(positions.every((String? fen) => fen != null), isTrue);
    expect(positions.last, contains(' b '));
  });
}
