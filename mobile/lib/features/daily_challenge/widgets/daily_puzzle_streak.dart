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

class DailyStreakScreen extends StatelessWidget {
  const DailyStreakScreen({super.key, required this.onPractice});
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Daily Streak')),
    body: SafeArea(child: ValueListenableBuilder<int>(
      valueListenable: LocalGameArchive.activityRevision,
      builder: (context, _, child) {
        final streak = LocalGameArchive.stats().dailyStreak;
        final done = LocalGameArchive.isDailyChallengeLocked;
        final day = done && streak > 0 ? (streak - 1) % 7 + 1 : streak % 7;
        final nextDay = (streak % 7) + 1;
        return ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding:const EdgeInsets.all(20), decoration: BoxDecoration(
            gradient:const LinearGradient(colors:[Color(0xFF163C46),Color(0xFF081629)]),
            borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFE7B54D))),
            child:Column(children:[
              const Icon(Icons.local_fire_department, size:58, color:Color(0xFFFFBB55)),
              Text('$streak',style:Theme.of(context).textTheme.displayMedium),
              const UiText('Daily Streak'),
              const SizedBox(height:12),
              const UiText('Build your streak with today’s challenge',textAlign:TextAlign.center),
            ])),
          const SizedBox(height:16),
          Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(
            crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              Row(children:[const Expanded(child:UiText('Progress')),Text('$day / 7')]),
              const SizedBox(height:10),LinearProgressIndicator(value:day / 7,minHeight:8),
              const SizedBox(height:10),
              Row(children:[const Expanded(child:UiText('Next')),const Icon(Icons.monetization_on,color:Color(0xFFE7B54D)),
                Text(' ${dailyPuzzleRewardCoins(nextDay)}')]),
            ]))),
          DailyPuzzleStreak(streak:streak,completedToday:done),
          Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(
            crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              Row(children:[Icon(done ? Icons.check_circle : Icons.extension,color:const Color(0xFF55DFCC)),
                const SizedBox(width:10),Expanded(child:UiText(done ? 'Completed' : 'Today’s tactical challenge'))]),
              const SizedBox(height:12),
              FilledButton.icon(onPressed:onPractice,icon:const Icon(Icons.play_arrow),label:const UiText('Daily Puzzle')),
            ]))),
        ]);
      },
    )),
  );
}
