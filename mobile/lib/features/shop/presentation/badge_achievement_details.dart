import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../data/shop_api.dart';

const badgeRequirements = <String, String>{
  'academy-scout': 'Complete your first Academy lesson.',
  'puzzle-hunter': 'Complete 25 different puzzles.',
  'tactical-eye': 'Complete 20 different medium or hard puzzles.',
  'opening-sage': 'Complete 5 different opening lessons.',
  'streak-flame': 'Complete daily challenges on 7 consecutive days.',
  'checkmate-crown': 'Win 10 online games by checkmate.',
};

class BadgeAchievementDetails extends StatelessWidget {
  const BadgeAchievementDetails({required this.item, super.key});
  final CosmeticItemDto item;
  @override
  Widget build(BuildContext context) {
    final progress = item.achievement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(
          progress == null
              ? 'Decorative profile badge. No extra coins or playing advantage.'
              : badgeRequirements[item.slug] ??
                    'Complete the achievement to earn this badge.',
          style: const TextStyle(color: Color(0xFFB9D7E8), fontSize: 14),
        ),
        if (progress != null) ...[
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress.earned
                ? 1
                : (progress.current /
                          (progress.target > 0 ? progress.target : 1))
                      .clamp(0.0, 1.0),
          ),
          const SizedBox(height: 8),
          UiText(
            progress.earned ? 'Achievement earned' : 'Progress: {0} / {1}',
            values: [progress.current, progress.target],
            style: const TextStyle(color: Color(0xFF5DE9D3)),
          ),
          if (item.owned && !progress.earned)
            const UiText(
              'Previously owned. You can still equip it; achievement progress is separate.',
              style: TextStyle(color: Color(0xFFB9D7E8)),
            ),
        ],
        const SizedBox(height: 8),
        const UiText(
          'Equip one badge on your profile. Badges do not change your rating.',
          style: TextStyle(color: Color(0xFF9FB6C8), fontSize: 12),
        ),
      ],
    );
  }
}
