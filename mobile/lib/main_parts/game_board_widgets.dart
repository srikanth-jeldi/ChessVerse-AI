part of '../main.dart';

class CompactHeader extends StatelessWidget {
  const CompactHeader({
    required this.onHome,
    required this.onProfile,
    required this.onReset,
    required this.onLogout,
    this.onPause,
    super.key,
  });

  final VoidCallback onHome;
  final VoidCallback onProfile;
  final VoidCallback onReset;
  final VoidCallback onLogout;
  final VoidCallback? onPause;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          key: const ValueKey<String>('mobile-back-to-home'),
          tooltip: 'Back to Home',
          onPressed: onHome,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const ChessVerseMark(size: 36),
        if (onPause != null)
          IconButton(
            key: const ValueKey('pause-computer-game'),
            tooltip: 'Pause and save',
            onPressed: onPause,
            icon: const Icon(Icons.pause_circle_outline),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            const TextSpan(
              children: <InlineSpan>[
                TextSpan(text: 'ChessVerse'),
                TextSpan(
                  text: 'AI',
                  style: TextStyle(color: Color(0xFFEABF61)),
                ),
              ],
            ),
            semanticsLabel: 'ChessVerseAI',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Profile',
          onPressed: onProfile,
          icon: const Icon(Icons.person_rounded),
        ),
        IconButton(
          tooltip: 'Reset board',
          onPressed: onReset,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}

class ChessVerseMark extends StatelessWidget {
  const ChessVerseMark({this.size = 38, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/branding/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'ChessVerseAI logo',
      ),
    );
  }
}

class BoardStage extends StatelessWidget {
  const BoardStage({required this.palette, required this.child, super.key});

  final BoardPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.62),
            blurRadius: 38,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.24),
            blurRadius: 26,
            spreadRadius: -4,
            offset: const Offset(-5, -7),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(
                Colors.white.withValues(alpha: 0.22),
                palette.frame,
              ),
              Color.alphaBlend(
                palette.accent.withValues(alpha: 0.18),
                palette.frame,
              ),
              Color.alphaBlend(
                Colors.black.withValues(alpha: 0.42),
                palette.frame,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1.4,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: palette.accent.withValues(alpha: 0.55),
                width: 2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(padding: const EdgeInsets.all(1), child: child),
          ),
        ),
      ),
    );
  }
}

class ReviewedPositionRetryDialog extends StatefulWidget {
  const ReviewedPositionRetryDialog({
    required this.fen,
    required this.initialPieces,
    required this.whiteToMove,
    required this.bestMove,
    required this.explanation,
    this.progressLabel = 'RETRY THIS POSITION',
    this.nextLabel = 'Back to review',
    this.languageCode = 'en',
    this.onNext,
    super.key,
  });

  final String fen;
  final Map<String, ChessPiece> initialPieces;
  final bool whiteToMove;
  final String bestMove;
  final String explanation;
  final String progressLabel;
  final String nextLabel;
  final String languageCode;
  final VoidCallback? onNext;

  @override
  State<ReviewedPositionRetryDialog> createState() =>
      _ReviewedPositionRetryDialogState();
}

