import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../../core/app_preferences.dart';
import '../../../core/chess_piece_appearance.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart'
    show
        boardSkinForTheme,
        BoardSkin,
        BoardStage,
        PracticeMatchStudio,
        ChessBoard,
        ChessPiece,
        ChessRules,
        boardPalettes,
        gamePiecesFromFen;
import '../../../core/widgets/player_avatar.dart';
import '../../analysis/domain/pgn_position_reconstructor.dart'
    show replayUciLine;
import '../data/community_api.dart';
import '../data/social_api.dart';

class DailyPracticeCupScreen extends StatefulWidget {
  const DailyPracticeCupScreen({
    super.key,
    required this.api,
    required this.token,
  });
  final CommunityApi api;
  final String token;
  @override
  State<DailyPracticeCupScreen> createState() => _CupState();
}

class _CupState extends State<DailyPracticeCupScreen> {
  Map<String, dynamic>? cup, position;
  String? selected, error;
  bool busy = false;
  int? retryBoard;
  BoardSkin skin = BoardSkin.royalWalnut;
  bool coordinates = true;
  Timer? poll;
  String? previewFen;
  String? lastFrom, lastTo, captureSquare;
  ChessPiece? moved, captured;

  void recordTransition(String fen, String uci) {
    final before = gamePiecesFromFen(fen);
    lastFrom = uci.substring(0, 2);
    lastTo = uci.substring(2, 4);
    moved = before[lastFrom];
    captureSquare = lastTo;
    if (moved?.code == 'P' &&
        lastFrom![0] != lastTo![0] &&
        before[lastTo] == null) {
      captureSquare = '${lastTo![0]}${lastFrom![1]}';
    }
    captured = before[captureSquare];
  }

  @override
  void initState() {
    super.initState();
    loadBoardPreferences();
    refresh();
  }

  Future<void> loadBoardPreferences() async {
    const prefs = AppPreferences();
    final values = await Future.wait([
      prefs.readString('boardTheme', fallback: 'Royal Walnut'),
      prefs.readString('pieceStyle', fallback: 'Premium 3D'),
      prefs.readString('pieceSize', fallback: 'Extra Large'),
      prefs.readString('pieceFinish', fallback: 'classic-staunton'),
      prefs.readBool('coordinates', fallback: true),
    ]);
    if (!mounted) return;
    ChessPieceAppearanceController.current.value = ChessPieceAppearance(
      style: ChessPieceAppearanceController.styleFromLabel(values[1] as String),
      size: ChessPieceAppearanceController.sizeFromLabel(values[2] as String),
      finish: values[3] as String,
    );
    setState(() {
      skin = boardSkinForTheme(values[0] as String);
      coordinates = values[4] as bool;
    });
  }

  @override
  void dispose() {
    poll?.cancel();
    super.dispose();
  }

  Future<void> refresh({int? board, String? move}) async {
    if (busy) return;
    poll?.cancel();
    setState(() {
      busy = true;
      retryBoard = board;
      error = null;
    });
    try {
      if (board == null) {
        final data = cup == null
            ? await widget.api.joinDailyPractice(widget.token)
            : await widget.api.dailyPracticeStandings(widget.token, cup!['id']);
        if (mounted) {
          setState(() {
            cup = data;
            position = null;
            selected = null;
          });
          final seconds = (data['lobbySeconds'] as int?) ?? 0;
          if (seconds > 0) {
            poll = Timer(
              Duration(seconds: ((seconds - 1) % 10 + 1).clamp(1, 5)),
              () => refresh(),
            );
          } else if (games.any((game) => game['result'] == '*')) {
            poll = Timer(const Duration(seconds: 10), () => refresh());
          }
        }
      } else {
        Future<void>? animation;
        if (move != null && position != null) {
          final fen = position!['fen'] as String;
          final frames = replayUciLine(fen, [move]);
          if (frames.length == 2) {
            setState(() {
              recordTransition(fen, move);
              selected = null;
              previewFen = frames.last;
            });
            animation = Future<void>.delayed(
              Duration(milliseconds: captured == null ? 400 : 520),
            );
          }
        }
        final data = await widget.api.practiceBoard(
          widget.token,
          cup!['id'],
          board,
          move: move,
          ply: move == null ? null : position!['ply'],
        );
        if (!mounted) return;
        if (animation != null) await animation;
        if (!mounted) return;
        final previous = position;
        final previousPly = previous?['ply'] as int? ?? 0;
        final ply = data['ply'] as int;
        final game = (data['cup']['games'] as List).firstWhere(
          (g) => g['number'] == board,
        );
        final history = (game['moves'] as String? ?? '')
            .split(' ')
            .where((m) => m.isNotEmpty)
            .toList();
        if (previous?['board'] == board &&
            ply > previousPly &&
            history.length == ply) {
          final pending = history.sublist(previousPly);
          final frames = replayUciLine(previous!['fen'], pending);
          if (frames.length == pending.length + 1) {
            final alreadyShown =
                previewFen != null &&
                pending.isNotEmpty &&
                pending.first == move &&
                frames[1] == previewFen;
            for (var i = alreadyShown ? 1 : 0; i < pending.length; i++) {
              recordTransition(frames[i], pending[i]);
              if (i + 1 < pending.length) {
                setState(() {
                  selected = null;
                  previewFen = null;
                  position = {
                    ...previous,
                    'fen': frames[i + 1],
                    'ply': previousPly + i + 1,
                  };
                });
                await Future<void>.delayed(
                  Duration(milliseconds: captured == null ? 400 : 520),
                );
                if (!mounted) return;
              }
            }
          }
        } else if (previous?['board'] != board) {
          lastFrom = lastTo = captureSquare = null;
          moved = captured = null;
        }
        setState(() {
          previewFen = null;
          position = data;
          cup = data['cup'];
          selected = null;
        });
        if (!myTurn && currentGame['result'] == '*') {
          poll = Timer(const Duration(seconds: 4), () => refresh(board: board));
        }
      }
    } on SocialException catch (e) {
      if (mounted) {
        setState(
          () => error = switch (e.statusCode) {
            401 => 'Your session has expired. Please sign in again.',
            404 when cup == null =>
              'Daily Practice Cup is temporarily unavailable.',
            _ => 'Unable to open your board. Please try again.',
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Unable to open your board. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          if (previewFen != null) {
            previewFen = null;
            lastFrom = lastTo = captureSquare = null;
            moved = captured = null;
          }
          busy = false;
        });
      }
    }
  }

