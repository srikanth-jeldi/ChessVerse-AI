import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';

class PuzzlesScreen extends StatelessWidget {
  const PuzzlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReferenceScaffold(
      title: 'Puzzles',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const <Widget>[
          _FeatureHero(
            icon: Icons.extension_rounded,
            title: 'Daily Puzzle',
            subtitle: 'Solve puzzle and improve your skills',
            action: 'Solve',
          ),
          SizedBox(height: 18),
          _SectionTitle('Puzzle Categories'),
          _ProgressTile(label: 'Easy', value: '0/150', color: AppColors.success),
          _ProgressTile(label: 'Medium', value: '0/150', color: AppColors.accentGold),
          _ProgressTile(label: 'Hard', value: '0/150', color: AppColors.warning),
        ],
      ),
    );
  }
}

class SavedGamesScreen extends StatelessWidget {
  const SavedGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const List<_SavedGame> games = <_SavedGame>[
      _SavedGame('vs AI (Medium)', 'You won', 'Today, 10:30 AM', AppColors.success),
      _SavedGame('vs AI (Easy)', 'You won', 'Today, 09:15 AM', AppColors.success),
      _SavedGame('vs Player', 'You lost', 'Yesterday, 08:45 PM', AppColors.danger),
      _SavedGame('vs AI (Hard)', 'Draw', 'Yesterday, 07:10 PM', AppColors.accentGold),
    ];

    return _ReferenceScaffold(
      title: 'My Games',
      child: Column(
        children: <Widget>[
          const _SegmentTabs(labels: <String>['All', 'White', 'Black']),
          const SizedBox(height: 16),
          ...games.map((_SavedGame game) => _SavedGameTile(game: game)),
        ],
      ),
    );
  }
}

class GameOptionsScreen extends StatelessWidget {
  const GameOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReferenceScaffold(
      title: 'Game Options',
      child: Column(
        children: const <Widget>[
          _SwitchOption(label: 'Flip Board', enabled: true),
          _MenuOption(label: 'Board Theme', value: 'Walnut'),
          _MenuOption(label: 'Piece Theme', value: 'Staunton 3D'),
          _SwitchOption(label: 'Sound', enabled: true),
          _SwitchOption(label: 'Show Coordinates', enabled: true),
          _SwitchOption(label: 'Move Hints', enabled: false),
          _SwitchOption(label: 'Best Move Trail', enabled: true),
          SizedBox(height: 26),
          _DangerButton(label: 'Resign'),
        ],
      ),
    );
  }
}

class MoveHistoryScreen extends StatelessWidget {
  const MoveHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const List<(String, String)> moves = <(String, String)>[
      ('e4', 'e5'),
      ('Nf3', 'Nc6'),
      ('Bc4', 'Nf6'),
      ('Ng5', 'd5'),
      ('exd5', 'Na5'),
      ('Bb5+', 'c6'),
      ('dxc6', 'bxc6'),
      ('Qf3', 'Be7'),
    ];

    return _ReferenceScaffold(
      title: 'Move History',
      child: Column(
        children: <Widget>[
          const Row(
            children: <Widget>[
              SizedBox(width: 36),
              Expanded(child: Text('White', textAlign: TextAlign.center)),
              Expanded(child: Text('Black', textAlign: TextAlign.center)),
            ],
          ),
          const Divider(),
          ...List<Widget>.generate(moves.length, (int index) {
            final (String white, String black) = moves[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: <Widget>[
                  SizedBox(width: 36, child: Text('${index + 1}.')),
                  Expanded(child: Text(white, textAlign: TextAlign.center)),
                  Expanded(child: Text(black, textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          FilledButton(onPressed: null, child: Text('Close')),
        ],
      ),
    );
  }
}

class GameResultScreen extends StatelessWidget {
  const GameResultScreen({this.draw = false, super.key});

  final bool draw;

  @override
  Widget build(BuildContext context) {
    return _ReferenceScaffold(
      title: draw ? 'Game Over' : 'Game Result',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Icon(
            draw ? Icons.workspace_premium_rounded : Icons.emoji_events_rounded,
            color: draw ? AppColors.textSecondary : AppColors.accentGold,
            size: 72,
          ),
          const SizedBox(height: 12),
          Text(
            draw ? 'Draw!' : 'You Win!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: draw ? AppColors.textPrimary : AppColors.accentGold,
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            draw ? 'by Stalemate' : 'by Checkmate',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          _ScoreCard(score: draw ? '½ - ½' : '1 - 0'),
          const SizedBox(height: 18),
          const _ResultMetric(label: 'Moves', value: '18'),
          const _ResultMetric(label: 'Accuracy', value: '92.4%'),
          const _ResultMetric(label: 'Best Move (%)', value: '87.1%'),
          const _ResultMetric(label: 'Time Taken', value: '07:23'),
          const SizedBox(height: 24),
          FilledButton(onPressed: null, child: Text('New Game')),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: null, child: Text('Back to Home')),
        ],
      ),
    );
  }
}

class _ReferenceScaffold extends StatelessWidget {
  const _ReferenceScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ChessVerseCard(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureHero extends StatelessWidget {
  const _FeatureHero({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String action;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.accentGold, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            FilledButton(onPressed: null, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return _MenuSurface(
      child: Row(
        children: <Widget>[
          Icon(Icons.extension_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SwitchOption extends StatelessWidget {
  const _SwitchOption({required this.label, required this.enabled});
  final String label;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    return _MenuSurface(
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Switch(value: enabled, onChanged: null),
        ],
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  const _MenuOption({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return _MenuSurface(
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _MenuSurface extends StatelessWidget {
  const _MenuSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: null,
      child: Text(label, style: const TextStyle(color: AppColors.danger)),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({required this.labels});
  final List<String> labels;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels
          .map(
            (String label) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: label == labels.first ? AppColors.primary : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(label, textAlign: TextAlign.center),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SavedGame {
  const _SavedGame(this.title, this.result, this.time, this.color);
  final String title;
  final String result;
  final String time;
  final Color color;
}

class _SavedGameTile extends StatelessWidget {
  const _SavedGameTile({required this.game});
  final _SavedGame game;
  @override
  Widget build(BuildContext context) {
    return _MenuSurface(
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/branding/app_icon.png',
              width: 54,
              height: 54,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(game.title, style: Theme.of(context).textTheme.titleMedium),
                Text(game.result, style: TextStyle(color: game.color)),
                Text(game.time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});
  final String score;
  @override
  Widget build(BuildContext context) {
    return _MenuSurface(
      child: Row(
        children: <Widget>[
          const CircleAvatar(child: Text('You')),
          Expanded(
            child: Text(
              score,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const CircleAvatar(child: Text('AI')),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
