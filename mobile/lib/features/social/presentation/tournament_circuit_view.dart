import 'dart:async';

import 'package:flutter/material.dart';

import '../data/community_api.dart';

class TournamentCircuitView extends StatelessWidget {
  const TournamentCircuitView({
    required this.tournaments,
    required this.fairPlayScore,
    required this.circuitPoints,
    required this.onOpen,
    required this.onRefresh,
    super.key,
  });

  final List<TournamentDto> tournaments;
  final int fairPlayScore;
  final int circuitPoints;
  final ValueChanged<TournamentDto> onOpen;
  final Future<void> Function() onRefresh;

  List<TournamentDto> get _currentTournaments {
    final bySeries = <String, TournamentDto>{};
    for (final event in tournaments) {
      final key = event.name.trim().toLowerCase();
      final current = bySeries[key];
      if (current == null || _prefer(event, current)) {
        bySeries[key] = event;
      }
    }
    return bySeries.values.toList(growable: false);
  }

  bool _prefer(TournamentDto candidate, TournamentDto current) {
    int priority(TournamentDto event) {
      if (event.joined) return 40;
      return switch (event.status) {
        'ACTIVE' => 30,
        'OPEN' => 20,
        'FINISHED' => 10,
        _ => 0,
      };
    }

    final candidatePriority = priority(candidate);
    final currentPriority = priority(current);
    if (candidatePriority != currentPriority) {
      return candidatePriority > currentPriority;
    }
    final candidateStart = candidate.startsAt;
    final currentStart = current.startsAt;
    if (candidateStart == null) return false;
    if (currentStart == null) return true;
    if (candidate.status == 'FINISHED') {
      return candidateStart.isAfter(currentStart);
    }
    return candidateStart.isBefore(currentStart);
  }

  @override
  Widget build(BuildContext context) {
    final events = _currentTournaments;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
              child: _CircuitHero(
                  score: fairPlayScore, circuitPoints: circuitPoints)),
          if (events.isEmpty)
            const SliverFillRemaining(
                hasScrollBody: false, child: _EmptyCircuit())
          else ...<Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: Row(children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('WORLD CHESS CIRCUIT',
                            style: TextStyle(
                                color: Color(0xFFF1C76B),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4)),
                        SizedBox(height: 4),
                        Text('Season 01 · Compete across iconic cities',
                            style: TextStyle(color: Color(0xFF9FB0C1))),
                      ],
                    ),
                  ),
                  _Pill(
                      icon: Icons.workspace_premium_rounded,
                      label: '${events.where((e) => e.joined).length} joined'),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: _CircuitProgress(points: circuitPoints),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
              sliver: SliverLayoutBuilder(builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 1000
                    ? 3
                    : width >= 650
                        ? 2
                        : 1;
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final event = events[index];
                      return _CircuitCard(
                        event: event,
                        theme: CircuitTheme.forTournament(event, index),
                        featured: index == 0,
                        onTap: () => onOpen(event),
                      );
                    },
                    childCount: events.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: columns == 1 ? .94 : .82,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class CircuitTheme {
  const CircuitTheme(this.city, this.subtitle, this.icon, this.colors,
      this.artwork, this.trophyArtwork);
  final String city, subtitle, artwork, trophyArtwork;
  final IconData icon;
  final List<Color> colors;

  static const List<CircuitTheme> themes = <CircuitTheme>[
    CircuitTheme(
        'HYDERABAD',
        'ROYAL CUP',
        Icons.account_balance_rounded,
        <Color>[Color(0xFF061A35), Color(0xFF0B3470), Color(0xFFB47824)],
        'assets/backgrounds/tournament-hyderabad-royal-cup-v1.png',
        'assets/branding/trophy-hyderabad-royal-v1.png'),
    CircuitTheme(
        'TOKYO',
        'NEON MASTERS',
        Icons.bolt_rounded,
        <Color>[Color(0xFF10072D), Color(0xFF47208D), Color(0xFF00A7D6)],
        'assets/backgrounds/tournament-tokyo-neon-masters-v1.png',
        'assets/branding/trophy-tokyo-neon-v1.png'),
    CircuitTheme(
        'DUBAI',
        'GOLD OPEN',
        Icons.location_city_rounded,
        <Color>[Color(0xFF17100A), Color(0xFF624014), Color(0xFFE0A735)],
        'assets/backgrounds/tournament-dubai-gold-open-v1.png',
        'assets/branding/trophy-dubai-gold-v1.png'),
    CircuitTheme(
        'LONDON',
        'CLASSIC',
        Icons.castle_rounded,
        <Color>[Color(0xFF091421), Color(0xFF243D5A), Color(0xFF8DA9C0)],
        'assets/backgrounds/tournament-london-classic-v1.png',
        'assets/branding/trophy-london-classic-v1.png'),
    CircuitTheme(
        'NEW YORK',
        'GRAND FINAL',
        Icons.emoji_events_rounded,
        <Color>[Color(0xFF090D1D), Color(0xFF173769), Color(0xFFE2B54E)],
        'assets/backgrounds/tournament-new-york-grand-final-v1.png',
        'assets/branding/trophy-new-york-grand-final-v1.png'),
  ];

  static CircuitTheme forTournament(TournamentDto event, int index) {
    return forName(event.name, index);
  }

  static CircuitTheme forName(String tournamentName, [int index = 0]) {
    final name = tournamentName.toLowerCase();
    if (name.contains('hyderabad')) return themes[0];
    if (name.contains('tokyo')) return themes[1];
    if (name.contains('dubai')) return themes[2];
    if (name.contains('london')) return themes[3];
    if (name.contains('new york') || name.contains('grand final')) {
      return themes[4];
    }
    return themes[index % themes.length];
  }
}

