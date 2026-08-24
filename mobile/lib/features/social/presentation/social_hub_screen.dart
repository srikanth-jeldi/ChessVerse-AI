import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../auth/data/auth_session_store.dart';
import '../../online/data/online_match_api.dart';
import '../data/social_api.dart';
import '../data/community_api.dart';
import '../../notifications/presentation/notification_center_screen.dart';
import '../../notifications/presentation/notification_bell_button.dart';
import '../../notifications/data/notification_api.dart';

class SocialHubScreen extends StatefulWidget {
  const SocialHubScreen({this.onOpenMatch, this.previewHub, super.key});
  final ValueChanged<OnlineMatchDto>? onOpenMatch;
  final SocialHubDto? previewHub;
  @override
  State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen> {
  static const SocialApi _api = SocialApi();
  static const CommunityApi _communityApi = CommunityApi();
  StoredAuthSession? _session;
  SocialHubDto? _hub;
  CommunityDto? _community;
  int _section = 0;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    if (widget.previewHub != null) {
      _hub = widget.previewHub;
      _community = const CommunityDto(
          clubs: <ClubDto>[],
          tournaments: <TournamentDto>[],
          conversations: <ConversationDto>[],
          fairPlayScore: 100);
      _busy = false;
    } else {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    if (mounted)
      setState(() {
        _busy = true;
        _error = null;
      });
    try {
      final StoredAuthSession? session = await const AuthSessionStore().read();
      if (session == null)
        throw const SocialException('Sign in to use friends and challenges.');
      final List<Object> values = await Future.wait<Object>(<Future<Object>>[
        _api.load(session.token),
        _communityApi.load(session.token)
      ]);
      if (mounted)
        setState(() {
          _session = session;
          _hub = values[0] as SocialHubDto;
          _community = values[1] as CommunityDto;
          _busy = false;
        });
    } on SocialException catch (error) {
      if (mounted)
        setState(() {
          _error = error.message;
          _busy = false;
        });
    }
  }

  Future<void> _addFriend() async {
    final TextEditingController controller = TextEditingController();
    final String? username = await showDialog<String>(
        context: context,
        barrierColor: const Color(0xDD00070D),
        builder: (context) {
          final MediaQueryData media = MediaQuery.of(context);
          final bool keyboardVisible = media.viewInsets.bottom > 0;
          final double availableHeight = media.size.height -
              media.viewInsets.bottom -
              media.padding.top -
              media.padding.bottom -
              24;
          final double dialogHeight = availableHeight
              .clamp(280.0, keyboardVisible ? 500.0 : 650.0)
              .toDouble();
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
                horizontal: 18, vertical: keyboardVisible ? 8 : 20),
            child: SizedBox(
              width: 520,
              height: dialogHeight,
              child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: <Color>[
                      Color(0xFF0C2536),
                      Color(0xFF071725),
                    ]),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFF68D9C8)),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(color: Color(0x553DE0CB), blurRadius: 28),
                    ],
                  ),
                  child: Column(children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton.outlined(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(children: <Widget>[
                          Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF103941),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                    color: Color(0x7748E5D1), blurRadius: 24),
                              ],
                            ),
                            child: const Icon(Icons.person_add_alt_1_rounded,
                                size: 29, color: Color(0xFFF0B74B)),
                          ),
                          SizedBox(height: keyboardVisible ? 12 : 22),
                          const Text.rich(
                            TextSpan(children: <InlineSpan>[
                              TextSpan(text: 'Add a '),
                              TextSpan(
                                  text: 'ChessVerseAI',
                                  style:
                                      TextStyle(color: Color(0xFFE8B54D))),
                              TextSpan(text: ' friend'),
                            ]),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Search by username or player ID to\nsend a friend request.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFFAAB7C2), height: 1.4),
                          ),
                          SizedBox(height: keyboardVisible ? 16 : 24),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Username or Player ID',
                                style: TextStyle(color: Color(0xFF68DFC9))),
                          ),
                          const SizedBox(height: 7),
                          TextField(
                            controller: controller,
                            autofocus: true,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => Navigator.pop(
                                context, controller.text.trim()),
                            decoration: const InputDecoration(
                              hintText: 'Enter username',
                              prefixIcon: Icon(Icons.person_outline_rounded,
                                  color: Color(0xFF62DDC8)),
                            ),
                          ),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Example: MagnusAI',
                                  style: TextStyle(color: Color(0xFF71828E))),
                            ),
                          ),
                          SizedBox(height: keyboardVisible ? 10 : 16),
                        ]),
                      ),
                    ),
                    Row(children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE2AD45),
                            foregroundColor: const Color(0xFF15120B),
                            minimumSize: const Size.fromHeight(52),
                          ),
                          onPressed: () =>
                              Navigator.pop(context, controller.text.trim()),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Send Request',
                                maxLines: 1,
                                style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    ]),
                  ]),
                ),
            ),
          );
        });
    controller.dispose();
    if (username == null || username.isEmpty || _session == null) return;
    await _act(() => _api.addFriend(_session!.token, username));
  }

  Future<void> _act(Future<SocialHubDto> Function() action) async {
    try {
      final SocialHubDto hub = await action();
      if (mounted) setState(() => _hub = hub);
    } on SocialException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _challenge(SocialPlayerDto friend) async {
    int minutes = 10;
    final int? choice = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: const Color(0xFF071927),
        builder: (context) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text('Challenge ${friend.displayName}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const Text('Choose an authoritative server clock.'),
                      const SizedBox(height: 18),
                      Wrap(
                          spacing: 8,
                          children: <int>[3, 5, 10, 15]
                              .map((value) => ChoiceChip(
                                  label: Text('$value min'),
                                  selected: minutes == value,
                                  onSelected: (_) {
                                    minutes = value;
                                    Navigator.pop(context, value);
                                  }))
                              .toList()),
                    ]))));
    if (choice == null || _session == null) return;
    try {
      final SocialChallengeDto value =
          await _api.challenge(_session!.token, friend.playerId, choice);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Challenge sent • room ${value.roomCode}')));
      await _refresh();
    } on SocialException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _accept(SocialChallengeDto challenge) async {
    if (_session == null) return;
    try {
      final OnlineMatchDto match =
          await _api.acceptChallenge(_session!.token, challenge.id);
      if (mounted) widget.onOpenMatch?.call(match);
    } on SocialException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _decline(SocialChallengeDto challenge) async {
    if (_session == null) return;
    try {
      final SocialHubDto hub =
          await _api.declineChallenge(_session!.token, challenge.id);
      if (!mounted) return;
      setState(() => _hub = hub);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Challenge declined. The challenger was notified.')));
    } on SocialException catch (error) {
      // A second device may already have accepted/declined this invitation.
      // Always refresh so a stale actionable card is never left on screen.
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _notificationAction(PlayerNotificationDto item) async {
    final String action = (item.actionType ?? '').toUpperCase();
    if (action == 'MATCH' && item.actionId != null && _session != null) {
      try {
        final match = await const OnlineMatchApi()
            .getMatch(_session!.token, item.actionId!);
        if (mounted) widget.onOpenMatch?.call(match);
      } on OnlineMatchException catch (error) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }
    final int section = switch (action) {
      'CLUB' => 1,
      'TOURNAMENT' => 2,
      'CHAT' => 3,
      _ => 0,
    };
    if (mounted) setState(() => _section = section);
    await _refresh();
  }

  Future<void> _communityAct(Future<CommunityDto> Function() action) async {
    try {
      final CommunityDto value = await action();
      if (mounted) setState(() => _community = value);
    } on SocialException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _openPlayerProfile(SocialPlayerDto player) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _SocialPlayerProfile(
            player: player,
            onChallenge: () => _challenge(player),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF020D16),
        appBar: AppBar(
            title: const Text('COMMUNITY',
                style:
                    TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.3)),
            actions: <Widget>[
              NotificationBellButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => NotificationCenterScreen(
                            onAction: _notificationAction))),
              ),
              if (_section == 0)
                IconButton(
                    onPressed: _addFriend,
                    tooltip: 'Add friend',
                    icon: const Icon(Icons.person_add_alt_1_rounded))
            ],
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(72),
                child: _CommunityTabs(
                    selected: _section,
                    onChanged: (value) => setState(() => _section = value)))),
        body: _busy
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _Error(message: _error!, retry: _refresh)
                : _section == 0
                    ? RefreshIndicator(
                        onRefresh: _refresh,
                        child: LayoutBuilder(builder: (context, constraints) {
                          final bool wide = constraints.maxWidth >= 820;
                          final List<Widget> sections = <Widget>[
                            _Hero(
                                friendCount: _hub!.friends.length,
                                challengeCount: _hub!.challenges
                                    .where((c) => c.status == 'PENDING')
                                    .length),
                            _FriendFinder(onAdd: _addFriend),
                            if (_hub!.incoming.isNotEmpty)
                              _Section(
                                  title: 'FRIEND REQUESTS',
                                  icon: Icons.person_add_rounded,
                                  children: _hub!.incoming
                                      .map((player) => _PlayerCard(
                                          player: player,
                                          primaryLabel: 'Accept',
                                          onPrimary: () => _act(() =>
                                              _api.respond(_session!.token,
                                                  player.connectionId, true)),
                                          secondaryLabel: 'Decline',
                                          onSecondary: () => _act(() =>
                                              _api.respond(_session!.token,
                                                  player.connectionId, false))))
                                      .toList()),
                            _Section(
                                title: 'CHALLENGES',
                                icon: Icons.sports_martial_arts_rounded,
                                empty:
                                    'Your private challenges will appear here.',
                                children: _hub!.challenges
                                    .where((c) => c.status == 'PENDING')
                                    .map((challenge) => _ChallengeCard(
                                        challenge: challenge,
                                        onAccept: challenge.incoming
                                            ? () => _accept(challenge)
                                            : null,
                                        onDecline: challenge.incoming
                                            ? () => _decline(challenge)
                                            : null))
                                    .toList()),
                            _Section(
                                title: 'ACTIVE FRIENDS',
                                icon: Icons.circle,
                                empty: 'No friends are online right now.',
                                children: _hub!.friends
                                    .map((player) => _PlayerCard(
                                        player: player,
                                        primaryLabel: 'Challenge',
                                        onTap: () => _openPlayerProfile(player),
                                        onPrimary: () => _challenge(player)))
                                    .toList()),
                          ];
                          return ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 18, 16, 40),
                              children: <Widget>[
                                Center(
                                    child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: 1180),
                                        child: wide
                                            ? Wrap(
                                                spacing: 16,
                                                runSpacing: 16,
                                                children: sections
                                                    .map((w) => SizedBox(
                                                        width: w is _Hero
                                                            ? 1180
                                                            : 570,
                                                        child: w))
                                                    .toList())
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: sections
                                                    .expand((w) => <Widget>[
                                                          w,
                                                          const SizedBox(
                                                              height: 14)
                                                        ])
                                                    .toList())))
                              ]);
                        }))
                    : _CommunitySection(
                        section: _section,
                        community: _community!,
                        friends: _hub!.friends,
                        onRefresh: _refresh,
                        onClub: (club) => _communityAct(() => _communityApi
                            .club(_session!.token, club.id, !club.joined)),
                        onTournament: (event) => _communityAct(() =>
                            _communityApi.tournament(
                                _session!.token, event.id, !event.joined)),
                        api: _communityApi,
                        token: _session!.token),
      );
}

