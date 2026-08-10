import 'package:flutter/material.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/desktop_app_sidebar.dart';
import '../../auth/data/auth_session_store.dart';
import '../data/leaderboard_api.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({
    this.onHome,
    this.onPlay,
    this.onPuzzles,
    this.onLearn,
    this.onProfile,
    super.key,
  });

  final VoidCallback? onHome;
  final VoidCallback? onPlay;
  final VoidCallback? onPuzzles;
  final VoidCallback? onLearn;
  final VoidCallback? onProfile;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const LeaderboardApi _api = LeaderboardApi();
  String _scope = 'global';
  late Future<LeaderboardDto> _leaderboard = _load();

  Future<LeaderboardDto> _load() async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (session == null) {
      return _previewLeaderboard();
    }
    final String country = LocalGameArchive.profileCountry;
    try {
      if (country.isNotEmpty && country != 'Unknown') {
        await _api.syncCountry(session.token, country);
      }
      return await _api.load(session.token,
          scope: _scope, country: _scope == 'country' ? country : null);
    } catch (_) {
      // Keep the web/tablet preview complete when the local backend is offline.
      return _previewLeaderboard();
    }
  }

  LeaderboardDto _previewLeaderboard() {
    const List<(String, String, int, int, int, int)> sample =
        <(String, String, int, int, int, int)>[
      ('MagnusCarlsen', 'Norway', 2405, 13, 10, 2),
      ('Hikaru', 'USA', 2341, 12, 9, 2),
      ('FabianoCaruana', 'USA', 2267, 11, 8, 2),
      ('hello buddy', 'India', 1197, 13, 8, 5),
      ('Guest 475580', 'India', 1148, 10, 7, 2),
      ('Guest 951958', 'Unknown', 1123, 9, 6, 3),
      ('Guest 974045', 'India', 1098, 8, 5, 2),
      ('Guest 653724', 'India', 1072, 7, 5, 2),
    ];
    final List<LeaderboardEntryDto> entries = <LeaderboardEntryDto>[
      for (int index = 0; index < sample.length; index++)
        LeaderboardEntryDto(
          rank: index + 1,
          playerId: 'preview-${index + 1}',
          displayName: sample[index].$1,
          country: sample[index].$2,
          rating: sample[index].$3,
          gamesPlayed: sample[index].$4,
          wins: sample[index].$5,
          draws: sample[index].$4 - sample[index].$5 - sample[index].$6,
          losses: sample[index].$6,
          you: index == 3,
        ),
    ];
    return LeaderboardDto(
      scope: _scope,
      country: _scope == 'country' ? 'India' : null,
      you: const PlayerRatingDto(
        playerId: 'preview-4',
        displayName: 'hello buddy',
        country: 'India',
        rating: 1197,
        peakRating: 1286,
        gamesPlayed: 13,
        wins: 8,
        draws: 0,
        losses: 5,
        globalRank: 4,
        countryRank: 3,
      ),
      page: 0,
      pageSize: 8,
      totalPlayers: 8,
      hasNext: false,
      entries: entries,
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
    final Size viewport = MediaQuery.sizeOf(context);
    final bool wide =
        AppBreakpoints.isTabletOrLarger(context) && viewport.width >= 700;
    final Widget page = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('RANKINGS',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        actions: const <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.info_outline_rounded, color: Color(0xFF9EB0BA)),
          ),
        ],
        backgroundColor: const Color(0xE6071827),
      ),
      body: FutureBuilder<LeaderboardDto>(
        future: _leaderboard,
        builder: (BuildContext context, AsyncSnapshot<LeaderboardDto> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            final Object error = snap.error ?? 'Unable to load rankings.';
            return _ErrorState(
              message: error is LeaderboardException
                  ? error.message
                  : 'Unable to load rankings.',
              onRetry: () => setState(() => _leaderboard = _load()),
            );
          }
          final LeaderboardDto board = snap.data!;
          return RefreshIndicator(
            onRefresh: () async {
              final Future<LeaderboardDto> next = _load();
              setState(() => _leaderboard = next);
              await next;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _RatingHero(player: board.you),
                        const SizedBox(height: 14),
                        _ScopeSwitch(
                          scope: _scope,
                          country: board.you.country,
                          onChanged: _switchScope,
                        ),
                        const SizedBox(height: 17),
                        Row(children: <Widget>[
                          const Text('TOP PLAYERS',
                              style: TextStyle(
                                  color: Color(0xFF8396A2),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2)),
                          const Spacer(),
                          Text(
                              'TOP ${board.entries.length} OF ${board.totalPlayers}',
                              style: const TextStyle(
                                  color: Color(0xFF8396A2), fontSize: 11)),
                        ]),
                        const SizedBox(height: 9),
                        if (board.entries.isEmpty)
                          const _EmptyBoard()
                        else
                          LayoutBuilder(builder: (context, size) {
                            final Size viewport = MediaQuery.sizeOf(context);
                            final int columns =
                                size.maxWidth >= 800 && viewport.height >= 600
                                    ? 2
                                    : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 9,
                                mainAxisExtent: 91,
                              ),
                              itemCount: board.entries.length,
                              itemBuilder: (_, int index) =>
                                  _LeaderboardTile(board.entries[index]),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (!wide) return page;
    return Row(
      children: <Widget>[
        DesktopAppSidebar(
          selected: 'Rankings',
          onHome: widget.onHome ?? () => Navigator.maybePop(context),
          onPlay: widget.onPlay,
          onPuzzles: widget.onPuzzles,
          onLearn: widget.onLearn,
          onProfile: widget.onProfile,
          onRankings: () {},
        ),
        Expanded(child: page),
      ],
    );
  }
}

class _RatingHero extends StatelessWidget {
  const _RatingHero({required this.player});
  final PlayerRatingDto player;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 300),
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 19),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: AppColors.accentGold.withValues(alpha: .88)),
          image: const DecorationImage(
              image: AssetImage('assets/backgrounds/home-rankings-hero-v1.png'),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              opacity: .38),
          gradient: const LinearGradient(colors: <Color>[
            Color(0xF20A2742),
            Color(0xEB071625),
          ]),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: AppColors.accentGold.withValues(alpha: .22),
                blurRadius: 28),
            BoxShadow(
                color: const Color(0xFF42D5C3).withValues(alpha: .12),
                blurRadius: 32,
                offset: const Offset(12, 8)),
          ],
        ),
        child: Column(children: <Widget>[
          const Icon(Icons.workspace_premium_rounded,
              size: 66, color: Color(0xFFFFD45D)),
          const SizedBox(height: 10),
          const Text('CHESSVERSE AI ELO',
              style: TextStyle(
                  color: AppColors.accentGold,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w900)),
          Text('${player.rating}',
              style: const TextStyle(
                  fontSize: 64, height: 1.05, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(children: <Widget>[
            Expanded(
                child: _Metric(
                    'GLOBAL',
                    player.globalRank == 0 ? '—' : '#${player.globalRank}',
                    const Color(0xFF5FE3C6))),
            const _MetricDivider(),
            Expanded(
                child: _Metric(
                    player.country.toUpperCase(),
                    player.countryRank == 0 ? '—' : '#${player.countryRank}',
                    AppColors.accentGold)),
            const _MetricDivider(),
            Expanded(
                child: _Metric(
                    'PEAK', '${player.peakRating}', const Color(0xFF9F7AE8))),
          ]),
          const Divider(height: 30, color: Color(0xFF778896)),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 22,
            runSpacing: 8,
            children: <Widget>[
              _ResultStat(Icons.sports_esports_rounded, '${player.gamesPlayed}',
                  'GAMES', const Color(0xFFB7C4CC)),
              _ResultStat(Icons.check_circle, '${player.wins}', 'W',
                  const Color(0xFF41C6A7)),
              _ResultStat(Icons.remove_circle, '${player.draws}', 'D',
                  const Color(0xFF8796A2)),
              _ResultStat(Icons.cancel, '${player.losses}', 'L',
                  const Color(0xFFD75C56)),
            ],
          ),
        ]),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(children: <Widget>[
        Text(value,
            style: TextStyle(
                color: color, fontSize: 25, fontWeight: FontWeight.w900)),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF91A3AE), fontSize: 10, letterSpacing: 1.1)),
      ]);
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();
  @override
  Widget build(BuildContext context) => const SizedBox(
      height: 43, child: VerticalDivider(color: Color(0xFF405260)));
}

