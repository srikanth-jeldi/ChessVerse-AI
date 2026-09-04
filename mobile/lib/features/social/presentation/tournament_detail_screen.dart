import 'package:flutter/material.dart';

import '../data/community_api.dart';
import '../../shop/presentation/cosmetic_shop_screen.dart';
import '../data/social_api.dart';
import 'tournament_circuit_view.dart';

class TournamentDetailScreen extends StatefulWidget {
  const TournamentDetailScreen(
      {required this.id,
      required this.token,
      required this.api,
      this.onOpenMatch,
      super.key});
  final String id, token;
  final CommunityApi api;
  final Future<void> Function(String matchId)? onOpenMatch;

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  TournamentDetailDto? detail;
  String? error;
  String? actionError;
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
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    }
  }

  Future<void> _toggle() async {
    final value = detail;
    if (value == null) return;
    setState(() => busy = true);
    try {
      await widget.api.tournament(widget.token, widget.id, !value.joined);
      if (mounted) setState(() => actionError = null);
      await _load();
    } on SocialException catch (exception) {
      if (mounted) setState(() => actionError = exception.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _earnCoins() async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
        builder: (_) => CosmeticShopScreen(token: widget.token)));
    if (mounted) setState(() => actionError = null);
  }

  @override
  Widget build(BuildContext context) {
    final value = detail;
    return Scaffold(
      backgroundColor: const Color(0xFF030A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071421),
        title: Text(value?.name ?? 'World Chess Circuit'),
      ),
      body: error != null
          ? _LoadError(message: error!, onRetry: _load)
          : value == null
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE2B54E)))
              : TournamentDetailContent(
                  detail: value,
                  busy: busy,
                  actionError: actionError,
                  onToggle: _toggle,
                  onEarnCoins: _earnCoins,
                  onRefresh: _load,
                  onOpenMatch: widget.onOpenMatch),
    );
  }
}

