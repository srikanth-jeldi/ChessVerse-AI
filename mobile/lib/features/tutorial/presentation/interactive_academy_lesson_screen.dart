import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../domain/academy_lesson.dart';

enum _LessonPhase { demonstration, practice, success }

class InteractiveAcademyLessonScreen extends StatefulWidget {
  const InteractiveAcademyLessonScreen({
    required this.lesson,
    super.key,
  });

  final AcademyLesson lesson;

  @override
  State<InteractiveAcademyLessonScreen> createState() =>
      _InteractiveAcademyLessonScreenState();
}

class _InteractiveAcademyLessonScreenState
    extends State<InteractiveAcademyLessonScreen>
    with SingleTickerProviderStateMixin {
  static const AppPreferences _preferences = AppPreferences();
  late final AnimationController _controller;
  late final Animation<double> _movement;
  _LessonPhase _phase = _LessonPhase.demonstration;
  Timer? _practiceTimer;
  String? _selected;
  String? _feedback;
  bool _loadingProgress = true;
  Set<String> _completed = <String>{};
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    );
    _movement = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubicEmphasized,
    );
    _controller.addStatusListener(_handleAnimationStatus);
    unawaited(_loadProgress());
    WidgetsBinding.instance.addPostFrameCallback((_) => _playDemonstration());
  }

  Future<void> _loadProgress() async {
    String stored = '';
    try {
      stored = await _preferences.readString(
        'academy.completed',
        fallback: '',
      );
    } on Object {
      // Lessons remain fully usable in privacy-restricted browsers and test
      // environments where secure storage is unavailable.
    }
    if (!mounted) return;
    setState(() {
      _completed = stored
          .split(',')
          .where((String value) => value.trim().isNotEmpty)
          .toSet();
      _loadingProgress = false;
    });
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _practiceTimer?.cancel();
    _practiceTimer = Timer(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      setState(() {
        _phase = _LessonPhase.practice;
        _selected = null;
        _feedback = widget.lesson.coachPrompt;
      });
    });
  }

  void _playDemonstration() {
    _practiceTimer?.cancel();
    setState(() {
      _phase = _LessonPhase.demonstration;
      _selected = null;
      _feedback = 'Watch the AI coach demonstrate the move.';
    });
    _controller.forward(from: 0);
  }

  Future<void> _completeLesson() async {
    _completed.add(widget.lesson.id);
    try {
      await _preferences.writeString(
        'academy.completed',
        (_completed.toList()..sort()).join(','),
      );
    } on Object {
      // Keep the current-session completion state even if persistence fails.
    }
  }

  void _onSquareTap(String square) {
    if (_phase != _LessonPhase.practice) return;
    if (_selected == null) {
      if (square != widget.lesson.from) {
        setState(() {
          _attempts += 1;
          _feedback =
              'Start with the ${_pieceName(widget.lesson.pieces[widget.lesson.from]?.symbol)} on ${widget.lesson.from}.';
        });
        return;
      }
      setState(() {
        _selected = square;
        _feedback = 'Good. Now choose the best destination square.';
      });
      return;
    }
    if (square == _selected) {
      setState(() => _selected = null);
      return;
    }
    if (square == widget.lesson.to) {
      setState(() {
        _phase = _LessonPhase.success;
        _selected = null;
        _feedback = widget.lesson.successMessage;
      });
      unawaited(_completeLesson());
      return;
    }
    setState(() {
      _attempts += 1;
      _selected = null;
      _feedback = _smartCorrection(square);
    });
  }

  String _smartCorrection(String square) {
    final AcademyPiece? piece = widget.lesson.pieces[widget.lesson.from];
    final String name = _pieceName(piece?.symbol);
    return switch (piece?.symbol) {
      'P' => 'Not quite. Pawns move straight ahead; look again at ${widget.lesson.to}.',
      'N' => 'Try the L-shape: two squares, then one sideways. Find ${widget.lesson.to}.',
      'B' => 'Keep the bishop on its diagonal. $square leaves that diagonal.',
      'R' => 'A rook needs a straight rank or file. Trace the glowing line.',
      'Q' => 'The queen needs a clear straight or diagonal line to ${widget.lesson.to}.',
      'K' => 'The king moves one safe square. Check the highlighted escape square.',
      _ => 'That is not the strongest $name move here. Follow the animated route once more.',
    };
  }

  @override
  void dispose() {
    _practiceTimer?.cancel();
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size viewport = MediaQuery.sizeOf(context);
    final bool desktop = viewport.width >= 900 && viewport.height >= 620;
    return Scaffold(
      backgroundColor: const Color(0xFF04111B),
      appBar: AppBar(
        backgroundColor: const Color(0xF2071827),
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.lesson.title,
                style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(widget.lesson.eyebrow,
                style: const TextStyle(
                  color: AppColors.accentGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                )),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Replay demonstration',
            onPressed: _playDemonstration,
            icon: const Icon(Icons.replay_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: desktop ? _buildDesktop(context) : _buildMobile(context),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(width: 230, child: _CurriculumRail(lesson: widget.lesson)),
            const SizedBox(width: 20),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _AnimatedAcademyBoard(
                    lesson: widget.lesson,
                    movement: _movement,
                    phase: _phase,
                    selected: _selected,
                    onSquareTap: _onSquareTap,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 330,
              child: _CoachPanel(
                lesson: widget.lesson,
                phase: _phase,
                feedback: _feedback,
                attempts: _attempts,
                completed: _completed.contains(widget.lesson.id),
                loading: _loadingProgress,
                onReplay: _playDemonstration,
                onPracticeAgain: _resetPractice,
              ),
            ),
          ],
        ),
      );

  Widget _buildMobile(BuildContext context) => CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
            sliver: SliverList.list(children: <Widget>[
              _MobileLessonProgress(phase: _phase),
              const SizedBox(height: 12),
              _AnimatedAcademyBoard(
                lesson: widget.lesson,
                movement: _movement,
                phase: _phase,
                selected: _selected,
                onSquareTap: _onSquareTap,
              ),
              const SizedBox(height: 14),
              _CoachPanel(
                lesson: widget.lesson,
                phase: _phase,
                feedback: _feedback,
                attempts: _attempts,
                completed: _completed.contains(widget.lesson.id),
                loading: _loadingProgress,
                onReplay: _playDemonstration,
                onPracticeAgain: _resetPractice,
              ),
            ]),
          ),
        ],
      );

  void _resetPractice() {
    setState(() {
      _phase = _LessonPhase.practice;
      _selected = null;
      _attempts = 0;
      _feedback = widget.lesson.coachPrompt;
    });
  }
}

