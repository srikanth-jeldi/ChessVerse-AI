import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../domain/daily_challenge_models.dart';

class DailyChallengeLauncher extends StatelessWidget {
  const DailyChallengeLauncher({
    required this.challenge,
    required this.onStart,
    this.onViewDetails,
    super.key,
  });

  final DailyChallengeUiState challenge;
  final VoidCallback onStart;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return ChessVerseCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Color(0xFF0D1628),
                Color(0xFF241A4A),
                Color(0xFF050B18),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.backgroundDeep,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Today\'s Checkmate',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${challenge.difficulty.title} · ${challenge.difficulty.subtitle}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  challenge.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Solve the daily forced line, protect your streak, and review the mating pattern after completion.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _InlineMetric(
                        label: 'Streak',
                        value: '${challenge.streakDays} days',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InlineMetric(
                        label: 'Moves',
                        value: challenge.progressLabel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InlineMetric(
                        label: 'Best',
                        value: challenge.bestTimeLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ChessVerseButton(
                        label: 'Start challenge',
                        icon: Icons.play_arrow_rounded,
                        onPressed: onStart,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.info_outline_rounded),
                      tooltip: 'Daily challenge details',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