class _CircuitHero extends StatelessWidget {
  const _CircuitHero({required this.score, required this.circuitPoints});
  final int score;
  final int circuitPoints;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF0B2E60),
              Color(0xFF071526),
              Color(0xFF171008)
            ],
          ),
          border: Border.all(color: const Color(0xFFB98B35)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
                color: Color(0x442B75D6), blurRadius: 24, offset: Offset(0, 9)),
          ],
        ),
        child: Row(children: <Widget>[
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                  colors: <Color>[Color(0xFF1B61B8), Color(0xFF061425)]),
              border: Border.all(color: const Color(0xFFE3B84E), width: 1.5),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: Color(0xFFFFD46B), size: 38),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('SEASON 01',
                      style: TextStyle(
                          color: Color(0xFF77B8FF),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                  SizedBox(height: 5),
                  Text('Your road to the crown',
                      style:
                          TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                  SizedBox(height: 5),
                  Text('City cups · Knockout brackets · Cosmetic rewards',
                      style: TextStyle(color: Color(0xFFB5C1CE), height: 1.25)),
                ]),
          ),
          Column(children: <Widget>[
            Text('$circuitPoints CP',
                style: const TextStyle(
                    color: Color(0xFFFFD66F),
                    fontSize: 13,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('$score',
                style: const TextStyle(
                    color: Color(0xFF64E4D1),
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const Text('FAIR PLAY',
                style: TextStyle(
                    color: Color(0xFF89A3AF), fontSize: 9, letterSpacing: 1)),
          ]),
        ]),
      );
}

class _CircuitProgress extends StatelessWidget {
  const _CircuitProgress({required this.points});
  final int points;

  static const List<(int, String, IconData)> rewards =
      <(int, String, IconData)>[
    (500, 'Royal Board', Icons.grid_on_rounded),
    (1250, 'Neon Pieces', Icons.bolt_rounded),
    (2500, 'Champion Frame', Icons.filter_frames_rounded),
    (5000, 'Circuit Crown', Icons.workspace_premium_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    const maximum = 5000;
    final progress = (points / maximum).clamp(0.0, 1.0);
    (int, String, IconData)? next;
    for (final reward in rewards) {
      if (reward.$1 > points) {
        next = reward;
        break;
      }
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF071522),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF31516A)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[
              const Icon(Icons.route_rounded, color: Color(0xFFE2B54E)),
              const SizedBox(width: 9),
              const Expanded(
                child: Text('SEASON PROGRESSION',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: .8)),
              ),
              Text('$points / $maximum CP',
                  style: const TextStyle(
                      color: Color(0xFFFFD66F), fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xFF14283A),
                color: const Color(0xFFE2B54E),
              ),
            ),
            const SizedBox(height: 9),
            Text(
                next == null
                    ? 'All Season 01 cosmetics unlocked'
                    : 'Next: ${next.$2} at ${next.$1} CP',
                style: const TextStyle(color: Color(0xFFA9B9C7), fontSize: 12)),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: rewards.map((reward) {
                  final unlocked = points >= reward.$1;
                  return Container(
                    width: 126,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: unlocked
                          ? const Color(0xFF102D33)
                          : const Color(0xFF0B1A27),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: unlocked
                              ? const Color(0xFF55DCC8)
                              : const Color(0xFF294358)),
                    ),
                    child: Column(children: <Widget>[
                      Icon(reward.$3,
                          color: unlocked
                              ? const Color(0xFFFFD66F)
                              : const Color(0xFF617789),
                          size: 28),
                      const SizedBox(height: 7),
                      Text(reward.$2,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(unlocked ? 'UNLOCKED' : '${reward.$1} CP',
                          style: TextStyle(
                              color: unlocked
                                  ? const Color(0xFF5DE1C9)
                                  : const Color(0xFF8195A5),
                              fontSize: 9,
                              fontWeight: FontWeight.w900)),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ]),
    );
  }
}

