import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../widgets/daily_puzzle_countdown.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({
    required this.onPlay,
    required this.onOpenStreak,
    super.key,
  });

  final VoidCallback onPlay;
  final VoidCallback onOpenStreak;

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  late final Timer _clock;
  DateTime _day = dailyPuzzleDay(DateTime.now());

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      final DateTime day = dailyPuzzleDay(DateTime.now());
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
    ),
    body: SafeArea(
      child: ValueListenableBuilder<int>(
        valueListenable: LocalGameArchive.activityRevision,
        builder: (context, _, _) {
          final DateTime now = DateTime.now();
          final bool completed = LocalGameArchive.isDailyChallengeLockedAt(now);
          final int streak = LocalGameArchive.dailyStreakAt(now);
          final int reward = dailyPuzzleRewardCoins(
            completed ? streak : streak + 1,
          );
          final Widget challenge = _ChallengeHero(
            completed: completed,
            reward: reward,
            onPlay: widget.onPlay,
          );
          final Widget progress = ChessVerseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Image.asset(
                      'assets/badges/streak-flame-v1.webp',
                      width: 58,
                      height: 58,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: UiText(
                        '{0} day streak',
                        values: <Object>[streak],
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: widget.onOpenStreak,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const UiText('View Daily Streak'),
                ),
              ],
            ),
          );
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    if (constraints.maxWidth >= 760)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 2, child: challenge),
                          const SizedBox(width: 16),
                          Expanded(child: progress),
                        ],
                      )
                    else ...<Widget>[
                      challenge,
                      const SizedBox(height: 14),
                      progress,
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _ChallengeHero extends StatelessWidget {
  const _ChallengeHero({
    required this.completed,
    required this.reward,
    required this.onPlay,
  });

  final bool completed;
  final int reward;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => ChessVerseCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SizedBox(
            height: 166,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(
                  'assets/backgrounds/daily-challenge-card-v2.webp',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, .36),
                  excludeFromSemantics: true,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Colors.transparent, Color(0xED071A2C)],
                      stops: <double>[.35, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: UiText(
                      completed ? 'Challenge complete' : 'Today’s puzzle',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DailyPuzzleCountdown(completed: completed),
              const SizedBox(height: 8),
              UiText(
                completed
                    ? 'You earned {0} coins today.'
                    : 'Solve today’s puzzle to earn {0} coins.',
                values: <Object>[reward],
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              ChessVerseButton(
                label: completed
                    ? 'View today’s challenge'
                    : 'Play Daily Challenge',
                icon: completed
                    ? Icons.visibility_rounded
                    : Icons.play_arrow_rounded,
                onPressed: onPlay,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
