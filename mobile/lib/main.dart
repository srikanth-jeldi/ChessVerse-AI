import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const ChessVerseApp());
}

class ChessVerseApp extends StatelessWidget {
  const ChessVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChessVerse AI',
      debugShowCheckedModeBanner: false,
      theme: ChessVerseTheme.dark(),
      home: const GameScreen(),
    );
  }
}

class ChessVerseTheme {
  static ThemeData dark() {
    const ink = Color(0xFF101014);
    const brass = Color(0xFFD6A84F);
    const mint = Color(0xFF63D2B8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: brass,
        secondary: mint,
        surface: Color(0xFF1A1B20),
        onSurface: Color(0xFFF6F1E8),
      ),
      scaffoldBackgroundColor: ink,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Color(0xFFF6F1E8),
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: Color(0xFFF6F1E8),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFE6D8BC),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFC8C1B6),
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brass,
          foregroundColor: ink,
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF6F1E8),
          side: const BorderSide(color: Color(0xFF61553F)),
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFFF6F1E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

enum BoardSkin { royalWalnut, jadeGlass, tournament }

class BoardPalette {
  const BoardPalette({
    required this.label,
    required this.light,
    required this.dark,
    required this.frame,
    required this.accent,
  });

  final String label;
  final Color light;
  final Color dark;
  final Color frame;
  final Color accent;
}

const Map<BoardSkin, BoardPalette> boardPalettes = <BoardSkin, BoardPalette>{
  BoardSkin.royalWalnut: BoardPalette(
    label: 'Walnut',
    light: Color(0xFFE9D5B7),
    dark: Color(0xFF7A4F2A),
    frame: Color(0xFF342113),
    accent: Color(0xFFD6A84F),
  ),
  BoardSkin.jadeGlass: BoardPalette(
    label: 'Jade',
    light: Color(0xFFD8EEE1),
    dark: Color(0xFF2F7D66),
    frame: Color(0xFF12372E),
    accent: Color(0xFF63D2B8),
  ),
  BoardSkin.tournament: BoardPalette(
    label: 'Classic',
    light: Color(0xFFF0D9B5),
    dark: Color(0xFFB58863),
    frame: Color(0xFF30251E),
    accent: Color(0xFFE2B458),
  ),
};

class ChessPiece {
  const ChessPiece(this.code, this.white);

  final String code;
  final bool white;
}

class GameSnapshot {
  const GameSnapshot({
    required this.pieces,
    required this.moves,
    required this.capturedWhite,
    required this.capturedBlack,
    required this.coachNote,
    required this.lastFromSquare,
    required this.lastToSquare,
    required this.lastCaptureSquare,
    required this.whiteSeconds,
    required this.blackSeconds,
  });

  final Map<String, ChessPiece> pieces;
  final List<String> moves;
  final List<ChessPiece> capturedWhite;
  final List<ChessPiece> capturedBlack;
  final String coachNote;
  final String? lastFromSquare;
  final String? lastToSquare;
  final String? lastCaptureSquare;
  final int whiteSeconds;
  final int blackSeconds;
}

class ParsedMove {
  const ParsedMove(this.from, this.to);

  final String from;
  final String to;
}

class SquarePosition {
  const SquarePosition(this.file, this.rank);

  final int file;
  final int rank;
}

class ChessRules {
  static SquarePosition positionOf(String square) {
    return SquarePosition(square.codeUnitAt(0) - 97, int.parse(square[1]));
  }

  static String squareOf(int file, int rank) {
    return '${String.fromCharCode(97 + file)}$rank';
  }

  static bool isInside(int file, int rank) {
    return file >= 0 && file < 8 && rank >= 1 && rank <= 8;
  }

  static List<String> legalTargets(
    String from,
    Map<String, ChessPiece> pieces,
  ) {
    return pseudoLegalTargets(from, pieces);
  }

  static List<String> safeLegalTargets(
    String from,
    Map<String, ChessPiece> pieces,
  ) {
    final ChessPiece? piece = pieces[from];
    if (piece == null) {
      return <String>[];
    }

    return pseudoLegalTargets(from, pieces).where((String target) {
      final Map<String, ChessPiece> next = applyMove(from, target, pieces);
      return !isKingInCheck(piece.white, next);
    }).toList();
  }