class TournamentDetailContent extends StatelessWidget {
  const TournamentDetailContent({
    required this.detail,
    required this.busy,
    required this.onToggle,
    this.actionError,
    this.onEarnCoins,
    required this.onRefresh,
    this.onOpenMatch,
    super.key,
  });
  final TournamentDetailDto detail;
  final bool busy;
  final String? actionError;
  final Future<void> Function() onToggle;
  final Future<void> Function()? onEarnCoins;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String matchId)? onOpenMatch;

  @override
  Widget build(BuildContext context) {
    final theme = CircuitTheme.forName(detail.name);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _TournamentHero(detail: detail, theme: theme),
                    const SizedBox(height: 16),
                    _RegistrationPanel(
                        detail: detail,
                        busy: busy,
                        actionError: actionError,
                        onToggle: onToggle,
                        onEarnCoins: onEarnCoins ?? onToggle),
                    const SizedBox(height: 16),
                    _TournamentRewardVault(detail: detail, theme: theme),
                    const SizedBox(height: 24),
                    _TournamentGuide(detail: detail),
                    if (detail.champion != null) ...<Widget>[
                      const SizedBox(height: 16),
                      _ChampionCard(
                        player: detail.champion!,
                        runnerUp: detail.runnerUp,
                        theme: theme,
                      ),
                    ],
                    const SizedBox(height: 26),
                    const _SectionHeading(
                      icon: Icons.account_tree_rounded,
                      title: 'TOURNAMENT BRACKET',
                      subtitle:
                          'Rounds advance automatically after verified results',
                    ),
                    const SizedBox(height: 12),
                    if (detail.rounds.isEmpty)
                      const _BracketPending()
                    else
                      _BracketGrid(
                          rounds: detail.rounds,
                          currentRound: detail.currentRound,
                          onOpenMatch: onOpenMatch),
                    const SizedBox(height: 24),
                    const _FairPlayNotice(),
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentRewardVault extends StatelessWidget {
  const _TournamentRewardVault({required this.detail, required this.theme});
  final TournamentDetailDto detail;
  final CircuitTheme theme;

  String get cadence => switch (detail.cadenceDays) {
        7 => 'WEEKLY',
        14 => 'EVERY 2 WEEKS',
        30 => 'MONTHLY',
        60 => 'EVERY 2 MONTHS',
        90 => 'SEASON FINAL',
        _ => 'SPECIAL EVENT',
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: <Color>[
            theme.colors.first.withValues(alpha: .96),
            theme.colors[1].withValues(alpha: .74),
            const Color(0xFF09131E),
          ]),
          border: Border.all(color: theme.colors.last),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: theme.colors.last.withValues(alpha: .18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 650;
          final Widget badge = TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: .84, end: 1),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutBack,
            builder: (_, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: <Color>[
                  theme.colors.last.withValues(alpha: .8),
                  theme.colors[1],
                  const Color(0xFF06101B),
                ]),
                border: Border.all(color: const Color(0xFFFFDC7B), width: 2),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x66F2B94B), blurRadius: 28),
                ],
              ),
              child: Stack(alignment: Alignment.center, children: <Widget>[
                Icon(theme.icon, color: const Color(0xFFFFE5A1), size: 54),
                const Positioned(
                  right: 16,
                  bottom: 16,
                  child: Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFF5DE1C9), size: 30),
                ),
              ]),
            ),
          );
          final Widget rewards = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(children: <Widget>[
                Expanded(
                  child: Text('3D CITY REWARD VAULT • $cadence',
                      style: const TextStyle(
                          color: Color(0xFFFFD66F),
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8)),
                ),
                Text('${detail.minimumPlayers}+ PLAYERS',
                    style: const TextStyle(
                        color: Color(0xFF63DFC9),
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 7),
              Text(
                detail.badgeCode.replaceAll('_', ' '),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Wrap(spacing: 9, runSpacing: 9, children: <Widget>[
                _RewardChip(
                    icon: Icons.emoji_events_rounded,
                    label: 'CHAMPION',
                    coins: detail.championBonus,
                    color: const Color(0xFFFFD66F)),
                _RewardChip(
                    icon: Icons.military_tech_rounded,
                    label: 'RUNNER-UP',
                    coins: detail.runnerUpBonus,
                    color: const Color(0xFFC7D7E7)),
                _RewardChip(
                    icon: Icons.verified_rounded,
                    label: 'PARTICIPATION',
                    coins: detail.participationBonus,
                    color: const Color(0xFF63DFC9)),
              ]),
              const SizedBox(height: 11),
              Text(
                'Champion also wins the live ${detail.prizePool}-coin entry pool. Every verified entrant receives the city badge.',
                style: const TextStyle(color: Color(0xFFB9C9D7), height: 1.35),
              ),
            ],
          );
          if (compact) {
            return Column(children: <Widget>[
              badge,
              const SizedBox(height: 16),
              rewards,
            ]);
          }
          return Row(children: <Widget>[
            badge,
            const SizedBox(width: 22),
            Expanded(child: rewards),
          ]);
        }),
      );
}

class _RewardChip extends StatelessWidget {
  const _RewardChip(
      {required this.icon,
      required this.label,
      required this.coins,
      required this.color});
  final IconData icon;
  final String label;
  final int coins;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xB2071623),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: .55)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 7),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFFAFC0CE),
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
                Text('+$coins COINS',
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w900)),
              ]),
        ]),
      );
}

class _TournamentHero extends StatelessWidget {
  const _TournamentHero({required this.detail, required this.theme});
  final TournamentDetailDto detail;
  final CircuitTheme theme;

