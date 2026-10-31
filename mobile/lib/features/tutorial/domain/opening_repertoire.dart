import '../../analysis/domain/pgn_position_reconstructor.dart';

class OpeningLine {
  const OpeningLine(this.id, this.name, this.moves);
  final String id, name;
  final List<String> moves;
  List<String> get positions =>
      replayUciLine(standardInitialFen, moves, requireLegalMoves: true);
}

/// Short main-line exercises, not claims that alternative legal moves are bad.
const openingRepertoire = <OpeningLine>[
  OpeningLine('ruy-lopez', 'Ruy Lopez', [
    'e2e4',
    'e7e5',
    'g1f3',
    'b8c6',
    'f1b5',
    'a7a6',
    'b5a4',
    'g8f6',
    'e1g1',
    'f8e7',
  ]),
  OpeningLine('sicilian', 'Sicilian Defence', [
    'e2e4',
    'c7c5',
    'g1f3',
    'd7d6',
    'd2d4',
    'c5d4',
    'f3d4',
    'g8f6',
    'b1c3',
    'a7a6',
  ]),
  OpeningLine('italian', 'Italian Game', [
    'e2e4',
    'e7e5',
    'g1f3',
    'b8c6',
    'f1c4',
    'f8c5',
    'c2c3',
    'g8f6',
    'd2d3',
    'd7d6',
  ]),
  OpeningLine('queens-gambit', 'Queen’s Gambit', [
    'd2d4',
    'd7d5',
    'c2c4',
    'e7e6',
    'b1c3',
    'g8f6',
    'c1g5',
    'f8e7',
    'e2e3',
    'e8g8',
  ]),
];

class OpeningPractice {
  OpeningPractice(this.line, {this.playWhite = true}) {
    if (_positions.length != line.moves.length + 1) {
      throw StateError('Invalid opening line');
    }
    _reply();
  }
  final OpeningLine line;
  late final List<String> _positions = line.positions;
  final bool playWhite;
  int ply = 0;
  bool get complete => ply >= line.moves.length;
  String get fen => _positions[ply];
  String? get expected => complete ? null : line.moves[ply];
  bool tryMove(String move) {
    if (complete || move != expected) return false;
    ply++;
    _reply();
    return true;
  }

  void _reply() {
    if (!complete && (ply.isEven != playWhite)) ply++;
  }
}