class _CommunityTabs extends StatelessWidget {
  const _CommunityTabs({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 62,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Row(
              children: List<Widget>.generate(4, (i) {
            const labels = <String>['Friends', 'Clubs', 'Tournaments', 'Chat'];
            const icons = <IconData>[
              Icons.people_alt_rounded,
              Icons.shield_rounded,
              Icons.emoji_events_rounded,
              Icons.forum_rounded
            ];
            final active = selected == i;
            return Expanded(
                child: Padding(
                    padding: EdgeInsets.only(right: i == 3 ? 0 : 5),
                    child: InkWell(
                        onTap: () => onChanged(i),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: active
                                        ? const Color(0xFF6BFFE9)
                                        : const Color(0xFF6D7480),
                                    width: 1.2),
                                gradient: active
                                    ? const LinearGradient(colors: <Color>[
                                        Color(0xFF176B69),
                                        Color(0xFF063C48)
                                      ])
                                    : null,
                                boxShadow: active
                                    ? const <BoxShadow>[
                                        BoxShadow(
                                            color: Color(0x9948E5D1),
                                            blurRadius: 17)
                                      ]
                                    : null),
                            child: Row(children: <Widget>[
                              Icon(icons[i],
                                  size: 17,
                                  color: active
                                      ? const Color(0xFF69F3DF)
                                      : const Color(0xFFF0B747)),
                              const SizedBox(width: 4),
                              Flexible(
                                  child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(labels[i],
                                    maxLines: 1,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: active
                                            ? Colors.white
                                            : const Color(0xFFF3F1EC))),
                              ))
                            ])))));
          }))));
}

