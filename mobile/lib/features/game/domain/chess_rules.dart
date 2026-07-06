import 'chess_move.dart';
import 'chess_piece.dart';

typedef BoardState = Map<String, ChessPiece>;

class BoardPoint {
  const BoardPoint(this.file, this.rank);

  final int file;
  final int rank;
}

abstract final class ChessRules {
  static BoardState initialBoard() => <String, ChessPiece>{
        'a8': const ChessPiece(type: PieceType.rook, color: PieceColor.black),
        'b8': const ChessPiece(type: PieceType.knight, color: PieceColor.black),
        'c8': const ChessPiece(type: PieceType.bishop, color: PieceColor.black),
        'd8': const ChessPiece(type: PieceType.queen, color: PieceColor.black),
        'e8': const ChessPiece(type: PieceType.king, color: PieceColor.black),
        'f8': const ChessPiece(type: PieceType.bishop, color: PieceColor.black),
        'g8': const ChessPiece(type: PieceType.knight, color: PieceColor.black),
        'h8': const ChessPiece(type: PieceType.rook, color: PieceColor.black),
        for (final String file in files) '${file}7': const ChessPiece(type: PieceType.pawn, color: PieceColor.black),
        for (final String file in files) '${file}2': const ChessPiece(type: PieceType.pawn, color: PieceColor.white),
        'a1': const ChessPiece(type: PieceType.rook, color: PieceColor.white),
        'b1': const ChessPiece(type: PieceType.knight, color: PieceColor.white),
        'c1': const ChessPiece(type: PieceType.bishop, color: PieceColor.white),
        'd1': const ChessPiece(type: PieceType.queen, color: PieceColor.white),
        'e1': const ChessPiece(type: PieceType.king, color: PieceColor.white),
        'f1': const ChessPiece(type: PieceType.bishop, color: PieceColor.white),
        'g1': const ChessPiece(type: PieceType.knight, color: PieceColor.white),
        'h1': const ChessPiece(type: PieceType.rook, color: PieceColor.white),
      };

  static const List<String> files = <String>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

  static BoardPoint pointOf(String square) => BoardPoint(square.codeUnitAt(0) - 97, int.parse(square[1]));

  static String squareOf(int file, int rank) => '${String.fromCharCode(97 + file)}$rank';

  static bool isInside(int file, int rank) => file >= 0 && file < 8 && rank >= 1 && rank <= 8;

  static List<String> legalTargets({
    required String from,
    required BoardState board,
    required List<ChessMove> history,
  }) {
    final ChessPiece? piece = board[from];
    if (piece == null) return <String>[];

    final Set<String> targets = pseudoTargets(from: from, board: board).toSet();
    targets.addAll(castlingTargets(from: from, board: board, history: history));
    targets.addAll(enPassantTargets(from: from, board: board, history: history));

    return targets.where((String to) {
      final BoardState next = applyMove(board: board, move: buildMove(from: from, to: to, board: board, history: history));
      return !isKingInCheck(piece.color, next);
    }).toList(growable: false);
  }

  static ChessMove buildMove({
    required String from,
    required String to,
    required BoardState board,
    required List<ChessMove> history,
  }) {
    final ChessPiece piece = board[from]!;
    final bool castle = piece.type == PieceType.king && from[0] == 'e' && (to[0] == 'g' || to[0] == 'c');
    final String? enPassantSquare = _enPassantCaptureSquare(from: from, to: to, board: board, history: history);
    final bool promotion = piece.type == PieceType.pawn && ((piece.isWhite && to.endsWith('8')) || (!piece.isWhite && to.endsWith('1')));
    return ChessMove(
      from: from,
      to: to,
      capturedSquare: enPassantSquare ?? (board[to] == null ? null : to),
      isCastle: castle,
      isPromotion: promotion,
      isEnPassant: enPassantSquare != null,
    );
  }

  static BoardState applyMove({required BoardState board, required ChessMove move}) {
    final BoardState next = BoardState.from(board);
    final ChessPiece? piece = next.remove(move.from);
    if (piece == null) return next;
    if (move.capturedSquare != null) next.remove(move.capturedSquare);
    next[move.to] = move.isPromotion ? ChessPiece(type: PieceType.queen, color: piece.color) : piece;

    if (move.isCastle) {
      final String rank = piece.isWhite ? '1' : '8';
      if (move.to == 'g$rank') {
        final ChessPiece? rook = next.remove('h$rank');
        if (rook != null) next['f$rank'] = rook;
      } else if (move.to == 'c$rank') {
        final ChessPiece? rook = next.remove('a$rank');
        if (rook != null) next['d$rank'] = rook;
      }
    }
    return next;
  }

