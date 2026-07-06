import 'package:flutter/material.dart';

import '../../../../core/theme/chessverse_theme.dart';
import '../../domain/chess_piece.dart';
import '../../domain/chess_rules.dart';

class ChessBoardView extends StatelessWidget {
  const ChessBoardView({
    required this.board,
    required this.selectedSquare,
    required this.legalTargets,
    required this.onSquareTap,
    super.key,
  });

  final BoardState board;
  final String? selectedSquare;
  final List<String> legalTargets;
  final ValueChanged<String> onSquareTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: ChessVerseColors.gold, width: 2),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
            itemCount: 64,
            itemBuilder: (BuildContext context, int index) {
              final int row = index ~/ 8;
              final int col = index % 8;
              final int rank = 8 - row;
              final String square = ChessRules.squareOf(col, rank);
              final ChessPiece? piece = board[square];
              final bool light = (row + col).isEven;
              final bool selected = selectedSquare == square;
              final bool target = legalTargets.contains(square);
              return _BoardSquare(
                square: square,
                piece: piece,
                light: light,
                selected: selected,
                target: target,
                onTap: () => onSquareTap(square),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BoardSquare extends StatelessWidget {
  const _BoardSquare({
    required this.square,
    required this.piece,
    required this.light,
    required this.selected,
    required this.target,
    required this.onTap,
  });

  final String square;
  final ChessPiece? piece;
  final bool light;
  final bool selected;
  final bool target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color base = light ? const Color(0xFFE9D5B7) : const Color(0xFF7A4F2A);
    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(color: selected ? ChessVerseColors.gold.withValues(alpha: 0.74) : base),
          if (target)
            Center(
              child: Container(
                width: piece == null ? 18 : 46,
                height: piece == null ? 18 : 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: piece == null
                      ? Colors.black.withValues(alpha: 0.28)
                      : ChessVerseColors.danger.withValues(alpha: 0.42),
                  border: piece == null ? null : Border.all(color: ChessVerseColors.danger, width: 2),
                ),
              ),
            ),
          if (piece != null)
            Center(
              child: Text(
                piece!.symbol,
                style: TextStyle(
                  fontSize: 38,
                  height: 1,
                  color: piece!.isWhite ? Colors.white : Colors.black87,
                  shadows: const <Shadow>[Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
                ),
              ),
            ),
          Positioned(
            left: 3,
            bottom: 2,
            child: Text(
              square,
              style: TextStyle(
                fontSize: 8,
                color: light ? Colors.black54 : Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
