import 'package:chessverse_ai/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('engine move review copy', () {
    test('uses one authoritative verdict for the best move', () {
      expect(
        engineMoveReviewText(
          isBestMove: true,
          isWeakMove: false,
          recommendation: 'e2 to e4',
        ),
        'Best move • Confirmed by AI analysis.',
      );
    });

    test('does not falsely confirm a non-best playable move', () {
      expect(
        engineMoveReviewText(
          isBestMove: false,
          isWeakMove: false,
          recommendation: 'e2 to e4',
        ),
        'Playable move • AI preferred e2 to e4.',
      );
    });

    test('shows a single actionable warning for a weak move', () {
      expect(
        engineMoveReviewText(
          isBestMove: false,
          isWeakMove: true,
          recommendation: 'e2 to e4',
        ),
        'Weak move alert • e2 to e4 was safer. Tap Analyze to see why.',
      );
    });
  });

  group('attack map', () {
    test('pawns attack diagonally only and in their own direction', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'd4': const ChessPiece('P', true),
        'f5': const ChessPiece('P', false),
      };

      expect(ChessRules.attacksSquare('d4', 'c5', board), isTrue);
      expect(ChessRules.attacksSquare('d4', 'e5', board), isTrue);
      expect(ChessRules.attacksSquare('d4', 'd5', board), isFalse);
      expect(ChessRules.attacksSquare('d4', 'c3', board), isFalse);
      expect(ChessRules.attacksSquare('f5', 'e4', board), isTrue);
      expect(ChessRules.attacksSquare('f5', 'g4', board), isTrue);
      expect(ChessRules.attacksSquare('f5', 'f4', board), isFalse);
    });

    test('all non-pawn pieces use chess attack geometry', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'd4': const ChessPiece('N', true),
        'a1': const ChessPiece('B', true),
        'a4': const ChessPiece('R', true),
        'h4': const ChessPiece('Q', true),
        'e1': const ChessPiece('K', true),
      };

      expect(ChessRules.attacksSquare('d4', 'f5', board), isTrue);
      expect(ChessRules.attacksSquare('d4', 'd5', board), isFalse);
      expect(ChessRules.attacksSquare('a1', 'c3', board), isTrue);
      expect(ChessRules.attacksSquare('a4', 'a7', board), isTrue);
      expect(ChessRules.attacksSquare('h4', 'e7', board), isTrue);
      expect(ChessRules.attacksSquare('e1', 'f2', board), isTrue);
      expect(ChessRules.attacksSquare('e1', 'e3', board), isFalse);
    });

    test('sliding attacks stop at the first blocker', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'a1': const ChessPiece('B', true),
        'b2': const ChessPiece('P', true),
        'd4': const ChessPiece('K', false),
      };

      expect(ChessRules.attacksSquare('a1', 'b2', board), isTrue);
      expect(ChessRules.attacksSquare('a1', 'c3', board), isFalse);
      expect(ChessRules.attacksSquare('a1', 'd4', board), isFalse);
    });

    test('a square occupied by a friendly piece is still defended', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'a8': const ChessPiece('R', false),
        'a7': const ChessPiece('P', false),
      };

      expect(ChessRules.attacksSquare('a8', 'a7', board), isTrue);
    });
  });

  group('king safety and terminal state', () {
    test('the reported pawn move is a queen discovered check', () {
      final Map<String, ChessPiece> before = <String, ChessPiece>{
        'e1': const ChessPiece('K', true),
        'b3': const ChessPiece('Q', true),
        'd5': const ChessPiece('P', true),
        'f7': const ChessPiece('K', false),
      };

      expect(ChessRules.isKingInCheck(false, before), isFalse);
      final Map<String, ChessPiece> after =
          ChessRules.applyMove('d5', 'd6', before);
      expect(ChessRules.attacksSquare('d6', 'f7', after), isFalse);
      expect(ChessRules.attacksSquare('b3', 'f7', after), isTrue);
      expect(ChessRules.checkingAttackers(false, after), <String>['b3']);
      expect(ChessRules.isKingInCheck(false, after), isTrue);
    });

    test('a pinned piece cannot expose its own king', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'e1': const ChessPiece('K', true),
        'e2': const ChessPiece('R', true),
        'e8': const ChessPiece('R', false),
        'a8': const ChessPiece('K', false),
      };

      expect(ChessRules.safeLegalTargets('e2', board), isNot(contains('d2')));
      expect(ChessRules.safeLegalTargets('e2', board), contains('e3'));
    });

    test('adjacent kings are attacks and can never move together', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'e1': const ChessPiece('K', true),
        'e3': const ChessPiece('K', false),
      };

      expect(ChessRules.attacksSquare('e3', 'e2', board), isTrue);
      expect(ChessRules.safeLegalTargets('e1', board), isNot(contains('e2')));
    });

    test('check with a blocking defense is not checkmate', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'e1': const ChessPiece('K', true),
        'a2': const ChessPiece('R', true),
        'e8': const ChessPiece('R', false),
        'a8': const ChessPiece('K', false),
      };

      expect(ChessRules.isKingInCheck(true, board), isTrue);
      expect(ChessRules.safeLegalTargets('a2', board), contains('e2'));
      expect(ChessRules.isCheckmate(true, board), isFalse);
    });

    test('stalemate is a draw and is never reported as checkmate', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'h8': const ChessPiece('K', false),
        'f7': const ChessPiece('K', true),
        'g6': const ChessPiece('Q', true),
      };

      expect(ChessRules.isKingInCheck(false, board), isFalse);
      expect(ChessRules.hasAnySafeMove(false, board), isFalse);
      expect(ChessRules.isStalemate(false, board), isTrue);
      expect(ChessRules.isCheckmate(false, board), isFalse);
    });

    test('a king cannot move into an enemy pawn attack', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'e3': const ChessPiece('K', true),
        'e8': const ChessPiece('K', false),
        'd5': const ChessPiece('P', false),
      };

      expect(ChessRules.safeLegalTargets('e3', board), isNot(contains('e4')));
    });
  });

  group('piece movement boundaries', () {
    test('pawn double-step requires both forward squares to be empty', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'e2': const ChessPiece('P', true),
        'e3': const ChessPiece('N', false),
      };
      expect(ChessRules.legalTargets('e2', board), isEmpty);
    });

    test('pawns capture enemies diagonally but never move onto them forward',
        () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'd4': const ChessPiece('P', true),
        'd5': const ChessPiece('R', false),
        'c5': const ChessPiece('N', false),
        'e5': const ChessPiece('B', true),
      };
      expect(ChessRules.legalTargets('d4', board), contains('c5'));
      expect(ChessRules.legalTargets('d4', board), isNot(contains('d5')));
      expect(ChessRules.legalTargets('d4', board), isNot(contains('e5')));
    });

    test('recorded g4xf3 black-pawn capture is a legal diagonal capture', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'e1': const ChessPiece('K', true),
        'e8': const ChessPiece('K', false),
        'f3': const ChessPiece('P', true),
        'g4': const ChessPiece('P', false),
      };

      expect(ChessRules.safeLegalTargets('g4', board), contains('f3'));
      final Map<String, ChessPiece> after =
          ChessRules.applyMove('g4', 'f3', board);
      expect(after['g4'], isNull);
      expect(after['f3']?.code, 'P');
      expect(after['f3']?.white, isFalse);
    });

    test('a pawn cannot ignore check to make the same g4xf3 capture', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'a1': const ChessPiece('K', true),
        'e1': const ChessPiece('R', true),
        'e8': const ChessPiece('K', false),
        'f3': const ChessPiece('P', true),
        'g4': const ChessPiece('P', false),
      };

      expect(ChessRules.isKingInCheck(false, board), isTrue);
      expect(ChessRules.legalTargets('g4', board), contains('f3'));
      expect(ChessRules.safeLegalTargets('g4', board), isNot(contains('f3')));
    });

    test('knights jump blockers but cannot capture a friendly piece', () {
      final Map<String, ChessPiece> board = <String, ChessPiece>{
        'b1': const ChessPiece('N', true),
        'b2': const ChessPiece('P', true),
        'c2': const ChessPiece('P', true),
        'a3': const ChessPiece('P', true),
        'c3': const ChessPiece('P', false),
      };
      expect(ChessRules.legalTargets('b1', board), contains('c3'));
      expect(ChessRules.legalTargets('b1', board), isNot(contains('a3')));
    });
  });

  test('standard starting position matches depth 1-3 perft counts', () {
    final Map<String, ChessPiece> board = _startingPosition();

    expect(_perft(board, true, 1), 20);
    expect(_perft(board, true, 2), 400);
    expect(_perft(board, true, 3), 8902);
  });

  test('standard position also matches the depth-4 perft reference', () {
    expect(_perft(_startingPosition(), true, 4), 197281);
  });
}

int _perft(Map<String, ChessPiece> board, bool whiteToMove, int depth) {
  if (depth == 0) return 1;
  int nodes = 0;
  for (final MapEntry<String, ChessPiece> entry
      in board.entries.toList(growable: false)) {
    if (entry.value.white != whiteToMove) continue;
    for (final String target in ChessRules.safeLegalTargets(entry.key, board)) {
      nodes += _perft(
        ChessRules.applyMove(entry.key, target, board),
        !whiteToMove,
        depth - 1,
      );
    }
  }
  return nodes;
}

Map<String, ChessPiece> _startingPosition() {
  final Map<String, ChessPiece> board = <String, ChessPiece>{};
  const List<String> backRank = <String>[
    'R',
    'N',
    'B',
    'Q',
    'K',
    'B',
    'N',
    'R'
  ];
  for (int file = 0; file < 8; file++) {
    final String name = String.fromCharCode(97 + file);
    board['${name}1'] = ChessPiece(backRank[file], true);
    board['${name}2'] = const ChessPiece('P', true);
    board['${name}7'] = const ChessPiece('P', false);
    board['${name}8'] = ChessPiece(backRank[file], false);
  }
  return board;
}
