import 'package:flutter/material.dart';

import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/data/auth_session_store.dart';
import '../data/online_match_api.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  final OnlineMatchApi _api = const OnlineMatchApi();
  late Future<List<OnlineMatchDto>> _online = _load();

  Future<List<OnlineMatchDto>> _load() async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (session == null) return const <OnlineMatchDto>[];
    return _api.history(session.token);
  }

  Future<void> _refresh() async {
    final Future<List<OnlineMatchDto>> next = _load();
    setState(() => _online = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('MATCH HISTORY'),
        backgroundColor: const Color(0xD9071827),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<OnlineMatchDto>>(
          future: _online,
          builder: (BuildContext context,
              AsyncSnapshot<List<OnlineMatchDto>> snapshot) {
            final List<OnlineMatchDto> online =
                snapshot.data ?? const <OnlineMatchDto>[];
            final List<SavedGameRecord> local = LocalGameArchive.games;
            if (snapshot.connectionState == ConnectionState.waiting &&
                online.isEmpty) {
              return const SkeletonPage(rows: 5);
            }
            if (snapshot.hasError && online.isEmpty && local.isEmpty) {
              return _HistoryMessage(
                icon: Icons.cloud_off_rounded,
                message: 'Match history could not be loaded. Pull to retry.',
                detail: '${snapshot.error}',
              );
            }
            if (online.isEmpty && local.isEmpty) {
              return const _HistoryMessage(
                icon: Icons.history_rounded,
                message: 'Your completed matches will appear here.',
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                if (online.isNotEmpty) ...<Widget>[
                  const _Heading('ONLINE ARENA'),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap a completed game to replay every move.',
                    style: TextStyle(color: Color(0xFF8FA5B1), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ...online.map(
                    (OnlineMatchDto match) => _OnlineHistoryCard(
                      match,
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => OnlineMatchReplayScreen(match: match),
                        ),
                      ),
                    ),
                  ),
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

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.message,
    this.detail,
  });
  final IconData icon;
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: 180),
          Icon(icon, size: 58, color: const Color(0xFF607A87)),
          const SizedBox(height: 14),
          Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9CB0BA)),
            ),
          ),
          if (detail != null) ...<Widget>[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                detail!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF607A87), fontSize: 11),
              ),
            ),
          ],
        ],
      );
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
  const _OnlineHistoryCard(this.match, {required this.onTap});
  final OnlineMatchDto match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _MatchPresentation presentation = _MatchPresentation(match);
    return _HistoryShell(
      accent: presentation.accent,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          _PlayerAvatar(
            name: presentation.opponent,
            photoUrl: presentation.opponentPhotoUrl,
            color: presentation.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  presentation.outcome,
                  style: TextStyle(
                    color: presentation.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'vs ${presentation.opponent}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${presentation.reason}  •  ${match.moves.length} ply  •  ${_formatDuration(match.durationSeconds)}',
                  style: const TextStyle(
                    color: Color(0xFF8FA5B1),
                    fontSize: 11,
                  ),
                ),
                if (match.finishedAt != null)
                  Text(
                    _formatDate(match.finishedAt!),
                    style: const TextStyle(
                      color: Color(0xFF607A87),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                match.result ?? '—',
                style: TextStyle(
                  color: presentation.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (presentation.ratingDelta != null)
                Text(
                  '${presentation.ratingDelta! >= 0 ? '+' : ''}${presentation.ratingDelta}',
                  style: const TextStyle(fontSize: 11),
                ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8FA5B1)),
            ],
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
                    '${game.mode} • ${game.moves.length} ply • ${_formatDate(game.playedAt)}',
                    style:
                        const TextStyle(color: Color(0xFF8FA5B1), fontSize: 11),
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
  const _HistoryShell({
    required this.accent,
    required this.child,
    this.onTap,
  });
  final Color accent;
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xE60C1D2B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(14), child: child),
          ),
        ),
      );
}

class OnlineMatchReplayScreen extends StatefulWidget {
  const OnlineMatchReplayScreen({required this.match, super.key});
  final OnlineMatchDto match;

  @override
  State<OnlineMatchReplayScreen> createState() =>
      _OnlineMatchReplayScreenState();
}

class _OnlineMatchReplayScreenState extends State<OnlineMatchReplayScreen> {
  late final List<Map<String, String>> _positions =
      _ReplayPositionBuilder.build(widget.match.moves);
  int _ply = 0;

