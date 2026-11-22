import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';

enum _DailyMenuItem { challenge, streak, puzzles, rules }

class DailyNavigationMenu extends StatelessWidget {
  const DailyNavigationMenu({
    super.key,
    this.onOpenChallenge,
    this.onOpenStreak,
    this.onOpenPuzzles,
  });

  final VoidCallback? onOpenChallenge;
  final VoidCallback? onOpenStreak;
  final VoidCallback? onOpenPuzzles;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_DailyMenuItem>(
    tooltip: uiText(context, 'Daily menu'),
    icon: const Icon(Icons.menu_rounded),
    position: PopupMenuPosition.under,
    onSelected: (item) {
      switch (item) {
        case _DailyMenuItem.challenge:
          onOpenChallenge?.call();
        case _DailyMenuItem.streak:
          onOpenStreak?.call();
        case _DailyMenuItem.puzzles:
          onOpenPuzzles?.call();
        case _DailyMenuItem.rules:
          _showRules(context);
      }
    },
    itemBuilder: (_) => [
      _item(
        _DailyMenuItem.challenge,
        Icons.extension_rounded,
        'Daily Challenge',
        enabled: onOpenChallenge != null,
      ),
      _item(
        _DailyMenuItem.streak,
        Icons.local_fire_department_rounded,
        'Daily Streak',
        enabled: onOpenStreak != null,
      ),
      _item(
        _DailyMenuItem.puzzles,
        Icons.school_rounded,
        'Puzzle Academy',
        enabled: onOpenPuzzles != null,
      ),
      _item(
        _DailyMenuItem.rules,
        Icons.info_outline_rounded,
        'How Daily Challenge works',
      ),
    ],
  );

  PopupMenuItem<_DailyMenuItem> _item(
    _DailyMenuItem item,
    IconData icon,
    String label, {
    bool enabled = true,
  }) => PopupMenuItem<_DailyMenuItem>(
    value: item,
    enabled: enabled,
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Flexible(child: UiText(label)),
      ],
    ),
  );

  void _showRules(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const UiText('How Daily Challenge works'),
        content: const UiText(
          'Your 24 hours begin when you first open the puzzle board. '
          'Solve the puzzle to earn coins and extend your streak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const UiText('Done'),
          ),
        ],
      ),
    );
  }
}
