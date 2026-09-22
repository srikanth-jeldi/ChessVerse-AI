const String standardInitialFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

/// Replays standard SAN (and coordinate/UCI) moves and returns the FEN before
/// every ply. This keeps imported PGN boards available while cloud analysis is
/// pending or when a move did not need an engine review.
List<String?> reconstructFenBeforeMoves(
  List<String> moves, {
  String? initialFen,
}) {
  final _PgnBoard? board = _PgnBoard.fromFen(initialFen ?? standardInitialFen);
  if (board == null) return List<String?>.filled(moves.length, null);

  final List<String?> positions = <String?>[];
  bool valid = true;
  for (final String move in moves) {
    positions.add(valid ? board.fen : null);
    if (valid && !board.play(move)) valid = false;
  }
  return positions;
}

class CoachMoveCandidate {
  const CoachMoveCandidate({
    required this.move,
    required this.piece,
    required this.isCapture,
    required this.isPromotion,
    required this.isCastle,
  });

  final String move;
  final String piece;
  final bool isCapture;
  final bool isPromotion;
  final bool isCastle;
}

/// Returns useful legal-looking moves from [fen] for coaching comparison.
///
/// Engine evidence is still the authority for the best move. These candidates
/// give learners a short calculation menu instead of pretending that one line
/// was their only choice.
List<CoachMoveCandidate> coachMoveCandidates(String fen, {int limit = 5}) {
  final _PgnBoard? board = _PgnBoard.fromFen(fen);
  if (board == null || limit <= 0) return const <CoachMoveCandidate>[];
  final List<({CoachMoveCandidate candidate, int score})> ranked = [];
  for (final MapEntry<String, String> entry in board.pieces.entries) {
    final String piece = entry.value;
    if (_PgnBoard._isWhite(piece) != board.whiteToMove) continue;
    for (int file = 0; file < 8; file++) {
      for (int rank = 1; rank <= 8; rank++) {
        final String target = _PgnBoard._square(file, rank);
        if (target == entry.key) continue;
        final bool capture =
            board.pieces.containsKey(target) ||
            (piece.toUpperCase() == 'P' && board.enPassant == target);
        bool castle = false;
        bool canMove = board._canMove(entry.key, target, piece, capture);
        if (piece.toUpperCase() == 'K' &&
            (entry.key.codeUnitAt(0) - target.codeUnitAt(0)).abs() == 2) {
          castle = board._canCastle(entry.key, target, piece);
          canMove = castle;
        }
        if (!canMove) continue;
        final bool promotion =
            piece.toUpperCase() == 'P' &&
            (target[1] == '1' || target[1] == '8');
        final String move = '${entry.key}$target${promotion ? 'q' : ''}';
        final String? captured = board.pieces[target];
        int score = capture ? 500 + _pieceValue(captured) : 0;
        if (promotion) score += 800;
        if (castle) score += 260;
        if ('d4e4d5e5'.contains(target)) score += 90;
        if (piece.toUpperCase() == 'N' || piece.toUpperCase() == 'B') {
          final bool home = entry.key[1] == (board.whiteToMove ? '1' : '8');
          if (home) score += 75;
        }
        score += 20 - (file - 3).abs() - (rank - 4).abs();
        ranked.add((
          candidate: CoachMoveCandidate(
            move: move,
            piece: piece.toUpperCase(),
            isCapture: capture,
            isPromotion: promotion,
            isCastle: castle,
          ),
          score: score,
        ));
      }
    }
  }
  ranked.sort((left, right) => right.score.compareTo(left.score));
  return ranked.take(limit).map((item) => item.candidate).toList();
}

int _pieceValue(String? piece) => switch (piece?.toUpperCase()) {
  'Q' => 900,
  'R' => 500,
  'B' || 'N' => 300,
  'P' => 100,
  _ => 0,
};

class _PgnBoard {
  _PgnBoard({
    required this.pieces,
    required this.whiteToMove,
    required this.castling,
    required this.enPassant,
    required this.halfmove,
    required this.fullmove,
  });

  final Map<String, String> pieces;
  bool whiteToMove;
  String castling;
  String? enPassant;
  int halfmove;
  int fullmove;