  static bool hasAnyLegalMove(PieceColor color, BoardState board, List<ChessMove> history) {
    for (final MapEntry<String, ChessPiece> entry in board.entries) {
      if (entry.value.color == color && legalTargets(from: entry.key, board: board, history: history).isNotEmpty) return true;
    }
    return false;
  }

  static bool isKingInCheck(PieceColor color, BoardState board) {
    String? kingSquare;
    for (final MapEntry<String, ChessPiece> entry in board.entries) {
      if (entry.value.color == color && entry.value.type == PieceType.king) {
        kingSquare = entry.key;
        break;
      }
    }
    if (kingSquare == null) return false;
    for (final MapEntry<String, ChessPiece> entry in board.entries) {
      if (entry.value.color != color && attacksSquare(from: entry.key, target: kingSquare, board: board)) return true;
    }
    return false;
  }

  static bool attacksSquare({required String from, required String target, required BoardState board}) {
    final ChessPiece? piece = board[from];
    if (piece == null) return false;
    if (piece.type == PieceType.pawn) {
      final BoardPoint origin = pointOf(from);
      final BoardPoint attacked = pointOf(target);
      final int direction = piece.isWhite ? 1 : -1;
      return attacked.rank == origin.rank + direction && (attacked.file - origin.file).abs() == 1;
    }
    return pseudoTargets(from: from, board: board).contains(target);
  }

  static List<String> pseudoTargets({required String from, required BoardState board}) {
    final ChessPiece? piece = board[from];
    if (piece == null) return <String>[];
    return switch (piece.type) {
      PieceType.pawn => _pawnTargets(from, piece, board),
      PieceType.knight => _jumpTargets(from, piece, board, const <BoardPoint>[BoardPoint(1, 2), BoardPoint(2, 1), BoardPoint(2, -1), BoardPoint(1, -2), BoardPoint(-1, -2), BoardPoint(-2, -1), BoardPoint(-2, 1), BoardPoint(-1, 2)]),
      PieceType.bishop => _rayTargets(from, piece, board, const <BoardPoint>[BoardPoint(1, 1), BoardPoint(1, -1), BoardPoint(-1, 1), BoardPoint(-1, -1)]),
      PieceType.rook => _rayTargets(from, piece, board, const <BoardPoint>[BoardPoint(1, 0), BoardPoint(-1, 0), BoardPoint(0, 1), BoardPoint(0, -1)]),
      PieceType.queen => _rayTargets(from, piece, board, const <BoardPoint>[BoardPoint(1, 0), BoardPoint(-1, 0), BoardPoint(0, 1), BoardPoint(0, -1), BoardPoint(1, 1), BoardPoint(1, -1), BoardPoint(-1, 1), BoardPoint(-1, -1)]),
      PieceType.king => _jumpTargets(from, piece, board, const <BoardPoint>[BoardPoint(1, 0), BoardPoint(-1, 0), BoardPoint(0, 1), BoardPoint(0, -1), BoardPoint(1, 1), BoardPoint(1, -1), BoardPoint(-1, 1), BoardPoint(-1, -1)]),
    };
  }

  static List<String> _pawnTargets(String from, ChessPiece piece, BoardState board) {
    final BoardPoint origin = pointOf(from);
    final int direction = piece.isWhite ? 1 : -1;
    final int startRank = piece.isWhite ? 2 : 7;
    final List<String> targets = <String>[];
    final int oneRank = origin.rank + direction;
    if (isInside(origin.file, oneRank)) {
      final String one = squareOf(origin.file, oneRank);
      if (!board.containsKey(one)) {
        targets.add(one);
        final int twoRank = origin.rank + direction * 2;
        final String two = squareOf(origin.file, twoRank);
        if (origin.rank == startRank && isInside(origin.file, twoRank) && !board.containsKey(two)) targets.add(two);
      }
    }
    for (final int delta in <int>[-1, 1]) {
      final int file = origin.file + delta;
      final int rank = origin.rank + direction;
      if (!isInside(file, rank)) continue;
      final String target = squareOf(file, rank);
      final ChessPiece? occupant = board[target];
      if (occupant != null && occupant.color != piece.color) targets.add(target);
    }
    return targets;
  }

