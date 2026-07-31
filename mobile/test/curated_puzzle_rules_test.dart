import 'package:chessverse_ai/features/puzzles/domain/puzzle_catalog.dart';
import 'package:chessverse_ai/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all curated lines are legal in the app rules engine and end in mate',
      () {
    for (final ChessPuzzle puzzle in PuzzleCatalog.all) {
      Map<String, ChessPiece> board = _parseFen(puzzle.fen);
      bool whiteToMove = true;
      for (final String uci in puzzle.solution) {
        final String from = uci.substring(0, 2);
        final String to = uci.substring(2, 4);
        final ChessPiece? piece = board[from];
        expect(piece, isNotNull, reason: '${puzzle.id}: missing $from');
        expect(
          piece!.white,
          whiteToMove,
          reason: '${puzzle.id}: wrong side for $uci',
        );
        expect(
          ChessRules.safeLegalTargets(from, board),
          contains(to),
          reason: '${puzzle.id}: app rules reject $uci',
        );
        board = ChessRules.applyMove(from, to, board);
        whiteToMove = !whiteToMove;
      }
      expect(
        ChessRules.isKingInCheck(false, board),
        isTrue,
        reason: '${puzzle.id}: final black king is not in check',
      );
      final bool blackHasMove = board.entries
          .where((MapEntry<String, ChessPiece> entry) => !entry.value.white)
          .any(
            (MapEntry<String, ChessPiece> entry) =>
                ChessRules.safeLegalTargets(entry.key, board).isNotEmpty,
          );
      expect(
        blackHasMove,
        isFalse,
        reason: '${puzzle.id}: final position is not checkmate',
      );
    }
  });
}

Map<String, ChessPiece> _parseFen(String fen) {
  const String files = 'abcdefgh';
  final Map<String, ChessPiece> pieces = <String, ChessPiece>{};
  final List<String> ranks = fen.split(' ').first.split('/');
  for (int rankIndex = 0; rankIndex < 8; rankIndex++) {
    int fileIndex = 0;
    for (final int rune in ranks[rankIndex].runes) {
      final String token = String.fromCharCode(rune);
      final int? empty = int.tryParse(token);
      if (empty != null) {
        fileIndex += empty;
      } else {
        pieces['${files[fileIndex]}${8 - rankIndex}'] = ChessPiece(
          token.toUpperCase(),
          token == token.toUpperCase(),
        );
        fileIndex++;
      }
    }
  }
  return pieces;
}
