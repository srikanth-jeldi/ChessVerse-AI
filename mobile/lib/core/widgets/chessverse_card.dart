import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'chessverse_glow_frame.dart';

class ChessVerseCard extends StatelessWidget {
  const ChessVerseCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(20);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF103143), Color(0xFF091C2D)],
        ),
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ChessVerseGlowFrame(
        color: const Color(0xFF53D8D1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
