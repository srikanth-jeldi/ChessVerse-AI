import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../widgets/daily_navigation_menu.dart';
import '../widgets/daily_puzzle_countdown.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({
    required this.onPlay,
    required this.onOpenStreak,
    required this.onOpenPuzzles,
    super.key,
  });

  final VoidCallback onPlay;
  final VoidCallback onOpenStreak;
  final VoidCallback onOpenPuzzles;

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  late final Timer _clock;
  DateTime _day = LocalGameArchive.dailyPuzzleDateForAttempt(DateTime.now());

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      final DateTime day = LocalGameArchive.dailyPuzzleDateForAttempt(
        DateTime.now(),
      );
      if (day != _day) setState(() => _day = day);
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDeep,
    appBar: AppBar(
      title: const UiText('Daily Challenge'),
      backgroundColor: AppColors.background,
      actions: <Widget>[
        DailyNavigationMenu(
          onOpenStreak: widget.onOpenStreak,
          onOpenPuzzles: widget.onOpenPuzzles,
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: ValueListenableBuilder<int>(
        valueListenable: LocalGameArchive.activityRevision,
        builder: (context, _, _) {
          final DateTime now = DateTime.now();
          final bool completed = LocalGameArchive.isDailyChallengeLockedAt(now);
          final int streak = LocalGameArchive.dailyStreakAt(now);
          return Align(
            alignment: MediaQuery.sizeOf(context).width < 600
                ? Alignment.topCenter
                : const Alignment(0, -.36),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 790),
                child: _ChallengeCard(
                  completed: completed,
                  streak: streak,
                  reward: dailyPuzzleRewardCoins(
                    completed ? streak : streak + 1,
                  ),
                  onPlay: widget.onPlay,
                  onOpenStreak: widget.onOpenStreak,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.completed,
    required this.streak,
    required this.reward,
    required this.onPlay,
    required this.onOpenStreak,
  });

  final bool completed;
  final int streak;
  final int reward;
  final VoidCallback onPlay;
  final VoidCallback onOpenStreak;

  @override
  Widget build(BuildContext context) => ChessVerseCard(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = constraints.maxWidth >= 520;
        final double artWidth = wide ? 204 : 104;
        final Widget play = ChessVerseButton(
          label: completed ? 'View today’s challenge' : 'Play Daily Challenge',
          icon: completed ? Icons.visibility_rounded : Icons.play_arrow_rounded,
          onPressed: onPlay,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  key: const ValueKey<String>('daily-challenge-artwork'),
                  width: artWidth,
                  height: artWidth * 1.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/backgrounds/daily-challenge-card-v2.webp',
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.extension_rounded,
                        color: AppColors.accentGold,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: wide ? 24 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      UiText(
                        completed ? 'Challenge complete' : 'Today’s puzzle',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: wide ? 29 : 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundDeep,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: DailyPuzzleCountdown(completed: completed),
                        ),
                      ),
                      const SizedBox(height: 10),
                      UiText(
                        completed
                            ? 'You earned {0} coins today.'
                            : 'Solve today’s puzzle to earn {0} coins.',
                        values: <Object>[reward],
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (wide) ...<Widget>[const SizedBox(height: 16), play],
                    ],
                  ),
                ),
              ],
            ),
            if (!wide) ...<Widget>[const SizedBox(height: 14), play],
            const Divider(height: 30, color: AppColors.border),
            Row(
              children: <Widget>[
                Image.asset(
                  'assets/badges/streak-flame-v1.webp',
                  width: 37,
                  height: 37,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: UiText(
                    '{0} day streak',
                    values: <Object>[streak],
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: OutlinedButton(
                    onPressed: onOpenStreak,
                    child: const UiText(
                      'View Daily Streak',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