class _CommunitySection extends StatelessWidget {
  const _CommunitySection(
      {required this.section,
      required this.community,
      required this.friends,
      required this.onRefresh,
      required this.onClub,
      required this.onTournament,
      required this.api,
      required this.token});
  final int section;
  final CommunityDto community;
  final List<SocialPlayerDto> friends;
  final Future<void> Function() onRefresh;
  final ValueChanged<ClubDto> onClub;
  final ValueChanged<TournamentDto> onTournament;
  final CommunityApi api;
  final String token;
  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = switch (section) {
      1 => community.clubs
          .map((c) => _ClubCard(club: c, onTap: () => onClub(c)))
          .toList(),
      2 => community.tournaments
          .map((t) => _TournamentCard(event: t, onTap: () => onTournament(t)))
          .toList(),
      _ => friends
          .map((f) => _ChatCard(
              friend: f,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) =>
                      _ChatScreen(friend: f, api: api, token: token)))))
          .toList()
    };
    final String title = switch (section) {
      1 => 'CLUBS',
      2 => 'TOURNAMENTS',
      _ => 'CHAT & CHALLENGE'
    };
    return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
            children: <Widget>[
              Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _FairPlayBanner(score: community.fairPlayScore),
                            const SizedBox(height: 16),
                            Text(title,
                                style: const TextStyle(
                                    color: Color(0xFFE5B550),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2)),
                            const SizedBox(height: 10),
                            if (cards.isEmpty)
                              const _EmptyCommunity()
                            else
                              LayoutBuilder(
                                  builder: (context, c) => c.maxWidth > 760
                                      ? Wrap(
                                          spacing: 14,
                                          runSpacing: 14,
                                          children: cards
                                              .map((w) => SizedBox(
                                                  width: (c.maxWidth - 14) / 2,
                                                  child: w))
                                              .toList())
                                      : Column(children: cards))
                          ])))
            ]));
  }
}

class _FairPlayBanner extends StatelessWidget {
  const _FairPlayBanner({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) => Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: <Color>[
            Color(0xFF073C42),
            Color(0xFF071827),
            Color(0xFF06131F)
          ]),
          border: Border.all(color: const Color(0xFF55E8D2), width: 1.2),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x4439D9C6), blurRadius: 18)
          ]),
      child: Row(children: <Widget>[
        Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A5758),
                border: Border.all(color: const Color(0xFF42DCCA))),
            child: const Icon(Icons.verified_user_rounded,
                color: Color(0xFF5DE3CF), size: 34)),
        const SizedBox(width: 13),
        const Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
              Text('FAIR PLAY PROTECTED',
                  style: TextStyle(
                      color: Color(0xFF5DE3CF),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4)),
              SizedBox(height: 8),
              Text(
                  'Server-validated moves •\nauthoritative clocks • auditable signals',
                  style: TextStyle(
                      color: Color(0xFFABB9C6), height: 1.3, fontSize: 12))
            ])),
        Container(width: 1, height: 62, color: const Color(0xFF6B7D89)),
        const SizedBox(width: 13),
        Text('$score',
            style: const TextStyle(
                color: Color(0xFF5DE3CF),
                fontSize: 34,
                fontWeight: FontWeight.w900))
      ]));
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club, required this.onTap});
  final ClubDto club;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final (IconData, Color) identity = switch (club.name) {
      'Royal Knights' => (
          Icons.workspace_premium_rounded,
          const Color(0xFFE6B64E)
        ),
      'Checkmate Academy' => (Icons.school_rounded, const Color(0xFF8FA9C0)),
      'Blitz Warriors' => (Icons.bolt_rounded, const Color(0xFFE29A42)),
      _ => (Icons.shield_rounded, const Color(0xFF55DCC8))
    };
    return _FeatureCard(
        icon: identity.$1,
        color: identity.$2,
        artwork: switch (club.name) {
          'Blitz Warriors' => 'assets/backgrounds/home-online-hero-v1.png',
          'Checkmate Academy' => 'assets/backgrounds/home-learn-hero-v1.png',
          'Royal Knights' => 'assets/backgrounds/home-friends-hero-v1.png',
          _ => 'assets/backgrounds/grandmaster-table-v1.webp',
        },
        title: club.name,
        subtitle: club.description,
        meta: '${club.members} members • ${club.ratingRequirement}+ rating',
        button: club.joined ? 'Leave' : 'Join club',
        onTap: onTap);
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({required this.event, required this.onTap});
  final TournamentDto event;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _FeatureCard(
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFF54DFC9),
      artwork: switch (event.name) {
        'Rapid Arena' => 'assets/backgrounds/home-analysis-hero-v1.png',
        'Blitz Sprint' => 'assets/backgrounds/home-online-hero-v1.png',
        _ => 'assets/backgrounds/grandmaster-table-v1.webp',
      },
      title: event.name,
      subtitle: event.description,
      meta: '${event.minutes} min • ${event.players}/${event.capacity} players',
      button: event.joined ? 'Withdraw' : 'Join tournament',
      onTap: onTap);
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.meta,
      required this.button,
      required this.onTap,
      this.artwork});
  final IconData icon;
  final Color color;
  final String title, subtitle, meta, button;
  final String? artwork;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: <Color>[Color(0xF20A1D2D), Color(0xF2071624)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF315166))),
      child: Stack(children: <Widget>[
        if (artwork != null)
          Positioned.fill(
              child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                      width: 190,
                      child: Image.asset(artwork!,
                          fit: BoxFit.cover,
                          color: const Color(0x9958DACA),
                          colorBlendMode: BlendMode.softLight)))),
        Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: <Color>[
          const Color(0xFF081B2A),
          const Color(0xDD081B2A),
          const Color(0x55081B2A)
        ])))),
        Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF092E38),
                                border:
                                    Border.all(color: const Color(0xFF51DFC9))),
                            child: Icon(icon, color: color, size: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                              Text(title,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Text(subtitle,
                                  style: const TextStyle(
                                      color: Color(0xFFA7B7C2), height: 1.3)),
                              const SizedBox(height: 8),
                              Text(meta,
                                  style: const TextStyle(
                                      color: Color(0xFFF0B84D),
                                      fontWeight: FontWeight.w800))
                            ]))
                      ]),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(42),
                          side: const BorderSide(color: Color(0xFF35D6C2)),
                          foregroundColor: const Color(0xFF58E2CF)),
                      onPressed: onTap,
                      icon: Icon(button.contains('View')
                          ? Icons.visibility_rounded
                          : Icons.person_add_alt_1_rounded),
                      label: Text(button,
                          style: const TextStyle(fontWeight: FontWeight.w800)))
                ]))
      ]));
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({required this.friend, required this.onTap});
  final SocialPlayerDto friend;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF2A485C))),
      tileColor: const Color(0xEE0A1C2B),
      leading: CircleAvatar(
          backgroundImage:
              friend.photoUrl == null ? null : NetworkImage(friend.photoUrl!),
          child: friend.photoUrl == null
              ? Text(friend.displayName.substring(0, 1).toUpperCase())
              : null),
      title: Text(friend.displayName,
          style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(friend.online
          ? 'Online • Tap to chat'
          : 'Offline • Messages sync securely'),
      trailing: const Icon(Icons.chevron_right_rounded));
}

