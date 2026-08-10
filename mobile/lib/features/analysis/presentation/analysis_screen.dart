import 'package:flutter/material.dart';

import '../../../core/layout/responsive_page.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../domain/ai_review_report.dart';
import 'adaptive_ai_review.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SavedGameRecord> games = LocalGameArchive.games;
    final int totalMoves = games.fold<int>(
      0,
      (int total, SavedGameRecord game) => total + game.moves.length,
    );
    final int averageMoves =
        games.isEmpty ? 0 : (totalMoves / games.length).round();
    final int losses = games
        .where((SavedGameRecord game) =>
            game.result.toLowerCase().contains('loss'))
        .length;
    final SavedGameRecord? latest = games.isEmpty ? null : games.first;
    final AiReviewReport? latestReport = latest == null
        ? null
        : AiReviewReport.fromMoves(
            latest.moves,
            newestFirst: false,
            result: latest.result,
          );
    final String focus = _trainingFocus(games, averageMoves, losses);
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                    games.isEmpty
                        ? 'Play a game to unlock your first personalized AI training report.'
                        : 'Your AI coach reviewed ${games.length} saved game${games.length == 1 ? '' : 's'} and $totalMoves recorded moves.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('AI performance snapshot',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _AnalysisFeatureCard(
              icon: Icons.timeline_rounded,
              title: latestReport == null
                  ? '${games.length} games analyzed'
                  : '${latestReport.accuracy}% latest-game accuracy',
              subtitle: latestReport?.headline ??
                  '$averageMoves average recorded moves per game.',
            ),
            const SizedBox(height: 12),
            _AnalysisFeatureCard(
              icon: Icons.psychology_alt_rounded,
              title: 'Personalized training focus',
              subtitle: latestReport == null
                  ? focus
                  : '${latestReport.trainingFocus} Recommended: ${latestReport.recommendedLesson}.',
            ),
            const SizedBox(height: 12),
            _AnalysisFeatureCard(
              icon: Icons.warning_amber_rounded,
              title: latest == null ? 'Latest game report' : latest.result,
              subtitle: latest == null
                  ? 'Your latest result and coach recommendation will appear here.'
                  : latestReport?.turningPoint ??
                      '${latest.summary} • ${latest.detail}',
            ),
            const SizedBox(height: 18),
            ChessVerseButton(
              label: games.isEmpty ? 'No saved game yet' : 'Open full AI review',
              icon: Icons.auto_graph_rounded,
              onPressed: games.isEmpty
                  ? null
                  : () => showAdaptiveAiReview(
                        context,
                        report: latestReport!,
                      ),
            ),
          ],
        ),
      ),
    );
  }

  String _trainingFocus(
    List<SavedGameRecord> games,
    int averageMoves,
    int losses,
  ) {
    if (games.isEmpty) {
      return 'Start with a Newcomer AI game, then review the board after every result.';
    }
    if (losses * 2 > games.length) {
      return 'Prioritize king safety and scan every opponent check, capture, and threat before moving.';
    }
    if (averageMoves > 55) {
      return 'Your games run long. Train endgame conversion and activate your king after queens are exchanged.';
    }
    if (averageMoves < 18) {
      return 'Strengthen opening development: control the center, develop minor pieces, and castle early.';
    }
    return 'Build tactical consistency: calculate forcing checks and captures before choosing a positional move.';
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
