import 'package:flutter/material.dart';

import '../../../../core/theme/chessverse_theme.dart';
import '../../application/game_controller.dart';
import '../widgets/primary_panel.dart';
import 'chess_board_screen.dart';

class GameModeScreen extends StatefulWidget {
  const GameModeScreen({super.key});

  @override
  State<GameModeScreen> createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen> {
  ChessGameMode _mode = ChessGameMode.ai;
  AiDifficulty _difficulty = AiDifficulty.medium;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Game Mode')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            PrimaryPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Choose Opponent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  _ModeTile(
                    title: 'Play vs AI',
                    subtitle: 'Offline AI fallback. Best for APK testing.',
                    selected: _mode == ChessGameMode.ai,
                    onTap: () => setState(() => _mode = ChessGameMode.ai),
                  ),
                  const SizedBox(height: 10),
                  _ModeTile(
                    title: 'Local 2 Player',
                    subtitle: 'Both players use same mobile.',
                    selected: _mode == ChessGameMode.local,
                    onTap: () => setState(() => _mode = ChessGameMode.local),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('AI Difficulty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  SegmentedButton<AiDifficulty>(
                    segments: AiDifficulty.values
                        .map((AiDifficulty difficulty) => ButtonSegment<AiDifficulty>(value: difficulty, label: Text(difficulty.label)))
                        .toList(),
                    selected: <AiDifficulty>{_difficulty},
                    onSelectionChanged: _mode == ChessGameMode.ai
                        ? (Set<AiDifficulty> value) => setState(() => _difficulty = value.first)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              child: const Text('Start Game'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChessBoardScreen(mode: _mode, difficulty: _difficulty),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.title, required this.subtitle, required this.selected, required this.onTap});

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? ChessVerseColors.gold.withValues(alpha: 0.16) : ChessVerseColors.panelSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? ChessVerseColors.gold : Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: <Widget>[
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, color: selected ? ChessVerseColors.gold : ChessVerseColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: ChessVerseColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