  static _PgnBoard? fromFen(String source) {
    final List<String> fields = source.trim().split(RegExp(r'\s+'));
    if (fields.length != 6) return null;
    final List<String> ranks = fields[0].split('/');
    if (ranks.length != 8) return null;
    final Map<String, String> pieces = <String, String>{};
    for (int row = 0; row < 8; row++) {
      int file = 0;
      for (final int rune in ranks[row].runes) {
        final String value = String.fromCharCode(rune);
        final int? empty = int.tryParse(value);
        if (empty != null) {
          file += empty;
        } else {
          if (file > 7 || !'prnbqkPRNBQK'.contains(value)) return null;
          pieces['${String.fromCharCode(97 + file)}${8 - row}'] = value;
          file++;
        }
      }
      if (file != 8) return null;
    }
    return _PgnBoard(
      pieces: pieces,
      whiteToMove: fields[1] == 'w',
      castling: fields[2] == '-' ? '' : fields[2],
      enPassant: fields[3] == '-' ? null : fields[3],
      halfmove: int.tryParse(fields[4]) ?? 0,
      fullmove: int.tryParse(fields[5]) ?? 1,
    );
  }

  String get fen {
    final StringBuffer placement = StringBuffer();
    for (int rank = 8; rank >= 1; rank--) {
      int empty = 0;
      for (int file = 0; file < 8; file++) {
        final String? piece = pieces[_square(file, rank)];
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) placement.write(empty);
          empty = 0;
          placement.write(piece);
        }
      }
      if (empty > 0) placement.write(empty);
      if (rank > 1) placement.write('/');
    }
    return '$placement ${whiteToMove ? 'w' : 'b'} '
        '${castling.isEmpty ? '-' : castling} ${enPassant ?? '-'} '
        '$halfmove $fullmove';
  }

  bool play(String rawMove) {
    String san = rawMove.trim().replaceFirst(RegExp(r'^\d+\.(?:\.\.)?'), '');
    san = san.replaceAll(RegExp(r'[!?+#]+$'), '');
    if (san.isEmpty || san == 'e.p.' || san == 'ep') return san.isNotEmpty;

    final RegExpMatch? uci = RegExp(
      r'^([a-h][1-8])[-x]?([a-h][1-8])(?:=?([qrbnQRBN]))?$',
    ).firstMatch(san);
    if (uci != null) {
      return _apply(uci.group(1)!, uci.group(2)!, uci.group(3));
    }

    final String castle = san.replaceAll('0', 'O');
    if (castle == 'O-O' || castle == 'O-O-O') {
      final String rank = whiteToMove ? '1' : '8';
      final bool kingSide = castle == 'O-O';
      return _apply(
        'e$rank',
        '${kingSide ? 'g' : 'c'}$rank',
        null,
        castle: true,
      );
    }

    final RegExpMatch? match = RegExp(
      r'^([KQRBN])?([a-h])?([1-8])?x?([a-h][1-8])(?:=?([QRBN]))?$',
    ).firstMatch(san);
    if (match == null) return false;
    final String pieceType = match.group(1) ?? 'P';
    final String? fileHint = match.group(2);
    final String? rankHint = match.group(3);
    final String target = match.group(4)!;
    final bool white = whiteToMove;
    final List<String> candidates = pieces.entries
        .where((MapEntry<String, String> entry) {
          final String piece = entry.value;
          return _isWhite(piece) == white &&
              piece.toUpperCase() == pieceType &&
              (fileHint == null || entry.key[0] == fileHint) &&
              (rankHint == null || entry.key[1] == rankHint) &&
              _canMove(entry.key, target, piece, san.contains('x'));
        })
        .map((MapEntry<String, String> entry) => entry.key)
        .toList(growable: false);
    if (candidates.length != 1) return false;
    return _apply(candidates.single, target, match.group(5));
  }

  bool _canMove(String from, String to, String piece, bool capture) {
    final String? target = pieces[to];
    if (target != null && _isWhite(target) == _isWhite(piece)) return false;
    final int ff = from.codeUnitAt(0) - 97;
    final int fr = int.parse(from[1]);
    final int tf = to.codeUnitAt(0) - 97;
    final int tr = int.parse(to[1]);
    final int df = tf - ff;
    final int dr = tr - fr;
    switch (piece.toUpperCase()) {
      case 'P':
        final int direction = _isWhite(piece) ? 1 : -1;
        if (capture) {
          return df.abs() == 1 &&
              dr == direction &&
              (target != null || enPassant == to);
        }
        if (df != 0 || target != null) return false;
        if (dr == direction) return true;
        final int start = _isWhite(piece) ? 2 : 7;
        return fr == start &&
            dr == direction * 2 &&
            !pieces.containsKey(_square(ff, fr + direction));
      case 'N':
        return (df.abs() == 1 && dr.abs() == 2) ||
            (df.abs() == 2 && dr.abs() == 1);
      case 'B':
        return df.abs() == dr.abs() && _rayClear(ff, fr, tf, tr);
      case 'R':
        return (df == 0 || dr == 0) && _rayClear(ff, fr, tf, tr);
      case 'Q':
        return (df == 0 || dr == 0 || df.abs() == dr.abs()) &&
            _rayClear(ff, fr, tf, tr);
      case 'K':
        return df.abs() <= 1 && dr.abs() <= 1;
    }
    return false;
  }

  bool _canCastle(String from, String to, String piece) {
    if (piece.toUpperCase() != 'K') return false;
    final bool white = _isWhite(piece);
    final String rank = white ? '1' : '8';
    if (from != 'e$rank' || (to != 'g$rank' && to != 'c$rank')) return false;
    final bool kingSide = to[0] == 'g';
    final String right = white
        ? (kingSide ? 'K' : 'Q')
        : (kingSide ? 'k' : 'q');
    if (!castling.contains(right)) return false;
    final List<String> clear = kingSide
        ? <String>['f$rank', 'g$rank']
        : <String>['b$rank', 'c$rank', 'd$rank'];
    return clear.every((square) => !pieces.containsKey(square));
  }

  bool _rayClear(int ff, int fr, int tf, int tr) {
    final int fileStep = (tf - ff).sign;
    final int rankStep = (tr - fr).sign;
    int file = ff + fileStep;
    int rank = fr + rankStep;
    while (file != tf || rank != tr) {
      if (pieces.containsKey(_square(file, rank))) return false;
      file += fileStep;
      rank += rankStep;
    }
    return true;
  }

  bool _apply(
    String from,
    String to,
    String? promotion, {
    bool castle = false,
  }) {
    String? piece = pieces[from];
    if (piece == null || _isWhite(piece) != whiteToMove) return false;
    final bool pawnMove = piece.toUpperCase() == 'P';
    final bool enPassantCapture =
        pawnMove && from[0] != to[0] && !pieces.containsKey(to);
    final bool capture = pieces.containsKey(to) || enPassantCapture;

    pieces.remove(from);
    pieces.remove(to);
    if (enPassantCapture) pieces.remove('${to[0]}${from[1]}');
    if (castle ||
        (piece.toUpperCase() == 'K' &&
            (from.codeUnitAt(0) - to.codeUnitAt(0)).abs() == 2)) {
      final bool kingSide = to[0] == 'g';
      final String rookFrom = '${kingSide ? 'h' : 'a'}${from[1]}';
      final String rookTo = '${kingSide ? 'f' : 'd'}${from[1]}';
      final String? rook = pieces.remove(rookFrom);
      if (rook != null) pieces[rookTo] = rook;
    }
    if (promotion != null && promotion.isNotEmpty) {
      piece = _isWhite(piece)
          ? promotion.toUpperCase()
          : promotion.toLowerCase();
    }
    pieces[to] = piece;

    _updateCastling(from, to, piece);
    final int rankDelta = int.parse(to[1]) - int.parse(from[1]);
    enPassant = pawnMove && rankDelta.abs() == 2
        ? '${from[0]}${(int.parse(from[1]) + int.parse(to[1])) ~/ 2}'
        : null;
    halfmove = pawnMove || capture ? 0 : halfmove + 1;
    if (!whiteToMove) fullmove++;
    whiteToMove = !whiteToMove;
    return true;
  }

  void _updateCastling(String from, String to, String movedPiece) {
    if (movedPiece.toUpperCase() == 'K') {
      castling = castling.replaceAll(
        _isWhite(movedPiece) ? RegExp(r'[KQ]') : RegExp(r'[kq]'),
        '',
      );
    }
    const Map<String, String> rookRights = <String, String>{
      'a1': 'Q',
      'h1': 'K',
      'a8': 'q',
      'h8': 'k',
    };
    for (final String square in <String>[from, to]) {
      final String? right = rookRights[square];
      if (right != null) castling = castling.replaceAll(right, '');
    }
  }

  static bool _isWhite(String piece) => piece == piece.toUpperCase();
  static String _square(int file, int rank) =>
      '${String.fromCharCode(97 + file)}$rank';
}
