import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../auth/data/auth_session_store.dart';
import '../../auth/data/guest_feature_trial.dart';
import '../../auth/presentation/guest_feature_gate.dart';
import '../data/engine_candidates_api.dart';
import '../domain/pgn_position_reconstructor.dart';

/// Analysis uses the existing authenticated Stockfish endpoint. Board editing
/// stays available without a connection; failed analysis never invents a score.
class SetupAnalysisScreen extends StatefulWidget {
  const SetupAnalysisScreen({super.key, required this.fen, this.analyze});
  final String fen;
  final Future<List<EngineCandidateLine>> Function(String fen)? analyze;

  @override
  State<SetupAnalysisScreen> createState() => _SetupAnalysisScreenState();
}

class _SetupAnalysisScreenState extends State<SetupAnalysisScreen> {
  List<EngineCandidateLine> _lines = [];
  List<String> _positions = [];
  int _ply = 0;
  int _selected = 0;
  bool _loading = true;
  String? _error;
  bool _trialGranted = false;

  @override
  void initState() {
    super.initState();
    _positions = [widget.fen];
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<EngineCandidateLine> lines;
      if (widget.analyze != null) {
        lines = await widget.analyze!(widget.fen).timeout(
          const Duration(seconds: 25),
        );
      } else {
        final session = await const AuthSessionStore().read();
        if (session == null || session.isExpired) {
          if (mounted) {
            setState(
              () =>
                  _error = 'Sign in to analyse this position, then try again.',
            );
          }
          return;
        }
        lines = await const EngineCandidatesApi()
            .analyze(session.token, fen: widget.fen)
            .timeout(const Duration(seconds: 25));
      }
      // Ignore malformed or illegal engine lines instead of displaying them.
      lines = lines
          .where(
            (line) =>
                replayUciLine(widget.fen, [
                  line.move,
                ], requireLegalMoves: true).length ==
                2,
          )
          .toList();
      if (!mounted) return;
      if (lines.isNotEmpty && !_trialGranted) {
        if (!await GuestFeatureGate.allow(context, GuestFeature.review)) {
          if (mounted) {
            setState(
              () =>
                  _error = 'Sign in to analyse this position, then try again.',
            );
          }
          return;
        }
        _trialGranted = true;
      }
      if (!mounted) return;
      setState(() {
        _lines = lines;
        if (lines.isNotEmpty) _select(0);
      });
    } on EngineCandidatesApiException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.statusCode == 401 || error.statusCode == 403
              ? 'Sign in to analyse this position, then try again.'
              : 'Analysis is unavailable. Check your connection and try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Analysis is unavailable. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(int index) {
    _selected = index;
    _ply = 0;
    final line = _lines[index];
    final moves =
        line.principalVariation.isNotEmpty &&
            line.principalVariation.first == line.move
        ? line.principalVariation
        : [line.move, ...line.principalVariation];
    _positions = replayUciLine(widget.fen, moves, requireLegalMoves: true);
  }

  String _score(EngineCandidateLine line) {
    // Stockfish reports from the root side-to-move perspective.
    final sign = widget.fen.split(' ')[1] == 'w' ? 1 : -1;
    if (line.mateIn != null) return '#${line.mateIn! * sign}';
    final value = line.evaluationCp * sign / 100;
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Analyse Position')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SetupPositionBoard(fen: _positions[_ply]),
                const SizedBox(height: 12),
                UiText(
                  _positions[_ply].split(' ')[1] == 'w'
                      ? 'White to move'
                      : 'Black to move',
                  textAlign: TextAlign.center,
                ),
                if (_positions.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        key: const ValueKey('line-back'),
                        tooltip: uiText(context, 'Previous move'),
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _ply > 0
                            ? () => setState(() => _ply--)
                            : null,
                      ),
                      Text('$_ply / ${_positions.length - 1}'),
                      IconButton(
                        key: const ValueKey('line-next'),
                        tooltip: uiText(context, 'Next move'),
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _ply + 1 < _positions.length
                            ? () => setState(() => _ply++)
                            : null,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                if (_loading) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 12),
                  const UiText(
                    'Analysing position…',
                    textAlign: TextAlign.center,
                  ),
                ] else if (_error != null) ...[
                  UiText(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const UiText('Retry')),
                ] else if (_lines.isEmpty)
                  const UiText(
                    'No playable engine line was returned. The position may be finished.',
                  )
                else ...[
                  const UiText('Evaluation from White’s perspective'),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _lines.length; i++)
                    Card(
                      child: InkWell(
                        onTap: () => setState(() => _select(i)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UiText(i == 0 ? 'Best move' : 'Alternative move'),
                              Text(
                                '${_lines[i].move}   ${_score(_lines[i])}',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (i == _selected)
                                const UiText(
                                  'Use the arrows to explore this line.',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                const UiText('Position FEN'),
                SelectableText(widget.fen, textDirection: TextDirection.ltr),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SetupPositionBoard extends StatelessWidget {
  const SetupPositionBoard({super.key, required this.fen});
  final String fen;
  @override
  Widget build(BuildContext context) {
    final cells = <String?>[];
    for (final c in fen.split(' ').first.split('')) {
      if (c == '/') continue;
      final empty = int.tryParse(c);
      if (empty != null) {
        cells.addAll(List.filled(empty, null));
      } else {
        cells.add(c);
      }
    }
    const names = {
      'k': 'king',
      'q': 'queen',
      'r': 'rook',
      'b': 'bishop',
      'n': 'knight',
      'p': 'pawn',
    };
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, i) {
            final piece = i < cells.length ? cells[i] : null;
            final square = '${String.fromCharCode(97 + i % 8)}${8 - i ~/ 8}';
            return Semantics(
              label: '$square ${piece ?? ''}',
              child: ColoredBox(
                color: (i ~/ 8 + i % 8).isEven
                    ? const Color(0xFFD9C8A8)
                    : const Color(0xFF765239),
                child: Stack(
                  children: [
                    if (piece != null)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Image.asset(
                            'assets/pieces/staunton_${piece == piece.toUpperCase() ? 'white' : 'black'}_${names[piece.toLowerCase()]}.png',
                          ),
                        ),
                      ),
                    Positioned(
                      left: 2,
                      bottom: 1,
                      child: Text(
                        square,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