class _ReviewedPositionRetryDialogState
    extends State<ReviewedPositionRetryDialog> {
  late Map<String, ChessPiece> _pieces;
  String? _selected;
  String? _lastFrom;
  String? _lastTo;
  String? _message;
  bool _answered = false;
  bool _correct = false;
  int _hintStage = 0;

  CoachLocalizations get _copy => CoachLocalizations(widget.languageCode);

  String _capturedPieces(bool white) {
    const Map<String, int> starting = <String, int>{
      'Q': 1,
      'R': 2,
      'B': 2,
      'N': 2,
      'P': 8,
    };
    const Map<String, String> whiteGlyphs = <String, String>{
      'Q': '♕',
      'R': '♖',
      'B': '♗',
      'N': '♘',
      'P': '♙',
    };
    const Map<String, String> blackGlyphs = <String, String>{
      'Q': '♛',
      'R': '♜',
      'B': '♝',
      'N': '♞',
      'P': '♟',
    };
    final StringBuffer missing = StringBuffer();
    for (final MapEntry<String, int> entry in starting.entries) {
      final int present = widget.initialPieces.values
          .where(
            (ChessPiece piece) =>
                piece.white == white && piece.code == entry.key,
          )
          .length;
      for (int count = present; count < entry.value; count++) {
        missing.write((white ? whiteGlyphs : blackGlyphs)[entry.key]);
      }
    }
    return missing.toString();
  }

  @override
  void initState() {
    super.initState();
    _pieces = Map<String, ChessPiece>.from(widget.initialPieces);
  }

  Set<String> get _legalTargets {
    final String? selected = _selected;
    if (selected == null || _answered) return <String>{};
    final Set<String> targets = ChessRules.safeLegalTargets(
      selected,
      _pieces,
    ).toSet();
    if (widget.bestMove.startsWith(selected) && widget.bestMove.length >= 4) {
      final String target = widget.bestMove.substring(2, 4);
      if (_isLegalFenSpecialMove(selected, target)) targets.add(target);
    }
    return targets;
  }

  bool _isLegalFenSpecialMove(String from, String target) {
    final List<String> parts = widget.fen.split(RegExp(r'\s+'));
    final ChessPiece? piece = _pieces[from];
    if (piece == null) return false;
    if (piece.code == 'P' && parts.length > 3 && parts[3] == target) {
      final SquarePosition a = ChessRules.positionOf(from);
      final SquarePosition b = ChessRules.positionOf(target);
      final String captured = ChessRules.squareOf(b.file, a.rank);
      return (b.file - a.file).abs() == 1 &&
          b.rank - a.rank == (piece.white ? 1 : -1) &&
          !_pieces.containsKey(target) &&
          _pieces[captured]?.code == 'P' &&
          _pieces[captured]?.white != piece.white;
    }
    if (piece.code != 'K' || parts.length < 3) return false;
    final bool kingSide = target == (piece.white ? 'g1' : 'g8');
    final bool queenSide = target == (piece.white ? 'c1' : 'c8');
    if (!kingSide && !queenSide) return false;
    final String right = piece.white
        ? (kingSide ? 'K' : 'Q')
        : (kingSide ? 'k' : 'q');
    if (!parts[2].contains(right) ||
        ChessRules.isKingInCheck(piece.white, _pieces)) {
      return false;
    }
    final int rank = piece.white ? 1 : 8;
    final List<String> empty = kingSide
        ? <String>['f$rank', 'g$rank']
        : <String>['b$rank', 'c$rank', 'd$rank'];
    if (empty.any(_pieces.containsKey)) return false;
    final String transit = kingSide ? 'f$rank' : 'd$rank';
    final String rookSquare = kingSide ? 'h$rank' : 'a$rank';
    if (_pieces[rookSquare]?.code != 'R' ||
        _pieces[rookSquare]?.white != piece.white) {
      return false;
    }
    final Map<String, ChessPiece> transitBoard = ChessRules.applyMove(
      from,
      transit,
      _pieces,
    );
    if (ChessRules.isKingInCheck(piece.white, transitBoard)) return false;
    final Map<String, ChessPiece> destinationBoard = ChessRules.applyMove(
      transit,
      target,
      transitBoard,
    );
    return !ChessRules.isKingInCheck(piece.white, destinationBoard);
  }

  Map<String, ChessPiece> _applyReviewedMove(String from, String target) {
    final ChessPiece? piece = _pieces[from];
    final List<String> parts = widget.fen.split(RegExp(r'\s+'));
    final Map<String, ChessPiece> next = Map<String, ChessPiece>.from(_pieces);
    if (piece?.code == 'P' &&
        parts.length > 3 &&
        parts[3] == target &&
        !next.containsKey(target)) {
      final SquarePosition a = ChessRules.positionOf(from);
      final SquarePosition b = ChessRules.positionOf(target);
      next.remove(ChessRules.squareOf(b.file, a.rank));
    }
    next.remove(from);
    if (piece != null) {
      final bool promotion =
          piece.code == 'P' && (target.endsWith('8') || target.endsWith('1'));
      final String promoted = widget.bestMove.length >= 5
          ? widget.bestMove[4].toUpperCase()
          : 'Q';
      next[target] = promotion ? ChessPiece(promoted, piece.white) : piece;
      if (piece.code == 'K' &&
          (from.codeUnitAt(0) - target.codeUnitAt(0)).abs() == 2) {
        final int rank = piece.white ? 1 : 8;
        final bool kingSide = target.startsWith('g');
        final String rookFrom = kingSide ? 'h$rank' : 'a$rank';
        final String rookTo = kingSide ? 'f$rank' : 'd$rank';
        final ChessPiece? rook = next.remove(rookFrom);
        if (rook != null) next[rookTo] = rook;
      }
    }
    return next;
  }

  void _tapSquare(String square) {
    if (_answered) return;
    final ChessPiece? tapped = _pieces[square];
    if (_selected == null) {
      if (tapped?.white == widget.whiteToMove) {
        setState(() => _selected = square);
      }
      return;
    }
    final String from = _selected!;
    if (tapped?.white == widget.whiteToMove) {
      setState(() => _selected = square);
      return;
    }
    if (!_legalTargets.contains(square)) return;
    final String attempted = '$from$square'.toLowerCase();
    final bool correct = widget.bestMove.toLowerCase().startsWith(attempted);
    final int nextHintStage = correct
        ? _hintStage
        : (_hintStage + 1).clamp(1, 3);
    setState(() {
      // A wrong attempt and the correct solution belong to two different
      // positions. Restore the reviewed snapshot before drawing the solution
      // arrow; otherwise the arrow is painted over a board that already
      // contains the user's incorrect move and appears displaced.
      _pieces = correct
          ? _applyReviewedMove(from, square)
          : Map<String, ChessPiece>.from(widget.initialPieces);
      _lastFrom = correct ? from : null;
      _lastTo = correct ? square : null;
      _selected = null;
      _answered = true;
      _correct = correct;
      _hintStage = nextHintStage;
      _message = correct
          ? '${_copy.text('bestFound')} ${localizeLiveCoach(localizeReviewNarrative(widget.explanation, widget.languageCode), widget.languageCode)}'
          : '${_copy.text('goodTry')} ${_retryHintText(nextHintStage)}';
    });
  }

  String _retryHintText(int stage) {
    final String from = widget.bestMove.substring(0, 2);
    final String to = widget.bestMove.substring(2, 4);
    final ChessPiece? piece = widget.initialPieces[from];
    final String name = switch (piece?.code) {
      'K' => 'king',
      'Q' => 'queen',
      'R' => 'rook',
      'B' => 'bishop',
      'N' => 'knight',
      _ => 'pawn',
    };
    return switch (stage) {
      1 => 'Hint 1/3: Look for the strongest move with your $name.',
      2 => 'Hint 2/3: Start calculating from $from.',
      _ =>
        'Hint 3/3: Try $from → $to. ${localizeLiveCoach(localizeReviewNarrative(widget.explanation, widget.languageCode), widget.languageCode)}',
    };
  }

  void _showRetryHint() {
    final int next = (_hintStage + 1).clamp(1, 3);
    setState(() {
      _hintStage = next;
      _answered = false;
      _correct = false;
      _pieces = Map<String, ChessPiece>.from(widget.initialPieces);
      _selected = next >= 2 ? widget.bestMove.substring(0, 2) : null;
      _lastFrom = null;
      _lastTo = null;
      _message = _retryHintText(next);
    });
  }

  void _reset() {
    setState(() {
      _pieces = Map<String, ChessPiece>.from(widget.initialPieces);
      _selected = null;
      _lastFrom = null;
      _lastTo = null;
      _message = null;
      _answered = false;
      _correct = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final BoardPalette palette = boardPalettes[BoardSkin.sapphire]!;
    final bool inCheck = ChessRules.isKingInCheck(widget.whiteToMove, _pieces);
    final String? checkedKing = inCheck
        ? ChessRules.kingSquare(widget.whiteToMove, _pieces)
        : null;
    return Dialog(
      backgroundColor: const Color(0xFF061722),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 850),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.replay_circle_filled_rounded,
                    color: Color(0xFF59E4C8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.progressLabel.startsWith('POSITION BEFORE MOVE ')
                          ? _copy.text('positionBefore', {
                              'move': widget.progressLabel.substring(
                                'POSITION BEFORE MOVE '.length,
                              ),
                            })
                          : widget.progressLabel == 'RETRY THIS POSITION'
                          ? _copy.text('retry')
                          : widget.progressLabel,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                _copy.text('findContinuation', {
                  'side': _copy.text(widget.whiteToMove ? 'white' : 'black'),
                }),
                style: const TextStyle(color: Color(0xFF9DB0BE)),
              ),
              const SizedBox(height: 6),
              Builder(
                builder: (BuildContext context) {
                  final String whiteCaptured = _capturedPieces(true);
                  final String blackCaptured = _capturedPieces(false);
                  return Text(
                    _copy.language != 'en'
                        ? '${_copy.text('restored')} · ${_copy.text('white')}: −${whiteCaptured.isEmpty ? '0' : whiteCaptured} · ${_copy.text('black')}: −${blackCaptured.isEmpty ? '0' : blackCaptured}'
                        : whiteCaptured.isEmpty && blackCaptured.isEmpty
                        ? 'Starting position restored • All pieces on board'
                        : 'Exact game snapshot restored • Missing White: ${whiteCaptured.isEmpty ? '—' : whiteCaptured}  Black: ${blackCaptured.isEmpty ? '—' : blackCaptured}',
                    style: const TextStyle(
                      color: Color(0xFF63D2B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              AspectRatio(
                aspectRatio: 1,
                child: ChessBoard(
                  pieces: _pieces,
                  selectedSquare: _selected,
                  legalTargets: _legalTargets,
                  lastFromSquare: _lastFrom,
                  lastToSquare: _lastTo,
                  lastCaptureSquare: null,
                  moveSequence: _answered ? 1 : 0,
                  checkedKingSquare: checkedKing,
                  decisiveSquare: null,
                  coachArrowFrom: _hintStage >= 3 && !_correct
                      ? widget.bestMove.substring(0, 2)
                      : null,
                  coachArrowTo: _hintStage >= 3 && !_correct
                      ? widget.bestMove.substring(2, 4)
                      : null,
                  idleHintFrom: null,
                  idleHintTo: null,
                  flipped: !widget.whiteToMove,
                  showCoordinates: true,
                  palette: palette,
                  onSquareTap: _tapSquare,
                ),
              ),
              if (_message != null) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2734),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF59E4C8)),
                  ),
                  child: Text(_message!, style: const TextStyle(height: 1.4)),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(_copy.text('retry')),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey<String>('position-retry-hint'),
                    onPressed: _hintStage < 3 ? _showRetryHint : null,
                    icon: const Icon(Icons.lightbulb_rounded),
                    label: Text('Hint ${(_hintStage + 1).clamp(1, 3)}/3'),
                  ),
                  FilledButton(
                    onPressed:
                        widget.onNext ?? () => Navigator.of(context).pop(),
                    child: Text(
                      widget.nextLabel == 'Back to review'
                          ? _copy.text('back')
                          : widget.nextLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChessBoard extends StatefulWidget {
  const ChessBoard({
    required this.pieces,
    required this.selectedSquare,
    required this.legalTargets,
    required this.lastFromSquare,
    required this.lastToSquare,
    required this.lastCaptureSquare,
    this.lastMovedPiece,
    this.lastCapturedPiece,
    required this.moveSequence,
    required this.checkedKingSquare,
    required this.decisiveSquare,
    this.fallenKingSquare,
    this.fallenKingWhite,
    required this.coachArrowFrom,
    required this.coachArrowTo,
    this.idleHintFrom,
    this.idleHintTo,
    required this.flipped,
    required this.showCoordinates,
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
  final ChessPiece? lastMovedPiece;
  final ChessPiece? lastCapturedPiece;
  final int moveSequence;
  final String? checkedKingSquare;
  final String? decisiveSquare;
  final String? fallenKingSquare;
  final bool? fallenKingWhite;
  final String? coachArrowFrom;
  final String? coachArrowTo;
  final String? idleHintFrom;
  final String? idleHintTo;
  final bool flipped;
  final bool showCoordinates;
  final BoardPalette palette;
  final ValueChanged<String> onSquareTap;

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  Timer? _animationTimer;
  String? _activeMoveToken;

  String? _moveToken(ChessBoard board) {
    final ChessPiece? moved = board.lastMovedPiece;
    if (board.lastFromSquare == null ||
        board.lastToSquare == null ||
        moved == null) {
      return null;
    }
    final ChessPiece? captured = board.lastCapturedPiece;
    return '${board.moveSequence}:${board.lastFromSquare}:'
        '${board.lastToSquare}:${moved.white}:${moved.code}:'
        '${captured?.white}:${captured?.code}';
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _activeMoveToken = null;
  }

  void _startAnimation(String token) {
    _animationTimer?.cancel();
    setState(() => _activeMoveToken = token);
    _animationTimer = Timer(
      Duration(milliseconds: widget.lastCapturedPiece == null ? 400 : 520),
      () {
        if (!mounted || _activeMoveToken != token) {
          return;
        }
        setState(() => _activeMoveToken = null);
      },
    );
  }

  @override
  void didUpdateWidget(covariant ChessBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? oldToken = _moveToken(oldWidget);
    final String? newToken = _moveToken(widget);
    if (newToken == null) {
      _stopAnimation();
    } else if (newToken != oldToken) {
      _startAnimation(newToken);
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, ChessPiece> pieces = widget.pieces;
    final String? selectedSquare = widget.selectedSquare;
    final Set<String> legalTargets = widget.legalTargets;
    final String? lastFromSquare = widget.lastFromSquare;
    final String? lastToSquare = widget.lastToSquare;
    final String? lastCaptureSquare = widget.lastCaptureSquare;
    final ChessPiece? lastMovedPiece = widget.lastMovedPiece;
    final ChessPiece? lastCapturedPiece = widget.lastCapturedPiece;
    final int moveSequence = widget.moveSequence;
    final String? checkedKingSquare = widget.checkedKingSquare;
    final String? decisiveSquare = widget.decisiveSquare;
    final bool flipped = widget.flipped;
    final bool showCoordinates = widget.showCoordinates;
    final BoardPalette palette = widget.palette;
    final ValueChanged<String> onSquareTap = widget.onSquareTap;
    final bool moveAnimating =
        _activeMoveToken != null && _activeMoveToken == _moveToken(widget);

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
                final int file = flipped ? 7 - col : col;
                final int rank = flipped ? row + 1 : 8 - row;
                final String square = '${String.fromCharCode(97 + file)}$rank';
                final bool dark = (row + col).isOdd;
                final bool selected = square == selectedSquare;
                final bool kingFallen = square == widget.fallenKingSquare;
                // A checkmating move must leave the losing king visible.  Do
                // not let the short destination-piece animation hide it, and
                // recover gracefully from older saved positions that removed
                // the king instead of ending on checkmate.
                final ChessPiece? boardPiece = pieces[square];
                final ChessPiece? piece = kingFallen
                    ? (boardPiece ??
                          ChessPiece('K', widget.fallenKingWhite ?? true))
                    : moveAnimating && square == lastToSquare
                    ? null
                    : boardPiece;
                final bool legalTarget = legalTargets.contains(square);
                final bool captureTarget =
                    legalTarget && piece != null && square != selectedSquare;
                final bool lastMoveSquare =
                    square == lastFromSquare || square == lastToSquare;
                final bool lastCapture = square == lastCaptureSquare;
                final bool checkedKing = square == checkedKingSquare;
                final bool decisiveMove = square == decisiveSquare;
                final bool idleHintSource = square == widget.idleHintFrom;
                final bool idleHintTarget = square == widget.idleHintTo;
                return BoardSquare(
                  key: ValueKey<String>('square-$square'),
                  square: square,
                  dark: dark,
                  selected: selected,
                  legalTarget: legalTarget,
                  captureTarget: captureTarget,
                  lastMoveSquare: lastMoveSquare,
                  lastCapture: lastCapture,
                  checkedKing: checkedKing,
                  decisiveMove: decisiveMove,
                  idleHintSource: idleHintSource,
                  idleHintTarget: idleHintTarget,
                  kingFallen: kingFallen,
                  palette: palette,
                  premiumTexture: premiumBoardAsset(palette.label) != null,
                  piece: piece,
                  showRank: showCoordinates && col == 0,
                  showFile: showCoordinates && row == 7,
                  onTap: () => onSquareTap(square),
                );
              },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.2,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.10),
                        blurRadius: 18,
                        spreadRadius: -6,
                        offset: const Offset(-8, -8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        spreadRadius: -6,
                        offset: const Offset(8, 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (lastFromSquare != null &&
                lastToSquare != null &&
                (widget.coachArrowFrom == null || widget.coachArrowTo == null))
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<String>(
                      'move-trail-$lastFromSquare-$lastToSquare-$flipped',
                    ),
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 560),
                    curve: Curves.easeOutCubic,
                    builder:
                        (BuildContext context, double progress, Widget? child) {
                          return CustomPaint(
                            painter: LastMoveTrailPainter(
                              from: lastFromSquare,
                              to: lastToSquare,
                              flipped: flipped,
                              progress: progress,
                              accent: palette.accent,
                              // Keep the latest move visible until the next move.
                              // The old fade made the arrow look like a brief flash.
                              fadeOut: false,
                            ),
                          );
                        },
                  ),
                ),
              ),
            if (widget.coachArrowFrom != null && widget.coachArrowTo != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: LastMoveTrailPainter(
                      from: widget.coachArrowFrom!,
                      to: widget.coachArrowTo!,
                      flipped: flipped,
                      progress: 1,
                      accent: const Color(0xFF57E0C3),
                      fadeOut: false,
                    ),
                  ),
                ),
              ),
            if (moveAnimating &&
                lastFromSquare != null &&
                lastToSquare != null &&
                lastMovedPiece != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: MoveAndCaptureOverlay(
                    key: ValueKey<String>(
                      'move-overlay-$lastFromSquare-$lastToSquare-'
                      '${lastMovedPiece.white}-${lastMovedPiece.code}-'
                      '${lastCapturedPiece?.code}-$moveSequence',
                    ),
                    from: lastFromSquare,
                    to: lastToSquare,
                    flipped: flipped,
                    movedPiece: lastMovedPiece,
                    capturedPiece: lastCapturedPiece,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LastMoveTrailPainter extends CustomPainter {
  const LastMoveTrailPainter({
    required this.from,
    required this.to,
    required this.flipped,
    required this.progress,
    required this.accent,
    this.fadeOut = false,
  });

  final String from;
  final String to;
  final bool flipped;
  final double progress;
  final Color accent;
  final bool fadeOut;

  Offset _center(String square, Size size) {
    final int file = square.codeUnitAt(0) - 97;
    final int rank = int.parse(square.substring(1));
    final int col = flipped ? 7 - file : file;
    final int row = flipped ? rank - 1 : 8 - rank;
    final double cell = size.shortestSide / 8;
    return Offset((col + 0.5) * cell, (row + 0.5) * cell);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double drawProgress = fadeOut
        ? (progress / 0.68).clamp(0.0, 1.0)
        : progress.clamp(0.0, 1.0);
    final double opacity = fadeOut && progress > 0.68
        ? ((1 - progress) / 0.32).clamp(0.0, 1.0)
        : 1;
    if (opacity <= 0) return;

    final Offset start = _center(from, size);
    final Offset target = _center(to, size);
    final Offset end = Offset.lerp(start, target, drawProgress)!;
    final double cell = size.shortestSide / 8;
    final Offset delta = end - start;
    final double distance = delta.distance;
    if (distance < 1) {
      return;
    }

    final Offset direction = delta / distance;
    final double pieceClearance = cell * 0.27;
    final Offset visualStart = start + direction * pieceClearance;
    final Offset visualEnd = end - direction * pieceClearance;
    if ((visualEnd - visualStart).distance < cell * 0.18) {
      return;
    }
    final Offset mid = Offset.lerp(visualStart, visualEnd, 0.5)!;
    final double bend = math.min(cell * 0.22, distance * 0.12);
    final Offset normal = Offset(-direction.dy, direction.dx);
    final Offset control = mid + normal * bend;
    final Path trail = Path()
      ..moveTo(visualStart.dx, visualStart.dy)
      ..quadraticBezierTo(control.dx, control.dy, visualEnd.dx, visualEnd.dy);
    final Paint glow = Paint()
      ..color = accent.withValues(alpha: 0.34 * opacity)
      ..strokeWidth = cell * 0.19
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final Paint shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.32 * opacity)
      ..strokeWidth = cell * 0.14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final Paint line = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: 0.82 * opacity),
          accent.withValues(alpha: 0.9 * opacity),
          Colors.white.withValues(alpha: 0.7 * opacity),
        ],
      ).createShader(Rect.fromPoints(visualStart, visualEnd))
      ..strokeWidth = cell * 0.075
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(trail, shadow);
    canvas.drawPath(trail, glow);
    canvas.drawPath(trail, line);
    canvas.drawCircle(
      start,
      cell * 0.11 * drawProgress,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.045
        ..shader = line.shader,
    );
    canvas.drawCircle(
      target,
      cell * 0.24 * progress,
      Paint()
        ..color = accent.withValues(alpha: 0.12 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(LastMoveTrailPainter oldDelegate) {
    return oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.flipped != flipped ||
        oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.fadeOut != fadeOut;
  }
}

class MoveAndCaptureOverlay extends StatelessWidget {
  const MoveAndCaptureOverlay({
    required this.from,
    required this.to,
    required this.flipped,
    required this.movedPiece,
    this.capturedPiece,
    super.key,
  });

  final String from;
  final String to;
  final bool flipped;
  final ChessPiece movedPiece;
  final ChessPiece? capturedPiece;

  Offset _topLeft(String square, double cell) {
    final int file = square.codeUnitAt(0) - 97;
    final int rank = int.parse(square.substring(1));
    final int col = flipped ? 7 - file : file;
    final int row = flipped ? rank - 1 : 8 - rank;
    return Offset(col * cell, row * cell);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cell = constraints.maxWidth / 8;
        final Offset start = _topLeft(from, cell);
        final Offset target = _topLeft(to, cell);
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: capturedPiece == null ? 360 : 430),
          curve: Curves.easeInOutCubic,
          builder: (BuildContext context, double progress, Widget? child) {
            final Offset travel = Offset.lerp(start, target, progress)!;
            final double lift = -math.sin(math.pi * progress) * cell * 0.42;
            final double hitDirection = target.dx >= start.dx ? 1 : -1;
            // The victim stays at the target only until impact, then is
            // knocked away quickly instead of lingering over the new board.
            final double impactProgress = ((progress - 0.30) / 0.70).clamp(
              0.0,
              1.0,
            );
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  key: ValueKey<String>(
                    'moving-piece-${movedPiece.white}-${movedPiece.code}',
                  ),
                  left: travel.dx,
                  top: travel.dy + lift,
                  width: cell,
                  height: cell,
                  child: Transform.rotate(
                    angle: math.sin(math.pi * progress) * 0.12,
                    child: ChessCoin(
                      piece: movedPiece,
                      selected: false,
                      accent: const Color(0xFFFFD166),
                    ),
                  ),
                ),
                if (capturedPiece != null && impactProgress < 0.999)
                  Positioned(
                    key: ValueKey<String>(
                      'captured-piece-${capturedPiece!.white}-'
                      '${capturedPiece!.code}',
                    ),
                    left: target.dx,
                    top: target.dy,
                    width: cell,
                    height: cell,
                    child: Opacity(
                      opacity: (1 - impactProgress).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(
                          hitDirection * cell * 0.88 * impactProgress,
                          -math.sin(math.pi * impactProgress) * cell * 1.25 +
                              cell * 0.95 * impactProgress * impactProgress,
                        ),
                        child: Transform.rotate(
                          angle: hitDirection * impactProgress * math.pi * 1.65,
                          child: ChessCoin(
                            piece: capturedPiece!,
                            selected: false,
                            accent: const Color(0xFFFF3158),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
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
    required this.checkedKing,
    required this.decisiveMove,
    required this.idleHintSource,
    required this.idleHintTarget,
    this.kingFallen = false,
    required this.palette,
    required this.premiumTexture,
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
  final bool checkedKing;
  final bool decisiveMove;
  final bool idleHintSource;
  final bool idleHintTarget;
  final bool kingFallen;
  final BoardPalette palette;
  final bool premiumTexture;
  final bool showRank;
  final bool showFile;
  final VoidCallback onTap;
  final ChessPiece? piece;

  @override
  Widget build(BuildContext context) {
    final Color base = (dark ? palette.dark : palette.light).withValues(
      alpha: premiumTexture ? (dark ? .98 : .96) : 1,
    );
    final Color coordinateColor = dark
        ? palette.light.withValues(alpha: 0.72)
        : palette.dark.withValues(alpha: 0.72);

    final Color squareColor = checkedKing
        ? Color.alphaBlend(
            const Color(0xFFE11D48).withValues(alpha: 0.76),
            base,
          )
        : decisiveMove
        ? Color.alphaBlend(palette.accent.withValues(alpha: 0.62), base)
        : lastCapture
        ? Color.alphaBlend(
            const Color(0xFFE11D48).withValues(alpha: 0.62),
            base,
          )
        : selected
        ? Color.alphaBlend(palette.accent.withValues(alpha: 0.55), base)
        : lastMoveSquare
        ? Color.alphaBlend(
            const Color(0xFFFFFFFF).withValues(alpha: 0.26),
            base,
          )
        : base;

    final bool idleHint = idleHintSource || idleHintTarget;

    return InkWell(
      key: idleHintSource
          ? const ValueKey<String>('idle-hint-source')
          : idleHintTarget
          ? const ValueKey<String>('idle-hint-target')
          : null,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0,
          end:
              selected ||
                  legalTarget ||
                  lastCapture ||
                  checkedKing ||
                  decisiveMove ||
                  idleHint
              ? 1
              : 0,
        ),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double glow, Widget? child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: dark ? 0.10 : 0.22),
                    squareColor,
                  ),
                  squareColor,
                  Color.alphaBlend(
                    Colors.black.withValues(alpha: dark ? 0.18 : 0.08),
                    squareColor,
                  ),
                ],
                stops: const <double>[0, 0.48, 1],
              ),
              border: Border.all(
                color: idleHint
                    ? const Color(0xFF68C8FF)
                    : selected
                    ? const Color(0xFFF8E7B0)
                    : (dark ? Colors.black : Colors.white).withValues(
                        alpha: 0.08,
                      ),
                width: idleHint
                    ? 3.2
                    : selected
                    ? 3
                    : 1,
              ),
              boxShadow: <BoxShadow>[
                if (idleHint)
                  BoxShadow(
                    color: const Color(0xFF42B8FF)
                        .withValues(alpha: 0.9 * glow),
                    blurRadius: 26,
                    spreadRadius: 5,
                  ),
                if (legalTarget)
                  BoxShadow(
                    color: const Color(0xFFBDE6FF)
                        .withValues(alpha: 0.72 * glow),
                    blurRadius: 22,
                    spreadRadius: 4,
                  ),
                if (lastCapture || captureTarget)
                  BoxShadow(
                    color: const Color(0xFFFF1744)
                        .withValues(alpha: 0.55 * glow),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
                if (checkedKing)
                  BoxShadow(
                    color: const Color(0xFFFF1744)
                        .withValues(alpha: 0.9 * glow),
                    blurRadius: 28,
                    spreadRadius: 5,
                  ),
                if (decisiveMove)
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.8 * glow),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
              ],
            ),
            child: child,
          );
        },
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withValues(alpha: dark ? 0.045 : 0.09),
                        Colors.transparent,
                        Colors.black.withValues(alpha: dark ? 0.10 : 0.045),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
                    borderRadius: BorderRadius.circular(12),
                    gradient: RadialGradient(
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.92),
                        const Color(0xFFCBEAFF).withValues(alpha: 0.72),
                        const Color(0xFF6DBDFF).withValues(alpha: 0.28),
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF8EDBFF).withValues(alpha: 0.72),
                        blurRadius: 24,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.42),
                        blurRadius: 8,
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  child: const SizedBox(width: 28, height: 28),
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
            if (checkedKing)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFFD1D8),
                        width: 4,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.48),
                          blurRadius: 9,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Center(
              child: piece == null
                  ? const SizedBox.shrink()
                  : TweenAnimationBuilder<double>(
                      key: ValueKey<String>('king-fall-$square-$kingFallen'),
                      tween: Tween<double>(begin: 0, end: kingFallen ? 1 : 0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOutBack,
                      builder:
                          (BuildContext context, double fall, Widget? child) {
                            return Transform.translate(
                              offset: Offset(0, fall * 9),
                              child: Transform.rotate(
                                alignment: Alignment.bottomCenter,
                                angle:
                                    (piece!.white ? 1 : -1) *
                                    math.pi *
                                    .48 *
                                    fall,
                                child: child,
                              ),
                            );
                          },
                      child: ChessCoin(
                        key: ValueKey<String>(
                          '$square-${piece!.white}-${piece!.code}',
                        ),
                        piece: piece!,
                        selected: selected,
                        accent: palette.accent,
                      ),
                    ),
            ),
            if (lastCapture)
              Positioned.fill(
                child: IgnorePointer(
                  child: CaptureBurst(
                    key: ValueKey<String>(
                      'capture-burst-$square-${piece?.white}-${piece?.code}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CaptureBurst extends StatelessWidget {
  const CaptureBurst({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double progress, Widget? child) {
        return CustomPaint(painter: CaptureBurstPainter(progress));
      },
    );
  }
}

class CaptureBurstPainter extends CustomPainter {
  const CaptureBurstPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double extent = math.min(size.width, size.height);
    final double fade = (1 - progress).clamp(0, 1);
    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = extent * (0.08 - progress * 0.035)
      ..color = const Color(0xFFFFD166).withValues(alpha: fade * 0.95)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, extent * (0.12 + progress * 0.38), glow);

    final Paint slash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = extent * 0.07
      ..color = const Color(0xFFFF3158).withValues(alpha: fade * 0.9);
    final double slashLength = extent * (0.18 + progress * 0.34);
    canvas.drawLine(
      center + Offset(-slashLength, slashLength) * 0.55,
      center + Offset(slashLength, -slashLength) * 0.55,
      slash,
    );

    final Paint particle = Paint()
      ..color = const Color(0xFFFFE6A7).withValues(alpha: fade);
    for (int index = 0; index < 10; index++) {
      final double angle = (math.pi * 2 * index / 10) + 0.22;
      final double distance = extent * (0.12 + progress * 0.52);
      final Offset point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(
        point,
        extent * (0.018 + (index.isEven ? 0.012 : 0)),
        particle,
      );
    }
  }

  @override
  bool shouldRepaint(CaptureBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
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
    return ValueListenableBuilder<ChessPieceAppearance>(
      valueListenable: ChessPieceAppearanceController.current,
      builder: (BuildContext context, ChessPieceAppearance appearance, _) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double size = math.min(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final bool classic2d =
                appearance.style == ChessPieceVisualStyle.classic2d;
            final bool royalAsset =
                appearance.style == ChessPieceVisualStyle.premium3d &&
                premiumPieceAsset(appearance.finish, piece) != null;
            final double pieceScale = royalAsset
                ? switch (appearance.size) {
                    ChessPieceVisualSize.large => 1.00,
                    ChessPieceVisualSize.extraLarge => 1.08,
                    ChessPieceVisualSize.doubleExtraLarge => 1.16,
                  }
                : switch (appearance.size) {
                    ChessPieceVisualSize.large => classic2d ? 1.31 : 1.43,
                    ChessPieceVisualSize.extraLarge => classic2d ? 1.44 : 1.58,
                    ChessPieceVisualSize.doubleExtraLarge =>
                      classic2d ? 1.56 : 1.72,
                  };
            final double pieceSize = size * pieceScale;
            final double silhouetteScale = royalAsset
                ? 1.0
                : switch (piece.code) {
                    'K' => 1.00,
                    'Q' => .98,
                    'N' => .96,
                    'B' => .94,
                    'R' => .91,
                    _ => .88,
                  };

            return AnimatedRotation(
              turns: selected ? -0.012 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 220),
                scale: selected ? 1.13 : 1,
                curve: Curves.easeOutBack,
                child: SizedBox(
                  width: pieceSize,
                  height: pieceSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Positioned(
                        bottom: pieceSize * 0.08,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: <Color>[
                                (piece.white
                                        ? const Color(0xFFFFF0C8)
                                        : const Color(0xFF5D6674))
                                    .withValues(alpha: 0.28),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: SizedBox(
                            width: pieceSize * 0.72,
                            height: pieceSize * 0.34,
                          ),
                        ),
                      ),
                      if (!classic2d)
                        Positioned(
                          bottom: pieceSize * 0.045,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(pieceSize),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.48),
                                  blurRadius: pieceSize * 0.07,
                                  spreadRadius: pieceSize * 0.012,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: pieceSize * 0.11,
                                  offset: Offset(0, pieceSize * 0.08),
                                ),
                                if (selected)
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.68),
                                    blurRadius: pieceSize * 0.2,
                                    spreadRadius: pieceSize * 0.06,
                                  ),
                              ],
                            ),
                            child: SizedBox(
                              width: pieceSize * 0.42,
                              height: pieceSize * 0.035,
                            ),
                          ),
                        ),
                      Transform.translate(
                        offset: Offset(0, selected ? -pieceSize * 0.035 : 0),
                        child: Transform.scale(
                          scale: silhouetteScale,
                          child: _pieceVisual(appearance, pieceSize),
                        ),
                      ),
                      Positioned(
                        top: pieceSize * 0.11,
                        left: pieceSize * 0.25,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: piece.white ? 0.2 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(pieceSize),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  blurRadius: pieceSize * 0.09,
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: pieceSize * 0.13,
                              height: pieceSize * 0.035,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _pieceVisual(ChessPieceAppearance appearance, double pieceSize) {
    final String label =
        '${piece.white ? 'White' : 'Black'} ${pieceName(piece.code)}';
    if (appearance.style == ChessPieceVisualStyle.classic2d) {
      // Use the real white Unicode set for White. Re-colouring the solid
      // black glyphs made the classic white pawn retain a black silhouette on
      // several browser/Android serif fonts.
      final String solidGlyph = pieceGlyph(piece);
      final Color fill = piece.white
          ? const Color(0xFFFFF4D0)
          : const Color(0xFF10243A);
      final Color outline = piece.white
          ? const Color(0xFF9A6A16)
          : const Color(0xFFE7C67E);
      return Semantics(
        label: label,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Text(
              solidGlyph,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: pieceSize * .82,
                height: 1,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = math.max(1.8, pieceSize * .035)
                  ..color = outline,
              ),
            ),
            Text(
              solidGlyph,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: pieceSize * .82,
                height: 1,
                color: fill,
                shadows: <Shadow>[
                  Shadow(
                    color: Colors.black.withValues(alpha: .42),
                    blurRadius: pieceSize * .035,
                    offset: Offset(0, pieceSize * .018),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    Widget pieceImage({String? semanticLabel}) => Image.asset(
      pieceAsset(piece),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: semanticLabel,
    );
    Widget image = pieceImage(semanticLabel: label);
    if (appearance.style == ChessPieceVisualStyle.highContrast) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(
          piece.white ? const Color(0xFFFFF0B8) : const Color(0xFF89BFFF),
          BlendMode.modulate,
        ),
        child: image,
      );
    } else if (appearance.style == ChessPieceVisualStyle.premium3d) {
      final String? premiumAsset = premiumPieceAsset(appearance.finish, piece);
      if (premiumAsset != null) {
        return Semantics(
          label: label,
          child: Image.asset(
            premiumAsset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        );
      }
      final List<Color>? finishColors = premiumPieceFinishColors(
        appearance.finish,
        piece.white,
      );
      if (finishColors != null) {
        // Re-map the source luminance instead of replacing its RGB with a
        // flat alpha mask. This retains every carved edge, reflection and
        // bevel in the rendered Staunton asset while applying the purchased
        // royal material.
        image = ColorFiltered(
          colorFilter: ColorFilter.matrix(
            premiumPieceColorMatrix(finishColors),
          ),
          child: image,
        );
      }
    }
    return Semantics(label: label, child: image);
  }
}

String? premiumPieceAsset(String finish, ChessPiece piece) {
  final String? folder = switch (finish) {
    'crimson-crown-3d' => 'crimson-crown-3d',
    'inferno-gold' || 'golden-crown' => 'inferno-gold',
    'ruby-emperor' => 'ruby-emperor',
    'obsidian-regal' || 'ivory-obsidian' => 'obsidian-regal',
    'sapphire-elite' => 'sapphire-elite',
    'emerald-sovereign' => 'emerald-sovereign',
    _ => null,
  };
  if (folder == null) return null;
  final String name = switch (piece.code) {
    'K' => 'king',
    'Q' => 'queen',
    'R' => 'rook',
    'B' => 'bishop',
    'N' => 'knight',
    _ => 'pawn',
  };
  final String side = piece.white ? 'white' : 'black';
  return 'assets/pieces/premium_individual/$folder/$side/$name.webp';
}

String? premiumBoardAsset(String label) => switch (label) {
  'Walnut' => 'assets/boards/collection/royal-walnut-v1.webp',
  'Ocean Teal' => 'assets/boards/collection/ocean-teal-v1.webp',
  'Midnight Sapphire' => 'assets/boards/collection/midnight-sapphire-v1.webp',
  'Emerald Arena' => 'assets/boards/collection/emerald-arena-v1.webp',
  'Amethyst Clash' => 'assets/boards/collection/amethyst-clash-v1.webp',
  'Desert Gold' => 'assets/boards/collection/desert-gold-v1.webp',
  'Frost Marble' => 'assets/boards/collection/frost-marble-v1.webp',
  'Jade Dynasty' => 'assets/boards/collection/jade-dynasty-v1.webp',
  'Azure Temple' => 'assets/boards/collection/azure-temple-v1.webp',
  'Volcanic Obsidian' => 'assets/boards/collection/volcanic-obsidian-v1.webp',
  'Rose Quartz' => 'assets/boards/collection/rose-quartz-v1.webp',
  'Celestial Silver' => 'assets/boards/collection/celestial-silver-v1.webp',
  _ => null,
};

List<Color>? premiumPieceFinishColors(String finish, bool white) =>
    switch (finish) {
      'crimson-crown-3d' =>
        white
            ? const <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFFFE5A6),
                Color(0xFFD89B2B),
                Color(0xFFFFF0BE),
                Color(0xFF8C5410),
              ]
            : const <Color>[
                Color(0xFFFFA0AD),
                Color(0xFFFF294B),
                Color(0xFF760019),
                Color(0xFFFF4963),
                Color(0xFF280008),
              ],
      'inferno-gold' || 'golden-crown' =>
        white
            ? const <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFFFEDAD),
                Color(0xFFD99A22),
                Color(0xFFFFF2B8),
                Color(0xFF9A5A08),
              ]
            : const <Color>[
                Color(0xFFFFE48A),
                Color(0xFFD99716),
                Color(0xFF633200),
                Color(0xFFFFC844),
                Color(0xFF3A1B00),
              ],
      'ruby-emperor' =>
        white
            ? const <Color>[
                Color(0xFFFFE6CB),
                Color(0xFFFFAD75),
                Color(0xFFB52B34),
                Color(0xFFFFD09A),
                Color(0xFF6F101C),
              ]
            : const <Color>[
                Color(0xFFFF7B91),
                Color(0xFFC9153E),
                Color(0xFF560015),
                Color(0xFFFF385A),
                Color(0xFF260009),
              ],
      'obsidian-regal' || 'ivory-obsidian' =>
        white
            ? const <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFE9EEF5),
                Color(0xFF8793A1),
                Color(0xFFFFFFFF),
                Color(0xFF59616C),
              ]
            : const <Color>[
                Color(0xFFB9C2CE),
                Color(0xFF353C47),
                Color(0xFF05070A),
                Color(0xFF697482),
                Color(0xFF000000),
              ],
      'sapphire-elite' =>
        white
            ? const <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFBFE7FF),
                Color(0xFF397FE8),
                Color(0xFFD4F2FF),
                Color(0xFF1244A0),
              ]
            : const <Color>[
                Color(0xFF8CDFFF),
                Color(0xFF245DFF),
                Color(0xFF061450),
                Color(0xFF298DFF),
                Color(0xFF020725),
              ],
      'emerald-sovereign' =>
        white
            ? const <Color>[
                Color(0xFFFFFFD7),
                Color(0xFFFFD77A),
                Color(0xFF399D72),
                Color(0xFFFFEDAC),
                Color(0xFF126344),
              ]
            : const <Color>[
                Color(0xFF8DFFD0),
                Color(0xFF10A86B),
                Color(0xFF023D2A),
                Color(0xFF21DB8F),
                Color(0xFF011F16),
              ],
      'platinum-staunton' =>
        white
            ? const <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFE8F3FF),
                Color(0xFF8296AA),
                Color(0xFFFFFFFF),
                Color(0xFF526678),
              ]
            : const <Color>[
                Color(0xFFE2EDFA),
                Color(0xFF71869C),
                Color(0xFF172432),
                Color(0xFFAEC2D5),
                Color(0xFF09111A),
              ],
      _ => null,
    };

