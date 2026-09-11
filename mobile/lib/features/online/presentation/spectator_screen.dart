import 'dart:async';

import 'package:flutter/material.dart';

import '../data/online_match_api.dart';

class SpectatorScreen extends StatefulWidget {
  const SpectatorScreen({
    required this.token,
    this.api = const OnlineMatchApi(),
    super.key,
  });

  final String token;
  final OnlineMatchApi api;

  @override
  State<SpectatorScreen> createState() => _SpectatorScreenState();
}

class _SpectatorScreenState extends State<SpectatorScreen> {
  List<OnlineMatchDto> _games = const <OnlineMatchDto>[];
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final List<OnlineMatchDto> games = await widget.api.liveGames(
        widget.token,
      );
      if (!mounted) return;
      setState(() {
        _games = games;
        _loading = false;
        _error = null;
      });
    } on Object {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = 'Live games could not be loaded.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF061524),
    appBar: AppBar(
      title: const Text('WATCH & LEARN'),
      backgroundColor: const Color(0xFF071B2D),
      actions: <Widget>[
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(child: Text(_error!))
        : _games.isEmpty
        ? const _EmptyArena()
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 60),
            itemCount: _games.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, int index) => _LiveGameCard(
              game: _games[index],
              onTap: () => Navigator.pop(context, _games[index]),
            ),
          ),
  );
}

class _EmptyArena extends StatelessWidget {
  const _EmptyArena();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.visibility_rounded, size: 72, color: Color(0xFF63D2B8)),
          SizedBox(height: 18),
          Text(
            'No live games right now',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Active community battles will appear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFAEC0D1)),
          ),
        ],
      ),
    ),
  );
}

class _LiveGameCard extends StatelessWidget {
  const _LiveGameCard({required this.game, required this.onTap});
  final OnlineMatchDto game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF0A2033),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0xFF2B756C)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF123E43),
              child: Icon(Icons.sensors_rounded, color: Color(0xFF63D2B8)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${game.whitePlayerName ?? 'White'}  vs  ${game.blackPlayerName ?? 'Black'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'LIVE • ${game.plyCount} moves • ${game.activeColor} to move',
                    style: const TextStyle(color: Color(0xFF63D2B8)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.play_circle_fill_rounded,
              color: Color(0xFFE2AE49),
              size: 36,
            ),
          ],
        ),
      ),
    ),
  );
}