class _EmptyCommunity extends StatelessWidget {
  const _EmptyCommunity();
  @override
  Widget build(BuildContext context) => Container(
      constraints: const BoxConstraints(minHeight: 330),
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: <Color>[Color(0xF20A1D2D), Color(0xF2071624)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF315166))),
      child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
                radius: 52,
                backgroundColor: Color(0xFF082A36),
                child: Icon(Icons.forum_outlined,
                    size: 52, color: Color(0xFF55E4CF))),
            SizedBox(height: 24),
            Text('Nothing here yet.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text('Add a friend to start your\nchess network.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFFAAB8C4), fontSize: 17, height: 1.35))
          ]));
}

class _ChatScreen extends StatefulWidget {
  const _ChatScreen(
      {required this.friend, required this.api, required this.token});
  final SocialPlayerDto friend;
  final CommunityApi api;
  final String token;
  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _composerFocus = FocusNode();
  List<MessageDto> _messages = <MessageDto>[];
  MessageDto? _replyingTo;
  bool _busy = true;
  Timer? _pollTimer;
  @override
  void initState() {
    super.initState();
    _composerFocus.addListener(() {
      if (_composerFocus.hasFocus) _scrollToLatest();
    });
    _load();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _text.dispose();
    _composerFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    void move() {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => move());
    Future<void>.delayed(const Duration(milliseconds: 90), move);
    Future<void>.delayed(const Duration(milliseconds: 280), move);
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final v = await widget.api.messages(widget.token, widget.friend.playerId);
      if (mounted)
        setState(() {
          _messages = v;
          _busy = false;
        });
      if (!silent) _scrollToLatest();
    } on SocialException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        if (!silent)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty) return;
    final String outgoingBody = _replyingTo == null
        ? body
        : '↪ ${_replyingTo!.body.replaceAll('\n', ' ')}\n$body';
    _text.clear();
    setState(() => _replyingTo = null);
    final pending = MessageDto(
        id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
        senderId: '',
        recipientId: widget.friend.playerId,
        body: outgoingBody,
        mine: true,
        sentAt: DateTime.now(),
        delivered: false,
        seen: false,
        pending: true);
    if (mounted)
      setState(() => _messages = <MessageDto>[..._messages, pending]);
    _scrollToLatest();
    try {
      final m = await widget.api
          .send(widget.token, widget.friend.playerId, outgoingBody);
      if (mounted)
        setState(() => _messages =
            _messages.map((item) => item.id == pending.id ? m : item).toList());
      _scrollToLatest();
    } on SocialException catch (e) {
      if (mounted) {
        setState(() => _messages.removeWhere((item) => item.id == pending.id));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _attach() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final PlatformFile file = result.files.single;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This file could not be opened.')));
      return;
    }
    if (bytes.length > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a file smaller than 10 MB.')));
      return;
    }
    final String caption = _text.text.trim();
    _text.clear();
    try {
      final MessageDto message = await widget.api.sendAttachment(
          widget.token,
          widget.friend.playerId,
          file.name,
          bytes,
          _mimeFor(file.name),
          caption);
      if (mounted)
        setState(() => _messages = <MessageDto>[..._messages, message]);
      _scrollToLatest();
    } on SocialException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  String _mimeFor(String name) {
    final String value = name.toLowerCase();
    if (value.endsWith('.png')) return 'image/png';
    if (value.endsWith('.jpg') || value.endsWith('.jpeg')) return 'image/jpeg';
    if (value.endsWith('.webp')) return 'image/webp';
    if (value.endsWith('.gif')) return 'image/gif';
    if (value.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }

  void _showEmojiPicker() => showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A1C2B),
      isScrollControlled: true,
      builder: (sheetContext) {
        const emojis = <String>[
          '😀',
          '😃',
          '😄',
          '😁',
          '😆',
          '😂',
          '🤣',
          '😊',
          '😇',
          '😍',
          '🥰',
          '😘',
          '😎',
          '🤔',
          '🤩',
          '🥳',
          '😏',
          '😕',
          '😢',
          '😭',
          '😡',
          '😱',
          '🤯',
          '😴',
          '👍',
          '👎',
          '👏',
          '🙌',
          '🤝',
          '💪',
          '🙏',
          '✌️',
          '🤞',
          '👌',
          '👋',
          '🫡️',
          '❤️',
          '💛',
          '💚',
          '💙',
          '💜',
          '💔',
          '💯',
          '🔥',
          '✨',
          '🎉',
          '🏆',
          '🏅',
          '♟️',
          '♞️',
          '♛️',
          '♚️',
          '🎯',
          '⚡',
          '🚀',
          '🌍',
          '✅',
          '❌',
          '❓',
          '💡'
        ];
        return SafeArea(
            child: SizedBox(
                height: 330,
                child: Column(children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 8, 6),
                      child: Row(children: <Widget>[
                        const Expanded(
                            child: Text('Choose emoji',
                                style: TextStyle(fontWeight: FontWeight.w800))),
                        IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded))
                      ])),
                  Expanded(
                      child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 8),
                          itemCount: emojis.length,
                          itemBuilder: (_, index) => InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                _text.text += emojis[index];
                                _text.selection = TextSelection.collapsed(
                                    offset: _text.text.length);
                                _composerFocus.requestFocus();
                              },
                              child: Center(
                                  child: Text(emojis[index],
                                      style: const TextStyle(fontSize: 26))))))
                ])));
      });

  Widget _buildComposer() {
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      if (_replyingTo != null)
        Container(
            margin: const EdgeInsets.fromLTRB(46, 2, 54, 5),
            padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
            decoration: BoxDecoration(
                color: const Color(0xF2102B37),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                    left: BorderSide(color: Color(0xFF45DCCB), width: 3))),
            child: Row(children: <Widget>[
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                    Text(_replyingTo!.mine ? 'You' : widget.friend.displayName,
                        style: const TextStyle(
                            color: Color(0xFF45DCCB),
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                    Text(_replyingTo!.body.replaceAll('\n', ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFFB7C6CD), fontSize: 11)),
                  ])),
              IconButton(
                  onPressed: () => setState(() => _replyingTo = null),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18)),
            ])),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
        Expanded(
            child: Container(
                constraints: const BoxConstraints(minHeight: 46),
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                    color: const Color(0xF2202C33),
                    borderRadius: BorderRadius.circular(24)),
                child: Row(children: <Widget>[
                  IconButton(
                      tooltip: 'Attach image or file',
                      onPressed: _attach,
                      icon: const Icon(Icons.add_rounded,
                          size: 20, color: Color(0xFF54DECD))),
                  Expanded(
                      child: TextField(
                          controller: _text,
                          focusNode: _composerFocus,
                          maxLength: 500,
                          style: const TextStyle(fontSize: 14),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              hintText: 'Message your friend…',
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              suffixIcon: IconButton(
                                  onPressed: _showEmojiPicker,
                                  icon: const Icon(
                                      Icons.sentiment_satisfied_alt_rounded,
                                      color: Color(0xFF42DACA)))))),
                ]))),
        const SizedBox(width: 8),
        IconButton.filled(
            style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFE0AA42),
                foregroundColor: const Color(0xFF151109),
                minimumSize: const Size(48, 48),
                shape: const CircleBorder()),
            onPressed: _send,
            icon: const Icon(Icons.send_rounded)),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF020D16),
      appBar: AppBar(
          toolbarHeight: 58,
          titleSpacing: 0,
          title: Row(children: <Widget>[
            Stack(children: <Widget>[
              CircleAvatar(
                  radius: 19,
                  backgroundColor: const Color(0xFF0A3341),
                  backgroundImage: widget.friend.photoUrl == null
                      ? null
                      : NetworkImage(widget.friend.photoUrl!),
                  child: widget.friend.photoUrl == null
                      ? Text(widget.friend.displayName
                          .substring(0, 1)
                          .toUpperCase())
                      : null),
              Positioned(
                  right: 0,
                  bottom: 1,
                  child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.friend.online
                              ? const Color(0xFF28E898)
                              : const Color(0xFF647783),
                          border: Border.all(
                              color: const Color(0xFF06202E), width: 2))))
            ]),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                  Text(widget.friend.displayName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(widget.friend.online ? 'Online' : 'Offline',
                      style: TextStyle(
                          color: widget.friend.online
                              ? const Color(0xFF48E0C9)
                              : const Color(0xFF91A4B0),
                          fontSize: 11))
                ]))
          ]),
          actions: <Widget>[
            IconButton.outlined(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF45DCCB))),
            const SizedBox(width: 8)
          ]),
      body: Stack(children: <Widget>[
        Positioned.fill(
            child: Image.asset('assets/backgrounds/grandmaster-table-v1.webp',
                fit: BoxFit.cover,
                color: const Color(0x2200B8A5),
                colorBlendMode: BlendMode.softLight)),
        Positioned.fill(child: ColoredBox(color: const Color(0xC9020D16))),
        Positioned.fill(
            child: DecoratedBox(
                decoration: const BoxDecoration(
                    gradient: RadialGradient(
                        center: Alignment(.75, -.45),
                        radius: 1.25,
                        colors: <Color>[
              Color(0x3524D8C2),
              Color(0x00020D16)
            ])))),
        Column(children: <Widget>[
          Expanded(
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: _scroll,
                      padding: EdgeInsets.fromLTRB(
                          MediaQuery.sizeOf(context).width > 800 ? 80 : 14,
                          14,
                          MediaQuery.sizeOf(context).width > 800 ? 80 : 14,
                          20),
                      children: <Widget>[
                          const Row(children: <Widget>[
                            Expanded(child: Divider(color: Color(0xFF23645F))),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Today',
                                    style: TextStyle(
                                        color: Color(0xFFB7C6CD),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700))),
                            Expanded(child: Divider(color: Color(0xFF23645F)))
                          ]),
                          const SizedBox(height: 12),
                          ..._messages.map((m) => _MessageBubble(
                              message: m,
                              token: widget.token,
                              api: widget.api,
                              onReply: () {
                                setState(() => _replyingTo = m);
                                _composerFocus.requestFocus();
                                _scrollToLatest();
                              }))
                        ])),
          SafeArea(
              top: false,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      MediaQuery.sizeOf(context).width > 800 ? 80 : 10,
                      6,
                      MediaQuery.sizeOf(context).width > 800 ? 80 : 10,
                      10),
                  child: _buildComposer()))
        ])
      ]));
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble(
      {required this.message,
      required this.onReply,
      required this.token,
      required this.api});
  final MessageDto message;
  final VoidCallback onReply;
  final String token;
  final CommunityApi api;
  @override
  Widget build(BuildContext context) {
    final h = message.sentAt.hour;
    final hour = h % 12 == 0 ? 12 : h % 12;
    final minute = message.sentAt.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute ${h >= 12 ? 'PM' : 'AM'}';
    final double width = MediaQuery.sizeOf(context).width;
    final List<String> parts = message.body.split('\n');
    final String? quoted = parts.isNotEmpty && parts.first.startsWith('↪ ')
        ? parts.removeAt(0).substring(2)
        : null;
    final String visibleBody = parts.join('\n');
    return Align(
        alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
            onLongPress: onReply,
            child: Container(
                margin: const EdgeInsets.only(bottom: 3),
                constraints:
                    BoxConstraints(maxWidth: width > 800 ? 430 : width * .78),
                child: IntrinsicWidth(
                    child: CustomPaint(
                        painter: _ChatBubblePainter(outgoing: message.mine),
                        child: Padding(
                            padding: EdgeInsets.fromLTRB(message.mine ? 9 : 14,
                                5, message.mine ? 14 : 9, 4),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  if (quoted != null)
                                    Container(
                                        width: double.infinity,
                                        margin:
                                            const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.fromLTRB(
                                            7, 4, 6, 4),
                                        decoration: const BoxDecoration(
                                            color: Color(0x40101A22),
                                            border: Border(
                                                left: BorderSide(
                                                    color: Color(0xFF42DACA),
                                                    width: 2))),
                                        child: Text(quoted,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFFB9C7CC)))),
                                  if (message.attachmentName != null)
                                    _ChatAttachment(
                                        message: message,
                                        token: token,
                                        api: api),
                                  if (message.attachmentName != null &&
                                      visibleBody.isNotEmpty)
                                    const SizedBox(height: 4),
                                  Wrap(
                                      alignment: WrapAlignment.end,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.end,
                                      spacing: 8,
                                      runSpacing: 2,
                                      children: <Widget>[
                                        Text(visibleBody,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                height: 1.22,
                                                color: Color(0xFFF1EEE7))),
                                        Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Text(time,
                                                  style: const TextStyle(
                                                      color: Color(0xFFB2BEC5),
                                                      fontSize: 10)),
                                              if (message.mine) ...<Widget>[
                                                const SizedBox(width: 3),
                                                _ReceiptTicks(
                                                    pending: message.pending,
                                                    delivered:
                                                        message.delivered,
                                                    seen: message.seen)
                                              ]
                                            ])
                                      ])
                                ])))))));
  }
}