  String get _schedule {
    if (detail.status == 'ACTIVE') return 'LIVE NOW';
    if (detail.status == 'FINISHED') return 'TOURNAMENT COMPLETE';
    final starts = detail.startsAt;
    if (starts == null) return 'REGISTRATION OPEN';
    final remaining = starts.difference(DateTime.now());
    if (remaining.isNegative) return 'STARTING SOON';
    if (remaining.inDays > 0) {
      return 'STARTS IN ${remaining.inDays}D ${remaining.inHours % 24}H';
    }
    return 'STARTS IN ${remaining.inHours}H ${remaining.inMinutes % 60}M';
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 490,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colors.last),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: theme.colors[1].withValues(alpha: .35),
                blurRadius: 28,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(fit: StackFit.expand, children: <Widget>[
          Image.asset(theme.artwork, fit: BoxFit.cover),
          DecoratedBox(
              decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  theme.colors.first.withValues(alpha: .35),
                  theme.colors[1].withValues(alpha: .72),
                  const Color(0xFF040A12),
                ]),
          )),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(children: <Widget>[
                    _StatusBadge(status: detail.status, label: _schedule),
                    const Spacer(),
                    const _StatusBadge(status: 'FAIR', label: 'FAIR PLAY'),
                  ]),
                  const Spacer(),
                  Icon(theme.icon, color: const Color(0xFFFFD66F), size: 52),
                  const SizedBox(height: 10),
                  Text(theme.city,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                  Text(theme.subtitle,
                      style: const TextStyle(
                          color: Color(0xFFFFD66F),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.3)),
                  const SizedBox(height: 10),
                  Text(detail.description,
                      style: const TextStyle(
                          color: Color(0xFFD3DEE9),
                          fontSize: 15,
                          height: 1.35)),
                  const SizedBox(height: 17),
                  Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
                    _HeroStat(
                        icon: Icons.timer_outlined,
                        value: '${detail.minutes}+0',
                        label: 'TIME'),
                    _HeroStat(
                        icon: Icons.groups_rounded,
                        value: '${detail.players}/${detail.capacity}',
                        label: 'PLAYERS'),
                    _HeroStat(
                        icon: Icons.account_tree_rounded,
                        value: detail.currentRound > 0
                            ? '${detail.currentRound}'
                            : '—',
                        label: 'ROUND'),
                    _HeroStat(
                        icon: Icons.monetization_on_rounded,
                        value: '${detail.entryCoins}',
                        label: 'ENTRY'),
                    _HeroStat(
                        icon: Icons.emoji_events_rounded,
                        value: '${detail.prizePool}',
                        label: 'LIVE POOL'),
                  ]),
                ]),
          ),
        ]),
      );
}

class _RegistrationPanel extends StatelessWidget {
  const _RegistrationPanel(
      {required this.detail,
      required this.busy,
      required this.actionError,
      required this.onToggle,
      required this.onEarnCoins});
  final TournamentDetailDto detail;
  final bool busy;
  final String? actionError;
  final Future<void> Function() onToggle;
  final Future<void> Function() onEarnCoins;

  @override
  Widget build(BuildContext context) {
    final fraction = detail.capacity == 0
        ? 0.0
        : (detail.players / detail.capacity).clamp(0.0, 1.0);
    final open = detail.status == 'OPEN';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color(0xFF091827),
          border: Border.all(color: const Color(0xFF294963))),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: <Widget>[
                Icon(
                    detail.joined
                        ? Icons.verified_rounded
                        : Icons.how_to_reg_rounded,
                    color: detail.joined
                        ? const Color(0xFF5DE1C9)
                        : const Color(0xFFFFCB64)),
                const SizedBox(width: 9),
                Flexible(
                    child: Text(
                        detail.joined
                            ? 'REGISTRATION CONFIRMED'
                            : 'TOURNAMENT REGISTRATION',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, letterSpacing: .5))),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 9,
                      backgroundColor: const Color(0xFF172B3B),
                      color: fraction > .85
                          ? const Color(0xFFFFAA45)
                          : const Color(0xFF42D9C2))),
              const SizedBox(height: 8),
              Text(
                  '${(detail.capacity - detail.players).clamp(0, detail.capacity)} places remaining',
                  style: const TextStyle(color: Color(0xFFAAB9C7))),
              const SizedBox(height: 6),
              Text(
                  '${detail.entryCoins} play coins reserved on join • ${detail.prizePool} current prize pool',
                  style: const TextStyle(
                      color: Color(0xFFFFD66F), fontWeight: FontWeight.w700)),
              if (actionError != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(actionError!,
                    style: const TextStyle(color: Color(0xFFFF7777))),
                if (actionError!.toLowerCase().contains('insufficient coins'))
                  TextButton.icon(
                    onPressed: onEarnCoins,
                    icon: const Icon(Icons.smart_display_rounded),
                    label: const Text('Earn free coins'),
                  ),
              ],
            ]);
        final action = FilledButton.icon(
          onPressed: !open || busy ? null : onToggle,
          style: FilledButton.styleFrom(
              minimumSize: Size(compact ? double.infinity : 210, 50),
              backgroundColor: detail.joined
                  ? const Color(0xFF173747)
                  : const Color(0xFFD9A536),
              foregroundColor: detail.joined
                  ? const Color(0xFF69E3D1)
                  : const Color(0xFF07111B)),
          icon: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(detail.joined
                  ? Icons.logout_rounded
                  : Icons.emoji_events_rounded),
          label: Text(
              !open
                  ? detail.status
                  : detail.joined
                      ? 'WITHDRAW'
                      : 'JOIN TOURNAMENT',
              style: const TextStyle(fontWeight: FontWeight.w900)),
        );
        if (compact) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                information,
                const SizedBox(height: 16),
                action,
              ]);
        }
        return Row(children: <Widget>[
          Expanded(child: information),
          const SizedBox(width: 24),
          action,
        ]);
      }),
    );
  }
}