  static List<String> pseudoLegalTargets(
    String from,
    Map<String, ChessPiece> pieces,
  ) {
    final ChessPiece? piece = pieces[from];
    if (piece == null) {
      return <String>[];
    }

    return switch (piece.code) {
      'P' => _pawnTargets(from, piece, pieces),
      'N' => _jumpTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 2),
          SquarePosition(2, 1),
          SquarePosition(2, -1),
          SquarePosition(1, -2),
          SquarePosition(-1, -2),
          SquarePosition(-2, -1),
          SquarePosition(-2, 1),
          SquarePosition(-1, 2),
        ]),
      'B' => _rayTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 1),
          SquarePosition(1, -1),
          SquarePosition(-1, 1),
          SquarePosition(-1, -1),
        ]),
      'R' => _rayTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 0),
          SquarePosition(-1, 0),
          SquarePosition(0, 1),
          SquarePosition(0, -1),
        ]),
      'Q' => _rayTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 0),
          SquarePosition(-1, 0),
          SquarePosition(0, 1),
          SquarePosition(0, -1),
          SquarePosition(1, 1),
          SquarePosition(1, -1),
          SquarePosition(-1, 1),
          SquarePosition(-1, -1),
        ]),
      'K' => _jumpTargets(from, piece, pieces, const <SquarePosition>[
          SquarePosition(1, 0),
          SquarePosition(-1, 0),
          SquarePosition(0, 1),
          SquarePosition(0, -1),
          SquarePosition(1, 1),
          SquarePosition(1, -1),
          SquarePosition(-1, 1),
          SquarePosition(-1, -1),
        ]),
      _ => <String>[],
    };
  }

  static bool hasAnySafeMove(bool white, Map<String, ChessPiece> pieces) {
    for (final MapEntry<String, ChessPiece> entry in pieces.entries) {
      if (entry.value.white == white &&
          safeLegalTargets(entry.key, pieces).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static bool isKingInCheck(bool white, Map<String, ChessPiece> pieces) {
    String? kingSquare;
    for (final MapEntry<String, ChessPiece> entry in pieces.entries) {
      if (entry.value.white == white && entry.value.code == 'K') {
        kingSquare = entry.key;
        break;
      }
    }
    if (kingSquare == null) {
      return false;
    }

    for (final MapEntry<String, ChessPiece> entry in pieces.entries) {
      if (entry.value.white != white &&
          attacksSquare(entry.key, kingSquare, pieces)) {
        return true;
      }
    }
    return false;
  }

  static bool attacksSquare(
    String from,
    String target,
    Map<String, ChessPiece> pieces,
  ) {
    final ChessPiece? piece = pieces[from];
    if (piece == null) {
      return false;
    }

    if (piece.code == 'P') {
      final SquarePosition origin = positionOf(from);
      final SquarePosition attacked = positionOf(target);
      final int direction = piece.white ? 1 : -1;
      return attacked.rank == origin.rank + direction &&
          (attacked.file - origin.file).abs() == 1;
    }

    return pseudoLegalTargets(from, pieces).contains(target);
  }

  static Map<String, ChessPiece> applyMove(
    String from,
    String target,
    Map<String, ChessPiece> pieces,
  ) {
    final Map<String, ChessPiece> next = Map<String, ChessPiece>.from(pieces);
    final ChessPiece? piece = next.remove(from);
    if (piece != null) {
      next[target] = piece;
    }
    return next;
  }

  static List<String> _pawnTargets(
    String from,
    ChessPiece piece,
    Map<String, ChessPiece> pieces,
  ) {
    final SquarePosition origin = positionOf(from);
    final int direction = piece.white ? 1 : -1;
    final int startRank = piece.white ? 2 : 7;
    final List<String> targets = <String>[];
    final int oneRank = origin.rank + direction;

    if (isInside(origin.file, oneRank)) {
      final String oneStep = squareOf(origin.file, oneRank);
      if (!pieces.containsKey(oneStep)) {
        targets.add(oneStep);

        final int twoRank = origin.rank + direction * 2;
        final String twoStep = squareOf(origin.file, twoRank);
        if (origin.rank == startRank &&
            isInside(origin.file, twoRank) &&
            !pieces.containsKey(twoStep)) {
          targets.add(twoStep);
        }
      }
    }

    for (final int fileDelta in <int>[-1, 1]) {
      final int targetFile = origin.file + fileDelta;
      final int targetRank = origin.rank + direction;
      if (!isInside(targetFile, targetRank)) {
        continue;
      }
      final String target = squareOf(targetFile, targetRank);
      final ChessPiece? occupant = pieces[target];
      if (occupant != null && occupant.white != piece.white) {
        targets.add(target);
      }
    }

    return targets;
  }

  static List<String> _jumpTargets(
    String from,
    ChessPiece piece,
    Map<String, ChessPiece> pieces,
    List<SquarePosition> deltas,
  ) {
    final SquarePosition origin = positionOf(from);
    final List<String> targets = <String>[];

    for (final SquarePosition delta in deltas) {
      final int file = origin.file + delta.file;
      final int rank = origin.rank + delta.rank;
      if (!isInside(file, rank)) {
        continue;
      }
      final String target = squareOf(file, rank);
      final ChessPiece? occupant = pieces[target];
      if (occupant == null || occupant.white != piece.white) {
        targets.add(target);
      }
    }

    return targets;
  }

  static List<String> _rayTargets(
    String from,
    ChessPiece piece,
    Map<String, ChessPiece> pieces,
    List<SquarePosition> directions,
  ) {
    final SquarePosition origin = positionOf(from);
    final List<String> targets = <String>[];

    for (final SquarePosition direction in directions) {
      int file = origin.file + direction.file;
      int rank = origin.rank + direction.rank;

      while (isInside(file, rank)) {
        final String target = squareOf(file, rank);
        final ChessPiece? occupant = pieces[target];
        if (occupant == null) {
          targets.add(target);
        } else {
          if (occupant.white != piece.white) {
            targets.add(target);
          }
          break;
        }
        file += direction.file;
        rank += direction.rank;
      }
    }

    return targets;
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<String> _moves = <String>[];
  final List<ChessPiece> _capturedWhite = <ChessPiece>[];
  final List<ChessPiece> _capturedBlack = <ChessPiece>[];
  final List<GameSnapshot> _history = <GameSnapshot>[];
  Timer? _clockTimer;
  String? _selectedSquare;
  String? _lastFromSquare;
  String? _lastToSquare;
  String? _lastCaptureSquare;
  String _coachNote = 'Select a coin to see legal moves.';
  BoardSkin _skin = BoardSkin.royalWalnut;
  double _aiLevel = 4;
  bool _coachEnabled = true;
  int _whiteSeconds = 10 * 60;
  int _blackSeconds = 10 * 60;

  static const Map<String, ChessPiece> _initialPieces = <String, ChessPiece>{
    'a8': ChessPiece('R', false),
    'b8': ChessPiece('N', false),
    'c8': ChessPiece('B', false),
    'd8': ChessPiece('Q', false),
    'e8': ChessPiece('K', false),
    'f8': ChessPiece('B', false),
    'g8': ChessPiece('N', false),
    'h8': ChessPiece('R', false),
    'a7': ChessPiece('P', false),
    'b7': ChessPiece('P', false),
    'c7': ChessPiece('P', false),
    'd7': ChessPiece('P', false),
    'e7': ChessPiece('P', false),
    'f7': ChessPiece('P', false),
    'g7': ChessPiece('P', false),
    'h7': ChessPiece('P', false),
    'a2': ChessPiece('P', true),
    'b2': ChessPiece('P', true),
    'c2': ChessPiece('P', true),
    'd2': ChessPiece('P', true),
    'e2': ChessPiece('P', true),
    'f2': ChessPiece('P', true),
    'g2': ChessPiece('P', true),
    'h2': ChessPiece('P', true),
    'a1': ChessPiece('R', true),
    'b1': ChessPiece('N', true),
    'c1': ChessPiece('B', true),
    'd1': ChessPiece('Q', true),
    'e1': ChessPiece('K', true),
    'f1': ChessPiece('B', true),
    'g1': ChessPiece('N', true),
    'h1': ChessPiece('R', true),
  };

  late Map<String, ChessPiece> _pieces =
      Map<String, ChessPiece>.from(_initialPieces);

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _moves.isEmpty) {
        return;
      }
      setState(() {
        if (_moves.length.isEven) {
          _whiteSeconds = math.max(0, _whiteSeconds - 1);
        } else {
          _blackSeconds = math.max(0, _blackSeconds - 1);
        }
        if (_whiteSeconds == 0 || _blackSeconds == 0) {
          _coachNote = _whiteSeconds == 0
              ? 'White clock expired. Black wins on time.'
              : 'Black clock expired. White wins on time.';
        }
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BoardPalette palette = boardPalettes[_skin]!;
    final Set<String> legalTargets = _selectedSquare == null
        ? <String>{}
        : _legalTargetsFor(_selectedSquare!).toSet();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF111014),
              Color(0xFF21170F),
              Color(0xFF101A17),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool wide = constraints.maxWidth >= 980;
              final EdgeInsets pagePadding = EdgeInsets.symmetric(
                horizontal: wide ? 28 : 16,
                vertical: wide ? 20 : 12,
              );

              final Widget board = ChessBoard(
                pieces: _pieces,
                selectedSquare: _selectedSquare,
                legalTargets: legalTargets,
                lastFromSquare: _lastFromSquare,
                lastToSquare: _lastToSquare,
                lastCaptureSquare: _lastCaptureSquare,
                palette: palette,
                onSquareTap: _handleSquareTap,
              );

              final Widget panel = GamePanel(
                activeColor: _moves.length.isEven ? 'White' : 'Black',
                aiLevel: _aiLevel.round(),
                coachEnabled: _coachEnabled,
                moves: _moves,
                capturedWhite: _capturedWhite,
                capturedBlack: _capturedBlack,
                coachNote: _coachNote,
                whiteClock: _formatClock(_whiteSeconds),
                blackClock: _formatClock(_blackSeconds),
                skin: _skin,
                onSkinChanged: (BoardSkin skin) => setState(() => _skin = skin),
                onAiLevelChanged: (double level) {
                  setState(() => _aiLevel = level);
                },
                onCoachChanged: (bool value) {
                  setState(() => _coachEnabled = value);
                },
                onReset: _reset,
                onUndo: _undo,
                onHint: _showHint,
                onAnalyze: _showAnalysis,
                canUndo: _history.isNotEmpty,
              );

              return Padding(
                padding: pagePadding,
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            child: BoardStage(
                              palette: palette,
                              moveCount: _moves.length,
                              whiteClock: _formatClock(_whiteSeconds),
                              blackClock: _formatClock(_blackSeconds),
                              child: board,
                            ),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(width: 380, child: panel),
                        ],
                      )
                    : Column(
                        children: <Widget>[
                          CompactHeader(onReset: _reset),
                          const SizedBox(height: 12),
                          Expanded(
                            flex: 5,
                            child: BoardStage(
                              palette: palette,
                              moveCount: _moves.length,
                              whiteClock: _formatClock(_whiteSeconds),
                              blackClock: _formatClock(_blackSeconds),
                              child: board,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(flex: 4, child: panel),
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleSquareTap(String square) {
    String? promotionSquare;
    bool? promotionWhite;

    setState(() {
      final bool whitesTurn = _moves.length.isEven;
      if (_selectedSquare == null) {
        final ChessPiece? piece = _pieces[square];
        if (piece == null) {
          _coachNote = 'Choose one of your coins first.';
          return;
        }
        if (piece.white != whitesTurn) {
          _coachNote = '${whitesTurn ? 'White' : 'Black'} to move.';
          return;
        }
        final List<String> targets = _legalTargetsFor(square);
        if (targets.isEmpty) {
          _coachNote = '${piece.code} has no legal target from $square.';
        } else {
          _selectedSquare = square;
          final String suffix = targets.length == 1 ? '' : 's';
          _coachNote =
              '${piece.code} from $square has ${targets.length} option$suffix.';
        }
        return;
      }

      if (_selectedSquare == square) {
        _selectedSquare = null;
        return;
      }

      final List<String> legalTargets =
          _legalTargetsFor(_selectedSquare!);
      if (!legalTargets.contains(square)) {
        _coachNote = 'That move is blocked. Pick a highlighted square.';
        _selectedSquare = null;
        return;
      }

      final String from = _selectedSquare!;
      _saveSnapshot();
      _lastFromSquare = from;
      _lastToSquare = square;
      _lastCaptureSquare = null;
      final bool castleMove = _isCastleMove(from, square);
      final String? enPassantCaptureSquare =
          _enPassantCaptureSquare(from, square);
      final ChessPiece? piece = _pieces.remove(from);
      if (piece != null) {
        final ChessPiece? captured = enPassantCaptureSquare == null
            ? _pieces[square]
            : _pieces.remove(enPassantCaptureSquare);
        if (captured != null) {
          if (captured.white) {
            _capturedWhite.add(captured);
          } else {
            _capturedBlack.add(captured);
          }
          _lastCaptureSquare = square;
        }
        _pieces[square] = piece;
        if (castleMove) {
          _moveCastlingRook(square, piece.white);
        }
        final String move = castleMove
            ? (square.startsWith('g') ? 'O-O' : 'O-O-O')
            : enPassantCaptureSquare != null
                ? '$from x $square e.p.'
                : captured == null
                    ? '$from$square'
                    : '$from x $square';
        _moves.insert(0, move);
        _coachNote = castleMove
            ? '${piece.white ? 'White' : 'Black'} castles ${square.startsWith('g') ? 'king side' : 'queen side'}.'
            : captured == null
                ? '${piece.code} moves to $square.'
                : '${piece.code} captures ${captured.code} on $square.';
        if (piece.code == 'P' &&
            ((piece.white && square.endsWith('8')) ||
                (!piece.white && square.endsWith('1')))) {
          promotionSquare = square;
          promotionWhite = piece.white;
          _coachNote = 'Choose a promotion coin for $square.';
        } else {
          _coachNote = _gameStateNote(!piece.white, fallback: _coachNote);
        }
      }
      _selectedSquare = null;
    });

    if (promotionSquare != null && promotionWhite != null) {
      _showPromotionPicker(promotionSquare!, promotionWhite!);
    }
  }

  List<String> _legalTargetsFor(String square) {
    final ChessPiece? piece = _pieces[square];
    if (piece == null) {
      return <String>[];
    }

    final Set<String> targets =
        ChessRules.safeLegalTargets(square, _pieces).toSet();
    targets.addAll(_castlingTargets(square, piece));
    targets.addAll(_enPassantTargets(square, piece));
    return targets.toList();
  }

  List<String> _castlingTargets(String from, ChessPiece piece) {
    if (piece.code != 'K' || _hasMovedFrom(from)) {
      return <String>[];
    }

    final String rank = piece.white ? '1' : '8';
    if (from != 'e$rank' || ChessRules.isKingInCheck(piece.white, _pieces)) {
      return <String>[];
    }

    final List<String> targets = <String>[];
    if (_canCastle(
      white: piece.white,
      rookFrom: 'h$rank',
      emptySquares: <String>['f$rank', 'g$rank'],
      kingPath: <String>['f$rank', 'g$rank'],
    )) {
      targets.add('g$rank');
    }
    if (_canCastle(
      white: piece.white,
      rookFrom: 'a$rank',
      emptySquares: <String>['b$rank', 'c$rank', 'd$rank'],
      kingPath: <String>['d$rank', 'c$rank'],
    )) {
      targets.add('c$rank');
    }

    return targets;
  }

  bool _canCastle({
    required bool white,
    required String rookFrom,
    required List<String> emptySquares,
    required List<String> kingPath,
  }) {
    final ChessPiece? rook = _pieces[rookFrom];
    if (rook == null ||
        rook.code != 'R' ||
        rook.white != white ||
        _hasMovedFrom(rookFrom)) {
      return false;
    }

    for (final String square in emptySquares) {
      if (_pieces.containsKey(square)) {
        return false;
      }
    }

    for (final String square in kingPath) {
      final Map<String, ChessPiece> next =
          ChessRules.applyMove(white ? 'e1' : 'e8', square, _pieces);
      if (ChessRules.isKingInCheck(white, next)) {
        return false;
      }
    }
    return true;
  }

  List<String> _enPassantTargets(String from, ChessPiece piece) {
    if (piece.code != 'P' || _moves.isEmpty) {
      return <String>[];
    }

    final ParsedMove? lastMove = _parseMove(_moves.first);
    if (lastMove == null) {
      return <String>[];
    }

    final ChessPiece? movedPiece = _pieces[lastMove.to];
    if (movedPiece == null ||
        movedPiece.code != 'P' ||
        movedPiece.white == piece.white) {
      return <String>[];
    }

    final SquarePosition fromPosition = ChessRules.positionOf(lastMove.from);
    final SquarePosition toPosition = ChessRules.positionOf(lastMove.to);
    if ((fromPosition.rank - toPosition.rank).abs() != 2) {
      return <String>[];
    }

    final SquarePosition pawnPosition = ChessRules.positionOf(from);
    final int requiredRank = piece.white ? 5 : 4;
    if (pawnPosition.rank != requiredRank ||
        (pawnPosition.file - toPosition.file).abs() != 1 ||
        pawnPosition.rank != toPosition.rank) {
      return <String>[];
    }

    final String target = ChessRules.squareOf(
      toPosition.file,
      pawnPosition.rank + (piece.white ? 1 : -1),
    );
    final Map<String, ChessPiece> next = Map<String, ChessPiece>.from(_pieces)
      ..remove(from)
      ..remove(lastMove.to);
    next[target] = piece;

    return ChessRules.isKingInCheck(piece.white, next)
        ? <String>[]
        : <String>[target];
  }

  bool _isCastleMove(String from, String to) {
    final ChessPiece? piece = _pieces[from];
    return piece != null &&
        piece.code == 'K' &&
        from.startsWith('e') &&
        (to.startsWith('g') || to.startsWith('c'));
  }

  void _moveCastlingRook(String kingTarget, bool white) {
    final String rank = white ? '1' : '8';
    if (kingTarget == 'g$rank') {
      final ChessPiece? rook = _pieces.remove('h$rank');
      if (rook != null) {
        _pieces['f$rank'] = rook;
      }
    } else if (kingTarget == 'c$rank') {
      final ChessPiece? rook = _pieces.remove('a$rank');
      if (rook != null) {
        _pieces['d$rank'] = rook;
      }
    }
  }

  String? _enPassantCaptureSquare(String from, String to) {
    final ChessPiece? piece = _pieces[from];
    if (piece == null || piece.code != 'P' || _pieces.containsKey(to)) {
      return null;
    }

    final SquarePosition fromPosition = ChessRules.positionOf(from);
    final SquarePosition toPosition = ChessRules.positionOf(to);
    if ((fromPosition.file - toPosition.file).abs() != 1) {
      return null;
    }

    final String captureSquare =
        ChessRules.squareOf(toPosition.file, fromPosition.rank);
    final ChessPiece? captured = _pieces[captureSquare];
    if (captured == null ||
        captured.code != 'P' ||
        captured.white == piece.white) {
      return null;
    }
    return captureSquare;
  }

  bool _hasMovedFrom(String square) {
    for (final String move in _moves) {
      final ParsedMove? parsed = _parseMove(move);
      if (parsed?.from == square) {
        return true;
      }
    }
    return false;
  }

  ParsedMove? _parseMove(String move) {
    if (move.startsWith('O-O')) {
      return null;
    }

    final String cleaned = move
        .replaceAll(' x ', '')
        .replaceAll(' e.p.', '')
        .split('=')
        .first;
    if (cleaned.length < 4) {
      return null;
    }
    return ParsedMove(cleaned.substring(0, 2), cleaned.substring(2, 4));
  }

  void _reset() {
    setState(() {
      _pieces = Map<String, ChessPiece>.from(_initialPieces);
      _moves.clear();
      _capturedWhite.clear();
      _capturedBlack.clear();
      _history.clear();
      _lastFromSquare = null;
      _lastToSquare = null;
      _lastCaptureSquare = null;
      _whiteSeconds = 10 * 60;
      _blackSeconds = 10 * 60;
      _selectedSquare = null;
      _coachNote = 'Select a coin to see legal moves.';
    });
  }

  void _saveSnapshot() {
    _history.add(
      GameSnapshot(
        pieces: Map<String, ChessPiece>.from(_pieces),
        moves: List<String>.from(_moves),
        capturedWhite: List<ChessPiece>.from(_capturedWhite),
        capturedBlack: List<ChessPiece>.from(_capturedBlack),
        coachNote: _coachNote,
        lastFromSquare: _lastFromSquare,
        lastToSquare: _lastToSquare,
        lastCaptureSquare: _lastCaptureSquare,
        whiteSeconds: _whiteSeconds,
        blackSeconds: _blackSeconds,
      ),
    );
    if (_history.length > 80) {
      _history.removeAt(0);
    }
  }

  void _undo() {
    if (_history.isEmpty) {
      return;
    }

    setState(() {
      final GameSnapshot snapshot = _history.removeLast();
      _pieces = Map<String, ChessPiece>.from(snapshot.pieces);
      _moves
        ..clear()
        ..addAll(snapshot.moves);
      _capturedWhite
        ..clear()
        ..addAll(snapshot.capturedWhite);
      _capturedBlack
        ..clear()
        ..addAll(snapshot.capturedBlack);
      _lastFromSquare = snapshot.lastFromSquare;
      _lastToSquare = snapshot.lastToSquare;
      _lastCaptureSquare = snapshot.lastCaptureSquare;
      _whiteSeconds = snapshot.whiteSeconds;
      _blackSeconds = snapshot.blackSeconds;
      _selectedSquare = null;
      _coachNote = 'Move undone. ${snapshot.coachNote}';
    });
  }

  void _showHint() {
    final bool whiteToMove = _moves.length.isEven;
    String? bestFrom;
    List<String> bestTargets = <String>[];

    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.white != whiteToMove) {
        continue;
      }
      final List<String> targets = _legalTargetsFor(entry.key);
      if (targets.length > bestTargets.length) {
        bestFrom = entry.key;
        bestTargets = targets;
      }
    }

    setState(() {
      _selectedSquare = bestFrom;
      if (bestFrom == null) {
        _coachNote = 'No legal moves found.';
      } else {
        _coachNote =
            'Coach hint: inspect $bestFrom. It has ${bestTargets.length} promising squares.';
      }
    });
  }

  void _showAnalysis() {
    final bool whiteToMove = _moves.length.isEven;
    int legalMoveCount = 0;
    int captureCount = 0;

    for (final MapEntry<String, ChessPiece> entry in _pieces.entries) {
      if (entry.value.white != whiteToMove) {
        continue;
      }
      for (final String target in _legalTargetsFor(entry.key)) {
        legalMoveCount++;
        if (_pieces[target] != null) {
          captureCount++;
        }
      }
    }

    setState(() {
      _coachNote =
          'AI analysis: ${whiteToMove ? 'White' : 'Black'} has $legalMoveCount legal moves and $captureCount capture threat${captureCount == 1 ? '' : 's'}.';
    });
  }

  Future<void> _showPromotionPicker(String square, bool white) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191A1F),
          title: const Text('Promote pawn'),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <String>['Q', 'R', 'B', 'N'].map((String code) {
              return PromotionChoice(
                piece: ChessPiece(code, white),
                onSelected: () {
                  setState(() {
                    _pieces[square] = ChessPiece(code, white);
                    _moves[0] = '${_moves.first}=$code';
                    _coachNote = _gameStateNote(
                      !white,
                      fallback: 'Pawn promoted to $code on $square.',
                    );
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _gameStateNote(bool sideToMoveWhite, {required String fallback}) {
    final bool inCheck = ChessRules.isKingInCheck(sideToMoveWhite, _pieces);
    final bool hasMove = ChessRules.hasAnySafeMove(sideToMoveWhite, _pieces);
    final String side = sideToMoveWhite ? 'White' : 'Black';

    if (inCheck && !hasMove) {
      return 'Checkmate. ${sideToMoveWhite ? 'Black' : 'White'} wins.';
    }
    if (!inCheck && !hasMove) {
      return 'Stalemate. No legal move for $side.';
    }
    if (inCheck) {
      return '$side is in check.';
    }
    return fallback;
  }

  String _formatClock(int seconds) {
    final int safeSeconds = math.max(0, seconds);
    final int minutes = safeSeconds ~/ 60;
    final int remainder = safeSeconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}

class CompactHeader extends StatelessWidget {
  const CompactHeader({required this.onReset, super.key});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.bolt_rounded, color: Color(0xFFD6A84F)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'ChessVerse AI',
            style: Theme.of(context).textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Reset board',
          onPressed: onReset,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class BoardStage extends StatelessWidget {
  const BoardStage({
    required this.palette,
    required this.moveCount,
    required this.whiteClock,
    required this.blackClock,
    required this.child,
    super.key,
  });

  final BoardPalette palette;
  final int moveCount;
  final String whiteClock;
  final String blackClock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (MediaQuery.sizeOf(context).width >= 980) ...<Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.bolt_rounded, color: Color(0xFFD6A84F)),
              const SizedBox(width: 10),
              Text('ChessVerse AI',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              MatchClock(label: 'White', value: whiteClock),
              const SizedBox(width: 8),
              MatchClock(label: 'Black', value: blackClock),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.frame,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.5),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.38),
                      blurRadius: 32,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: child,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            StatusPill(icon: Icons.shield_rounded, label: palette.label),
            const SizedBox(width: 8),
            StatusPill(icon: Icons.timeline_rounded, label: '$moveCount moves'),
          ],
        ),
      ],
    );
  }
}

class ChessBoard extends StatelessWidget {
  const ChessBoard({
    required this.pieces,
    required this.selectedSquare,
    required this.legalTargets,
    required this.lastFromSquare,
    required this.lastToSquare,
    required this.lastCaptureSquare,
    required this.palette,
    required this.onSquareTap,
    super.key,
  });

  final Map<String, ChessPiece> pieces;
  final String? selectedSquare;
  final Set<String> legalTargets;
  final String? lastFromSquare;
  final String? lastToSquare;
  final String? lastCaptureSquare;
  final BoardPalette palette;
  final ValueChanged<String> onSquareTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: <Widget>[
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemCount: 64,
              itemBuilder: (BuildContext context, int index) {
                final int row = index ~/ 8;
                final int col = index % 8;
                final String square =
                    '${String.fromCharCode(97 + col)}${8 - row}';
                final bool dark = (row + col).isOdd;
                final bool selected = square == selectedSquare;
                final ChessPiece? piece = pieces[square];
                final bool legalTarget = legalTargets.contains(square);
                final bool captureTarget =
                    legalTarget && piece != null && square != selectedSquare;
                final bool lastMoveSquare =
                    square == lastFromSquare || square == lastToSquare;
                final bool lastCapture = square == lastCaptureSquare;

                return BoardSquare(
                  square: square,
                  dark: dark,
                  selected: selected,
                  legalTarget: legalTarget,
                  captureTarget: captureTarget,
                  lastMoveSquare: lastMoveSquare,
                  lastCapture: lastCapture,
                  palette: palette,
                  piece: piece,
                  showRank: col == 0,
                  showFile: row == 7,
                  onTap: () => onSquareTap(square),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BoardSquare extends StatelessWidget {
  const BoardSquare({
    required this.square,
    required this.dark,
    required this.selected,
    required this.legalTarget,
    required this.captureTarget,
    required this.lastMoveSquare,
    required this.lastCapture,
    required this.palette,
    required this.showRank,
    required this.showFile,
    required this.onTap,
    this.piece,
    super.key,
  });

  final String square;
  final bool dark;
  final bool selected;
  final bool legalTarget;
  final bool captureTarget;
  final bool lastMoveSquare;
  final bool lastCapture;
  final BoardPalette palette;
  final bool showRank;
  final bool showFile;
  final VoidCallback onTap;
  final ChessPiece? piece;

  @override
  Widget build(BuildContext context) {
    final Color base = dark ? palette.dark : palette.light;
    final Color coordinateColor =
        dark
            ? palette.light.withValues(alpha: 0.72)
            : palette.dark.withValues(alpha: 0.72);

    final Color squareColor = lastCapture
        ? Color.alphaBlend(const Color(0xFFE11D48).withValues(alpha: 0.62), base)
        : selected
            ? Color.alphaBlend(palette.accent.withValues(alpha: 0.55), base)
            : lastMoveSquare
                ? Color.alphaBlend(
                    const Color(0xFFFFFFFF).withValues(alpha: 0.26),
                    base,
                  )
                : base;

    return InkWell(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0,
          end: selected || legalTarget || lastCapture ? 1 : 0,
        ),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double glow, Widget? child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: squareColor,
              border: selected
                  ? Border.all(color: const Color(0xFFF8E7B0), width: 3)
                  : null,
              boxShadow: <BoxShadow>[
                if (legalTarget)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.42 * glow),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                if (lastCapture || captureTarget)
                  BoxShadow(
                    color: const Color(0xFFFF1744)
                        .withValues(alpha: 0.55 * glow),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
              ],
            ),
            child: child,
          );
        },
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 5,
              left: 6,
              child: Text(
                showRank ? square.substring(1) : '',
                style: TextStyle(
                  color: coordinateColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 4,
              child: Text(
                showFile ? square.substring(0, 1) : '',
                style: TextStyle(
                  color: coordinateColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutBack,
                scale: legalTarget && piece == null ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.82),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.85),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const SizedBox(width: 20, height: 20),
                ),
              ),
            ),
            if (captureTarget)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFF1744),
                        width: 4,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFFFF1744)
                              .withValues(alpha: 0.72),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: Tween<double>(begin: 0.82, end: 1).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: piece == null
                    ? const SizedBox.shrink()
                    : ChessCoin(
                        key: ValueKey<String>(
                          '$square-${piece!.white}-${piece!.code}',
                        ),
                        piece: piece!,
                        selected: selected,
                        accent: palette.accent,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChessCoin extends StatelessWidget {
  const ChessCoin({
    required this.piece,
    required this.selected,
    required this.accent,
    super.key,
  });

  final ChessPiece piece;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double size =
            math.min(constraints.maxWidth, constraints.maxHeight);
        final double coinSize = size * 0.76;
        final Color face =
            piece.white ? const Color(0xFFF9F0DB) : const Color(0xFF202126);
        final Color rim =
            piece.white ? const Color(0xFFB78B3F) : const Color(0xFF5D6470);
        final Color text =
            piece.white ? const Color(0xFF2B2012) : const Color(0xFFF3E3BD);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: coinSize,
          height: coinSize,
          transform: Matrix4.identity()
            ..scaleByDouble(
              selected ? 1.08 : 1.0,
              selected ? 1.08 : 1.0,
              1,
              1,
            ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.45),
              radius: 0.92,
              colors: <Color>[
                piece.white ? Colors.white : const Color(0xFF3A3B42),
                face,
              ],
            ),
            border: Border.all(color: selected ? accent : rim, width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: accent.withValues(alpha: selected ? 0.35 : 0.08),
                blurRadius: selected ? 18 : 6,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(painter: CoinRingPainter(color: rim)),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    pieceGlyph(piece),
                    style: TextStyle(
                      color: text,
                      fontSize: coinSize * 0.42,
                      fontWeight: FontWeight.w900,
                      height: 0.86,
                      shadows: <Shadow>[
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    pieceName(piece.code),
                    style: TextStyle(
                      color: text.withValues(alpha: 0.78),
                      fontSize: coinSize * 0.12,
                      fontWeight: FontWeight.w900,
                      height: 0.9,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

String pieceGlyph(ChessPiece piece) {
  if (piece.white) {
    return switch (piece.code) {
      'K' => '\u2654',
      'Q' => '\u2655',
      'R' => '\u2656',
      'B' => '\u2657',
      'N' => '\u2658',
      _ => '\u2659',
    };
  }
  return switch (piece.code) {
    'K' => '\u265A',
    'Q' => '\u265B',
    'R' => '\u265C',
    'B' => '\u265D',
    'N' => '\u265E',
    _ => '\u265F',
  };
}

String pieceName(String code) {
  return switch (code) {
    'K' => 'KING',
    'Q' => 'QUEEN',
    'R' => 'ROOK',
    'B' => 'BISHOP',
    'N' => 'KNIGHT',
    _ => 'PAWN',
  };
}

class CoinRingPainter extends CustomPainter {
  const CoinRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.shortestSide / 2;
    final Paint ring = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, radius * 0.08);
    canvas.drawCircle(center, radius * 0.68, ring);

    final Paint tick = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = math.max(1, radius * 0.035)
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 18; i++) {
      final double angle = i * math.pi / 9;
      final Offset start = Offset(
        center.dx + math.cos(angle) * radius * 0.82,
        center.dy + math.sin(angle) * radius * 0.82,
      );
      final Offset end = Offset(
        center.dx + math.cos(angle) * radius * 0.9,
        center.dy + math.sin(angle) * radius * 0.9,
      );
      canvas.drawLine(start, end, tick);
    }
  }

  @override
  bool shouldRepaint(CoinRingPainter oldDelegate) => oldDelegate.color != color;
}

class PromotionChoice extends StatelessWidget {
  const PromotionChoice({
    required this.piece,
    required this.onSelected,
    super.key,
  });

  final ChessPiece piece;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: FilledButton(
        onPressed: onSelected,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: const Color(0xFF242128),
          foregroundColor: const Color(0xFFF6F1E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 48,
              height: 48,
              child: ChessCoin(
                piece: piece,
                selected: false,
                accent: const Color(0xFFD6A84F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              piece.code,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    required this.activeColor,
    required this.aiLevel,
    required this.coachEnabled,
    required this.moves,
    required this.capturedWhite,
    required this.capturedBlack,
    required this.coachNote,
    required this.whiteClock,
    required this.blackClock,
    required this.skin,
    required this.onSkinChanged,
    required this.onAiLevelChanged,
    required this.onCoachChanged,
    required this.onReset,
    required this.onUndo,
    required this.onHint,
    required this.onAnalyze,
    required this.canUndo,
    super.key,
  });

  final String activeColor;
  final int aiLevel;
  final bool coachEnabled;
  final List<String> moves;
  final List<ChessPiece> capturedWhite;
  final List<ChessPiece> capturedBlack;
  final String coachNote;
  final String whiteClock;
  final String blackClock;
  final BoardSkin skin;
  final ValueChanged<BoardSkin> onSkinChanged;
  final ValueChanged<double> onAiLevelChanged;
  final ValueChanged<bool> onCoachChanged;
  final VoidCallback onReset;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onAnalyze;
  final bool canUndo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool scrollPanel = constraints.maxHeight < 620;
        final Widget history = moves.isEmpty
            ? const EmptyMoveState()
            : ListView.separated(
                itemCount: moves.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    dense: true,
                    minLeadingWidth: 32,
                    leading: Text('${moves.length - index}.'),
                    title: Text(moves[index]),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  );
                },
              );

        final List<Widget> controls = <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'AI Arena',
                  style: Theme.of(context).textTheme.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Reset board',
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Undo move',
                onPressed: canUndo ? onUndo : null,
                icon: const Icon(Icons.undo_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatusPill(
                icon: Icons.auto_awesome_rounded,
                label: coachEnabled ? 'Coach on' : 'Coach off',
              ),
              StatusPill(icon: Icons.speed_rounded, label: 'Level $aiLevel'),
              StatusPill(icon: Icons.memory_rounded, label: activeColor),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(child: MatchClock(label: 'White', value: whiteClock)),
              const SizedBox(width: 10),
              Expanded(child: MatchClock(label: 'Black', value: blackClock)),
            ],
          ),
          const SizedBox(height: 18),
          CoachInsight(note: coachNote, enabled: coachEnabled),
          const SizedBox(height: 18),
          CapturedMaterial(
            capturedWhite: capturedWhite,
            capturedBlack: capturedBlack,
          ),
          const SizedBox(height: 18),
          Text('Board', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<BoardSkin>(
            segments: boardPalettes.entries
                .map(
                  (MapEntry<BoardSkin, BoardPalette> entry) =>
                      ButtonSegment<BoardSkin>(
                    value: entry.key,
                    label: Text(entry.value.label),
                  ),
                )
                .toList(),
            selected: <BoardSkin>{skin},
            onSelectionChanged: (Set<BoardSkin> selected) {
              onSkinChanged(selected.first);
            },
            style: ButtonStyle(
              shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('AI strength', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: aiLevel.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$aiLevel',
            onChanged: onAiLevelChanged,
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: coachEnabled,
              onChanged: onCoachChanged,
              title: const Text('AI coach'),
              secondary: const Icon(Icons.psychology_alt_rounded),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                  child: FilledButton.icon(
                    onPressed: onHint,
                    icon: const Icon(Icons.psychology_alt_rounded),
                    label: const Text('Hint'),
                  ),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAnalyze,
                    icon: const Icon(Icons.analytics_rounded),
                    label: const Text('Analyze'),
                  ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Move history', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
        ];

        final Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...controls,
            if (scrollPanel)
              SizedBox(height: 220, child: history)
            else
              Expanded(child: history),
          ],
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF191A1F).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A3124)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: scrollPanel
                ? SingleChildScrollView(child: content)
                : content,
          ),
        );
      },
    );
  }
}

