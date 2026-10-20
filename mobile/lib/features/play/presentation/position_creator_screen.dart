import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/desktop_navigation_shell.dart';
import '../../analysis/domain/pgn_position_reconstructor.dart';
import '../../analysis/presentation/setup_analysis_screen.dart';

class PositionSetup {
  const PositionSetup({
    required this.pieces,
    required this.humanWhite,
    this.whiteToMove = true,
  });

  final Map<String, String> pieces;
  final bool humanWhite;
  final bool whiteToMove;

  String get initialFen {
    final List<String> ranks = <String>[];
    for (int rank = 8; rank >= 1; rank--) {
      int empty = 0;
      final StringBuffer row = StringBuffer();
      for (int file = 0; file < 8; file++) {
        final String square = '${String.fromCharCode(97 + file)}$rank';
        final String? piece = pieces[square];
        if (piece == null) {
          empty++;
          continue;
        }
        if (empty > 0) {
          row.write(empty);
          empty = 0;
        }
        final String code = piece.substring(1);
        row.write(piece.startsWith('w') ? code : code.toLowerCase());
      }
      if (empty > 0) row.write(empty);
      ranks.add(row.toString());
    }
    return '${ranks.join('/')} ${whiteToMove ? 'w' : 'b'} - - 0 1';
  }
}

class PositionCreatorScreen extends StatefulWidget {
  const PositionCreatorScreen({super.key});

  @override
  State<PositionCreatorScreen> createState() => _PositionCreatorScreenState();
}

class _PositionCreatorScreenState extends State<PositionCreatorScreen> {
  Map<String, String> _pieces = <String, String>{'e1': 'wK', 'e8': 'bK'};
  String? _brush = 'wQ';
  bool _humanWhite = true;
  bool _whiteToMove = true;
  PositionSetup get _setup => PositionSetup(
    pieces: Map<String, String>.unmodifiable(_pieces),
    humanWhite: _humanWhite,
    whiteToMove: _whiteToMove,
  );

  static const List<String?> _palette = <String?>[
    'wK',
    'wQ',
    'wR',
    'wB',
    'wN',
    'wP',
    'bK',
    'bQ',
    'bR',
    'bB',
    'bN',
    'bP',
    null,
  ];

  void _tapSquare(String square) {
    setState(() {
      if (_brush == null) {
        _pieces.remove(square);
        return;
      }
      final String piece = _brush!;
      if (piece.endsWith('K')) {
        _pieces.removeWhere((_, value) => value == piece);
      }
      _pieces[square] = piece;
    });
  }

  String? _validationError() {
    if (_pieces.values.where((p) => p == 'wK').length != 1 ||
        _pieces.values.where((p) => p == 'bK').length != 1) {
      return 'Place exactly one white king and one black king.';
    }
    if (_pieces.entries.any(
      (entry) =>
          entry.value.endsWith('P') &&
          (entry.key.endsWith('1') || entry.key.endsWith('8')),
    )) {
      return 'Pawns cannot start on the first or eighth rank.';
    }
    for (final String color in <String>['w', 'b']) {
      if (_pieces.values.where((p) => p.startsWith(color)).length > 16 ||
          _pieces.values.where((p) => p == '${color}P').length > 8) {
        return 'Each side can have at most 16 pieces and 8 pawns.';
      }
    }
    final String whiteKing = _pieces.entries
        .singleWhere((e) => e.value == 'wK')
        .key;
    final String blackKing = _pieces.entries
        .singleWhere((e) => e.value == 'bK')
        .key;
    final int fileGap = (whiteKing.codeUnitAt(0) - blackKing.codeUnitAt(0))
        .abs();
    final int rankGap = (int.parse(whiteKing[1]) - int.parse(blackKing[1]))
        .abs();
    if (fileGap <= 1 && rankGap <= 1) {
      return 'Kings cannot stand on adjacent squares.';
    }
    if (setupHasNonMovingKingInCheck(_setup.initialFen)) {
      return 'The side not moving cannot already be in check. Change the board or side to move.';
    }
    return null;
  }