class _ReceiptTicks extends StatelessWidget {
  const _ReceiptTicks(
      {required this.pending, required this.delivered, required this.seen});
  final bool pending;
  final bool delivered;
  final bool seen;

  @override
  Widget build(BuildContext context) {
    final Color color =
        seen ? const Color(0xFF20DDF2) : const Color(0xFFA7B4BE);
    if (pending || !delivered) {
      return Icon(Icons.check_rounded, size: 14, color: color);
    }
    return SizedBox(
        width: 18,
        height: 14,
        child: Stack(children: <Widget>[
          Positioned(
              left: 0,
              child: Icon(Icons.check_rounded, size: 14, color: color)),
          Positioned(
              left: 5, child: Icon(Icons.check_rounded, size: 14, color: color))
        ]));
  }
}

class _ChatAttachment extends StatefulWidget {
  const _ChatAttachment(
      {required this.message, required this.token, required this.api});
  final MessageDto message;
  final String token;
  final CommunityApi api;

  @override
  State<_ChatAttachment> createState() => _ChatAttachmentState();
}

class _ChatAttachmentState extends State<_ChatAttachment> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final List<int> bytes =
          await widget.api.attachmentBytes(widget.token, widget.message.id);
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save chat attachment',
        fileName: widget.message.attachmentName,
        bytes: Uint8List.fromList(bytes),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Attachment could not be downloaded.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MessageDto message = widget.message;
    final bool image = message.attachmentType?.startsWith('image/') ?? false;
    if (image) {
      return InkWell(
          onTap: _save,
          child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FutureBuilder<List<int>>(
                  future: widget.api.attachmentBytes(widget.token, message.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData)
                      return Image.memory(Uint8List.fromList(snapshot.data!),
                          width: 230, height: 170, fit: BoxFit.cover);
                    if (snapshot.hasError)
                      return const SizedBox(
                          width: 230,
                          height: 90,
                          child:
                              Center(child: Icon(Icons.broken_image_outlined)));
                    return const SizedBox(
                        width: 230,
                        height: 90,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)));
                  })));
    }
    final double kb = (message.attachmentSize ?? 0) / 1024;
    return InkWell(
        onTap: _save,
        borderRadius: BorderRadius.circular(10),
        child: Container(
            constraints: const BoxConstraints(minWidth: 190),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: const Color(0x33203138),
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Icon(
                  _saving
                      ? Icons.downloading_rounded
                      : Icons.insert_drive_file_outlined,
                  color: const Color(0xFF57DECD)),
              const SizedBox(width: 8),
              Flexible(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                    Text(message.attachmentName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                        '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB · Tap to save',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFFB2BEC5)))
                  ]))
            ])));
  }
}

