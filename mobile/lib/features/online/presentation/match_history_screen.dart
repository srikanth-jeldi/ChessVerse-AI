import 'package:flutter/material.dart';

import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_session_store.dart';
import '../data/online_match_api.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  final OnlineMatchApi _api = const OnlineMatchApi();
  late Future<List<OnlineMatchDto>> _online;

  @override
  void initState() {
    super.initState();
    _online = _load();
  }

  Future<List<OnlineMatchDto>> _load() async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (session == null) return const <OnlineMatchDto>[];
    return _api.history(session.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030A12),
      appBar: AppBar(
        title: const Text('MATCH HISTORY'),
        backgroundColor: const Color(0xFF071522),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final Future<List<OnlineMatchDto>> next = _load();
          setState(() => _online = next);
          await next;
        },
        child: FutureBuilder<List<OnlineMatchDto>>(
          future: _online,
          builder: (BuildContext context,
              AsyncSnapshot<List<OnlineMatchDto>> snapshot) {
            final List<OnlineMatchDto> online =
                snapshot.data ?? const <OnlineMatchDto>[];
            final List<SavedGameRecord> local = LocalGameArchive.games;
            if (snapshot.connectionState == ConnectionState.waiting &&
                online.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (online.isEmpty && local.isEmpty) {
              return ListView(
                children: const <Widget>[
                  SizedBox(height: 180),
                  Icon(Icons.history_rounded,
                      size: 58, color: Color(0xFF607A87)),
                  SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Your completed matches will appear here.',
                      style: TextStyle(color: Color(0xFF9CB0BA)),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                if (online.isNotEmpty) ...<Widget>[
                  const _Heading('ONLINE ARENA'),
                  const SizedBox(height: 10),
                  ...online.map(_OnlineHistoryCard.new),
                  const SizedBox(height: 20),
                ],
                if (local.isNotEmpty) ...<Widget>[
                  const _Heading('ON THIS DEVICE'),
                  const SizedBox(height: 10),
                  ...local.map(_LocalHistoryCard.new),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: AppColors.accentGold,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w900,
        ),
      );
}

class _OnlineHistoryCard extends StatelessWidget {
  const _OnlineHistoryCard(this.match);
  final OnlineMatchDto match;

  @override
  Widget build(BuildContext context) {
    final bool white = match.yourColor.toLowerCase() == 'white';
    final String you = white
        ? (match.whitePlayerName ?? 'You')
        : (match.blackPlayerName ?? 'You');
    final String opponent = white
        ? (match.blackPlayerName ?? 'Opponent')
        : (match.whitePlayerName ?? 'Opponent');
    final String result = match.result ?? '—';
    final bool won =
        (result == '1-0' && white) || (result == '0-1' && !white);
    final Color accent = result == '1/2-1/2'
        ? AppColors.accentGold
        : won
            ? const Color(0xFF63D2B8)
            : const Color(0xFFF08A6A);
    final int? ratingDelta = match.ratingBefore == null ||
            match.ratingAfter == null
        ? null
        : match.ratingAfter! - match.ratingBefore!;
    return _HistoryShell(
      accent: accent,
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: accent.withValues(alpha: 0.15),
            child: Icon(
              won
                  ? Icons.emoji_events_rounded
                  : result == '1/2-1/2'
                      ? Icons.handshake_rounded
                      : Icons.flag_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$you vs $opponent',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${match.resultReason ?? 'FINISHED'} • ${match.moves.length} ply',
                  style: const TextStyle(
                    color: Color(0xFF8FA5B1),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            ratingDelta == null
                ? result
                : '$result\n${ratingDelta >= 0 ? '+' : ''}$ratingDelta',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: accent,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalHistoryCard extends StatelessWidget {
  const _LocalHistoryCard(this.game);
  final SavedGameRecord game;
  @override
  Widget build(BuildContext context) => _HistoryShell(
        accent: const Color(0xFF668CA2),
        child: Row(
          children: <Widget>[
            const Icon(Icons.devices_rounded, color: Color(0xFF63D2B8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(game.summary,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    '${game.mode} • ${game.moves.length} ply',
                    style: const TextStyle(
                        color: Color(0xFF8FA5B1), fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(game.result,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _HistoryShell extends StatelessWidget {
  const _HistoryShell({required this.accent, required this.child});
  final Color accent;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xE60C1D2B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: child,
      );
}
