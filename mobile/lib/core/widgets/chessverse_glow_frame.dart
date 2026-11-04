import 'package:flutter/material.dart';

/// A static illuminated edge: no repeating animation or full-screen blur.
/// Paints above artwork so images cannot hide the border.
class ChessVerseGlowFrame extends StatelessWidget {
  const ChessVerseGlowFrame({
    required this.child,
    this.color = const Color(0xFFE8BC58),
    this.radius = 20,
    super.key,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: .09), blurRadius: 8),
      ],
    ),
    child: CustomPaint(
      foregroundPainter: _GlowEdgePainter(color, radius),
      child: child,
    ),
  );
}

class _GlowEdgePainter extends CustomPainter {
  const _GlowEdgePainter(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = (Offset.zero & size).deflate(.8);
    final edge = RRect.fromRectAndRadius(bounds, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color,
          const Color(0xFFFFF1BD),
          color.withValues(alpha: .45),
          const Color(0xFF53D8D1),
          color,
        ],
        stops: const [0, .18, .45, .77, 1],
      ).createShader(bounds);
    canvas.drawRRect(edge, paint);
  }

  @override
  bool shouldRepaint(_GlowEdgePainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}