class _TournamentGuide extends StatelessWidget {
  const _TournamentGuide({required this.detail});

  final TournamentDetailDto detail;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _SectionHeading(
            icon: Icons.menu_book_rounded,
            title: 'HOW TO PLAY',
            subtitle: 'Join, find your board and advance through the circuit',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 560
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            const steps = <(IconData, String, String)>[
              (
                Icons.how_to_reg_rounded,
                '1. REGISTER',
                'Tap Join Tournament before registration closes.'
              ),
              (
                Icons.notifications_active_rounded,
                '2. RETURN AT START',
                'Open this page when the tournament status becomes LIVE.'
              ),
              (
                Icons.account_tree_rounded,
                '3. OPEN YOUR BOARD',
                'Find your pairing in the active round and tap the match card.'
              ),
              (
                Icons.emoji_events_rounded,
                '4. ADVANCE',
                'Win your game to enter the next round and chase the crown.'
              ),
            ];
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: steps
                  .map((step) => SizedBox(
                        width: width,
                        child: _GuideStep(
                            icon: step.$1, title: step.$2, body: step.$3),
                      ))
                  .toList(),
            );
          }),
          const SizedBox(height: 16),
          _OfficialRules(detail: detail),
        ],
      );
}

class _GuideStep extends StatelessWidget {
  const _GuideStep(
      {required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 142),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF091827),
          border: Border.all(color: const Color(0xFF294963)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: const Color(0xFF5DE1C9), size: 27),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Color(0xFFFFD66F),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5)),
            const SizedBox(height: 7),
            Text(body,
                style: const TextStyle(
                    color: Color(0xFFB7C6D3), fontSize: 13, height: 1.35)),
          ],
        ),
      );
}

class _OfficialRules extends StatelessWidget {
  const _OfficialRules({required this.detail});

  final TournamentDetailDto detail;

  @override
  Widget build(BuildContext context) {
    final rules = <String>[
      'Single-elimination: one verified loss ends your tournament run.',
      'Time control: ${detail.minutes} minutes per player with no increment (${detail.minutes}+0).',
      'The event starts with at least ${detail.minimumPlayers} registered players.',
      'Pairings follow registration order; an odd player count can receive a bye.',
      'A draw creates a fresh replay between the same two players.',
      'Your entry is charged once only. Draw replays never charge again.',
      'Withdraw before registration closes for a full entry refund.',
      'If the event is cancelled, reserved entry coins are returned automatically.',
      'Checkmate, resignation or running out of time decides the winner.',
      'Moves and clocks are server-authoritative; only legal moves are accepted.',
      'No engines, outside assistance, account sharing or intentional connection abuse.',
      'Keep a stable connection and return promptly if your network drops.',
      'Disconnect grace is 45 seconds. One absent player loses; if both drop, the board is replayed.',
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
            colors: <Color>[Color(0xFF102338), Color(0xFF091522)]),
        border: Border.all(color: const Color(0xFFB48635)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(children: <Widget>[
            Icon(Icons.gavel_rounded, color: Color(0xFFFFD66F)),
            SizedBox(width: 10),
            Expanded(
              child: Text('OFFICIAL TOURNAMENT RULES',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: .7)),
            ),
          ]),
          const SizedBox(height: 14),
          for (final rule in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle_rounded,
                        size: 16, color: Color(0xFF5DE1C9)),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(rule,
                        style: const TextStyle(
                            color: Color(0xFFC5D1DC), height: 1.35)),
                  ),
                ],
              ),
            ),
          const Divider(height: 24, color: Color(0xFF385066)),
          const Wrap(
            spacing: 16,
            runSpacing: 8,
            children: <Widget>[
              _PointsRule(label: 'REGISTER', value: '+100 CP'),
              _PointsRule(label: 'EACH WIN', value: '+250 CP'),
              _PointsRule(label: 'CHAMPION', value: '+1000 CP'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointsRule extends StatelessWidget {
  const _PointsRule({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8FA4B6),
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFFFFD66F), fontWeight: FontWeight.w900)),
        ],
      );
}

