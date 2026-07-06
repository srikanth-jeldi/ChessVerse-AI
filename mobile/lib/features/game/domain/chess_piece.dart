enum PieceType { pawn, knight, bishop, rook, queen, king }

enum PieceColor { white, black }

extension PieceColorX on PieceColor {
  bool get isWhite => this == PieceColor.white;
  PieceColor get opposite => isWhite ? PieceColor.black : PieceColor.white;
  String get label => isWhite ? 'White' : 'Black';
}

class ChessPiece {
  const ChessPiece({required this.type, required this.color});

  final PieceType type;
  final PieceColor color;

  bool get isWhite => color.isWhite;

  String get symbol {
    return switch ((type, color)) {
      (PieceType.king, PieceColor.white) => '♔',
      (PieceType.queen, PieceColor.white) => '♕',
      (PieceType.rook, PieceColor.white) => '♖',
      (PieceType.bishop, PieceColor.white) => '♗',
      (PieceType.knight, PieceColor.white) => '♘',
      (PieceType.pawn, PieceColor.white) => '♙',
      (PieceType.king, PieceColor.black) => '♚',
      (PieceType.queen, PieceColor.black) => '♛',
      (PieceType.rook, PieceColor.black) => '♜',
      (PieceType.bishop, PieceColor.black) => '♝',
      (PieceType.knight, PieceColor.black) => '♞',
      (PieceType.pawn, PieceColor.black) => '♟',
    };
  }

  String get fenCode {
    final String code = switch (type) {
      PieceType.king => 'k',
      PieceType.queen => 'q',
      PieceType.rook => 'r',
      PieceType.bishop => 'b',
      PieceType.knight => 'n',
      PieceType.pawn => 'p',
    };
    return isWhite ? code.toUpperCase() : code;
  }
}
