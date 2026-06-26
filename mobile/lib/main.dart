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

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<String> _moves = <String>[];
  String? _selectedSquare;
  BoardSkin _skin = BoardSkin.royalWalnut;
  double _aiLevel = 4;
  bool _coachEnabled = true;

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
  Widget build(BuildContext context) {
    final BoardPalette palette = boardPalettes[_skin]!;

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
                palette: palette,
                onSquareTap: _handleSquareTap,
              );

              final Widget panel = GamePanel(
                activeColor: _moves.length.isEven ? 'White' : 'Black',
                aiLevel: _aiLevel.round(),
                coachEnabled: _coachEnabled,
                moves: _moves,
                skin: _skin,
                onSkinChanged: (BoardSkin skin) => setState(() => _skin = skin),
                onAiLevelChanged: (double level) {
                  setState(() => _aiLevel = level);
                },
                onCoachChanged: (bool value) {
                  setState(() => _coachEnabled = value);
                },
                onReset: _reset,
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
    setState(() {
      if (_selectedSquare == null) {
        if (_pieces.containsKey(square)) {
          _selectedSquare = square;
        }
        return;
      }

      if (_selectedSquare == square) {
        _selectedSquare = null;
        return;
      }

      final ChessPiece? piece = _pieces.remove(_selectedSquare);
      if (piece != null) {
        _pieces[square] = piece;
        _moves.insert(0, '$_selectedSquare$square');
      }
      _selectedSquare = null;
    });
  }

  void _reset() {
    setState(() {
      _pieces = Map<String, ChessPiece>.from(_initialPieces);
      _moves.clear();
      _selectedSquare = null;
    });
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
    required this.child,
    super.key,
  });

  final BoardPalette palette;
  final int moveCount;
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
              MatchClock(label: 'White', value: '10:00'),
              const SizedBox(width: 8),
              MatchClock(label: 'Black', value: '10:00'),
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
                  border: Border.all(color: palette.accent.withOpacity(0.5)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.38),
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
    required this.palette,
    required this.onSquareTap,
    super.key,
  });

  final Map<String, ChessPiece> pieces;
  final String? selectedSquare;
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

                return BoardSquare(
                  square: square,
                  dark: dark,
                  selected: selected,
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
  final BoardPalette palette;
  final bool showRank;
  final bool showFile;
  final VoidCallback onTap;
  final ChessPiece? piece;

  @override
  Widget build(BuildContext context) {
    final Color base = dark ? palette.dark : palette.light;
    final Color coordinateColor =
        dark ? palette.light.withOpacity(0.72) : palette.dark.withOpacity(0.72);

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(palette.accent.withOpacity(0.55), base)
              : base,
          border: selected
              ? Border.all(color: const Color(0xFFF8E7B0), width: 3)
              : null,
        ),
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
          transform: Matrix4.identity()..scale(selected ? 1.08 : 1.0),
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
                color: Colors.black.withOpacity(0.34),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: accent.withOpacity(selected ? 0.35 : 0.08),
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
                  Icon(
                    pieceIcon(piece.code),
                    color: text,
                    size: coinSize * 0.34,
                  ),
                  Text(
                    piece.code,
                    style: TextStyle(
                      color: text,
                      fontSize: coinSize * 0.24,
                      fontWeight: FontWeight.w900,
                      height: 0.9,
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

IconData pieceIcon(String code) {
  return switch (code) {
    'K' => Icons.workspace_premium_rounded,
    'Q' => Icons.diamond_rounded,
    'R' => Icons.account_balance_rounded,
    'B' => Icons.change_history_rounded,
    'N' => Icons.navigation_rounded,
    _ => Icons.circle_rounded,
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
      ..color = color.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, radius * 0.08);
    canvas.drawCircle(center, radius * 0.68, ring);

    final Paint tick = Paint()
      ..color = color.withOpacity(0.28)
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

class GamePanel extends StatelessWidget {
  const GamePanel({
    required this.activeColor,
    required this.aiLevel,
    required this.coachEnabled,
    required this.moves,
    required this.skin,
    required this.onSkinChanged,
    required this.onAiLevelChanged,
    required this.onCoachChanged,
    required this.onReset,
    super.key,
  });

  final String activeColor;
  final int aiLevel;
  final bool coachEnabled;
  final List<String> moves;
  final BoardSkin skin;
  final ValueChanged<BoardSkin> onSkinChanged;
  final ValueChanged<double> onAiLevelChanged;
  final ValueChanged<bool> onCoachChanged;
  final VoidCallback onReset;

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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: coachEnabled,
            onChanged: onCoachChanged,
            title: const Text('AI coach'),
            secondary: const Icon(Icons.psychology_alt_rounded),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.psychology_alt_rounded),
                  label: const Text('Hint'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
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
            color: const Color(0xFF191A1F).withOpacity(0.92),
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