class _ChatBubblePainter extends CustomPainter {
  const _ChatBubblePainter({required this.outgoing});
  final bool outgoing;

  @override
  void paint(Canvas canvas, Size size) {
    const double radius = 7;
    const double tail = 7;
    final Rect body = Rect.fromLTRB(outgoing ? 0 : tail, 0,
        outgoing ? size.width - tail : size.width, size.height);
    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(radius)));
    if (outgoing) {
      path
        ..moveTo(size.width - tail - 1, size.height - 13)
        ..lineTo(size.width, size.height - 3)
        ..lineTo(size.width - tail - 1, size.height - 5)
        ..close();
    } else {
      path
        ..moveTo(tail + 1, size.height - 13)
        ..lineTo(0, size.height - 3)
        ..lineTo(tail + 1, size.height - 5)
        ..close();
    }
    final Paint fill = Paint()
      ..color = outgoing ? const Color(0xFF075E57) : const Color(0xFF202C33);
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _ChatBubblePainter oldDelegate) =>
      oldDelegate.outgoing != outgoing;
}

class _Hero extends StatelessWidget {
  const _Hero({required this.friendCount, required this.challengeCount});
  final int friendCount, challengeCount;
  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFF3ED7C0)),
            image: const DecorationImage(
                image:
                    AssetImage('assets/backgrounds/home-friends-hero-v1.png'),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                opacity: .38)),
        child: LayoutBuilder(builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 600;
          final Widget identity = const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                Text('YOUR CHESS NETWORK',
                    style: TextStyle(
                        color: Color(0xFFE3B653),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1)),
                SizedBox(height: 5),
                Text('Friends, private challenges and live rivals',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))
              ]));
          final Widget metrics =
              Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
            _Metric('$friendCount', 'FRIENDS'),
            const SizedBox(width: 18),
            _Metric('$challengeCount', 'OPEN')
          ]);
          return Container(
              padding: EdgeInsets.all(compact ? 18 : 24),
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: <Color>[
                Color(0xF5073C42),
                Color(0xE8071A2A),
                Color(0x8A071A2A)
              ])),
              child: compact
                  ? Column(children: <Widget>[
                      Row(children: <Widget>[
                        const CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFF0C5D59),
                            child: Icon(Icons.groups_rounded,
                                size: 30, color: Color(0xFF61E5D0))),
                        const SizedBox(width: 14),
                        identity,
                      ]),
                      const SizedBox(height: 14),
                      Align(alignment: Alignment.centerRight, child: metrics)
                    ])
                  : Row(children: <Widget>[
                      const CircleAvatar(
                          radius: 32,
                          backgroundColor: Color(0xFF0C5D59),
                          child: Icon(Icons.groups_rounded,
                              size: 35, color: Color(0xFF61E5D0))),
                      const SizedBox(width: 18),
                      identity,
                      metrics
                    ]));
        }),
      );
}