class _AnimatedAcademyBoard extends StatelessWidget {
  const _AnimatedAcademyBoard({
    required this.lesson,
    required this.movement,
    required this.phase,
    required this.selected,
    required this.onSquareTap,
  });

  final AcademyLesson lesson;
  final Animation<double> movement;
  final _LessonPhase phase;
  final String? selected;
  final ValueChanged<String> onSquareTap;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFB88A45), width: 2),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x662DD5C4), blurRadius: 30),
              BoxShadow(color: Color(0xAA000000), blurRadius: 24, offset: Offset(0, 12)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double square = constraints.maxWidth / 8;
                return AnimatedBuilder(
                  animation: movement,
                  builder: (BuildContext context, Widget? child) {
                    final bool demonstrating = phase == _LessonPhase.demonstration;
                    final bool moved = phase == _LessonPhase.success;
                    final Map<String, AcademyPiece> pieces =
                        Map<String, AcademyPiece>.from(lesson.pieces);
                    if (moved) {
                      final AcademyPiece? piece = pieces.remove(lesson.from);
                      if (piece != null) pieces[lesson.to] = piece;
                    }
                    return Stack(children: <Widget>[
                      for (int row = 0; row < 8; row++)
                        for (int col = 0; col < 8; col++)
                          _BoardSquare(
                            row: row,
                            col: col,
                            size: square,
                            lesson: lesson,
                            phase: phase,
                            selected: selected,
                            piece: pieces[_squareName(row, col)],
                            hidePiece: demonstrating &&
                                _squareName(row, col) == lesson.from,
                            onTap: onSquareTap,
                          ),
                      if (demonstrating)
                        _MovingPiece(
                          lesson: lesson,
                          progress: movement.value,
                          squareSize: square,
                        ),
                      if (phase == _LessonPhase.success)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF59E4C8),
                                  width: 5,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]);
                  },
                );
              },
            ),
          ),
        ),
      );
}

class _BoardSquare extends StatelessWidget {
  const _BoardSquare({
    required this.row,
    required this.col,
    required this.size,
    required this.lesson,
    required this.phase,
    required this.selected,
    required this.piece,
    required this.hidePiece,
    required this.onTap,
  });

