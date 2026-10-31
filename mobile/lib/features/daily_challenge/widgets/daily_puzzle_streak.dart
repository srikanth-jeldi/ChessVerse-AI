import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../../core/local_game_archive.dart';

/// Reward schedule, not a wallet credit receipt. Credits are confirmed by sync.
class DailyPuzzleStreak extends StatelessWidget {
  const DailyPuzzleStreak({
    super.key,
    required this.streak,
    required this.completedToday,
  });
  final int streak;
  final bool completedToday;
  @override
  Widget build(BuildContext context) {
    final day = streak <= 0
        ? 1
        : completedToday
        ? (streak - 1) % 7 + 1
        : streak % 7 + 1;
    final completedDays = completedToday ? day : day - 1;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange),
              const UiText('Daily Streak'),
              Text('$streak'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 1; i <= 7; i++)
                Container(
                  constraints: const BoxConstraints(minWidth: 62),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF102C3B),
                    border: Border.all(
                      color: i == day
                          ? const Color(0xFF55DFCC)
                          : const Color(0xFF49606D),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$i'),
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFFE5B950),
                        size: 20,
                      ),
                      Text('+${dailyPuzzleRewardCoins(i)}'),
                      if (i <= completedDays)
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: Color(0xFF55DFCC),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