class _FriendFinder extends StatelessWidget {
  const _FriendFinder({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: <Color>[Color(0xFF0A1D2D), Color(0xFF071725)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF315166)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Row(children: <Widget>[
              Icon(Icons.people_alt_rounded, color: Color(0xFFF0B74B)),
              SizedBox(width: 10),
              Text('FRIENDS',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7)),
            ]),
            const SizedBox(height: 6),
            const Text('Add friends by their ChessVerseAI username.',
                style: TextStyle(color: Color(0xFFAAB7C2))),
            const SizedBox(height: 14),
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2132),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF456175)),
                ),
                child: const Row(children: <Widget>[
                  Icon(Icons.search_rounded, color: Color(0xFF9CADB9)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Search username or player ID',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Color(0xFF9CADB9))),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add friend')),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(children: <Widget>[
        Text(value,
            style: const TextStyle(
                color: Color(0xFF5FE3CE),
                fontSize: 25,
                fontWeight: FontWeight.w900)),
        Text(label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF93A7B4)))
      ]);
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title,
      required this.icon,
      required this.children,
      this.empty});
  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? empty;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xE60A1B2B),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF29475B))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(children: <Widget>[
              Icon(icon, color: const Color(0xFFE2AE49)),
              const SizedBox(width: 9),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1.1))
            ]),
            const SizedBox(height: 12),
            if (children.isEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Text(empty ?? 'Nothing here yet.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF91A4B0))))
            else
              ...children
          ]));
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard(
      {required this.player,
      required this.primaryLabel,
      required this.onPrimary,
      this.onTap,
      this.secondaryLabel,
      this.onSecondary});
  final SocialPlayerDto player;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x6636AFA5)),
              image: const DecorationImage(
                  image:
                      AssetImage('assets/backgrounds/home-friends-hero-v1.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  opacity: .16),
              gradient: const LinearGradient(colors: <Color>[
                Color(0xFF0C2638),
                Color(0xF20A2132),
                Color(0xC9081A29)
              ])),
          child: Row(children: <Widget>[
            Stack(children: <Widget>[
              CircleAvatar(
                  backgroundImage: player.photoUrl == null
                      ? null
                      : NetworkImage(player.photoUrl!),
                  child: player.photoUrl == null
                      ? Text(player.displayName.substring(0, 1).toUpperCase())
                      : null),
              Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                      radius: 5,
                      backgroundColor: player.online
                          ? const Color(0xFF45E6A8)
                          : const Color(0xFF607684)))
            ]),
            const SizedBox(width: 11),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Text(player.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text('@${player.username} • ${player.rating}',
                      style: const TextStyle(
                          color: Color(0xFF92A6B4), fontSize: 11))
                ])),
            if (secondaryLabel != null)
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            FilledButton(onPressed: onPrimary, child: Text(primaryLabel))
          ])));
}

