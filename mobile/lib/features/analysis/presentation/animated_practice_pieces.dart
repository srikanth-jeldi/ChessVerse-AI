import 'package:flutter/material.dart';

import '../domain/pgn_position_reconstructor.dart';

/// Animates adjacent chess positions, rather than guessing which of two
/// identical pieces moved. Unrelated positions and orientation changes snap.
class AnimatedPracticePieces extends StatefulWidget {
  const AnimatedPracticePieces({
    required this.fen,
    required this.flipped,
    required this.pieceBuilder,
    super.key,
  });

  final String fen;
  final bool flipped;
  final Widget Function(String) pieceBuilder;

  @override
  State<AnimatedPracticePieces> createState() => _AnimatedPracticePiecesState();
}

Map<String, String> _pieces(String fen) {
  final result = <String, String>{};
  final ranks = fen.split(' ').first.split('/');
  for (var row = 0; row < ranks.length && row < 8; row++) {
    var col = 0;
    for (final token in ranks[row].split('')) {
      final empty = int.tryParse(token);
      if (empty != null) {
        col += empty;
      } else if (col < 8) {
        result['${String.fromCharCode(97 + col)}${8 - row}'] = token;
        col++;
      }
    }
  }
  return result;
}

/// Destination -> origin, including the rook when castling.
Map<String, String> _transition(String before, String after) {
  final old = _pieces(before);
  final next = _pieces(after);
  final removed = old.keys.where((s) => old[s] != next[s]).toList();
  final added = next.keys.where((s) => old[s] != next[s]).toList();
  if (removed.length > 3 || added.length > 2) return {};
  for (final from in removed) {
    for (final to in added) {
      final promotion =
          old[from]!.toLowerCase() == 'p' && next[to]!.toLowerCase() != 'p';
      final move = '$from$to${promotion ? next[to]!.toLowerCase() : ''}';
      final positions = replayUciLine(before, [move], requireLegalMoves: true);
      if (positions.length != 2 ||
          positions.last.split(' ').take(2).join(' ') !=
              after.split(' ').take(2).join(' ')) {
        continue;
      }
      final result = <String, String>{to: from};
      if (old[from]!.toLowerCase() == 'k' &&
          (from.codeUnitAt(0) - to.codeUnitAt(0)).abs() == 2) {
        final rank = from[1];
        result['${to[0] == 'g' ? 'f' : 'd'}$rank'] =
            '${to[0] == 'g' ? 'h' : 'a'}$rank';
      }
      return result;
    }
  }
  return {};
}

class _AnimatedPracticePiecesState extends State<AnimatedPracticePieces>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  Map<String, String> _origins = {};

  @override
  void didUpdateWidget(covariant AnimatedPracticePieces oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fen == widget.fen && oldWidget.flipped == widget.flipped) {
      return;
    }
    _controller.stop();
    _origins = {};
    if (oldWidget.flipped == widget.flipped &&
        !MediaQuery.disableAnimationsOf(context)) {
      _origins = _transition(oldWidget.fen, widget.fen);
      if (_origins.isEmpty) {
        // Previous-move navigation in the continuation preview.
        final reverse = _transition(widget.fen, oldWidget.fen);
        _origins = {for (final e in reverse.entries) e.value: e.key};
      }
    }
    if (_origins.isEmpty) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _offset(String square) {
    final col = square.codeUnitAt(0) - 97;
    final row = 8 - int.parse(square[1]);
    return Offset(
      (widget.flipped ? 7 - col : col).toDouble(),
      (widget.flipped ? 7 - row : row).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final cell = constraints.maxWidth / 8;
        final pieces = _pieces(widget.fen).entries.toList()
          ..sort(
            (a, b) => (_origins.containsKey(a.key) ? 1 : 0).compareTo(
              _origins.containsKey(b.key) ? 1 : 0,
            ),
          );
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = MediaQuery.disableAnimationsOf(context)
                ? 1.0
                : Curves.easeOutCubic.transform(_controller.value);
            return Stack(
              children: [
                for (final piece in pieces)
                  Builder(
                    builder: (context) {
                      final end = _offset(piece.key);
                      final start = _offset(_origins[piece.key] ?? piece.key);
                      final position =
                          Offset.lerp(start, end, progress)! * cell;
                      return Positioned(
                        key: ValueKey('practice-piece-${piece.key}'),
                        left: position.dx,
                        top: position.dy,
                        width: cell,
                        height: cell,
                        child: widget.pieceBuilder(piece.value),
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    ),
  );
}