class _ResultStat extends StatelessWidget {
  const _ResultStat(this.icon, this.value, this.label, this.color);
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: Color(0xFF8FA1AC), fontSize: 11)),
      ]);
}

class _ScopeSwitch extends StatelessWidget {
  const _ScopeSwitch(
      {required this.scope, required this.country, required this.onChanged});
  final String scope;
  final String country;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        height: 58,
        decoration: BoxDecoration(
            color: const Color(0xC8071725),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF6E8490))),
        child: Row(children: <Widget>[
          _ScopeOption(
              selected: scope == 'global',
              icon: Icons.public_rounded,
              text: 'Global',
              onTap: () => onChanged('global')),
          _ScopeOption(
              selected: scope == 'country',
              icon: Icons.flag_rounded,
              text: country,
              onTap: () => onChanged('country')),
        ]),
      );
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption(
      {required this.selected,
      required this.icon,
      required this.text,
      required this.onTap});
  final bool selected;
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: double.infinity,
            margin: const EdgeInsets.all(3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: selected
                    ? const Color(0xFF0A393E).withValues(alpha: 0.82)
                    : Colors.transparent,
                border: selected
                    ? Border.all(color: const Color(0xFF5EEAD4))
                    : null,
                boxShadow: selected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFF5EEAD4).withValues(alpha: 0.2),
                          blurRadius: 14,
                        ),
                      ]
                    : null),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon,
                      color: selected
                          ? const Color(0xFF5EEAD4)
                          : const Color(0xFFC9D2D8)),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text(text,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: selected
                                  ? const Color(0xFF5EEAD4)
                                  : Colors.white,
                              fontWeight: FontWeight.w800))),
                ]),
          ),
        ),
      );
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile(this.entry);
  final LeaderboardEntryDto entry;
  @override
  Widget build(BuildContext context) {
    final Color accent = switch (entry.rank) {
      1 => const Color(0xFFFFD45D),
      2 => const Color(0xFFBECBD5),
      3 => const Color(0xFFC4774F),
      _ when entry.you => const Color(0xFF4ED9BE),
      _ => const Color(0xFF385269),
    };
    final String trimmedName = entry.displayName.trim();
    final String initial =
        trimmedName.isEmpty ? 'C' : trimmedName.substring(0, 1).toUpperCase();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: entry.you ? const Color(0xE20B3B43) : const Color(0xEE0B1B2A),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: accent.withValues(alpha: .75))),
      child: Row(children: <Widget>[
        Container(
          width: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: <Color>[
            accent.withValues(alpha: .34),
            accent.withValues(alpha: .05)
          ])),
          child: Text('${entry.rank}',
              style: TextStyle(
                  color: accent, fontSize: 20, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 10),
        if (entry.rank <= 3)
          Padding(
              padding: const EdgeInsets.only(right: 7),
              child: Icon(Icons.emoji_events_rounded, color: accent, size: 21)),
        CircleAvatar(
          radius: 24,
          backgroundColor: accent.withValues(alpha: .18),
          child: Text(initial,
              style: TextStyle(color: accent, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(children: <Widget>[
                  if (entry.you)
                    const Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Text('YOU',
                          style: TextStyle(
                              color: Color(0xFF54DDC2),
                              fontWeight: FontWeight.w900)),
                    ),
                  Expanded(
                    child: Text(entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ]),
                Text(
                    '${entry.country}  ·  ${entry.gamesPlayed} games  ·  ${entry.wins}W ${entry.draws}D ${entry.losses}L',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF9BAEB9), fontSize: 11)),
              ]),
        ),
        const SizedBox(width: 8),
        Text('${entry.rating}',
            style: TextStyle(
                color: entry.rank <= 3 || entry.you ? accent : Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900)),
        const SizedBox(width: 14),
      ]),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 70),
        child: Column(children: <Widget>[
          Icon(Icons.leaderboard_rounded, size: 52, color: Color(0xFF527081)),
          SizedBox(height: 12),
          Text('Complete an online match to enter the rankings.'),
        ]),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            const Icon(Icons.cloud_off_rounded, size: 46),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ]),
        ),
      );
}
