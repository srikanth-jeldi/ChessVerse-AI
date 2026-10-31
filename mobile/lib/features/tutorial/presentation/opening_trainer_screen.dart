import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../analysis/presentation/animated_practice_pieces.dart';
import '../domain/opening_repertoire.dart';
import '../data/opening_progress_store.dart';

class OpeningTrainerScreen extends StatefulWidget {
  const OpeningTrainerScreen({super.key});
  @override
  State<OpeningTrainerScreen> createState() => _OpeningTrainerScreenState();
}

class _OpeningTrainerScreenState extends State<OpeningTrainerScreen> {
  OpeningLine _line = openingRepertoire.first;
  bool _white = true, _hint = false, _wrong = false, _saving = false;
  String? _selected, _saveError;
  late OpeningPractice _practice = OpeningPractice(_line);
  Timer? _flash;
  void _reset() {
    _flash?.cancel();
    setState(() {
      _practice = OpeningPractice(_line, playWhite: _white);
      _selected = null;
      _hint = _wrong = false;
      _saveError = null;
    });
  }

  @override
  void dispose() {
    _flash?.cancel();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await OpeningProgressStore.complete(_line.id, _white);
    } catch (_) {
      if (mounted) {
        setState(() => _saveError = 'Progress could not be saved. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _square(String square) {
    if (_practice.complete || _saving) return;
    if (_selected == null || _selected == square) {
      setState(() => _selected = square);
      return;
    }
    final correct = _practice.tryMove('$_selected$square');
    _flash?.cancel();
    setState(() {
      _selected = null;
      _wrong = !correct;
      _hint = !correct;
    });
    if (correct && _practice.complete) unawaited(_save());
    if (!correct) {
      _flash = Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _wrong = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const UiText('Opening Trainer')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<OpeningLine>(
                  initialValue: _line,
                  isExpanded: true,
                  items: openingRepertoire
                      .map(
                        (line) => DropdownMenuItem(
                          value: line,
                          child: UiText(line.name),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (line) {
                          if (line != null) {
                            _line = line;
                            _reset();
                          }
                        },
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    ChoiceChip(
                      label: const UiText('White'),
                      selected: _white,
                      onSelected: _saving
                          ? null
                          : (_) {
                              _white = true;
                              _reset();
                            },
                    ),
                    ChoiceChip(
                      label: const UiText('Black'),
                      selected: !_white,
                      onSelected: _saving
                          ? null
                          : (_) {
                              _white = false;
                              _reset();
                            },
                    ),
                  ],
                ),
                const UiText(
                  'Practise this opening line. Other legal moves may also be good.',
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _practice.ply / _line.moves.length,
                ),
                const SizedBox(height: 12),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        GridView.builder(
                          padding: EdgeInsets.zero,
                          primary: false,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 64,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 8,
                              ),
                          itemBuilder: (_, index) {
                            final row = _white ? index ~/ 8 : 7 - index ~/ 8;
                            final col = _white ? index % 8 : 7 - index % 8;
                            final square =
                                '${String.fromCharCode(97 + col)}${8 - row}';
                            return Semantics(
                              label: square,
                              button: true,
                              child: InkWell(
                                key: ValueKey('opening-square-$square'),
                                onTap: () => _square(square),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  color: _wrong
                                      ? const Color(0xFFCF5151)
                                      : square == _selected
                                      ? Colors.lightBlue
                                      : (row + col).isEven
                                      ? const Color(0xFFD8C5A7)
                                      : const Color(0xFF6D4A32),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      square,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned.fill(
                          child: AnimatedPracticePieces(
                            fen: _practice.fen,
                            flipped: !_white,
                            pieceBuilder: (piece) {
                              const names = {
                                'k': 'king',
                                'q': 'queen',
                                'r': 'rook',
                                'b': 'bishop',
                                'n': 'knight',
                                'p': 'pawn',
                              };
                              return Padding(
                                padding: const EdgeInsets.all(3),
                                child: Image.asset(
                                  'assets/pieces/staunton_${piece == piece.toUpperCase() ? 'white' : 'black'}_${names[piece.toLowerCase()]}.png',
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          ),
                        ),
                        if (_hint && _practice.expected != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _OpeningArrow(
                                  _practice.expected!,
                                  !_white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_practice.complete) ...[
                  const UiText('Opening practice complete!'),
                  if (_saving) const LinearProgressIndicator(),
                  if (_saveError != null) ...[
                    UiText(_saveError!),
                    TextButton(
                      onPressed: _saving ? null : _save,
                      child: const UiText('Retry'),
                    ),
                  ],
                ] else if (_hint)
                  const UiText(
                    'Follow the arrow to practise the selected line.',
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (!_practice.complete)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _hint = true),
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const UiText('Hint'),
                      ),
                    FilledButton(
                      onPressed: _saving ? null : _reset,
                      child: const UiText('Restart'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _OpeningArrow extends CustomPainter {
  _OpeningArrow(this.move, this.flipped);
  final String move;
  final bool flipped;
  Offset point(String square, Size size) {
    final col = square.codeUnitAt(0) - 97, row = 8 - int.parse(square[1]);
    return Offset(
      ((flipped ? 7 - col : col) + .5) * size.width / 8,
      ((flipped ? 7 - row : row) + .5) * size.height / 8,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final a = point(move.substring(0, 2), size),
        b = point(move.substring(2, 4), size);
    final paint = Paint()
      ..color = AppColors.accentGold
      ..strokeWidth = size.width / 65
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a, b, paint);
    final angle = math.atan2(b.dy - a.dy, b.dx - a.dx), head = size.width / 24;
    for (final sign in [-1, 1]) {
      canvas.drawLine(
        b,
        b -
            Offset(
              math.cos(angle + sign * .55) * head,
              math.sin(angle + sign * .55) * head,
            ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OpeningArrow old) =>
      move != old.move || flipped != old.flipped;
}
