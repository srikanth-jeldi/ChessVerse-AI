import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_language.dart';
import '../../../core/club_localizations.dart';
import '../../../core/mistake_bank_localizations.dart';
import '../../../core/mistake_practice_localizations.dart';

import '../../../main.dart'
    show ChessBoard, ChessPiece, BoardSkin, boardPalettes;
import '../../online/data/online_match_api.dart';
import '../data/community_api.dart';
import '../data/social_api.dart';

mixin ClubLanguage<T extends StatefulWidget> on State<T> {
  String language =
      AppLanguageController.effectiveLanguageChanges.value ??
      AppLanguageController.resolveCode('system');
  String t(String key) => clubText(key, language);
  TextDirection get direction => ['ar', 'ur', 'fa', 'he'].contains(language)
      ? TextDirection.rtl
      : TextDirection.ltr;
  @override
  void initState() {
    super.initState();
    AppLanguageController.effectiveLanguageChanges.addListener(
      _languageChanged,
    );
    unawaited(
      AppLanguageController.effectiveCode()
          .then<void>((value) {
            if (mounted) setState(() => language = value);
          })
          .catchError((Object _) {
            /* Retain the resolved device language. */
          }),
    );
  }

  void _languageChanged() {
    if (mounted) {
      setState(
        () => language =
            AppLanguageController.effectiveLanguageChanges.value ?? language,
      );
    }
  }

  @override
  void dispose() {
    AppLanguageController.effectiveLanguageChanges.removeListener(
      _languageChanged,
    );
    super.dispose();
  }

  Future<void> chooseLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: ListView(
            children: AppLanguageController.supported
                .where((l) => l.code != 'system')
                .map(
                  (l) => ListTile(
                    title: Text(l.nativeName),
                    trailing: l.code == language
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.pop(context, l.code),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      try {
        await AppLanguageController.select(selected);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(t('error'))));
        }
      }
    }
  }

  Widget languageButton() => IconButton(
    key: const ValueKey('club-language'),
    tooltip: AppLanguageController.byCode(language).nativeName,
    onPressed: chooseLanguage,
    icon: const Icon(Icons.translate_rounded),
  );
}

/// The club is a destination after joining, rather than a leave-only card.
class ClubActivityScreen extends StatefulWidget {
  const ClubActivityScreen({
    super.key,
    required this.club,
    required this.token,
    this.onOpenMatch,
    this.socialApi = const SocialApi(),
    this.api = const CommunityApi(),
  });
  final ClubDto club;
  final String token;
  final ValueChanged<OnlineMatchDto>? onOpenMatch;
  final CommunityApi api;
  final SocialApi socialApi;
  @override
  State<ClubActivityScreen> createState() => _ClubActivityScreenState();
}