class _BracketGrid extends StatelessWidget {
  const _BracketGrid(
      {required this.rounds,
      required this.currentRound,
      required this.onOpenMatch});
  final List<TournamentRoundDto> rounds;
  final int currentRound;
  final Future<void> Function(String matchId)? onOpenMatch;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 600
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
        return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: rounds
                .map((round) => SizedBox(
                    width: width,
                    child: _RoundColumn(
                        round: round,
                        active: round.number == currentRound,
                        onOpenMatch: onOpenMatch)))
                .toList());
      });
}

class _RoundColumn extends StatelessWidget {
  const _RoundColumn(
      {required this.round, required this.active, required this.onOpenMatch});
  final TournamentRoundDto round;
  final bool active;
  final Future<void> Function(String matchId)? onOpenMatch;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFF081624),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active
                    ? const Color(0xFFE2B54E)
                    : const Color(0xFF28465C))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(children: <Widget>[
                CircleAvatar(
                    radius: 17,
                    backgroundColor: active
                        ? const Color(0xFFE2B54E)
                        : const Color(0xFF18344A),
                    foregroundColor:
                        active ? const Color(0xFF07111B) : Colors.white,
                    child: Text('${round.number}',
                        style: const TextStyle(fontWeight: FontWeight.w900))),
                const SizedBox(width: 9),
                Expanded(
                    child: Text(_roundName(round.number),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, letterSpacing: .5))),
                Text(round.status,
                    style: TextStyle(
                        color: active
                            ? const Color(0xFFFFD66F)
                            : const Color(0xFF7F96A8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
              for (final pairing in round.pairings) ...<Widget>[
                _PairingCard(pairing: pairing, onOpenMatch: onOpenMatch),
                const SizedBox(height: 9),
              ],
            ]),
      );

  String _roundName(int number) => switch (number) {
        1 => 'OPENING ROUND',
        2 => 'QUARTERFINAL',
        3 => 'SEMIFINAL',
        4 => 'FINAL',
        _ => 'ROUND $number',
      };
}

