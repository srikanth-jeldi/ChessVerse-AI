import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/desktop_navigation_shell.dart';
import 'daily_navigation_menu.dart';
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
  const DailyStreakScreen({
    super.key,
    required this.onPractice,
    this.onOpenChallenge,
    this.onOpenPuzzles,
  });

  final VoidCallback onPractice;
  final VoidCallback? onOpenChallenge;
  final VoidCallback? onOpenPuzzles;

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
  Widget build(BuildContext context) => DesktopNavigationShell(
    selected: uiText(context, 'Puzzles'),
    child: _buildPage(),
  );

  Widget _buildPage() => Scaffold(
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
            final Widget summary = _TodayChallenge(
              streak: streak,
              bestStreak: LocalGameArchive.bestDailyStreak,
              completedToday: completedToday,
              onPractice: widget.onPractice,
            );
            final Widget progress = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DailyPuzzleStreak(
                  streak: streak,
                  completedToday: completedToday,
                ),
                const SizedBox(height: 14),
                _WeeklyProgress(
                  completedDays: completedDays,
                  todayUtc: todayUtc,
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
                          DailyNavigationMenu(
                            onOpenChallenge: widget.onOpenChallenge,
                            onOpenPuzzles: widget.onOpenPuzzles,
                          ),
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
    required this.streak,
    required this.bestStreak,
    required this.completedToday,
    required this.onPractice,
  });

  final int streak;
  final int bestStreak;
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
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold.withValues(alpha: .48)),
              ),
              child: const Icon(
                Icons.monetization_on_rounded,
                color: _gold,
                size: 34,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  UiText(
                    completedToday
                        ? streak > 0
                              ? 'Coins earned'
                              : 'Challenge complete'
                        : 'Today’s coin reward',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!completedToday || streak > 0)
                    UiText(
                      '+{0} coins',
                      values: [
                        dailyPuzzleRewardCoins(
                          completedToday ? streak : streak + 1,
                        ),
                      ],
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  const SizedBox(height: 3),
                  UiText(
                    completedToday
                        ? 'Daily challenge completed. You can review it here.'
                        : 'Solve today’s puzzle to collect your reward.',
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
        const Divider(height: 24, color: AppColors.border),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            UiText('{0} day streak', values: [streak]),
            UiText(
              'Best: {0} days',
              values: [bestStreak],
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    ),
  );
}
