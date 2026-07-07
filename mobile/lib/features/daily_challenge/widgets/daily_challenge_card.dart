import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../domain/daily_challenge_models.dart';

class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({
    required this.challenge,
    this.onPlay,
    this.onViewDetails,
    super.key,
  });

  final DailyChallengeUiState challenge;
  final VoidCallback? onPlay;
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
                Color(0xFF18233F),
                Color(0xFF101827),
                Color(0xFF28184A),
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.backgroundDeep,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Daily Challenge',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            challenge.completedToday
                                ? 'Completed today. Keep your streak alive tomorrow.'
                                : 'New puzzle available today.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(completed: challenge.completedToday),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  challenge.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  challenge.difficulty.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _MetricChip(
                      icon: Icons.local_fire_department_rounded,
                      label: '${challenge.streakDays} day streak',
                    ),
                    _MetricChip(
                      icon: Icons.psychology_alt_rounded,
                      label: '${challenge.difficulty.title} · ${challenge.difficulty.subtitle}',
                    ),
                    _MetricChip(
                      icon: Icons.timer_rounded,
                      label: 'Best ${challenge.bestTimeLabel}',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ProgressSection(challenge: challenge),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ChessVerseButton(
                        label: challenge.completedToday ? 'Review' : 'Play today',
                        icon: Icons.play_arrow_rounded,
                        onPressed: onPlay,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.info_outline_rounded),
                      tooltip: 'Challenge details',
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: completed
            ? AppColors.success.withValues(alpha: 0.16)
            : AppColors.accentGold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: completed ? AppColors.success : AppColors.accentGold,
        ),
      ),
      child: Text(
        completed ? 'Done' : 'New',
        style: TextStyle(
          color: completed ? AppColors.success : AppColors.accentGold,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AppColors.accentGold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.challenge});

  final DailyChallengeUiState challenge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              'Progress',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              challenge.progressLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: challenge.progress,
            backgroundColor: AppColors.backgroundDeep.withValues(alpha: 0.55),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
          ),
        ),
      ],
    );
  }
}