  final int row;
  final int col;
  final double size;
  final AcademyLesson lesson;
  final _LessonPhase phase;
  final String? selected;
  final AcademyPiece? piece;
  final bool hidePiece;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final String squareName = _squareName(row, col);
    final bool light = (row + col).isEven;
    final bool highlighted = lesson.highlighted.contains(squareName);
    final bool isSelected = selected == squareName;
    final bool target = phase == _LessonPhase.practice && squareName == lesson.to;
    final Color base = light ? const Color(0xFFD8C5A7) : const Color(0xFF6D4A32);
    return Positioned(
      left: col * size,
      top: row * size,
      width: size,
      height: size,
      child: Semantics(
        button: true,
        label: '$squareName ${piece == null ? 'empty' : _pieceName(piece!.symbol)}',
        child: InkWell(
          onTap: () => onTap(squareName),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2FD5C4)
                  : target
                      ? const Color(0xFFB9993B)
                      : highlighted
                          ? Color.alphaBlend(const Color(0x554DE8D0), base)
                          : base,
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : highlighted
                        ? const Color(0x8859E4C8)
                        : Colors.black.withValues(alpha: .08),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(children: <Widget>[
              if (col == 0)
                Positioned(
                  left: 5,
                  top: 3,
                  child: Text('${8 - row}',
                      style: TextStyle(
                        color: light ? const Color(0xFF6D4A32) : const Color(0xFFD8C5A7),
                        fontSize: math.max(9, size * .15),
                        fontWeight: FontWeight.w900,
                      )),
                ),
              if (row == 7)
                Positioned(
                  right: 5,
                  bottom: 2,
                  child: Text(String.fromCharCode(97 + col),
                      style: TextStyle(
                        color: light ? const Color(0xFF6D4A32) : const Color(0xFFD8C5A7),
                        fontSize: math.max(9, size * .15),
                        fontWeight: FontWeight.w900,
                      )),
                ),
              if (target && piece == null)
                Center(
                  child: Container(
                    width: size * .24,
                    height: size * .24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xCC071A29),
                    ),
                  ),
                ),
              if (!hidePiece && piece != null)
                Center(child: _PieceGlyph(piece: piece!, size: size * .72)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _MovingPiece extends StatelessWidget {
  const _MovingPiece({
    required this.lesson,
    required this.progress,
    required this.squareSize,
  });

  final AcademyLesson lesson;
  final double progress;
  final double squareSize;

  @override
  Widget build(BuildContext context) {
    final Offset from = _squareOffset(lesson.from);
    final Offset to = _squareOffset(lesson.to);
    final Offset current = Offset.lerp(from, to, progress)!;
    final double lift = math.sin(progress * math.pi) * squareSize * .18;
    final AcademyPiece piece = lesson.pieces[lesson.from]!;
    return Positioned(
      left: current.dx * squareSize,
      top: current.dy * squareSize - lift,
      width: squareSize,
      height: squareSize,
      child: IgnorePointer(
        child: Transform.scale(
          scale: 1 + math.sin(progress * math.pi) * .13,
          child: _PieceGlyph(piece: piece, size: squareSize * .76, glowing: true),
        ),
      ),
    );
  }
}

class _PieceGlyph extends StatelessWidget {
  const _PieceGlyph({required this.piece, required this.size, this.glowing = false});

  final AcademyPiece piece;
  final double size;
  final bool glowing;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: .42),
                blurRadius: size * .09,
                offset: Offset(0, size * .06),
              ),
              if (glowing)
                const BoxShadow(color: Color(0xFF59E4C8), blurRadius: 18),
            ],
          ),
          child: Image.asset(
            _academyPieceAsset(piece),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel:
                '${piece.white ? 'White' : 'Black'} ${_pieceName(piece.symbol)}',
          ),
        ),
      );
}

String _academyPieceAsset(AcademyPiece piece) =>
    'assets/pieces/staunton_${piece.white ? 'white' : 'black'}_${_pieceName(piece.symbol).toLowerCase()}.png';

class _CoachPanel extends StatelessWidget {
  const _CoachPanel({
    required this.lesson,
    required this.phase,
    required this.feedback,
    required this.attempts,
    required this.completed,
    required this.loading,
    required this.onReplay,
    required this.onPracticeAgain,
  });

  final AcademyLesson lesson;
  final _LessonPhase phase;
  final String? feedback;
  final int attempts;
  final bool completed;
  final bool loading;
  final VoidCallback onReplay;
  final VoidCallback onPracticeAgain;