class _CircuitCard extends StatefulWidget {
  const _CircuitCard(
      {required this.event,
      required this.theme,
      required this.onTap,
      required this.featured});
  final TournamentDto event;
  final CircuitTheme theme;
  final VoidCallback onTap;
  final bool featured;

  @override
  State<_CircuitCard> createState() => _CircuitCardState();
}

class _CircuitCardState extends State<_CircuitCard> {
  Timer? _timer;

  TournamentDto get event => widget.event;
  CircuitTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timing {
    if (event.status == 'ACTIVE') return 'LIVE NOW';
    if (event.status == 'FINISHED') return 'COMPLETED';
    final starts = event.startsAt;
    if (starts == null) return 'REGISTRATION OPEN';
    final difference = starts.difference(DateTime.now());
    if (difference.isNegative) return 'STARTING SOON';
    if (difference.inDays > 0) {
      return 'STARTS IN ${difference.inDays}D ${difference.inHours % 24}H';
    }
    return 'STARTS IN ${difference.inHours}H ${difference.inMinutes % 60}M';
  }

  String get _actionLabel {
    if (event.status == 'FINISHED') return 'VIEW RESULTS';
    if (event.status == 'ACTIVE') return 'VIEW LIVE TOURNAMENT';
    if (event.joined) return 'REGISTERED';
    return 'VIEW DETAILS & REGISTER';
  }

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: widget.featured
                      ? const Color(0xFFE0B14A)
                      : theme.colors.last),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, 8)),
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
                      theme.colors.first.withValues(alpha: .42),
                      theme.colors[1].withValues(alpha: .76),
                      const Color(0xFF050B14),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          children: <Widget>[
                            _Pill(
                                icon: event.status == 'ACTIVE'
                                    ? Icons.play_arrow_rounded
                                    : Icons.schedule_rounded,
                                label: _timing),
                            _Pill(
                                icon: Icons.monetization_on_rounded,
                                label: 'ENTRY FEE ${event.entryCoins}'),
                          ]),
                      const Spacer(),
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(colors: <Color>[
                            Color(0x5539D8FF),
                            Color(0x22112238),
                            Colors.transparent,
                          ]),
                          border: Border.all(
                            color: const Color(0x66FFD570),
                          ),
                        ),
                        child: Image.asset(
                          theme.trophyArtwork,
                          fit: BoxFit.contain,
                          semanticLabel: '${theme.city} championship trophy',
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(theme.city,
                          style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4)),
                      Text(theme.subtitle,
                          style: const TextStyle(
                              color: Color(0xFFFFD570),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(event.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFFD1D9E2), height: 1.25)),
                      const SizedBox(height: 13),
                      Row(children: <Widget>[
                        _Stat(
                            icon: Icons.timer_outlined,
                            text: '${event.minutes}+0'),
                        const SizedBox(width: 14),
                        _Stat(
                            icon: Icons.groups_rounded,
                            text: '${event.players}/${event.capacity}'),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Color(0xFFFFD570)),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: event.joined
                              ? const Color(0xFF126558)
                              : event.status == 'FINISHED'
                                  ? const Color(0xFF183149)
                                  : const Color(0xFFE0AD42),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _actionLabel,
                          style: TextStyle(
                            color: event.joined || event.status == 'FINISHED'
                                ? Colors.white
                                : const Color(0xFF07111B),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ]),
              ),
            ]),
          ),
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xCC07111D),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0x7767A9E8)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Icon(icon, size: 14, color: const Color(0xFFFFD570)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5)),
        ]),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Icon(icon, color: const Color(0xFF78C4FF), size: 18),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      ]);
}

class _EmptyCircuit extends StatelessWidget {
  const _EmptyCircuit();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Icon(Icons.public_rounded, size: 64, color: Color(0xFFE0B14A)),
            SizedBox(height: 16),
            Text('The next circuit is being prepared',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 7),
            Text('Pull to refresh for newly announced city tournaments.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9FB0C1))),
          ]),
        ),
      );
}
