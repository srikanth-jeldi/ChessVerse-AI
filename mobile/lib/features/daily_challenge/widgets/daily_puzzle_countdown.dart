import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';

class DailyPuzzleCountdown extends StatefulWidget {
  const DailyPuzzleCountdown({super.key, required this.completed});

  final bool completed;

  @override
  State<DailyPuzzleCountdown> createState() => _DailyPuzzleCountdownState();
}

class _DailyPuzzleCountdownState extends State<DailyPuzzleCountdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int seconds =
        (dailyPuzzleTimeRemaining(DateTime.now()).inMilliseconds + 999) ~/ 1000;
    final String hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final String minutes = (seconds ~/ 60 % 60).toString().padLeft(2, '0');
    final String remainder = (seconds % 60).toString().padLeft(2, '0');
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: <Widget>[
        const Icon(
          Icons.schedule_rounded,
          color: AppColors.accentGold,
          size: 18,
        ),
        UiText(
          widget.completed ? 'Next puzzle in' : 'Time left today',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        Text(
          '$hours:$minutes:$remainder',
          style: const TextStyle(
            color: AppColors.accentGold,
            fontWeight: FontWeight.w900,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