  @override
  Widget build(BuildContext context) {
    final Color accent = phase == _LessonPhase.success
        ? const Color(0xFF59E4C8)
        : phase == _LessonPhase.practice
            ? AppColors.accentGold
            : const Color(0xFF9C72FF);
    return ChessVerseCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(children: <Widget>[
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_alt_rounded, color: accent),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('AI COACH',
                      style: TextStyle(
                        color: Color(0xFF59E4C8),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      )),
                  Text('WATCH • UNDERSTAND • PRACTICE',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      )),
                ],
              ),
            ),
            if (!loading && completed)
              const Icon(Icons.verified_rounded, color: Color(0xFF59E4C8)),
          ]),
          const SizedBox(height: 18),
          Text(lesson.explanation,
              style: const TextStyle(
                color: Color(0xFFD9E4EB),
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 360),
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: accent.withValues(alpha: .6)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Text(
                feedback ?? lesson.coachPrompt,
                key: ValueKey<String>(feedback ?? lesson.coachPrompt),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (phase == _LessonPhase.success)
            Row(children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPracticeAgain,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF59E4C8),
                    foregroundColor: const Color(0xFF04111B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('PRACTICE AGAIN',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ])
          else
            Row(children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReplay,
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('REPLAY'),
                ),
              ),
              if (phase == _LessonPhase.practice) ...<Widget>[
                const SizedBox(width: 10),
                Chip(
                  avatar: const Icon(Icons.touch_app_rounded, size: 17),
                  label: Text(attempts == 0 ? 'Your turn' : '$attempts tries'),
                ),
              ],
            ]),
        ],
      ),
    );
  }
}

class _CurriculumRail extends StatelessWidget {
  const _CurriculumRail({required this.lesson});
  final AcademyLesson lesson;

  @override
  Widget build(BuildContext context) => ChessVerseCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('LESSON FLOW',
                style: TextStyle(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                )),
            const SizedBox(height: 18),
            const _RailStep(number: '01', title: 'Watch', icon: Icons.animation_rounded),
            const _RailLine(),
            const _RailStep(number: '02', title: 'Understand', icon: Icons.psychology_rounded),
            const _RailLine(),
            const _RailStep(number: '03', title: 'Practice', icon: Icons.touch_app_rounded),
            const _RailLine(),
            const _RailStep(number: '04', title: 'Master', icon: Icons.workspace_premium_rounded),
            const Spacer(),
            Text(lesson.eyebrow,
                style: const TextStyle(
                  color: Color(0xFF59E4C8),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 6),
            Text(lesson.title,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _RailStep extends StatelessWidget {
  const _RailStep({required this.number, required this.title, required this.icon});
  final String number;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(children: <Widget>[
        CircleAvatar(
          radius: 19,
          backgroundColor: const Color(0xFF10344A),
          child: Icon(icon, color: const Color(0xFF59E4C8), size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(number,
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  )),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ]);
}

class _RailLine extends StatelessWidget {
  const _RailLine();
  @override
  Widget build(BuildContext context) => Container(
        width: 2,
        height: 28,
        margin: const EdgeInsets.only(left: 18),
        color: const Color(0xFF1D4252),
      );
}

class _MobileLessonProgress extends StatelessWidget {
  const _MobileLessonProgress({required this.phase});
  final _LessonPhase phase;

  @override
  Widget build(BuildContext context) {
    final int active = switch (phase) {
      _LessonPhase.demonstration => 0,
      _LessonPhase.practice => 1,
      _LessonPhase.success => 2,
    };
    return Row(
      children: <Widget>[
        for (int index = 0; index < 3; index++) ...<Widget>[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: index <= active
                    ? (active == 2
                        ? const Color(0xFF59E4C8)
                        : AppColors.accentGold)
                    : const Color(0xFF233846),
              ),
            ),
          ),
          if (index != 2) const SizedBox(width: 7),
        ],
      ],
    );
  }
}

String _squareName(int row, int col) =>
    '${String.fromCharCode(97 + col)}${8 - row}';

Offset _squareOffset(String square) {
  final int col = square.codeUnitAt(0) - 97;
  final int rank = int.parse(square.substring(1));
  return Offset(col.toDouble(), (8 - rank).toDouble());
}

// Legacy Unicode fallback retained for platforms that may add a no-assets
// accessibility mode later.
// ignore: unused_element
String _pieceGlyph(AcademyPiece piece) {
  const Map<String, String> white = <String, String>{
    'K': '♔',
    'Q': '♕',
    'R': '♖',
    'B': '♗',
    'N': '♘',
    'P': '♙',
  };
  const Map<String, String> black = <String, String>{
    'K': '♚',
    'Q': '♛',
    'R': '♜',
    'B': '♝',
    'N': '♞',
    'P': '♟',
  };
  return (piece.white ? white : black)[piece.symbol] ?? piece.symbol;
}

String _pieceName(String? symbol) => switch (symbol) {
      'P' => 'pawn',
      'N' => 'knight',
      'B' => 'bishop',
      'R' => 'rook',
      'Q' => 'queen',
      'K' => 'king',
      _ => 'piece',
    };