  @override
  Widget build(BuildContext context) {
    final OnlineMatchDto match = widget.match;
    final _MatchPresentation presentation = _MatchPresentation(match);
    final bool flipped = match.yourColor.toLowerCase() == 'black';
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('GAME REPLAY'),
        backgroundColor: const Color(0xD9071827),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double boardSize =
                constraints.maxWidth.clamp(280.0, 620.0).toDouble();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: <Widget>[
                _ReplayPlayers(match: match, presentation: presentation),
                const SizedBox(height: 14),
                Center(
                  child: SizedBox.square(
                    dimension: boardSize - 32,
                    child: _ReplayBoard(
                      pieces: _positions[_ply],
                      flipped: flipped,
                      lastMove: _ply == 0 ? null : match.moves[_ply - 1].uci,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _ply == 0
                      ? 'Starting position'
                      : 'Move $_ply of ${match.moves.length}: ${match.moves[_ply - 1].uci}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Slider(
                  value: _ply.toDouble(),
                  max: match.moves.length.toDouble().clamp(1, double.infinity),
                  divisions: match.moves.isEmpty ? 1 : match.moves.length,
                  label: '$_ply',
                  onChanged: (double value) =>
                      setState(() => _ply = value.round()),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _ply == 0 ? null : () => setState(() => _ply--),
                        icon: const Icon(Icons.skip_previous_rounded),
                        label: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _ply == match.moves.length
                            ? null
                            : () => setState(() => _ply++),
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Next'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: List<Widget>.generate(match.moves.length, (int i) {
                    final bool active = _ply == i + 1;
                    return ActionChip(
                      backgroundColor: active
                          ? AppColors.accentGold
                          : const Color(0xFF102435),
                      label: Text('${i + 1}. ${match.moves[i].uci}'),
                      onPressed: () => setState(() => _ply = i + 1),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReplayPlayers extends StatelessWidget {
  const _ReplayPlayers({required this.match, required this.presentation});
  final OnlineMatchDto match;
  final _MatchPresentation presentation;
  @override
  Widget build(BuildContext context) => _HistoryShell(
        accent: presentation.accent,
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(child: Text('You • ${match.yourColor}')),
                Text(
                  presentation.outcome,
                  style: TextStyle(
                    color: presentation.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Expanded(
                  child: Text(
                    presentation.opponent,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '${presentation.reason} • ${_formatDuration(match.durationSeconds)} • ${match.result ?? '—'}',
              style: const TextStyle(color: Color(0xFF8FA5B1), fontSize: 12),
            ),
          ],
        ),
      );
}

class _ReplayBoard extends StatelessWidget {
  const _ReplayBoard({
    required this.pieces,
    required this.flipped,
    this.lastMove,
  });
  final Map<String, String> pieces;
  final bool flipped;
  final String? lastMove;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (BuildContext context, int index) {
            final int row = index ~/ 8;
            final int col = index % 8;
            final int file = flipped ? 7 - col : col;
            final int rank = flipped ? row + 1 : 8 - row;
            final String square = '${String.fromCharCode(97 + file)}$rank';
            final bool highlighted = lastMove != null &&
                lastMove!.length >= 4 &&
                (square == lastMove!.substring(0, 2) ||
                    square == lastMove!.substring(2, 4));
            return ColoredBox(
              color: highlighted
                  ? const Color(0xFFD9A83E)
                  : (row + col).isEven
                      ? const Color(0xFFD8C8A8)
                      : const Color(0xFF775436),
              child: Center(
                child: Text(
                  _pieceGlyph(pieces[square]),
                  style: const TextStyle(fontSize: 32, height: 1),
                ),
              ),
            );
          },
        ),
      );
}

class _ReplayPositionBuilder {
  static List<Map<String, String>> build(List<OnlineMoveDto> moves) {
    final Map<String, String> board = _initialBoard();
    final List<Map<String, String>> result = <Map<String, String>>[
      Map<String, String>.from(board),
    ];
    for (final OnlineMoveDto move in moves) {
      final String uci = move.uci.toLowerCase();
      if (uci.length < 4) {
        result.add(Map<String, String>.from(board));
        continue;
      }
      final String from = uci.substring(0, 2);
      final String to = uci.substring(2, 4);
      String? piece = board.remove(from);
      if (piece == null) {
        result.add(Map<String, String>.from(board));
        continue;
      }
      final bool targetWasEmpty = !board.containsKey(to);
      if (piece.toLowerCase() == 'p' && from[0] != to[0] && targetWasEmpty) {
        board.remove('${to[0]}${from[1]}');
      }
      board.remove(to);
      if (piece.toLowerCase() == 'k' &&
          (from.codeUnitAt(0) - to.codeUnitAt(0)).abs() == 2) {
        final bool kingSide = to.startsWith('g');
        final String rookFrom = '${kingSide ? 'h' : 'a'}${from[1]}';
        final String rookTo = '${kingSide ? 'f' : 'd'}${from[1]}';
        final String? rook = board.remove(rookFrom);
        if (rook != null) board[rookTo] = rook;
      }
      if (uci.length >= 5) {
        piece = piece == piece.toUpperCase()
            ? uci[4].toUpperCase()
            : uci[4].toLowerCase();
      }
      board[to] = piece;
      result.add(Map<String, String>.from(board));
    }
    return result;
  }

  static Map<String, String> _initialBoard() {
    const String files = 'abcdefgh';
    const String back = 'rnbqkbnr';
    final Map<String, String> board = <String, String>{};
    for (int i = 0; i < 8; i++) {
      board['${files[i]}1'] = back[i].toUpperCase();
      board['${files[i]}2'] = 'P';
      board['${files[i]}7'] = 'p';
      board['${files[i]}8'] = back[i];
    }
    return board;
  }
}

class _MatchPresentation {
  _MatchPresentation(this.match)
      : white = match.yourColor.toLowerCase() == 'white' {
    final String result = match.result ?? '';
    won = (result == '1-0' && white) || (result == '0-1' && !white);
    draw = result == '1/2-1/2';
  }
  final OnlineMatchDto match;
  final bool white;
  late final bool won;
  late final bool draw;
  String get opponent => white
      ? (match.blackPlayerName ?? 'Opponent')
      : (match.whitePlayerName ?? 'Opponent');
  String? get opponentPhotoUrl =>
      white ? match.blackPlayerPhotoUrl : match.whitePlayerPhotoUrl;
  String get outcome => draw
      ? 'DRAW'
      : won
          ? 'VICTORY'
          : 'DEFEAT';
  String get reason => (match.resultReason ?? 'FINISHED')
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((String word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
  Color get accent => draw
      ? AppColors.accentGold
      : won
          ? const Color(0xFF63D2B8)
          : const Color(0xFFF08A6A);
  int? get ratingDelta =>
      match.ratingBefore == null || match.ratingAfter == null
          ? null
          : match.ratingAfter! - match.ratingBefore!;
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({
    required this.name,
    required this.photoUrl,
    required this.color,
  });
  final String name;
  final String? photoUrl;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final String clean = name.trim();
    final String initials = clean.isEmpty
        ? '?'
        : clean
            .split(RegExp(r'\s+'))
            .take(2)
            .map((String part) => part[0].toUpperCase())
            .join();
    final Uri? uri = Uri.tryParse(photoUrl ?? '');
    final bool networkPhoto =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.18),
      backgroundImage: networkPhoto ? NetworkImage(photoUrl!) : null,
      child:
          networkPhoto ? null : Text(initials, style: TextStyle(color: color)),
    );
  }
}

String _formatDuration(int? seconds) {
  if (seconds == null) return 'Duration unavailable';
  final int hours = seconds ~/ 3600;
  final int minutes = (seconds % 3600) ~/ 60;
  final int remaining = seconds % 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m ${remaining.toString().padLeft(2, '0')}s';
}

String _formatDate(DateTime date) {
  final DateTime local = date.toLocal();
  final String day = local.day.toString().padLeft(2, '0');
  final String month = local.month.toString().padLeft(2, '0');
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} • $hour:$minute';
}

String _pieceGlyph(String? piece) => switch (piece) {
      'K' => '♔',
      'Q' => '♕',
      'R' => '♖',
      'B' => '♗',
      'N' => '♘',
      'P' => '♙',
      'k' => '♚',
      'q' => '♛',
      'r' => '♜',
      'b' => '♝',
      'n' => '♞',
      'p' => '♟',
      _ => '',
    };