  List<Map> get games => (cup!['games'] as List).cast<Map>();
  List<Map> get seats => (cup!['seats'] as List).cast<Map>();
  Map get currentGame =>
      games.firstWhere((g) => g['number'] == position!['board']);
  bool get flipped => currentGame['black'] == cup!['mySeat'];
  bool get myTurn =>
      ((position!['fen'] as String).split(' ')[1] == 'b') == flipped;
  String name(int seat) => seats[seat]['name'] as String;

  Future<void> tapSquare(String square) async {
    if (busy || !myTurn || currentGame['result'] != '*') return;
    final legal = (position!['legal'] as List).cast<String>();
    final matches = legal
        .where((m) => m.startsWith('$selected$square'))
        .toList();
    if (matches.isEmpty) {
      setState(
        () => selected = legal.any((m) => m.startsWith(square)) ? square : null,
      );
      return;
    }
    final move = matches.length == 1
        ? matches.single
        : await showDialog<String>(
            context: context,
            builder: (context) => SimpleDialog(
              children: [
                for (final option in matches)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, option),
                    child: Text(option),
                  ),
              ],
            ),
          );
    if (mounted && move != null) {
      await refresh(board: position!['board'], move: move);
    }
  }

  Widget boardView() {
    final fen = previewFen ?? position!['fen'] as String;
    final pieces = gamePiecesFromFen(fen);
    final white = fen.split(' ')[1] == 'w';
    final checked = ChessRules.isKingInCheck(white, pieces)
        ? ChessRules.kingSquare(white, pieces)
        : null;
    final checkmate =
        checked != null &&
        currentGame['result'] == (white ? '0-1' : '1-0') &&
        (position!['legal'] as List).isEmpty;
    final palette = boardPalettes[skin]!;
    return BoardStage(
      palette: palette,
      child: ChessBoard(
        pieces: pieces,
        selectedSquare: selected,
        legalTargets: {
          if (selected != null)
            for (final uci in (position!['legal'] as List).cast<String>())
              if (uci.startsWith(selected!)) uci.substring(2, 4),
        },
        lastFromSquare: lastFrom,
        lastToSquare: lastTo,
        lastCaptureSquare: captured == null ? null : captureSquare,
        lastMovedPiece: moved,
        lastCapturedPiece: captured,
        moveSequence: (position!['ply'] as int) + (previewFen == null ? 0 : 1),
        checkedKingSquare: checked,
        decisiveSquare: checkmate ? lastTo : null,
        fallenKingSquare: checkmate ? checked : null,
        fallenKingWhite: checkmate ? white : null,
        coachArrowFrom: null,
        coachArrowTo: null,
        flipped: flipped,
        showCoordinates: coordinates,
        palette: palette,
        onSquareTap: tapSquare,
      ),
    );
  }

  Widget _computerBadge() => Container(
    padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
    decoration:BoxDecoration(border:Border.all(color:Colors.white24),borderRadius:BorderRadius.circular(8)),
    child:const UiText('AI',style:TextStyle(fontSize:11,color:Colors.white70)));

  Widget standings() {
    final scores = List<double>.filled(6, 0);
    for (final g in games) {
      if (g['result'] == '1-0') scores[g['white']]++;
      if (g['result'] == '0-1') scores[g['black']]++;
      if (g['result'] == '1/2-1/2') {
        scores[g['white']] += .5;
        scores[g['black']] += .5;
      }
    }
    final order = List.generate(6, (i) => i)
      ..sort((a, b) => scores[b].compareTo(scores[a]));
    return Column(
      children: [
        for (final i in order)
          ListTile(
            leading: PlayerAvatar(name: name(i)),

            title: Text(name(i)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children:[if(seats[i]['bot'] == true) _computerBadge(), const SizedBox(width:8), Text('${scores[i]}')]),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDeep,
    body: DecoratedBox(
      decoration: BoxDecoration(
        image: position == null
            ? null
            : const DecorationImage(
                image: AssetImage(
                  'assets/backgrounds/grandmaster-table-v1.webp',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
              ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (position == null)
              Material(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      if (Navigator.canPop(context)) const BackButton(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Semantics(
                            header: true,
                            child: UiText(
                              'Daily Practice Cup',
                              style: Theme.of(context).textTheme.titleLarge,
                              softWrap: true,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .refreshIndicatorSemanticLabel,
                        onPressed: busy
                            ? null
                            : () => refresh(
                                board: error != null
                                    ? retryBoard
                                    : position?['board'],
                              ),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  vertical: position == null ? 16 : 0,
                  horizontal: MediaQuery.sizeOf(context).width > 840
                      ? (MediaQuery.sizeOf(context).width - 800) / 2
                      : position == null
                      ? 16
                      : 0,
                ),
                children: [
                  if (busy && position == null) const LinearProgressIndicator(),
                  if (error != null) ...[
                    UiText(error!),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => refresh(board: retryBoard),
                        icon: const Icon(Icons.refresh),
                        label: const UiText('Retry'),
                      ),
                    ),
                  ],
                  if (cup != null && position == null) ...[
                    if ((cup!['lobbySeconds'] ?? 0) > 0) ...[
                      Text(
                        '${uiText(context, 'Starts in')} · ${seats.length}/6',
                        style: const TextStyle(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        key: ValueKey(cup!['lobbySeconds']),
                        tween: Tween(
                          begin: (cup!['lobbySeconds'] as int).toDouble(),
                          end: 0,
                        ),
                        duration: Duration(seconds: cup!['lobbySeconds']),
                        builder: (_, remaining, _) => Text(
                          '${remaining.ceil() ~/ 60}:${(remaining.ceil() % 60).toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      LinearProgressIndicator(
                        value: seats.length / 6,
                        color: const Color(0xff62ddca),
                      ),
                      for (final seat in seats)
                        ListTile(
                          leading: PlayerAvatar(name: seat['name']),
                          title: Text(seat['name']),
                          trailing: seat['bot'] == true ? _computerBadge() : null,
                        ),
                    ] else ...[
                      const UiText(
                        'YOUR BOARD',
                        style: TextStyle(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    for (final g in games.where(
                      (g) =>
                          g['white'] == cup!['mySeat'] ||
                          g['black'] == cup!['mySeat'],
                    ))
                      Card(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: g['result'] == '*'
                                ? const Color(0xff388d83)
                                : AppColors.border,
                          ),
                        ),
                        child: ListTile(
                          onTap: busy
                              ? null
                              : () => refresh(board: g['number']),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.surfaceLight,
                            child: Text(
                              '${g['round']}',
                              style: const TextStyle(
                                color: AppColors.accentGold,
                              ),
                            ),
                          ),
                          title: Text(
                            '${name(g['white'])}  •  ${name(g['black'])}',
                          ),
                          subtitle: g['result'] == '*'
                              ? const UiText('Enter / Resume game')
                              : null,
                          trailing: g['result'] == '*'
                              ? const Icon(Icons.play_arrow)
                              : Text(g['result']),
                        ),
                      ),
                    if (games.isNotEmpty) standings(),
                  ],
                  if (position != null)
                    PracticeMatchStudio(
                      key: ValueKey(position!['board']),
                      onRefresh: busy
                          ? null
                          : () => refresh(board: position!['board']),
                      board: boardView(),
                      flipped: flipped,
                      whiteName: name(currentGame['white']),
                      blackName: name(currentGame['black']),
                      whiteTurn:
                          ((previewFen ?? position!['fen']) as String).split(
                            ' ',
                          )[1] ==
                          'w',
                      result: currentGame['result'],
                      inCheck: ChessRules.isKingInCheck(
                        ((previewFen ?? position!['fen']) as String).split(
                              ' ',
                            )[1] ==
                            'w',
                        gamePiecesFromFen(previewFen ?? position!['fen']),
                      ),
                      moves: (currentGame['moves'] as String? ?? '')
                          .split(' ')
                          .where((m) => m.isNotEmpty)
                          .toList(),
                      onStandings: busy ? null : () => refresh(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
