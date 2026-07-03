import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/daily_challenge_models.dart';

class DailyChallengeDifficultySelector extends StatelessWidget {
  const DailyChallengeDifficultySelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final DailyChallengeUiDifficulty selected;
  final ValueChanged<DailyChallengeUiDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: DailyChallengeUiDifficulty.values.map((DailyChallengeUiDifficulty difficulty) {
        final bool active = difficulty == selected;
        return ChoiceChip(
          selected: active,
          onSelected: (_) => onChanged(difficulty),
          label: Text('${difficulty.title} · ${difficulty.subtitle}'),
          avatar: Icon(
            active ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: active ? AppColors.backgroundDeep : AppColors.textMuted,
          ),
          labelStyle: TextStyle(
            color: active ? AppColors.backgroundDeep : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
          selectedColor: AppColors.accentGold,
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: active ? AppColors.accentGold : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }).toList(),
    );
  }
}
