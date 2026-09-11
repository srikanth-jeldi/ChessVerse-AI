import 'package:flutter/material.dart';

import '../../auth/data/auth_session_store.dart';
import '../data/puzzle_sprint_api.dart';
import '../domain/puzzle_sprint.dart';

class PuzzleSprintLeaderboardScreen extends StatefulWidget {
  const PuzzleSprintLeaderboardScreen({super.key});

  @override
  State<PuzzleSprintLeaderboardScreen> createState() =>
      _PuzzleSprintLeaderboardScreenState();
}

class _PuzzleSprintLeaderboardScreenState
    extends State<PuzzleSprintLeaderboardScreen> {
  final PuzzleSprintApi _api = const PuzzleSprintApi();
  PuzzleSprintMode _mode = PuzzleSprintMode.rush;
  List<PuzzleSprintResultDto> _leaders = const <PuzzleSprintResultDto>[];
  List<PuzzleSprintResultDto> _history = const <PuzzleSprintResultDto>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final session = await const AuthSessionStore().read();
    if (!mounted || session == null) return;
    try {
      final values = await Future.wait(<Future<List<PuzzleSprintResultDto>>>[
        _api.leaderboard(session.token, _mode),
        _api.history(session.token),
      ]);
      if (!mounted) return;
      setState(() {
        _leaders = values[0];
        _history = values[1];
        _loading = false;
      });
    } on Object {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF061524),
    appBar: AppBar(title: const Text('PUZZLE RUSH RECORDS')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 60),
            children: <Widget>[
              SegmentedButton<PuzzleSprintMode>(
                segments: const <ButtonSegment<PuzzleSprintMode>>[
                  ButtonSegment(
                    value: PuzzleSprintMode.rush,
                    label: Text('RUSH'),
                  ),
                  ButtonSegment(
                    value: PuzzleSprintMode.survival,
                    label: Text('SURVIVAL'),
                  ),
                  ButtonSegment(
                    value: PuzzleSprintMode.mateInOne,
                    label: Text('MATE 1'),
                  ),
                ],
                selected: <PuzzleSprintMode>{_mode},
                onSelectionChanged: (value) {
                  _mode = value.first;
                  _load();
                },
              ),
              const SizedBox(height: 24),
              const _SectionTitle('GLOBAL LEADERBOARD'),
              ..._leaders.asMap().entries.map(
                (entry) => _ResultTile(
                  result: entry.value,
                  leading: '#${entry.key + 1}',
                ),
              ),
              if (_leaders.isEmpty) const _Empty('No ranked sessions yet.'),
              const SizedBox(height: 28),
              const _SectionTitle('YOUR ACCOUNT HISTORY'),
              ..._history.map(
                (result) => _ResultTile(
                  result: result,
                  leading: result.mode.replaceAll('_', ' '),
                ),
              ),
              if (_history.isEmpty)
                const _Empty('Finish a sprint to create your first record.'),
            ],
          ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFFE2AE49),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result, required this.leading});
  final PuzzleSprintResultDto result;
  final String leading;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF0A2033),
    child: ListTile(
      leading: SizedBox(
        width: 72,
        child: Text(
          leading,
          style: const TextStyle(
            color: Color(0xFF63D2B8),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      title: Text(
        result.playerName,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${result.attempted} attempted • ${result.durationSeconds}s',
      ),
      trailing: Text(
        '${result.score}',
        style: const TextStyle(
          color: Color(0xFFE2AE49),
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFFAEC0D1)),
    ),
  );
}
