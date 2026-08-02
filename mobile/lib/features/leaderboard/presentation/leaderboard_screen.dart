import 'package:flutter/material.dart';

import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_session_store.dart';
import '../data/leaderboard_api.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const LeaderboardApi _api = LeaderboardApi();
  String _scope = 'global';
  late Future<LeaderboardDto> _leaderboard;

  @override
  void initState() {
    super.initState();
    _leaderboard = _load();
  }

  Future<LeaderboardDto> _load() async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (session == null) {
      throw const LeaderboardException('Sign in to view online rankings.');
    }
    final String country = LocalGameArchive.profileCountry;
    if (country.isNotEmpty && country != 'Unknown') {
      await _api.syncCountry(session.token, country);
    }
    return _api.load(
      session.token,
      scope: _scope,
      country: _scope == 'country' ? country : null,
    );
  }

  void _switchScope(String scope) {
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _leaderboard = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('RANKINGS'),
        backgroundColor: const Color(0xD9071827),
      ),
      body: FutureBuilder<LeaderboardDto>(
        future: _leaderboard,
        builder:
            (BuildContext context, AsyncSnapshot<LeaderboardDto> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            final Object error = snapshot.error ?? 'Unable to load rankings.';
            final String message = error is LeaderboardException
                ? error.message
                : 'Unable to load rankings.';
            return _ErrorState(
              message: message,
              onRetry: () => setState(() => _leaderboard = _load()),
            );
          }
          final LeaderboardDto board = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              final Future<LeaderboardDto> next = _load();
              setState(() => _leaderboard = next);
              await next;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                _RatingHero(player: board.you),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: <ButtonSegment<String>>[
                    const ButtonSegment<String>(
                      value: 'global',
                      icon: Icon(Icons.public_rounded),
                      label: Text('Global'),
                    ),
                    ButtonSegment<String>(
                      value: 'country',
                      icon: const Icon(Icons.flag_rounded),
                      label: Text(board.you.country),
                    ),
                  ],
                  selected: <String>{_scope},
                  onSelectionChanged: (Set<String> value) =>
                      _switchScope(value.first),
                ),
                const SizedBox(height: 14),
                Text(
                  board.totalPlayers == 0
                      ? 'No ranked players yet'
                      : 'Top ${board.entries.length} of ${board.totalPlayers} ranked players',
                  style: const TextStyle(
                    color: Color(0xFF8197A4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (board.entries.isEmpty)
                  const _EmptyBoard()
                else
                  ...board.entries.map(_LeaderboardTile.new),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RatingHero extends StatelessWidget {
  const _RatingHero({required this.player});
  final PlayerRatingDto player;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF0C2E43), Color(0xFF102035)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accentGold.withValues(alpha: .7)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.accentGold.withValues(alpha: .12),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            const Icon(Icons.workspace_premium_rounded,
                size: 42, color: AppColors.accentGold),
            const SizedBox(height: 6),
            Text('${player.rating}',
                style:
                    const TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
            const Text('CHESSVERSEAI ELO',
                style: TextStyle(
                    color: AppColors.accentGold,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _Metric('GLOBAL',
                    player.globalRank == 0 ? '—' : '#${player.globalRank}'),
                _Metric(player.country.toUpperCase(),
                    player.countryRank == 0 ? '—' : '#${player.countryRank}'),
                _Metric('PEAK', '${player.peakRating}'),
              ],
            ),
            const Divider(height: 26),
            Text(
              '${player.gamesPlayed} games  •  ${player.wins}W  ${player.draws}D  ${player.losses}L',
              style: const TextStyle(color: Color(0xFFB5C8D2)),
            ),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          Text(value,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF7F9AA8), fontSize: 10, letterSpacing: .8)),
        ],
      );
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile(this.entry);
  final LeaderboardEntryDto entry;
  @override
  Widget build(BuildContext context) {
    final Color accent = entry.rank <= 3
        ? AppColors.accentGold
        : entry.you
            ? const Color(0xFF63D2B8)
            : const Color(0xFF355268);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: entry.you ? const Color(0xFF113443) : const Color(0xFF0B1A27),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: .65)),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 42,
            child: Text('#${entry.rank}',
                style: TextStyle(
                    color: accent, fontWeight: FontWeight.w900, fontSize: 17)),
          ),
          CircleAvatar(
            backgroundColor: accent.withValues(alpha: .16),
            child: Text(entry.displayName.characters.first.toUpperCase(),
                style: TextStyle(color: accent, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                    entry.you
                        ? '${entry.displayName}  • YOU'
                        : entry.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  '${entry.country}  •  ${entry.gamesPlayed} games  •  ${entry.wins}W',
                  style:
                      const TextStyle(color: Color(0xFF8197A4), fontSize: 11),
                ),
              ],
            ),
          ),
          Text('${entry.rating}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Column(
          children: <Widget>[
            Icon(Icons.leaderboard_rounded, size: 52, color: Color(0xFF527081)),
            SizedBox(height: 12),
            Text('Complete an online match to enter the rankings.'),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.cloud_off_rounded, size: 46),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}
