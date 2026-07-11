import 'package:flutter/material.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../core/layout/responsive_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';

class LearnChessScreen extends StatelessWidget {
  const LearnChessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool wide = AppBreakpoints.isTabletOrLarger(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Learn Chess'),
        backgroundColor: AppColors.background,
      ),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ChessVerseCard(
              padding: const EdgeInsets.all(22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.psychology_alt_rounded, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'ChessVerse Coach',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'After every important move, the coach explains whether it was Great, Good, Average, or Bad so players learn while playing.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: wide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: wide ? 1.25 : 0.96,
              children: const <Widget>[
                _LessonCard(
                  icon: Icons.account_tree_rounded,
                  title: 'Piece basics',
                  body: 'Learn how every coin moves and captures.',
                ),
                _LessonCard(
                  icon: Icons.security_rounded,
                  title: 'King safety',
                  body: 'Understand check, escape squares, and pins.',
                ),
                _LessonCard(
                  icon: Icons.bolt_rounded,
                  title: 'Tactics',
                  body: 'Forks, skewers, discovered attacks, and mates.',
                ),
                _LessonCard(
                  icon: Icons.emoji_events_rounded,
                  title: 'Endgames',
                  body: 'Finish cleanly with rook, queen, and pawn endings.',
                ),
              ],
            ),
            const SizedBox(height: 18),
            ChessVerseCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Move quality labels',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _QualityChip(label: 'Great', color: Color(0xFF63D2B8)),
                      _QualityChip(label: 'Good', color: Color(0xFFD6A84F)),
                      _QualityChip(label: 'Average', color: Color(0xFF8A8F9D)),
                      _QualityChip(label: 'Bad', color: Color(0xFFE15F5F)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ChessVerseCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.primary, size: 30),
          const Spacer(),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  const _QualityChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 6),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.55)),
      backgroundColor: color.withValues(alpha: 0.12),
    );
  }
}