class _SocialPlayerProfile extends StatelessWidget {
  const _SocialPlayerProfile({required this.player, required this.onChallenge});
  final SocialPlayerDto player;
  final VoidCallback onChallenge;
  @override
  Widget build(BuildContext context) {
    final int rate = player.gamesPlayed == 0
        ? 0
        : (player.wins * 100 / player.gamesPlayed).round();
    return Scaffold(
        backgroundColor: const Color(0xFF020D16),
        appBar: AppBar(
            centerTitle: true,
            title: const Text('PLAYER PROFILE',
                style: TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.4))),
        body: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(padding: const EdgeInsets.all(16), children: <Widget>[
            Container(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(colors: <Color>[
                      Color(0xFF0B4C55),
                      Color(0xFF091B2C),
                      Color(0xFF071521)
                    ]),
                    image: const DecorationImage(
                        image: AssetImage(
                            'assets/backgrounds/grandmaster-table-v1.webp'),
                        fit: BoxFit.cover,
                        opacity: .18),
                    border:
                        Border.all(color: const Color(0xFFE0AD45), width: 1.4)),
                child: Column(children: <Widget>[
                  Stack(children: <Widget>[
                    Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF5DE5D1), width: 2)),
                        child: CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF103747),
                            backgroundImage: player.photoUrl == null
                                ? null
                                : NetworkImage(player.photoUrl!),
                            child: player.photoUrl == null
                                ? Text(
                                    player.displayName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900))
                                : null)),
                    Positioned(
                        right: 4,
                        bottom: 8,
                        child: Container(
                            width: 27,
                            height: 27,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: player.online
                                    ? const Color(0xFF22E58F)
                                    : const Color(0xFF657784),
                                border: Border.all(
                                    color: const Color(0xFFE6B44D), width: 3))))
                  ]),
                  const SizedBox(height: 12),
                  Text(player.displayName,
                      style: const TextStyle(
                          fontSize: 27, fontWeight: FontWeight.w900)),
                  Text('@${player.username} • ${player.country}',
                      style: const TextStyle(
                          color: Color(0xFFABB9C5), fontSize: 15)),
                  const SizedBox(height: 10),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 9),
                      decoration: BoxDecoration(
                          color: const Color(0xFF092A38),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF35CDBB))),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.circle,
                                size: 12,
                                color: player.online
                                    ? const Color(0xFF32EA9D)
                                    : const Color(0xFF7A8993)),
                            const SizedBox(width: 9),
                            Text(player.online ? 'ONLINE' : 'OFFLINE',
                                style: const TextStyle(
                                    color: Color(0xFF62E3D0),
                                    fontWeight: FontWeight.w900))
                          ])),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE4AF45),
                          foregroundColor: const Color(0xFF161207),
                          minimumSize: const Size.fromHeight(50)),
                      onPressed: () {
                        Navigator.pop(context);
                        onChallenge();
                      },
                      icon: const Icon(Icons.castle_rounded, size: 30),
                      label: const Text('CHALLENGE',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)))
                ])),
            const SizedBox(height: 16),
            GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.15,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: <Widget>[
                  _SocialMetric(
                      '${player.rating}', 'RATING', Icons.bar_chart_rounded),
                  _SocialMetric('${player.peakRating}', 'PEAK',
                      Icons.trending_up_rounded),
                  _SocialMetric('${player.gamesPlayed}', 'RATED GAMES',
                      Icons.grid_view_rounded),
                  _SocialMetric(
                      '$rate%', 'WIN RATE', Icons.track_changes_rounded),
                  _SocialMetric(
                      '${player.wins}', 'WINS', Icons.emoji_events_rounded),
                  _SocialMetric(
                      '${player.draws}', 'DRAWS', Icons.handshake_outlined)
                ])
          ]),
        )));
  }
}

class _SocialMetric extends StatelessWidget {
  const _SocialMetric(this.value, this.label, this.icon);
  final String value, label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: const Color(0xFF0A1C2B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF28485B))),
      child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF082837),
                border: Border.all(color: const Color(0xFF1E6570))),
            child: Icon(icon, color: const Color(0xFF58E0CC))),
        const SizedBox(width: 8),
        Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(value,
                  style: const TextStyle(
                      color: Color(0xFF5FE3CE),
                      fontSize: 21,
                      fontWeight: FontWeight.w900)),
              Text(label,
                  style:
                      const TextStyle(color: Color(0xFF91A6B3), fontSize: 10))
            ])
      ]));
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard(
      {required this.challenge, this.onAccept, this.onDecline});
  final SocialChallengeDto challenge;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: const CircleAvatar(
          backgroundColor: Color(0xFF3B2C12),
          child: Icon(Icons.bolt_rounded, color: Color(0xFFFFC857))),
      title: Text(challenge.opponentName,
          style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text('${challenge.minutes} min • Room ${challenge.roomCode}'),
      trailing: onAccept == null
          ? const Chip(label: Text('SENT'))
          : Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              IconButton(
                  onPressed: onDecline,
                  tooltip: 'Decline',
                  icon: const Icon(Icons.close_rounded)),
              FilledButton(onPressed: onAccept, child: const Text('Play'))
            ]));
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        const Icon(Icons.cloud_off_rounded, size: 48),
        const SizedBox(height: 12),
        Text(message),
        const SizedBox(height: 12),
        FilledButton(onPressed: retry, child: const Text('Retry'))
      ]));
}
