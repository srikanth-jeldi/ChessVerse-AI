import 'package:flutter/material.dart';

import '../../../../core/theme/chessverse_theme.dart';
import '../widgets/primary_panel.dart';
import 'game_mode_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChessVerse AI'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const Text('Hello, Guest', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Start with offline playable chess. Login and online mode can come after core game is stable.', style: TextStyle(color: ChessVerseColors.muted)),
            const SizedBox(height: 24),
            PrimaryPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Milestone 1', style: TextStyle(color: ChessVerseColors.gold, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Core Game Flow', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Legal moves, AI reply, check, checkmate, stalemate, castling, en passant and pawn promotion.'),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play Chess'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const GameModeScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _HomeAction(title: 'Analyze Game', subtitle: 'Coming after stable PGN/move history.', enabled: false),
            const SizedBox(height: 12),
            _HomeAction(title: 'Learn Chess', subtitle: 'Coming after Milestone 1 gameplay QA.', enabled: false),
          ],
        ),
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({required this.title, required this.subtitle, required this.enabled});

  final String title;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.52,
      child: PrimaryPanel(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: ChessVerseColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.lock_clock_rounded),
          ],
        ),
      ),
    );
  }
}