class _PairingCard extends StatelessWidget {
  const _PairingCard({required this.pairing, required this.onOpenMatch});
  final TournamentPairingDto pairing;
  final Future<void> Function(String matchId)? onOpenMatch;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: pairing.matchId == null || onOpenMatch == null
          ? null
          : () => onOpenMatch!(pairing.matchId!),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: const Color(0xFF0D2132),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF24455D))),
        child: Column(children: <Widget>[
          Row(children: <Widget>[
            Text('BOARD ${pairing.board}',
                style: const TextStyle(
                    color: Color(0xFF77B9EE),
                    fontSize: 10,
                    fontWeight: FontWeight.w900)),
            const Spacer(),
            if (pairing.matchId != null)
              const Icon(Icons.sports_esports_rounded,
                  color: Color(0xFF5DDFC9), size: 17),
          ]),
          const SizedBox(height: 8),
          _PlayerRow(
              player: pairing.white,
              winner: pairing.winner?.id == pairing.white?.id),
          const Divider(height: 12, color: Color(0xFF274257)),
          _PlayerRow(
              player: pairing.black,
              winner: pairing.winner?.id == pairing.black?.id),
        ]),
      ));
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.winner});
  final TournamentPlayerDto? player;
  final bool winner;
  @override
  Widget build(BuildContext context) => Row(children: <Widget>[
        CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF1D3B50),
            backgroundImage: player?.photoUrl == null
                ? null
                : NetworkImage(player!.photoUrl!),
            child: player?.photoUrl == null
                ? Text((player?.name ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w900))
                : null),
        const SizedBox(width: 8),
        Expanded(
            child: Text(player?.name ?? 'TBD',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: winner ? const Color(0xFFFFD66F) : Colors.white,
                    fontWeight: winner ? FontWeight.w900 : FontWeight.w600))),
        if (winner)
          const Icon(Icons.workspace_premium_rounded,
              color: Color(0xFFFFD66F), size: 17),
      ]);
}

class _ChampionCard extends StatelessWidget {
  const _ChampionCard(
      {required this.player, required this.runnerUp, required this.theme});
  final TournamentPlayerDto player;
  final TournamentPlayerDto? runnerUp;
  final CircuitTheme theme;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(colors: <Color>[
              theme.colors.first,
              theme.colors[1],
              const Color(0xFF3E2A0A)
            ]),
            border: Border.all(color: const Color(0xFFFFD66F))),
        child: Row(children: <Widget>[
          const Icon(Icons.emoji_events_rounded,
              size: 52, color: Color(0xFFFFD66F)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('CIRCUIT CHAMPION',
                      style: TextStyle(
                          color: Color(0xFFFFD66F),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                  const SizedBox(height: 5),
                  Text(player.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                  if (runnerUp != null) ...<Widget>[
                    const SizedBox(height: 5),
                    Text('Runner-up • ${runnerUp!.name}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFC7D7E7))),
                  ],
                ]),
          ),
        ]),
      );
}

class _BracketPending extends StatelessWidget {
  const _BracketPending();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
            color: const Color(0xFF081624),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF294963))),
        child: const Column(children: <Widget>[
          Icon(Icons.account_tree_outlined, size: 48, color: Color(0xFFE2B54E)),
          SizedBox(height: 12),
          Text('Bracket unlocks when the tournament starts',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          SizedBox(height: 7),
          Text(
              'Registered players are seeded automatically and every result is server verified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFAAB9C7), height: 1.35)),
        ]),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Row(children: <Widget>[
        Icon(icon, color: const Color(0xFFE2B54E), size: 28),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              Text(subtitle,
                  style:
                      const TextStyle(color: Color(0xFF91A5B5), fontSize: 12)),
            ])),
      ]);
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
            color: const Color(0xCC07121E),
            borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Icon(icon, color: const Color(0xFF72BDFC), size: 19),
          const SizedBox(width: 7),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Color(0xFF8FA4B4), fontSize: 9)),
        ]),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});
  final String status, label;
  @override
  Widget build(BuildContext context) {
    final live = status == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: const Color(0xD907121E),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: live ? const Color(0xFFFF6E6E) : const Color(0xFF547796))),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Icon(live ? Icons.circle : Icons.shield_rounded,
            color: live ? const Color(0xFFFF6E6E) : const Color(0xFF67DFC9),
            size: 10),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .5)),
      ]),
    );
  }
}

class _FairPlayNotice extends StatelessWidget {
  const _FairPlayNotice();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF073031),
            border: Border.all(color: const Color(0xFF2F9F91))),
        child: const Row(children: <Widget>[
          Icon(Icons.verified_user_rounded, color: Color(0xFF5DE1C9)),
          SizedBox(width: 11),
          Expanded(
              child: Text(
                  'Server-validated moves · Authoritative clocks · Auditable tournament results',
                  style: TextStyle(color: Color(0xFFB8D8D3), height: 1.3))),
        ]),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          const Icon(Icons.cloud_off_rounded,
              size: 50, color: Color(0xFFFF8A72)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry')),
        ]),
      ));
}
