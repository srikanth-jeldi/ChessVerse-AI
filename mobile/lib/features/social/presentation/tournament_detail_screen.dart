import 'package:flutter/material.dart';
import '../data/community_api.dart';

class TournamentDetailScreen extends StatefulWidget {
  const TournamentDetailScreen(
      {required this.id, required this.token, required this.api, super.key});
  final String id, token;
  final CommunityApi api;
  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  TournamentDetailDto? detail;
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await widget.api.tournamentDetail(widget.token, widget.id);
      if (mounted) {
        setState(() {
          detail = value;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> _toggle() async {
    final value = detail;
    if (value == null) return;
    setState(() => busy = true);
    try {
      await widget.api.tournament(widget.token, widget.id, !value.joined);
      await _load();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = detail;
    return Scaffold(
        appBar: AppBar(title: Text(value?.name ?? 'Tournament')),
        body: error != null
            ? Center(child: Text(error!))
            : value == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child:
                        ListView(padding: const EdgeInsets.all(16), children: [
                      Text(value.description,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        Chip(label: Text('${value.minutes} min')),
                        Chip(
                            label: Text(
                                '${value.players}/${value.capacity} players')),
                        Chip(label: Text(value.status)),
                        if (value.currentRound > 0)
                          Chip(label: Text('Round ${value.currentRound}'))
                      ]),
                      const SizedBox(height: 12),
                      if (value.status == 'OPEN')
                        FilledButton.icon(
                            onPressed: busy ? null : _toggle,
                            icon: Icon(value.joined
                                ? Icons.exit_to_app_rounded
                                : Icons.person_add_rounded),
                            label: Text(
                                value.joined ? 'Withdraw' : 'Join tournament')),
                      if (value.champion != null) ...[
                        const SizedBox(height: 18),
                        Card(
                            child: ListTile(
                                leading: const Icon(Icons.emoji_events_rounded,
                                    color: Color(0xFFE5B550)),
                                title: const Text('Champion'),
                                subtitle: Text(value.champion!.name)))
                      ],
                      const SizedBox(height: 18),
                      Text('BRACKET',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      if (value.rounds.isEmpty)
                        const Card(
                            child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                    'Bracket is generated automatically when the tournament starts.'))),
                      for (final round in value.rounds) ...[
                        Text('Round ${round.number}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE5B550))),
                        const SizedBox(height: 8),
                        for (final pairing in round.pairings)
                          Card(
                              child: ListTile(
                                  leading: CircleAvatar(
                                      child: Text('${pairing.board}')),
                                  title: Text(
                                      '${pairing.white?.name ?? 'TBD'}  vs  ${pairing.black?.name ?? 'BYE'}'),
                                  subtitle: Text(pairing.winner != null
                                      ? 'Winner: ${pairing.winner!.name}'
                                      : pairing.status),
                                  trailing: pairing.matchId == null
                                      ? null
                                      : const Icon(
                                          Icons.sports_esports_rounded))),
                        const SizedBox(height: 14)
                      ]
                    ])));
  }
}