  static List<String> _jumpTargets(String from, ChessPiece piece, BoardState board, List<BoardPoint> deltas) {
    final BoardPoint origin = pointOf(from);
    final List<String> targets = <String>[];
    for (final BoardPoint delta in deltas) {
      final int file = origin.file + delta.file;
      final int rank = origin.rank + delta.rank;
      if (!isInside(file, rank)) continue;
      final String target = squareOf(file, rank);
      final ChessPiece? occupant = board[target];
      if (occupant == null || occupant.color != piece.color) targets.add(target);
    }
    return targets;
  }

  static List<String> _rayTargets(String from, ChessPiece piece, BoardState board, List<BoardPoint> directions) {
    final BoardPoint origin = pointOf(from);
    final List<String> targets = <String>[];
    for (final BoardPoint direction in directions) {
      int file = origin.file + direction.file;
      int rank = origin.rank + direction.rank;
      while (isInside(file, rank)) {
        final String target = squareOf(file, rank);
        final ChessPiece? occupant = board[target];
        if (occupant == null) {
          targets.add(target);
        } else {
          if (occupant.color != piece.color) targets.add(target);
          break;
        }
        file += direction.file;
        rank += direction.rank;
      }
    }
    return targets;
  }

  static List<String> castlingTargets({required String from, required BoardState board, required List<ChessMove> history}) {
    final ChessPiece? piece = board[from];
    if (piece == null || piece.type != PieceType.king || _hasMovedFrom(from, history)) return <String>[];
    final String rank = piece.isWhite ? '1' : '8';
    if (from != 'e$rank' || isKingInCheck(piece.color, board)) return <String>[];
    final List<String> targets = <String>[];
    if (_canCastle(piece.color, 'h$rank', <String>['f$rank', 'g$rank'], <String>['f$rank', 'g$rank'], board, history)) targets.add('g$rank');
    if (_canCastle(piece.color, 'a$rank', <String>['b$rank', 'c$rank', 'd$rank'], <String>['d$rank', 'c$rank'], board, history)) targets.add('c$rank');
    return targets;
  }

  static bool _canCastle(PieceColor color, String rookFrom, List<String> emptySquares, List<String> kingPath, BoardState board, List<ChessMove> history) {
    final ChessPiece? rook = board[rookFrom];
    if (rook == null || rook.type != PieceType.rook || rook.color != color || _hasMovedFrom(rookFrom, history)) return false;
    for (final String square in emptySquares) {
      if (board.containsKey(square)) return false;
    }
    final String kingFrom = color.isWhite ? 'e1' : 'e8';
    for (final String square in kingPath) {
      final BoardState next = BoardState.from(board)..remove(kingFrom);
      next[square] = ChessPiece(type: PieceType.king, color: color);
      if (isKingInCheck(color, next)) return false;
    }
    return true;
  }

  static List<String> enPassantTargets({required String from, required BoardState board, required List<ChessMove> history}) {
    final ChessPiece? piece = board[from];
    if (piece == null || piece.type != PieceType.pawn) return <String>[];
    final ChessMove? last = history.isEmpty ? null : history.last;
    if (last == null) return <String>[];
    final ChessPiece? movedPawn = board[last.to];
    if (movedPawn == null || movedPawn.type != PieceType.pawn || movedPawn.color == piece.color) return <String>[];
    final BoardPoint fromPoint = pointOf(last.from);
    final BoardPoint toPoint = pointOf(last.to);
    if ((fromPoint.rank - toPoint.rank).abs() != 2) return <String>[];
    final BoardPoint pawnPoint = pointOf(from);
    final int requiredRank = piece.isWhite ? 5 : 4;
    if (pawnPoint.rank != requiredRank || pawnPoint.rank != toPoint.rank || (pawnPoint.file - toPoint.file).abs() != 1) return <String>[];
    final String target = squareOf(toPoint.file, pawnPoint.rank + (piece.isWhite ? 1 : -1));
    return <String>[target];
  }

  static String? _enPassantCaptureSquare({required String from, required String to, required BoardState board, required List<ChessMove> history}) {
    final ChessPiece? piece = board[from];
    if (piece == null || piece.type != PieceType.pawn || board.containsKey(to)) return null;
    final List<String> targets = enPassantTargets(from: from, board: board, history: history);
    if (!targets.contains(to)) return null;
    final BoardPoint target = pointOf(to);
    final BoardPoint origin = pointOf(from);
    return squareOf(target.file, origin.rank);
  }

  static bool _hasMovedFrom(String square, List<ChessMove> history) {
    return history.any((ChessMove move) => move.from == square);
  }
}