class EmptyMoveState extends StatelessWidget {
  const EmptyMoveState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF242128),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3B352D)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Select a coin, then choose its target square.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class CoachInsight extends StatelessWidget {
  const CoachInsight({required this.note, required this.enabled, super.key});

  final String note;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF242128) : const Color(0xFF17171B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? const Color(0xFF6C5530) : const Color(0xFF323238),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              enabled
                  ? Icons.psychology_alt_rounded
                  : Icons.visibility_off_rounded,
              color: const Color(0xFFD6A84F),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                enabled ? note : 'AI coach is paused.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CapturedMaterial extends StatelessWidget {
  const CapturedMaterial({
    required this.capturedWhite,
    required this.capturedBlack,
    super.key,
  });

  final List<ChessPiece> capturedWhite;
  final List<ChessPiece> capturedBlack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Captured', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: CaptureRow(label: 'White', pieces: capturedWhite),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CaptureRow(label: 'Black', pieces: capturedBlack),
            ),
          ],
        ),
      ],
    );
  }
}

class CaptureRow extends StatelessWidget {
  const CaptureRow({required this.label, required this.pieces, super.key});

  final String label;
  final List<ChessPiece> pieces;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF202127),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B352D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: pieces.isEmpty
                  ? <Widget>[
                      const Text(
                        '-',
                        style: TextStyle(color: Color(0xFF9B948A)),
                      ),
                    ]
                  : pieces
                      .map(
                        (ChessPiece piece) => MiniCapturedPiece(piece: piece),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniCapturedPiece extends StatelessWidget {
  const MiniCapturedPiece({required this.piece, super.key});

  final ChessPiece piece;

  @override
  Widget build(BuildContext context) {
    final Color face =
        piece.white ? const Color(0xFFF9F0DB) : const Color(0xFF202126);
    final Color text =
        piece.white ? const Color(0xFF2B2012) : const Color(0xFFF3E3BD);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: face,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD6A84F)),
      ),
      child: SizedBox(
        width: 26,
        height: 26,
        child: Center(
          child: Text(
            piece.code,
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class MatchClock extends StatelessWidget {
  const MatchClock({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1C20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3124)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF242128),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B352D)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: const Color(0xFFD6A84F)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF6F1E8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
