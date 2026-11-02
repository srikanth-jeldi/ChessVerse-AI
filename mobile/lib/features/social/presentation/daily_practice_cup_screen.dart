import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../analysis/presentation/animated_practice_pieces.dart';
import '../data/community_api.dart';

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
  Timer? poll;

  @override
  void initState() {
    super.initState();
    refresh();
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
            poll = Timer(Duration(seconds: seconds.clamp(1,5)), () => refresh());
          } else if (games.any((game) => game['result'] == '*')) {
            poll = Timer(const Duration(seconds: 10), () => refresh());
          }
        }
      } else {
        final data = await widget.api.practiceBoard(
          widget.token,
          cup!['id'],
          board,
          move: move,
          ply: move == null ? null : position!['ply'],
        );
        if (!mounted) return;
        setState(() {
          position = data;
          cup = data['cup'];
          selected = null;
        });
        if (!myTurn && currentGame['result'] == '*') {
          poll = Timer(const Duration(seconds: 4), () => refresh(board: board));
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
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

  Widget boardView() => Directionality(
    textDirection: TextDirection.ltr,
    child: AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          GridView.builder(
            primary: false,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemCount: 64,
            itemBuilder: (_, index) {
              final row = flipped ? 7 - index ~/ 8 : index ~/ 8,
                  col = flipped ? 7 - index % 8 : index % 8;
              final square = '${String.fromCharCode(97 + col)}${8 - row}';
              return GestureDetector(
                onTap: () => tapSquare(square),
                child: ColoredBox(
                  color: selected == square
                      ? Colors.tealAccent
                      : (row + col).isEven
                      ? const Color(0xffd8c5a7)
                      : const Color(0xff6d4a32),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      square,
                      style: const TextStyle(fontSize: 9, color: Colors.black),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned.fill(
            child: AnimatedPracticePieces(
              fen: position!['fen'],
              flipped: flipped,
              pieceBuilder: (piece) {
                const types = {
                  'k': 'king',
                  'q': 'queen',
                  'r': 'rook',
                  'b': 'bishop',
                  'n': 'knight',
                  'p': 'pawn',
                };
                return Image.asset(
                  'assets/pieces/staunton_${piece == piece.toUpperCase() ? 'white' : 'black'}_${types[piece.toLowerCase()]}.png',
                  fit: BoxFit.contain,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

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
            leading: Icon(
              seats[i]['bot'] == true ? Icons.smart_toy : Icons.person,
              semanticLabel: seats[i]['bot'] == true ? uiText(context, 'AI') : null,
            ),
            title: Text(name(i)),
            trailing: Text('${scores[i]}'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundDeep,
    appBar: AppBar(
      title: const UiText('Daily Practice Cup'),
      actions: [
        IconButton(
          onPressed: busy ? null : () => refresh(board: position?['board']),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: EdgeInsets.symmetric(vertical:16, horizontal:
            MediaQuery.sizeOf(context).width > 840 ? (MediaQuery.sizeOf(context).width - 800)/2 : 16),
        children: [
          if (busy) const LinearProgressIndicator(),
          if (error != null) Text(error!),
          if (cup != null && position == null) ...[
            if ((cup!['lobbySeconds'] ?? 0) > 0) ...[
              Text('${uiText(context, 'Starts in')} · ${seats.length}/6',
                style: const TextStyle(color:AppColors.accentGold,fontWeight:FontWeight.bold)),
              TweenAnimationBuilder<double>(
                key: ValueKey(cup!['lobbySeconds']),
                tween: Tween(begin:(cup!['lobbySeconds'] as int).toDouble(),end:0),
                duration: Duration(seconds:cup!['lobbySeconds']),
                builder: (_, remaining, _) => Text('${remaining.ceil() ~/ 60}:${(remaining.ceil() % 60).toString().padLeft(2,'0')}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(color:AppColors.textPrimary,fontWeight:FontWeight.w800)),
              ),
              LinearProgressIndicator(value:seats.length/6,color:const Color(0xff62ddca)),
              for (final seat in seats) ListTile(leading: const Icon(Icons.person), title: Text(seat['name'])),
            ] else ...[
              const UiText('YOUR BOARD',style:TextStyle(color:AppColors.accentGold,
                fontWeight:FontWeight.w800,letterSpacing:1.4)),
              const SizedBox(height:8),
            ],
            for (final g in games.where(
              (g) =>
                  g['white'] == cup!['mySeat'] || g['black'] == cup!['mySeat'],
            ))
              Card(
                color:AppColors.surface,
                shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),
                  side:BorderSide(color:g['result']=='*'?const Color(0xff388d83):AppColors.border)),
                child: ListTile(
                  onTap: busy ? null : () => refresh(board: g['number']),
                  leading: CircleAvatar(backgroundColor:AppColors.surfaceLight,
                    child:Text('${g['round']}',style:const TextStyle(color:AppColors.accentGold))),
                  title: Text('${name(g['white'])}  •  ${name(g['black'])}'),
                  subtitle: g['result']=='*'?const UiText('Enter / Resume game'):null,
                  trailing: g['result'] == '*'
                      ? const Icon(Icons.play_arrow)
                      : Text(g['result']),
                ),
              ),
            if (games.isNotEmpty) standings(),
          ],
          if (position != null) ...[
            Text(
              '${name(currentGame['white'])}  •  ${name(currentGame['black'])}',
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: boardView(),
              ),
            ),
            if (currentGame['result'] != '*')
              Center(
                child: Text(
                  currentGame['result'],
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              )
            else
              Center(
                child: UiText(
                  (position!['fen'] as String).split(' ')[1] == 'w'
                      ? 'White to move'
                      : 'Black to move',
                ),
              ),
            TextButton.icon(
              onPressed: busy ? null : () => refresh(),
              icon: const Icon(Icons.list),
              label: const UiText('Tournaments'),
            ),
          ],
        ],
      ),
    ),
  );
}
