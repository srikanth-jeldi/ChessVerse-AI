import 'package:flutter/material.dart';

import '../../../core/layout/responsive_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analysis')),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ChessVerseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.analytics_rounded, size: 30),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Game Analysis',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review your move history, find missed tactics, and learn from AI coach explanations. Engine-backed analysis will be connected in the next backend phase.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Coming analysis tools', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const _AnalysisFeatureCard(
              icon: Icons.timeline_rounded,
              title: 'Move timeline',
              subtitle: 'See every move with evaluation markers.',
            ),
            const SizedBox(height: 12),
            const _AnalysisFeatureCard(
              icon: Icons.psychology_alt_rounded,
              title: 'Best move coach',
              subtitle: 'Understand why one move is stronger than another.',
            ),
            const SizedBox(height: 12),
            const _AnalysisFeatureCard(
              icon: Icons.warning_amber_rounded,
              title: 'Mistake detection',
              subtitle: 'Mark inaccuracies, mistakes, and blunders.',
            ),
            const SizedBox(height: 18),
            ChessVerseButton(
              label: 'Analyze current game coming soon',
              icon: Icons.auto_graph_rounded,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisFeatureCard extends StatelessWidget {
  const _AnalysisFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ChessVerseCard(
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.accentGold),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
