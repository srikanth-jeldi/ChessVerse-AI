import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../domain/daily_challenge_models.dart';

class DailyChallengeResultSheet extends StatelessWidget {
  const DailyChallengeResultSheet({
    required this.challenge,
    this.solved = true,
    this.onReview,
    this.onShare,
    super.key,
  });

  final DailyChallengeUiState challenge;
  final bool solved;
  final VoidCallback? onReview;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return ChessVerseCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: solved ? AppColors.goldGradient : null,
              color: solved ? null : AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              solved ? Icons.emoji_events_rounded : Icons.refresh_rounded,
              color: solved ? AppColors.backgroundDeep : AppColors.textSecondary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            solved ? 'Challenge solved' : 'Keep calculating',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            solved
                ? 'You completed today\'s ${challenge.difficulty.title.toLowerCase()} puzzle and protected your ${challenge.streakDays} day streak.'
                : 'One wrong move is enough in chess. Review the position and try again.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundDeep.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: <Widget>[
                _ResultRow(label: 'Difficulty', value: challenge.difficulty.title),
                const SizedBox(height: 10),
                _ResultRow(label: 'Moves', value: challenge.progressLabel),
                const SizedBox(height: 10),
                _ResultRow(label: 'Best time', value: challenge.bestTimeLabel),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: ChessVerseButton(
                  label: solved ? 'Share result' : 'Try again',
                  icon: solved ? Icons.ios_share_rounded : Icons.refresh_rounded,
                  onPressed: solved ? onShare : onReview,
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: onReview,
                icon: const Icon(Icons.visibility_rounded),
                tooltip: 'Review board',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
