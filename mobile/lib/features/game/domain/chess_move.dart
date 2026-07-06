class ChessMove {
  const ChessMove({
    required this.from,
    required this.to,
    this.capturedSquare,
    this.isCastle = false,
    this.isPromotion = false,
    this.isEnPassant = false,
  });

  final String from;
  final String to;
  final String? capturedSquare;
  final bool isCastle;
  final bool isPromotion;
  final bool isEnPassant;

  String get notation {
    if (isCastle) return to.startsWith('g') ? 'O-O' : 'O-O-O';
    final String capture = capturedSquare == null ? '' : 'x';
    final String promo = isPromotion ? '=Q' : '';
    final String ep = isEnPassant ? ' e.p.' : '';
    return '$from$capture$to$promo$ep';
  }
}