class _ClubActivityScreenState extends State<ClubActivityScreen>
    with ClubLanguage<ClubActivityScreen> {
  int _tab = 0;
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = false;
  bool _acting = false;
  List<SocialChallengeDto> _challenges = [];
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (ModalRoute.of(context)?.isCurrent == true && !_acting) {
        unawaited(_load());
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.api.clubActivities(
        widget.token,
        widget.club.id,
      );
      if (!mounted) return;
      setState(() => _data = data);
      // Club activities remain available when the separate invitations feed fails.
      SocialHubDto? hub;
      try {
        hub = await widget.socialApi.load(widget.token);
      } on SocialException {
        /* retry on refresh */
      }
      if (!mounted) return;
      setState(() {
        _data = data;
        _challenges =
            hub?.challenges
                .where((c) => c.status == 'PENDING' || c.status == 'ACCEPTED')
                .toList() ??
            [];
      });
    } on SocialException {
      if (mounted) setState(() => _error = t('error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await action();
    } on SocialException {
      _message(t('error'));
    } on OnlineMatchException {
      _message(t('error'));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _challenge(Map<String, dynamic> member) async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${t('challenge')} · ${member['name']}",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [3, 5, 10, 15]
                    .map(
                      (m) => FilledButton(
                        onPressed: () => Navigator.pop(context, m),
                        child: Text("$m ${t('minutes')}"),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (minutes == null || !mounted) return;
    await _act(() async {
      await widget.api.clubChallenge(
        widget.token,
        widget.club.id,
        member['id'] as String,
        minutes,
      );
      _message(t('sent'));
      await _load();
    });
  }

  Future<void> _openChallenge(SocialChallengeDto c) => _act(() async {
    final match = c.incoming && c.status == 'PENDING'
        ? await widget.socialApi.acceptChallenge(widget.token, c.id)
        : await const OnlineMatchApi().getMatch(widget.token, c.matchId);
    if (mounted) widget.onOpenMatch?.call(match);
  });

  Future<void> _leave() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('leave')),
        content: Text(t('leaveBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('leave')),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await _act(() async {
      await widget.api.club(widget.token, widget.club.id, false);
      if (mounted) Navigator.pop(context);
    });
  }

  Widget _panel(Widget child, {bool hero = false}) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        colors: hero
            ? [const Color(0xFF123D48), const Color(0xFF111D31)]
            : [const Color(0xFF101E30), const Color(0xFF101E30)],
      ),
      border: Border.all(
        color: hero ? const Color(0xFF638B78) : const Color(0xFF293B50),
      ),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final members = (data?['members'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final scores = (data?['leaderboard'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final completed = data?['completed'] == true;
    return Directionality(
      textDirection: direction,
      child: Theme(
        data: ThemeData.dark(useMaterial3: true).copyWith(
          textTheme: Theme.of(context).textTheme
              .apply(bodyColor: Colors.white, displayColor: Colors.white),
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF07121F),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF62DEC6),
            secondary: Color(0xFFE5BE65),
            surface: Color(0xFF101E30),
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF07121F),
            title: Text(widget.club.name, maxLines: 2),
            actions: [
              languageButton(),
              IconButton(
                tooltip: t('refresh'),
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
              PopupMenuButton<String>(
                enabled: !_acting,
                onSelected: (_) => _leave(),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'leave', child: Text(t('leave'))),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null)
                    _panel(
                      Column(
                        children: [
                          const Icon(Icons.wifi_off_rounded),
                          const SizedBox(height: 12),
                          Text(t('error')),
                          TextButton(onPressed: _load, child: Text(t('retry'))),
                        ],
                      ),
                    ),
                  if (data != null) ...[
                    _panel(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                completed
                                    ? Icons.task_alt
                                    : Icons.extension_rounded,
                                color: const Color(0xFFE5BE65),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t('daily'),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t('goal'),
                            style: const TextStyle(
                              color: Color(0xFFB5CBD4),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text("+10 ${t('points')}")),
                              Chip(
                                avatar: const Icon(
                                  Icons.people_outline,
                                  size: 18,
                                ),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("${data['completedMembers']}"),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check, size: 16),
                                  ],
                                ),
                              ),
                              Chip(label: Text(data['day'] as String)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              key: const ValueKey('club-daily-puzzle'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              icon: Icon(
                                completed
                                    ? Icons.replay
                                    : Icons.play_arrow_rounded,
                              ),
                              label: Text(
                                t(completed ? 'done' : 'play'),
                                textAlign: TextAlign.center,
                              ),
                              onPressed: _acting
                                  ? null
                                  : () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => ClubPuzzleScreen(
                                            api: widget.api,
                                            token: widget.token,
                                            clubId: widget.club.id,
                                            day: data['day'] as String,
                                            initialFen: data['fen'] as String,
                                          ),
                                        ),
                                      );
                                      if (mounted) await _load();
                                    },
                            ),
                          ),
                        ],
                      ),
                      hero: true,
                    ),
                    if (_challenges.isNotEmpty)
                      _panel(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('invites'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            ..._challenges.map(
                              (c) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(c.opponentName),
                                subtitle: Text("${c.minutes} ${t('minutes')}"),
                                trailing: TextButton(
                                  onPressed:
                                      _acting ||
                                          widget.onOpenMatch == null ||
                                          (!c.incoming && c.status == 'PENDING')
                                      ? null
                                      : () => _openChallenge(c),
                                  child: Text(
                                    c.status == 'PENDING'
                                        ? t(c.incoming ? 'accept' : 'waiting')
                                        : t('openMatch'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          key: const ValueKey('club-members-tab'),
                          selected: _tab == 0,
                          label: Text(t('members')),
                          onSelected: (_) => setState(() => _tab = 0),
                        ),
                        ChoiceChip(
                          key: const ValueKey('club-week-tab'),
                          selected: _tab == 1,
                          label: Text(t('week')),
                          onSelected: (_) => setState(() => _tab = 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_tab == 0)
                      ...members.map(
                        (m) => _panel(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF213B48),
                                    child: Icon(
                                      Icons.person_outline,
                                      color: m['online'] == true
                                          ? const Color(0xFF62DEC6)
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "${m['name']}${m['self'] == true ? ' · ${t('you')}' : ''}",
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${m['rating']} · ${t(m['online'] == true ? 'online' : 'offline')}",
                              ),
                              if (m['self'] != true)
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: OutlinedButton.icon(
                                    onPressed: _acting
                                        ? null
                                        : () => _challenge(m),
                                    icon: const Icon(
                                      Icons.sports_esports_outlined,
                                    ),
                                    label: Text(t('challenge')),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (_tab == 1) ...[
                      _panel(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['weekStart'] as String,
                              style: const TextStyle(color: Color(0xFFE5BE65)),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              t('rules'),
                              style: const TextStyle(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      if (scores.isEmpty)
                        _panel(
                          Column(
                            children: [
                              const Icon(
                                Icons.emoji_events_outlined,
                                size: 40,
                                color: Color(0xFFE5BE65),
                              ),
                              const SizedBox(height: 12),
                              Text(t('empty')),
                            ],
                          ),
                        ),
                      ...scores.indexed.map(
                        (entry) => _panel(
                          Row(
                            children: [
                              Text(
                                '#${entry.$1 + 1}',
                                style: const TextStyle(
                                  color: Color(0xFFE5BE65),
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Text(entry.$2['name'] as String)),
                              const SizedBox(width: 8),
                              Text("${entry.$2['points']} ${t('points')}"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClubPuzzleScreen extends StatefulWidget {
  const ClubPuzzleScreen({
    super.key,
    required this.api,
    required this.token,
    required this.clubId,
    required this.day,
    required this.initialFen,
  });
  final CommunityApi api;
  final String token, clubId, day, initialFen;
  @override
  State<ClubPuzzleScreen> createState() => _ClubPuzzleScreenState();
}

class _ClubPuzzleScreenState extends State<ClubPuzzleScreen>
    with ClubLanguage<ClubPuzzleScreen> {
  late String _fen = widget.initialFen;
  final List<String> _moves = [];
  String? _selected;
  String? _feedback;
  bool _busy = false, _complete = false;
  Map<String, ChessPiece> _pieces() {
    final pieces = <String, ChessPiece>{};
    final rows = _fen.split(' ').first.split('/');
    for (var row = 0; row < 8; row++) {
      var file = 0;
      for (final symbol in rows[row].split('')) {
        final count = int.tryParse(symbol);
        if (count != null) {
          file += count;
        } else {
          pieces['${String.fromCharCode(97 + file)}${8 - row}'] = ChessPiece(
            symbol.toUpperCase(),
            symbol == symbol.toUpperCase(),
          );
          file++;
        }
      }
    }
    return pieces;
  }

  Future<void> _tap(String square) async {
    if (_busy || _complete) return;
    final pieces = _pieces();
    final white = _fen.split(' ')[1] == 'w';
    if (pieces[square]?.white == white) {
      setState(() => _selected = square);
      return;
    }
    final from = _selected;
    if (from == null) return;
    String promotion = '';
    if (pieces[from]?.code == 'P' &&
        (square.endsWith('8') || square.endsWith('1'))) {
      final chosen = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(mistakeBankText('P', language)),
          children: ['q', 'r', 'b', 'n']
              .map(
                (p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, p),
                  child: Text(mistakeBankText(p.toUpperCase(), language)),
                ),
              )
              .toList(),
        ),
      );
      if (chosen == null || !mounted) return;
      promotion = chosen;
    }
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      final moves = [..._moves, '$from$square$promotion'];
      final result = await widget.api.clubPuzzle(
        widget.token,
        widget.clubId,
        widget.day,
        moves,
      );
      if (!mounted) return;
      setState(() {
        if (result['correct'] == true) {
          _moves.add(moves.last);
          _fen = result['fen'] as String;
          _complete = result['completed'] == true;
          _feedback = _complete ? 'complete' : 'goal';
        } else {
          _feedback = 'wrong';
        }
        _selected = null;
      });
    } on SocialException {
      if (mounted) setState(() => _feedback = 'error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: direction,
    child: Scaffold(
      appBar: AppBar(title: Text(t('daily')), actions: [languageButton()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _complete
                ? t('done')
                : t(_fen.split(' ')[1] == 'w' ? 'white' : 'black'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(mistakeBankText('instructions', language)),
          if (_feedback != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _feedback == 'wrong'
                    ? mistakePracticeText('unverified', language)
                    : t(_feedback!),
                key: const ValueKey('club-puzzle-feedback'),
              ),
            ),
          if (_busy) const LinearProgressIndicator(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AspectRatio(
                aspectRatio: 1,
                child: ChessBoard(
                  pieces: _pieces(),
                  selectedSquare: _selected,
                  legalTargets: const {},
                  lastFromSquare: null,
                  lastToSquare: null,
                  lastCaptureSquare: null,
                  moveSequence: _moves.length,
                  checkedKingSquare: null,
                  decisiveSquare: null,
                  coachArrowFrom: null,
                  coachArrowTo: null,
                  flipped: widget.initialFen.split(' ')[1] == 'b',
                  showCoordinates: true,
                  palette: boardPalettes[BoardSkin.royalWalnut]!,
                  onSquareTap: _tap,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_complete)
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('open')),
            ),
          if (!_complete)
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _moves.clear();
                      _fen = widget.initialFen;
                      _selected = null;
                      _feedback = null;
                    }),
              child: Text(t('restart')),
            ),
        ],
      ),
    ),
  );
}
