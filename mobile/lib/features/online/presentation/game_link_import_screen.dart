import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../data/public_game_import.dart';

class GameLinkImportScreen extends StatefulWidget {
  const GameLinkImportScreen({super.key});
  @override
  State<GameLinkImportScreen> createState() => _GameLinkImportScreenState();
}

class _GameLinkImportScreenState extends State<GameLinkImportScreen> {
  final _link = TextEditingController(), _player = TextEditingController();
  final _api = PublicGameImport();
  DateTime _month = DateTime.now().toUtc();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _link.dispose();
    _player.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pgn = await _api.fetch(
        link: _link.text,
        username: _player.text,
        month: _month,
      );
      if (mounted) Navigator.pop(context, pgn);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : 'Could not download the game. Check your connection and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Import game link')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const UiText(
                  'Import a finished public game without copying PGN.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _link,
                  enabled: !_busy,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: uiText(context, 'Chess.com game URL'),
                  ),
                ),
                const SizedBox(height: 16),
                const UiText(
                  'Chess.com archives are organised by player and month. Enter either player’s username and the game month.',
                ),
                TextField(
                  controller: _player,
                  enabled: !_busy,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: uiText(context, 'Chess.com username'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _month,
                            firstDate: DateTime(2007),
                            lastDate: DateTime.now().toUtc(),
                          );
                          if (date != null && mounted) {
                            setState(() => _month = date);
                          }
                        },
                  child: Text(
                    '${UiCopy.text('Game month')}: ${_month.year}-${_month.month.toString().padLeft(2, '0')}',
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: UiText(_error!),
                  ),
                if (_busy) const LinearProgressIndicator(),
                FilledButton(
                  onPressed: _busy ? null : _import,
                  child: const UiText('Import Game'),
                ),
                const SizedBox(height: 16),
                const UiText(
                  'ChessVerseAI is not affiliated with or endorsed by Chess.com.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
