import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The responsive visual foundation shared by every ChessVerseAI route.
class ChessVerseAppBackdrop extends StatelessWidget {
  const ChessVerseAppBackdrop({super.key, required this.child});

  static const Key backdropKey = ValueKey<String>('global-app-backdrop');

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: backdropKey,
      color: const Color(0xFF06131F),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF071827),
                  Color(0xFF092236),
                  Color(0xFF040B13),
                ],
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ChessboardWatermarkPainter()),
            ),
          ),
          const Positioned(
            left: -130,
            top: -150,
            child: _BackdropGlow(
              size: 360,
              color: Color(0x2963D2B8),
            ),
          ),
          const Positioned(
            right: -160,
            bottom: 30,
            child: _BackdropGlow(
              size: 400,
              color: Color(0x21EABF61),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(color: color, blurRadius: size * .42, spreadRadius: 12),
          ],
        ),
      ),
    );
  }
}

class _ChessboardWatermarkPainter extends CustomPainter {
  const _ChessboardWatermarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double shortest = math.min(size.width, size.height);
    final double boardSize = math.min(
      math.max(shortest * .82, 360),
      math.min(size.width * .82, 760),
    );
    final double square = boardSize / 8;
    final Offset origin = Offset(
      (size.width - boardSize) / 2,
      (size.height - boardSize) / 2,
    );
    final Paint light = Paint()..color = const Color(0x08FFFFFF);
    final Paint dark = Paint()..color = const Color(0x10000000);
    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        canvas.drawRect(
          Rect.fromLTWH(
            origin.dx + file * square,
            origin.dy + rank * square,
            square,
            square,
          ),
          (rank + file).isEven ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
