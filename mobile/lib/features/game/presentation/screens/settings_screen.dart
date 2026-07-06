import 'package:flutter/material.dart';

import '../../../../core/theme/chessverse_theme.dart';
import '../widgets/primary_panel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sound = true;
  bool _legalMoves = true;
  bool _autoQueen = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            PrimaryPanel(
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    value: _sound,
                    title: const Text('Sound'),
                    subtitle: const Text('Check/game feedback sounds'),
                    onChanged: (bool value) => setState(() => _sound = value),
                  ),
                  SwitchListTile(
                    value: _legalMoves,
                    title: const Text('Legal move highlights'),
                    subtitle: const Text('Keep this ON for beginners'),
                    onChanged: (bool value) => setState(() => _legalMoves = value),
                  ),
                  SwitchListTile(
                    value: _autoQueen,
                    title: const Text('Auto queen promotion'),
                    subtitle: const Text('Milestone 1 uses auto queen for speed'),
                    onChanged: (bool value) => setState(() => _autoQueen = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const PrimaryPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  SizedBox(height: 8),
                  Text('Guest User', style: TextStyle(color: ChessVerseColors.muted)),
                  SizedBox(height: 8),
                  Text('Login will be connected after core gameplay QA is stable. Don’t mix auth bugs with chess-rule bugs.', style: TextStyle(color: ChessVerseColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