List<double> premiumPieceColorMatrix(List<Color> colors) {
  final Color highlight = colors.first;
  final Color shadow = colors.last;
  double channel(int bright, int dark) => (bright - dark) / 255;
  int component(double value) => (value * 255).round();
  final double redRange = channel(component(highlight.r), component(shadow.r));
  final double greenRange = channel(
    component(highlight.g),
    component(shadow.g),
  );
  final double blueRange = channel(component(highlight.b), component(shadow.b));
  const double redLuma = .2126;
  const double greenLuma = .7152;
  const double blueLuma = .0722;
  return <double>[
    redLuma * redRange,
    greenLuma * redRange,
    blueLuma * redRange,
    0,
    component(shadow.r).toDouble(),
    redLuma * greenRange,
    greenLuma * greenRange,
    blueLuma * greenRange,
    0,
    component(shadow.g).toDouble(),
    redLuma * blueRange,
    greenLuma * blueRange,
    blueLuma * blueRange,
    0,
    component(shadow.b).toDouble(),
    0,
    0,
    0,
    1,
    0,
  ];
}

String pieceAsset(ChessPiece piece) {
  return 'assets/pieces/staunton_${piece.white ? 'white' : 'black'}_${pieceName(piece.code)}.png';
}

String pieceName(String code) {
  return switch (code) {
    'K' => 'king',
    'Q' => 'queen',
    'R' => 'rook',
    'B' => 'bishop',
    'N' => 'knight',
    _ => 'pawn',
  };
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
    // U+265F defaults to an emoji-style 3D pawn on some Android fonts while
    // the other chess symbols stay as outlined text. VS15 forces the same
    // text presentation as the rest of the Classic 2D black set.
    _ => '\u265F\uFE0E',
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

class PieceSculpturePainter extends CustomPainter {
  const PieceSculpturePainter({required this.light, required this.accent});

  final bool light;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Color body = light
        ? const Color(0xFFF7E9C9)
        : const Color(0xFF252A32);
    final Color edge = light
        ? const Color(0xFFC09035)
        : const Color(0xFF68707D);
    final Paint shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          light ? Colors.white : const Color(0xFF505763),
          body,
          light ? const Color(0xFFD8B56C) : const Color(0xFF16191F),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final Paint edgePaint = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.035);

    final RRect base = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.66, w * 0.64, h * 0.18),
      Radius.circular(w * 0.12),
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.18, h * 0.72, w * 0.64, h * 0.18),
      shadow,
    );
    canvas.drawRRect(base, bodyPaint);
    canvas.drawRRect(base, edgePaint);

    final Path stem = Path()
      ..moveTo(w * 0.38, h * 0.68)
      ..quadraticBezierTo(w * 0.32, h * 0.46, w * 0.43, h * 0.32)
      ..lineTo(w * 0.57, h * 0.32)
      ..quadraticBezierTo(w * 0.68, h * 0.46, w * 0.62, h * 0.68)
      ..close();
    canvas.drawPath(stem, shadow);
    canvas.drawPath(stem, bodyPaint);
    canvas.drawPath(stem, edgePaint);

    canvas.drawCircle(Offset(w * 0.5, h * 0.26), w * 0.16, bodyPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.26), w * 0.16, edgePaint);
    canvas.drawCircle(
      Offset(w * 0.43, h * 0.18),
      w * 0.035,
      Paint()..color = Colors.white.withValues(alpha: light ? 0.86 : 0.28),
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      w * 0.3,
      Paint()
        ..color = accent.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035,
    );
  }

  @override
  bool shouldRepaint(PieceSculpturePainter oldDelegate) {
    return oldDelegate.light != light || oldDelegate.accent != accent;
  }
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
