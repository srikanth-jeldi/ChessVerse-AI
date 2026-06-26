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
      theme: ChessVerseTheme.light(),
      home: const GameScreen(),
    );
  }
}

class ChessVerseTheme {
  static ThemeData light() {
    const ink = Color(0xFF10131A);
    const accent = Color(0xFF0F766E);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: accent,
        surface: const Color(0xFFF7F7F2),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F7F2),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: ink,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: Color(0xFF3F4450), height: 1.35),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F7F2),
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<String> _moves = <String>[];
  String? _selectedSquare;

  static const Map<String, String> _initialPieces = <String, String>{
    'a8': '♜',
    'b8': '♞',
    'c8': '♝',
    'd8': '♛',
    'e8': '♚',
    'f8': '♝',
    'g8': '♞',
    'h8': '♜',
    'a7': '♟',
    'b7': '♟',
    'c7': '♟',
    'd7': '♟',
    'e7': '♟',
    'f7': '♟',
    'g7': '♟',
    'h7': '♟',
    'a2': '♙',
    'b2': '♙',
    'c2': '♙',
    'd2': '♙',
    'e2': '♙',
    'f2': '♙',
    'g2': '♙',
    'h2': '♙',
    'a1': '♖',
    'b1': '♘',
    'c1': '♗',
    'd1': '♕',
    'e1': '♔',
    'f1': '♗',
    'g1': '♘',
    'h1': '♖',
  };

  late Map<String, String> _pieces = Map<String, String>.from(_initialPieces);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChessVerse AI'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reset board',
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 900;
            final Widget board = ChessBoard(
              pieces: _pieces,
              selectedSquare: _selectedSquare,
              onSquareTap: _handleSquareTap,
            );
            final Widget panel = GamePanel(
              moveCount: _moves.length,
              activeColor: _moves.length.isEven ? 'White' : 'Black',
              moves: _moves,
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(flex: 7, child: board),
                        const SizedBox(width: 24),
                        SizedBox(width: 340, child: panel),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        board,
                        const SizedBox(height: 18),
                        Expanded(child: panel),
                      ],
                    ),
            );
          },
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

      final String? piece = _pieces.remove(_selectedSquare);
      if (piece != null) {
        _pieces[square] = piece;
        _moves.insert(0, '$_selectedSquare$square');
      }
      _selectedSquare = null;
    });
  }

  void _reset() {
    setState(() {
      _pieces = Map<String, String>.from(_initialPieces);
      _moves.clear();
      _selectedSquare = null;
    });
  }
}

class ChessBoard extends StatelessWidget {
  const ChessBoard({
    required this.pieces,
    required this.selectedSquare,
    required this.onSquareTap,
    super.key,
  });

  final Map<String, String> pieces;
  final String? selectedSquare;
  final ValueChanged<String> onSquareTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemCount: 64,
            itemBuilder: (BuildContext context, int index) {
              final int row = index ~/ 8;
              final int col = index % 8;
              final String square = '${String.fromCharCode(97 + col)}${8 - row}';
              final bool dark = (row + col).isOdd;
              final bool selected = square == selectedSquare;

              return InkWell(
                onTap: () => onSquareTap(square),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF14B8A6)
                        : dark
                            ? const Color(0xFF769656)
                            : const Color(0xFFEEEED2),
                    border: selected
                        ? Border.all(color: const Color(0xFF0F172A), width: 3)
                        : null,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      pieces[square] ?? '',
                      key: ValueKey<String>(pieces[square] ?? '$square-empty'),
                      style: TextStyle(
                        fontSize: MediaQuery.sizeOf(context).width < 420 ? 28 : 42,
                        height: 1,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    required this.moveCount,
    required this.activeColor,
    required this.moves,
    super.key,
  });

  final int moveCount;
  final String activeColor;
  final List<String> moves;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('AI Arena', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            StatusChip(icon: Icons.auto_awesome_rounded, label: 'Coach ready'),
            StatusChip(icon: Icons.speed_rounded, label: 'Level 1'),
            StatusChip(icon: Icons.memory_rounded, label: activeColor),
          ],
        ),
        const SizedBox(height: 18),
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
        Expanded(
          child: moves.isEmpty
              ? const Center(child: Text('Tap a piece, then tap a target square.'))
              : ListView.separated(
                  itemCount: moves.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      dense: true,
                      leading: Text('${moveCount - index}.'),
                      title: Text(moves[index]),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      backgroundColor: Colors.white,
    );
  }
}

