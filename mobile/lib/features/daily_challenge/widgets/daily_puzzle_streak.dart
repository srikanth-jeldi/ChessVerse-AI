import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../../core/local_game_archive.dart';

const _gold = Color(0xFFFFD56B);
const _cyan = Color(0xFF6DD8FF);

BoxDecoration _streakPanel({bool gold = false}) => BoxDecoration(
  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: gold ? const [Color(0xFF453210), Color(0xFF111A27)]
        : const [Color(0xFF163D58), Color(0xFF101C34)]),
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: gold ? _gold : _cyan.withValues(alpha: .6), width: 1.3),
  boxShadow: [BoxShadow(color: (gold ? _gold : _cyan).withValues(alpha: .16), blurRadius: 14)],
);

/// This is the reward schedule. Wallet credits are confirmed separately.
class DailyPuzzleStreak extends StatelessWidget {
  const DailyPuzzleStreak({super.key, required this.streak, required this.completedToday});
  final int streak;
  final bool completedToday;

  @override
  Widget build(BuildContext context) {
    final day = streak <= 0 ? 1 : completedToday ? (streak - 1) % 7 + 1 : streak % 7 + 1;
    final completedDays = completedToday ? day : day - 1;
    return LayoutBuilder(builder: (context, constraints) {
      final columns = MediaQuery.textScalerOf(context).scale(16) > 23 || constraints.maxWidth < 300 ? 2 : 4;
      final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
      return Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
        for (var i = 1; i <= 7; i++)
          SizedBox(width: width, child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            decoration: _streakPanel(gold: i == day),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$i', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 4),
              const Icon(Icons.monetization_on_rounded, color: _gold, size: 24),
              const SizedBox(height: 3),
              Text('+${dailyPuzzleRewardCoins(i)}', style: const TextStyle(
                color: _gold, fontSize: 16, fontWeight: FontWeight.w900)),
              if (i <= completedDays) const Icon(Icons.check_circle, size: 17, color: Color(0xFF64E4BD)),
            ]),
          )),
      ]);
    });
  }
}

class DailyStreakScreen extends StatelessWidget {
  const DailyStreakScreen({super.key, required this.onPractice});
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF031222),
    body: DecoratedBox(
      decoration: const BoxDecoration(image: DecorationImage(
        image: AssetImage('assets/backgrounds/daily-challenge-card-v2.webp'),
        fit: BoxFit.cover, colorFilter: ColorFilter.mode(Color(0xD9001023), BlendMode.srcOver))),
      child: SafeArea(child: ValueListenableBuilder<int>(
        valueListenable: LocalGameArchive.activityRevision,
        builder: (context, _, child) {
          final streak = LocalGameArchive.stats().dailyStreak;
          final done = LocalGameArchive.isDailyChallengeLocked;
          final day = done && streak > 0 ? (streak - 1) % 7 + 1 : streak % 7;
          final nextDay = streak % 7 + 1;
          return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), children: [
              Row(children: [
                const BackButton(color: _gold),
                Expanded(child: Column(children: [
                  UiText('Daily Streak', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: _gold, fontWeight: FontWeight.w900)),
                ])),
                const SizedBox(width: 48),
              ]),
              const SizedBox(height: 3),
              LayoutBuilder(builder: (context, constraints) {
                final height = (constraints.maxWidth * .29).clamp(82.0, 118.0);
                return SizedBox(height: height, child: Stack(alignment: Alignment.center, children: [
                  Positioned(left: 0, bottom: 12, width: constraints.maxWidth * .22, height: height * .65,
                    child: Image.asset('assets/pieces/staunton_white_knight.png', fit: BoxFit.contain)),
                  Positioned(right: 0, bottom: 12, width: constraints.maxWidth * .22, height: height * .65,
                    child: Image.asset('assets/pieces/staunton_black_knight.png', fit: BoxFit.contain)),
                  Image.asset('assets/badges/streak-flame-v1.webp', width: height, height: height),
                  Container(width: height * .42, height: height * .42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF171208),
                      border: Border.all(color: _gold, width: 2),
                      boxShadow: const [BoxShadow(color: Color(0xAAFF9800), blurRadius: 22)]),
                    child: Padding(padding: const EdgeInsets.all(8), child: FittedBox(
                      child: Text('$streak', style: const TextStyle(color: _gold, fontSize: 72, fontWeight: FontWeight.w900))))),
                ]));
              }),
              const UiText('Build your streak with today’s challenge', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.all(8), decoration: _streakPanel(), child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    const Icon(Icons.calendar_month, color: _gold),
                    const SizedBox(width: 10),
                    const Expanded(child: UiText('Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                    Text('$day / 7', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 9),
                  Row(children: [
                    for (var i = 1; i <= 7; i++) ...[
                      if (i > 1) Expanded(child: Container(height: 2, color: i <= day ? _gold : const Color(0xFF446177))),
                      CircleAvatar(radius: 9, backgroundColor: i <= day ? _gold : const Color(0xFF29475D),
                        child: i <= day ? const Icon(Icons.check, size: 15, color: Color(0xFF10202C)) : null),
                    ],
                  ]),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 5), child: Divider(color: Color(0xFF436478))),
                  Row(children: [
                    const Icon(Icons.monetization_on, color: _gold, size: 26),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const UiText('Next'),
                      Text('+${dailyPuzzleRewardCoins(nextDay)}', style: const TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.w900)),
                    ])),
                    if (done) const Flexible(child: UiText('Completed', style: TextStyle(color: Color(0xFF64E4BD)))),
                  ]),
                ])),
              const SizedBox(height: 6),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.local_fire_department, color: _gold),
                SizedBox(width: 8),
                Flexible(child: UiText('Daily Streak', style: TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 8),
              DailyPuzzleStreak(streak: streak, completedToday: done),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(12), decoration: _streakPanel(gold: true),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Image.asset('assets/pieces/staunton_white_knight.png', width: 36, height: 40),
                    const SizedBox(width: 12),
                    Expanded(child: UiText(done ? 'Completed' : 'Today’s tactical challenge',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  ]),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: const Color(0xFF111820),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                    onPressed: onPractice, icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: const UiText('Daily Puzzle', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
                ])),
            ])));
        },
      )),
    ),
  );
}
