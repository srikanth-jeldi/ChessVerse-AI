import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../auth/data/auth_session_store.dart';
import '../data/leaderboard_api.dart';

class CoinRankingsScreen extends StatefulWidget {
  const CoinRankingsScreen({super.key, required this.onRating, this.loader});
  final VoidCallback onRating;
  final Future<Map<String, dynamic>> Function(String period)? loader;
  @override
  State<CoinRankingsScreen> createState() => _CoinRankingsScreenState();
}

class _CoinRankingsScreenState extends State<CoinRankingsScreen> {
  String _period = 'weekly';
  late Future<Map<String, dynamic>> _data = _load();
  Future<Map<String, dynamic>> _load() async {
    if (widget.loader != null) return widget.loader!(_period);
    final session = await const AuthSessionStore().read();
    if (session == null) {
      return {'entries': <dynamic>[], 'previousWinners': <dynamic>[]};
    }
    return const LeaderboardApi().coinRankings(session.token, _period);
  }

  void _periodChanged(String period) {
    if (_period == period) return;
    setState(() {
      _period = period;
      _data = _load();
    });
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _data = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF061522),
    appBar: AppBar(
      title: const UiText('Coin rankings'),
      actions: [
        IconButton(
          tooltip: UiCopy.text('ELO ratings'),
          onPressed: widget.onRating,
          icon: const Icon(Icons.bar_chart_rounded),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const UiText(
                    'Rankings are temporarily unavailable. Pull to retry.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _refresh,
                    child: const UiActionText('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data ?? {};
        final entries = (data['entries'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        final winners = (data['previousWinners'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        final you = data['you'] as Map<String, dynamic>?;
        final first = data['firstPrizeWeek'] as String?;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFD166),
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    const UiText(
                      'Win games. Climb the coin league.',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const UiText(
                      'Your game winnings decide your rank. ELO is shown separately.',
                      style: TextStyle(color: Color(0xFFB6CCD8), fontSize: 15),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final prize in [(1, 500), (2, 300), (3, 200)])
                          Chip(
                            avatar: const Icon(
                              Icons.emoji_events_outlined,
                              size: 18,
                            ),
                            label: UiText(
                              '#{0}: {1} coins',
                              values: [prize.$1, prize.$2],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const UiText(
                      'Weekly top 3 prizes are credited automatically after the week ends.',
                    ),
                    const SizedBox(height: 8),
                    const UiText(
                      'Week: Monday to Sunday · India time (UTC+5:30)',
                      style: TextStyle(color: Color(0xFFB6CCD8)),
                    ),
                    if (first != null)
                      UiText('First prize week starts {0}', values: [first]),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _tab('weekly', 'This week')),
                  const SizedBox(width: 10),
                  Expanded(child: _tab('overall', 'Overall')),
                ],
              ),
              const SizedBox(height: 16),
              if (you != null) ...[
                const UiText(
                  'YOUR CURRENT RANK',
                  style: TextStyle(
                    color: Color(0xFF56DEC8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _entry(you, current: true),
              ] else
                _panel(
                  const UiText(
                    'Finish a qualifying coin match to enter the rankings.',
                  ),
                ),
              const SizedBox(height: 20),
              const UiText(
                'TOP PLAYERS',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                _panel(
                  const UiText(
                    'No qualifying winnings yet. Be the first this week.',
                  ),
                ),
              for (final entry in entries) _entry(entry),
              const SizedBox(height: 16),
              const UiText(
                'LAST WEEK’S WINNERS',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (winners.isEmpty)
                _panel(
                  const UiText(
                    'The first winners will appear after a full prize week.',
                  ),
                ),
              for (final winner in winners)
                _panel(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${winner['place']}  ${winner['displayName']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      UiText('{0} prize coins', values: [winner['prize']]),
                      Text(
                        '${winner['weekStart']}',
                        style: const TextStyle(color: Color(0xFFB6CCD8)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _panel(
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      'HOW SCORING WORKS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    UiText(
                      'Only net coins won in completed coin-entry games count. Your returned entry fee, ad rewards, purchases and prizes do not count.',
                    ),
                    SizedBox(height: 8),
                    UiText(
                      'A match needs at least 4 half-moves. Up to 3 wins against the same opponent per day count. Test accounts are excluded.',
                    ),
                    SizedBox(height: 8),
                    UiText(
                      'Ties: most qualifying wins, then earliest last win. Coins have no cash value.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: widget.onRating,
                icon: const Icon(Icons.bar_chart_rounded),
                label: const UiActionText('View ELO ratings'),
              ),
            ],
          ),
        );
      },
    ),
  );
  Widget _tab(String value, String text) => FilledButton(
    key: ValueKey('coin-period-$value'),
    onPressed: () => _periodChanged(value),
    style: FilledButton.styleFrom(
      backgroundColor: _period == value
          ? const Color(0xFF167C79)
          : const Color(0xFF172C3B),
    ),
    child: UiActionText(text),
  );
  Widget _panel(Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF102737),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFF36586C)),
    ),
    child: child,
  );
  Widget _entry(Map<String, dynamic> entry, {bool current = false}) => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              foregroundImage:
                  entry['photoUrl'] is String &&
                      (entry['photoUrl'] as String).isNotEmpty
                  ? NetworkImage(entry['photoUrl'] as String)
                  : null,
              onForegroundImageError:
                  entry['photoUrl'] is String &&
                      (entry['photoUrl'] as String).isNotEmpty
                  ? (_, _) {}
                  : null,
              backgroundColor: current
                  ? const Color(0xFF167C79)
                  : const Color(0xFF364858),
              child: Text(
                '#${entry['rank']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${entry['displayName']}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        UiText(
          '{0} coins won',
          values: [entry['coinsWon'] ?? 0],
          style: const TextStyle(
            color: Color(0xFFFFD166),
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        UiText(
          '{0} qualifying wins',
          values: [entry['wins'] ?? 0],
          style: const TextStyle(color: Color(0xFFB6CCD8)),
        ),
      ],
    ),
  );
}
