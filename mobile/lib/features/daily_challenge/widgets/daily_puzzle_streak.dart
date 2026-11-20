import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import 'daily_puzzle_countdown.dart';

const Color _gold = AppColors.accentGold;
const Color _teal = AppColors.accentTeal;

BoxDecoration _panel({bool highlighted = false}) => BoxDecoration(
  color: AppColors.surface,
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: highlighted
        ? const <Color>[Color(0xFF173749), Color(0xFF0C2435)]
        : const <Color>[Color(0xFF10283A), Color(0xFF0A1C2B)],
  ),
  borderRadius: BorderRadius.circular(20),
  border: Border.all(
    color: highlighted ? _gold.withValues(alpha: .78) : AppColors.border,
    width: highlighted ? 1.4 : 1,
  ),
  boxShadow: <BoxShadow>[
    BoxShadow(
      color: (highlighted ? _gold : _teal).withValues(alpha: .08),
      blurRadius: 18,
      offset: const Offset(0, 7),
    ),
  ],
);

/// Reward schedule preview. Coins are credited by the daily challenge flow.
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
    final int earnedDay = streak <= 0 ? 0 : (streak - 1) % 7 + 1;
    final int nextDay = earnedDay == 7 ? 1 : earnedDay + 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: _panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.workspace_premium_rounded,
                color: _gold,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: UiText(
                  'Streak rewards',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '$earnedDay / 7',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List<Widget>.generate(7, (int index) {
              final int day = index + 1;
              final bool earned = day <= earnedDay;
              final bool next = day == nextDay && !earned;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 6 ? 0 : 4),
                  child: Semantics(
                    label:
                        'Day $day, ${dailyPuzzleRewardCoins(day)} coins'
                        '${earned
                            ? ', earned'
                            : next
                            ? ', next reward'
                            : ''}',
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 86),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        color: earned
                            ? const Color(0xFF123C3B)
                            : next
                            ? const Color(0xFF392E19)
                            : AppColors.backgroundDeep.withValues(alpha: .42),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: earned
                              ? _teal.withValues(alpha: .85)
                              : next
                              ? _gold
                              : AppColors.border.withValues(alpha: .72),
                          width: next ? 1.4 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: earned || next
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: _gold,
                            size: 16,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '+${dailyPuzzleRewardCoins(day)}',
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Icon(
                            earned
                                ? Icons.check_circle_rounded
                                : next
                                ? Icons.arrow_upward_rounded
                                : Icons.circle_outlined,
                            size: 13,
                            color: earned
                                ? _teal
                                : next
                                ? _gold
                                : AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 9),
          UiText(
            completedToday
                ? 'You’ve collected today’s reward. Keep your streak going tomorrow.'
                : 'Complete today’s challenge to earn +{0} coins.',
            values: completedToday
                ? const <Object>[]
                : <Object>[dailyPuzzleRewardCoins(nextDay)],
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class DailyStreakScreen extends StatefulWidget {
  const DailyStreakScreen({super.key, required this.onPractice});

  final VoidCallback onPractice;

  @override
  State<DailyStreakScreen> createState() => _DailyStreakScreenState();
}

class _DailyStreakScreenState extends State<DailyStreakScreen> {
  Timer? _clock;
  DateTime _displayDay = LocalGameArchive.dailyPuzzleDateForAttempt(
    DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final DateTime now = DateTime.now();
      final DateTime day = LocalGameArchive.dailyPuzzleDateForAttempt(now);
      if (day != _displayDay) {
        setState(() => _displayDay = day);
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDeep,
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppColors.background, AppColors.backgroundDeep],
        ),
      ),
      child: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: LocalGameArchive.activityRevision,
          builder: (BuildContext context, int _, Widget? child) {
            final DateTime now = DateTime.now();
            final int streak = LocalGameArchive.dailyStreakAt(now);
            final bool completedToday =
                LocalGameArchive.isDailyChallengeLockedAt(now);
            final DateTime todayUtc = dailyPuzzleDay(now);
            final Set<DateTime> completedDays =
                LocalGameArchive.completedDailyChallengeDaysThisWeek(todayUtc);
            final Widget summary = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _StreakHero(
                  streak: streak,
                  bestStreak: LocalGameArchive.bestDailyStreak,
                  completedToday: completedToday,
                ),
                const SizedBox(height: 14),
                _TodayChallenge(
                  completedToday: completedToday,
                  onPractice: widget.onPractice,
                ),
              ],
            );
            final Widget progress = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _WeeklyProgress(
                  completedDays: completedDays,
                  todayUtc: todayUtc,
                ),
                const SizedBox(height: 14),
                DailyPuzzleStreak(
                  streak: streak,
                  completedToday: completedToday,
                ),
              ],
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: LayoutBuilder(
                  builder: (context, constraints) => ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const BackButton(color: _gold),
                          const Expanded(
                            child: UiText(
                              'Daily Streak',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (constraints.maxWidth >= 820)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: summary),
                            const SizedBox(width: 16),
                            Expanded(child: progress),
                          ],
                        )
                      else ...<Widget>[
                        summary,
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
    ),
  );
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({
    required this.streak,
    required this.bestStreak,
    required this.completedToday,
  });

  final int streak;
  final int bestStreak;
  final bool completedToday;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
    decoration: _panel(highlighted: true),
    child: Row(
      children: <Widget>[
        Image.asset(
          'assets/badges/streak-flame-v1.webp',
          width: 86,
          height: 86,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => const Icon(
            Icons.local_fire_department_rounded,
            size: 62,
            color: _gold,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UiText(
                streak == 0 ? 'Start your streak today' : '{0} day streak',
                values: <Object?>[streak],
                style: const TextStyle(
                  color: _gold,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              UiText(
                'Best: {0} days',
                values: <Object?>[bestStreak],
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              UiText(
                completedToday
                    ? 'Great work. Your streak is safe for today.'
                    : streak == 0
                    ? 'Play today to start a new streak.'
                    : 'Play today to keep your streak alive.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (completedToday ? _teal : _gold).withValues(
                    alpha: .12,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: (completedToday ? _teal : _gold).withValues(
                      alpha: .55,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      completedToday
                          ? Icons.check_circle_rounded
                          : Icons.bolt_rounded,
                      size: 15,
                      color: completedToday ? _teal : _gold,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: UiText(
                        completedToday
                            ? 'Completed today'
                            : 'Today’s challenge is ready',
                        style: TextStyle(
                          color: completedToday ? _teal : _gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WeeklyProgress extends StatelessWidget {
  const _WeeklyProgress({required this.completedDays, required this.todayUtc});

  final Set<DateTime> completedDays;
  final DateTime todayUtc;

  @override
  Widget build(BuildContext context) {
    final List<String> narrow = MaterialLocalizations.of(context)
        .narrowWeekdays;
    final DateTime today = DateTime.utc(
      todayUtc.year,
      todayUtc.month,
      todayUtc.day,
    );
    final DateTime monday = today.subtract(Duration(days: today.weekday - 1));

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: _panel(),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.calendar_month_rounded, color: _gold, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: UiText(
                  'Weekly progress',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${completedDays.length} / 7',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(7, (int index) {
              final DateTime date = monday.add(Duration(days: index));
              final bool isToday = date == today;
              final bool done = completedDays.contains(date);
              final bool missed = date.isBefore(today) && !done;
              final int weekdayIndex = (index + 1) % 7;
              final String label = narrow[weekdayIndex];
              return Expanded(
                child: Semantics(
                  label:
                      '${MaterialLocalizations.of(context).formatFullDate(date)}'
                      '${isToday ? ', today' : ''}'
                      '${done
                          ? ', complete'
                          : missed
                          ? ', missed'
                          : ''}',
                  child: Column(
                    children: <Widget>[
                      Text(
                        label,
                        style: TextStyle(
                          color: isToday ? _gold : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: isToday
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? const Color(0xFF155148)
                              : AppColors.backgroundDeep.withValues(alpha: .48),
                          border: Border.all(
                            color: done
                                ? _teal
                                : isToday
                                ? _gold
                                : AppColors.border,
                            width: isToday ? 1.7 : 1,
                          ),
                          boxShadow: isToday && !done
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: _gold.withValues(alpha: .16),
                                    blurRadius: 12,
                                  ),
                                ]
                              : const <BoxShadow>[],
                        ),
                        child: Icon(
                          done
                              ? Icons.check_rounded
                              : missed
                              ? Icons.remove_rounded
                              : null,
                          color: done ? _teal : AppColors.textSecondary,
                          size: 19,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 13,
                        child: isToday
                            ? const UiText(
                                'Today',
                                style: TextStyle(
                                  color: _gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          const UiText(
            'Calendar days are shown in UTC.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TodayChallenge extends StatelessWidget {
  const _TodayChallenge({
    required this.completedToday,
    required this.onPractice,
  });

  final bool completedToday;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _panel(highlighted: true),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold.withValues(alpha: .48)),
              ),
              child: const Icon(
                Icons.extension_rounded,
                color: _gold,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const UiText(
                    'Today’s challenge',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  UiText(
                    completedToday
                        ? 'Daily challenge completed. You can review it here.'
                        : 'Complete today’s puzzle and protect your streak.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DailyPuzzleCountdown(completed: completedToday),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPractice,
            icon: Icon(
              completedToday
                  ? Icons.visibility_rounded
                  : Icons.play_arrow_rounded,
              size: 22,
            ),
            label: UiText(
              completedToday
                  ? 'View today’s challenge'
                  : 'Play Daily Challenge',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: AppColors.backgroundDeep,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