  void _start() {
    final String? error = _validationError();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: UiText(error)));
      return;
    }
    Navigator.pop(
      context,
      PositionSetup(
        pieces: Map<String, String>.unmodifiable(_pieces),
        humanWhite: _humanWhite,
        whiteToMove: _whiteToMove,
      ),
    );
  }

  void _analyse() {
    final error = _validationError();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: UiText(error)));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SetupAnalysisScreen(fen: _setup.initialFen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 800;
    final Widget controls = _controls();
    return DesktopNavigationShell(
      selected: 'Play',
      child: Scaffold(
        backgroundColor: const Color(0xFF061524),
        appBar: AppBar(
          title: const UiText('Set Up Board'),
          backgroundColor: const Color(0xFF071B2D),
          actions: <Widget>[
            TextButton.icon(
              onPressed: () => setState(
                () => _pieces = <String, String>{'e1': 'wK', 'e8': 'bK'},
              ),
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const UiText('CLEAR'),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 6, child: _board()),
                          const SizedBox(width: 28),
                          Expanded(flex: 4, child: controls),
                        ],
                      )
                    : Column(
                        children: <Widget>[
                          _board(),
                          const SizedBox(height: 20),
                          controls,
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _board() =>
      Directionality(textDirection: TextDirection.ltr, child: _boardContent());

  Widget _boardContent() => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE2AE49), width: 2),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Colors.black54, blurRadius: 28, offset: Offset(0, 12)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(21),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (BuildContext context, int index) {
            final int rank = 8 - index ~/ 8;
            final int file = index % 8;
            final String square = '${String.fromCharCode(97 + file)}$rank';
            final String? piece = _pieces[square];
            final bool dark = (file + rank).isOdd;
            return Semantics(
              button: true,
              label: '$square${piece == null ? ', empty' : ', $piece'}',
              child: InkWell(
                key: ValueKey('setup-square-$square'),
                onTap: () => _tapSquare(square),
                child: ColoredBox(
                  color: dark
                      ? const Color(0xFF765239)
                      : const Color(0xFFD9C8A8),
                  child: Stack(
                    children: <Widget>[
                      if (piece != null)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              _asset(piece),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      Positioned(
                        left: 3,
                        bottom: 1,
                        child: Text(
                          square,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: dark
                                ? const Color(0xFFD9C8A8)
                                : const Color(0xFF765239),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _controls() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF0A2033),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF2A4A5F)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const UiText(
          'Set up a position',
          style: TextStyle(
            color: Color(0xFFE2AE49),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const UiText(
          'Place pieces, choose the side to move, then analyse or play.',
          style: TextStyle(color: Color(0xFFB7CAD7), height: 1.4),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _palette.map((String? piece) {
            final bool selected = _brush == piece;
            final bool blackPiece = piece?.startsWith('b') ?? false;
            return InkWell(
              key: ValueKey<String>('palette-${piece ?? 'erase'}'),
              onTap: () => setState(() => _brush = piece),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: selected
                      ? (blackPiece
                            ? const Color(0xFFDDF8F0)
                            : const Color(0xFF174C4A))
                      : (blackPiece
                            ? const Color(0xFFF5EEDC)
                            : const Color(0xFF071625)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF63D2B8)
                        : blackPiece
                        ? const Color(0xFFD8B567)
                        : const Color(0xFF294157),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: piece == null
                    ? const Icon(
                        Icons.auto_fix_off_rounded,
                        color: Color(0xFFE57373),
                      )
                    : Image.asset(_asset(piece), fit: BoxFit.contain),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const UiText('Side to move'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const ValueKey('setup-white-turn'),
              label: const UiText('White to move'),
              selected: _whiteToMove,
              onSelected: (_) => setState(() => _whiteToMove = true),
            ),
            ChoiceChip(
              key: const ValueKey('setup-black-turn'),
              label: const UiText('Black to move'),
              selected: !_whiteToMove,
              onSelected: (_) => setState(() => _whiteToMove = false),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const UiText('Your side against AI'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const UiText('PLAY WHITE'),
              selected: _humanWhite,
              onSelected: (_) => setState(() => _humanWhite = true),
            ),
            ChoiceChip(
              label: const UiText('PLAY BLACK'),
              selected: !_humanWhite,
              onSelected: (_) => setState(() => _humanWhite = false),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const UiText(
          'No castling or en passant rights in the starting position.',
          style: TextStyle(color: Color(0xFF8FA8BA), fontSize: 12),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('position-analyse'),
            onPressed: _analyse,
            icon: const Icon(Icons.analytics_outlined),
            label: const UiText(
              'Analyse Position',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey<String>('position-start-ai'),
            onPressed: _start,
            icon: const Icon(Icons.smart_toy_rounded),
            label: const UiText('Play against AI', textAlign: TextAlign.center),
          ),
        ),
      ],
    ),
  );

  String _asset(String piece) {
    const Map<String, String> names = <String, String>{
      'K': 'king',
      'Q': 'queen',
      'R': 'rook',
      'B': 'bishop',
      'N': 'knight',
      'P': 'pawn',
    };
    final String side = piece.startsWith('w') ? 'white' : 'black';
    return 'assets/pieces/staunton_${side}_${names[piece[1]]}.png';
  }
}
