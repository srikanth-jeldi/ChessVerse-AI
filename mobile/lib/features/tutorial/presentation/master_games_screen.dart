import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/academy_story_localizations.dart';
import '../../../core/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../data/academy_progress_store.dart';
import '../domain/master_game_lesson.dart';

enum _MasterNarrationState { stopped, playing, paused }

String _masterTtsLocale(String code) =>
    const <String, String>{
      'en': 'en-US',
      'te': 'te-IN',
      'hi': 'hi-IN',
      'ta': 'ta-IN',
      'kn': 'kn-IN',
      'ml': 'ml-IN',
      'mr': 'mr-IN',
      'bn': 'bn-IN',
      'gu': 'gu-IN',
      'pa': 'pa-IN',
      'ur': 'ur-PK',
      'ar': 'ar-SA',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'de': 'de-DE',
      'it': 'it-IT',
      'pt': 'pt-BR',
      'ru': 'ru-RU',
      'uk': 'uk-UA',
      'tr': 'tr-TR',
      'fa': 'fa-IR',
      'zh': 'zh-CN',
      'ja': 'ja-JP',
      'ko': 'ko-KR',
      'id': 'id-ID',
      'ms': 'ms-MY',
      'th': 'th-TH',
      'vi': 'vi-VN',
      'pl': 'pl-PL',
      'nl': 'nl-NL',
      'sv': 'sv-SE',
      'el': 'el-GR',
      'he': 'he-IL',
      'sw': 'sw-KE',
    }[code] ??
    'en-US';

class MasterGamesScreen extends StatefulWidget {
  const MasterGamesScreen({super.key});

  @override
  State<MasterGamesScreen> createState() => _MasterGamesScreenState();
}

class _MasterGamesScreenState extends State<MasterGamesScreen> {
  static const AcademyProgressStore _progressStore = AcademyProgressStore();
  String _languageCode = AppLanguageController.resolveCode(
    AppLanguageController.systemCode,
  );
  Set<String> _completed = <String>{};

  AcademyStoryLocalizations get _copy =>
      AcademyStoryLocalizations(_languageCode);

  @override
  void initState() {
    super.initState();
    AppLanguageController.effectiveLanguageChanges.addListener(
      _handleLanguageChange,
    );
    AppLanguageController.effectiveCode().then((String code) {
      if (mounted) setState(() => _languageCode = code);
    });
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final Set<String> completed = await _progressStore
          .readCompletedMasterGames();
      if (mounted) setState(() => _completed = completed);
    } on Object {
      // The catalog remains available if secure storage is unavailable.
    }
  }

  void _handleLanguageChange() {
    final String? code = AppLanguageController.effectiveLanguageChanges.value;
    if (code != null && mounted) setState(() => _languageCode = code);
  }

  @override
  void dispose() {
    AppLanguageController.effectiveLanguageChanges.removeListener(
      _handleLanguageChange,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AcademyStoryLocalizations copy = _copy;
    return Scaffold(
      backgroundColor: const Color(0xFF06131F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        title: Text(copy.text('master.title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          _MasterCatalogHero(copy: copy, completed: _completed),
          const SizedBox(height: 18),
          for (final MasterGameLesson lesson in MasterGameCatalog.lessons)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MasterGameCard(
                lesson: lesson,
                copy: copy,
                completed: _completed.contains(lesson.id),
                onReturned: _loadProgress,
              ),
            ),
        ],
      ),
    );
  }
}

class _MasterCatalogHero extends StatelessWidget {
  const _MasterCatalogHero({required this.copy, required this.completed});

  final AcademyStoryLocalizations copy;
  final Set<String> completed;

  int get total => MasterGameCatalog.lessons.length;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: <Color>[
          Color(0xFF153F4B),
          Color(0xFF0A2030),
          Color(0xFF071421),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: AppColors.accentGold.withValues(alpha: .55)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x334CDCC1),
          blurRadius: 30,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: Stack(
      children: <Widget>[
        const Positioned(
          right: -10,
          bottom: -24,
          child: Icon(
            Icons.emoji_events_rounded,
            size: 130,
            color: Color(0x18EABF61),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.accentGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    copy.text('master.eyebrow'),
                    style: const TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Text(
                  '${completed.length}/$total',
                  style: const TextStyle(
                    color: Color(0xFF63D2B8),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              copy.text('master.title'),
              style: const TextStyle(
                fontSize: 30,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(
                copy.text('master.intro'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: total == 0 ? 0 : completed.length / total,
                backgroundColor: const Color(0xFF24344C),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF63D2B8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: <Widget>[
                for (int index = 0; index < total; index++)
                  _MasteryBadge(
                    icon: switch (MasterGameCatalog.lessons[index].style) {
                      MasterThinkingStyle.attack =>
                        Icons.local_fire_department_rounded,
                      MasterThinkingStyle.calculation =>
                        Icons.psychology_alt_rounded,
                      MasterThinkingStyle.endurance =>
                        Icons.hourglass_bottom_rounded,
                    },
                    unlocked: completed.contains(
                      MasterGameCatalog.lessons[index].id,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _MasteryBadge extends StatelessWidget {
  const _MasteryBadge({required this.icon, required this.unlocked});

  final IconData icon;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 350),
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: unlocked ? const Color(0xFF63D2B8) : const Color(0xFF17283A),
      border: Border.all(
        color: unlocked ? AppColors.accentGold : AppColors.border,
      ),
      boxShadow: unlocked
          ? const <BoxShadow>[
              BoxShadow(color: Color(0x554CDCC1), blurRadius: 16),
            ]
          : null,
    ),
    child: Icon(
      unlocked ? icon : Icons.lock_outline_rounded,
      size: 20,
      color: unlocked ? const Color(0xFF071827) : AppColors.textMuted,
    ),
  );
}

class _MasterGameCard extends StatelessWidget {
  const _MasterGameCard({
    required this.lesson,
    required this.copy,
    required this.completed,
    required this.onReturned,
  });
  final MasterGameLesson lesson;
  final AcademyStoryLocalizations copy;
  final bool completed;
  final VoidCallback onReturned;

  IconData get _icon => switch (lesson.style) {
    MasterThinkingStyle.attack => Icons.local_fire_department_rounded,
    MasterThinkingStyle.calculation => Icons.psychology_alt_rounded,
    MasterThinkingStyle.endurance => Icons.hourglass_bottom_rounded,
  };

  @override
  Widget build(BuildContext context) => ChessVerseCard(
    key: ValueKey<String>('master-game-${lesson.id}'),
    padding: EdgeInsets.zero,
    onTap: () async {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => _MasterGameStudyScreen(lesson: lesson, copy: copy),
        ),
      );
      onReturned();
    },
    child: Row(
      children: <Widget>[
        Container(
          width: 88,
          constraints: const BoxConstraints(minHeight: 142),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[Color(0xFF184956), Color(0xFF0B2635)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(_icon, color: const Color(0xFF63D2B8), size: 32),
              const SizedBox(height: 9),
              Text(
                '${lesson.moveNumber}',
                style: const TextStyle(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${lesson.white} vs ${lesson.black}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (completed)
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF63D2B8),
                        size: 21,
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${lesson.event} · ${lesson.year} · ${lesson.result}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(
                  copy.text(
                    'master.pauseMeta',
                    values: <String, String>{
                      'move': '${lesson.moveNumber}',
                      'side': copy.text(
                        'master.side.${lesson.sideToMove.toLowerCase()}',
                      ),
                    },
                  ),
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 14),
          child: Icon(Icons.arrow_forward_rounded),
        ),
      ],
    ),
  );
}

class _MasterGameStudyScreen extends StatefulWidget {
  const _MasterGameStudyScreen({required this.lesson, required this.copy});
  final MasterGameLesson lesson;
  final AcademyStoryLocalizations copy;

  @override
  State<_MasterGameStudyScreen> createState() => _MasterGameStudyScreenState();
}

class _MasterGameStudyScreenState extends State<_MasterGameStudyScreen> {
  static const AcademyProgressStore _progressStore = AcademyProgressStore();
  late final FlutterTts _narrator;
  _MasterNarrationState _narrationState = _MasterNarrationState.stopped;
  String? _choice;

  @override
  void initState() {
    super.initState();
    _narrator = FlutterTts()
      ..setStartHandler(() => _setNarrationState(_MasterNarrationState.playing))
      ..setCompletionHandler(
        () => _setNarrationState(_MasterNarrationState.stopped),
      )
      ..setCancelHandler(
        () => _setNarrationState(_MasterNarrationState.stopped),
      )
      ..setErrorHandler(
        (_) => _setNarrationState(_MasterNarrationState.stopped),
      )
      ..setPauseHandler(() => _setNarrationState(_MasterNarrationState.paused))
      ..setContinueHandler(
        () => _setNarrationState(_MasterNarrationState.playing),
      );
    unawaited(_prepareNarrator());
  }

  void _setNarrationState(_MasterNarrationState state) {
    if (mounted) setState(() => _narrationState = state);
  }

  Future<void> _prepareNarrator() async {
    try {
      await _narrator.setLanguage(_masterTtsLocale(widget.copy.code));
      await _narrator.setSpeechRate(.43);
      await _narrator.setPitch(1.02);
      await _narrator.setVolume(1);
    } on Object {
      // On-screen localized coaching remains available without a TTS voice.
    }
  }

  Future<void> _toggleNarration() async {
    try {
      if (_narrationState == _MasterNarrationState.playing) {
        await _narrator.pause();
        return;
      }
      final MasterGameLesson lesson = widget.lesson;
      final String narration = <String>[
        widget.copy.text('master.${lesson.id}.question'),
        if (_choice != null) widget.copy.text('master.${lesson.id}.idea'),
      ].join(' ');
      await _narrator.speak(narration);
    } on Object {
      _setNarrationState(_MasterNarrationState.stopped);
    }
  }

  @override
  void dispose() {
    unawaited(_narrator.stop());
    super.dispose();
  }

  Future<void> _complete() async {
    try {
      await _progressStore.markMasterGameCompleted(widget.lesson.id);
    } on Object {
      // The masterclass remains completable if secure storage is unavailable.
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: <Color>[
                Color(0xFF164956),
                Color(0xFF0A2232),
                Color(0xFF081522),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.accentGold),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x6659E4C8), blurRadius: 40),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: Color(0x66EABF61), blurRadius: 30),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 48,
                  color: Color(0xFF071827),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.copy.text('master.complete'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.lesson.white} · ${widget.lesson.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF06131F).withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF63D2B8).withValues(alpha: .45),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.verified_rounded, color: Color(0xFF63D2B8)),
                    SizedBox(width: 10),
                    Text(
                      '1 / 1',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey<String>('master-completion-close'),
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(widget.copy.text('master.title')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final MasterGameLesson lesson = widget.lesson;
    final bool? correct = _choice == null ? null : lesson.isCorrect(_choice!);
    return Scaffold(
      backgroundColor: const Color(0xFF06131F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        title: Text('${lesson.white.split(' ').last} · ${lesson.year}'),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('master-narration'),
            tooltip: widget.copy.text(
              _narrationState == _MasterNarrationState.playing
                  ? 'ui.pause'
                  : 'ui.listen',
            ),
            onPressed: _toggleNarration,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Icon(
                _narrationState == _MasterNarrationState.playing
                    ? Icons.pause_circle_filled_rounded
                    : Icons.volume_up_rounded,
                key: ValueKey<_MasterNarrationState>(_narrationState),
                color: const Color(0xFF63D2B8),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _StoryStage(
                        lesson: lesson,
                        revealed: _choice != null,
                        copy: widget.copy,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFF1C5260),
                              Color(0xFF0A1B2C),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFF63D2B8)
                                .withValues(alpha: .55),
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(color: Color(0x334CDCC1), blurRadius: 28),
                          ],
                        ),
                        child: _MasterPositionBoard(
                          lesson: lesson,
                          revealMove: _choice != null,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ChessVerseCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              widget.copy.text('master.${lesson.id}.question'),
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final String move in lesson.choices)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: OutlinedButton.icon(
                                  key: ValueKey<String>('master-choice-$move'),
                                  onPressed: _choice == null
                                      ? () => setState(() => _choice = move)
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),
                                    side: BorderSide(
                                      color: _choice == move
                                          ? (lesson.isCorrect(move)
                                                ? const Color(0xFF63D2B8)
                                                : const Color(0xFFFF8A72))
                                          : AppColors.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: Icon(
                                    _choice == move
                                        ? (lesson.isCorrect(move)
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded)
                                        : Icons.radio_button_unchecked_rounded,
                                  ),
                                  label: Text(
                                    move,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            if (correct != null) ...<Widget>[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: correct
                                        ? const <Color>[
                                            Color(0xFF153F4B),
                                            Color(0xFF0B2635),
                                          ]
                                        : const <Color>[
                                            Color(0xFF442A2C),
                                            Color(0xFF231A23),
                                          ],
                                  ),
                                  border: Border.all(
                                    color: correct
                                        ? const Color(0xFF63D2B8)
                                        : const Color(0xFFFF8A72),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Icon(
                                      correct
                                          ? Icons.lightbulb_rounded
                                          : Icons.psychology_alt_rounded,
                                      color: correct
                                          ? const Color(0xFF63D2B8)
                                          : const Color(0xFFFF8A72),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            correct
                                                ? widget.copy.text(
                                                    'master.correct',
                                                  )
                                                : widget.copy.text(
                                                    'master.wrong',
                                                  ),
                                            style: TextStyle(
                                              color: correct
                                                  ? const Color(0xFF63D2B8)
                                                  : const Color(0xFFFF8A72),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            widget.copy.text(
                                              'master.${lesson.id}.idea',
                                            ),
                                            style: const TextStyle(
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: lesson.continuation
                                    .map(
                                      (String move) => Chip(label: Text(move)),
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: _complete,
                                icon: const Icon(Icons.school_rounded),
                                label: Text(
                                  widget.copy.text('master.complete'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class _MasterPositionBoard extends StatelessWidget {
  const _MasterPositionBoard({required this.lesson, required this.revealMove});

  final MasterGameLesson lesson;
  final bool revealMove;

  static const Map<String, String> _symbols = <String, String>{
    'K': '♔',
    'Q': '♕',
    'R': '♖',
    'B': '♗',
    'N': '♘',
    'P': '♙',
    'k': '♚',
    'q': '♛',
    'r': '♜',
    'b': '♝',
    'n': '♞',
    'p': '♟',
  };

  Offset _position(String square, double size) => Offset(
    (square.codeUnitAt(0) - 97) * size,
    (8 - int.parse(square[1])) * size,
  );

  @override
  Widget build(BuildContext context) {
    final Map<String, String> pieces = MasterGameCatalog.piecesFromFen(
      lesson.fen,
    );
    final String moving = pieces[lesson.masterFrom]!;
    pieces.remove(lesson.masterFrom);
    if (revealMove) {
      pieces.remove(lesson.masterTo);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double size = constraints.maxWidth / 8;
                return Stack(
                  children: <Widget>[
                    for (int row = 0; row < 8; row++)
                      for (int col = 0; col < 8; col++)
                        Positioned(
                          left: col * size,
                          top: row * size,
                          width: size,
                          height: size,
                          child: ColoredBox(
                            color: (row + col).isEven
                                ? const Color(0xFFD8C5A7)
                                : const Color(0xFF6D4A32),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Text(
                                '${String.fromCharCode(97 + col)}${8 - row}',
                                style: const TextStyle(
                                  color: Color(0x9906131F),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    for (final MapEntry<String, String> piece in pieces.entries)
                      Positioned(
                        left: _position(piece.key, size).dx,
                        top: _position(piece.key, size).dy,
                        width: size,
                        height: size,
                        child: Center(
                          child: Text(
                            _symbols[piece.value]!,
                            style: TextStyle(fontSize: size * .66, height: 1),
                          ),
                        ),
                      ),
                    TweenAnimationBuilder<Offset>(
                      key: ValueKey<String>('${lesson.id}-$revealMove'),
                      tween: Tween<Offset>(
                        begin: _position(lesson.masterFrom, size),
                        end: _position(
                          revealMove ? lesson.masterTo : lesson.masterFrom,
                          size,
                        ),
                      ),
                      duration: const Duration(milliseconds: 850),
                      curve: Curves.easeInOutCubic,
                      builder:
                          (
                            BuildContext context,
                            Offset offset,
                            Widget? child,
                          ) => Positioned(
                            left: offset.dx,
                            top: offset.dy,
                            width: size,
                            height: size,
                            child: child!,
                          ),
                      child: Center(
                        child: Text(
                          _symbols[moving]!,
                          style: TextStyle(fontSize: size * .66, height: 1),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryStage extends StatelessWidget {
  const _StoryStage({
    required this.lesson,
    required this.revealed,
    required this.copy,
  });
  final MasterGameLesson lesson;
  final bool revealed;
  final AcademyStoryLocalizations copy;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 450),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        colors: <Color>[Color(0xFF123A48), Color(0xFF09192A)],
      ),
      border: Border.all(
        color: revealed ? const Color(0xFF63D2B8) : AppColors.accentGold,
      ),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x4459E4C8), blurRadius: 24),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          lesson.sourceLabel,
          style: const TextStyle(
            color: AppColors.accentGold,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${lesson.white}\nvs ${lesson.black}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            const Icon(Icons.pause_circle_rounded, color: Color(0xFF63D2B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                copy.text(
                  'master.positionBefore',
                  values: <String, String>{'move': '${lesson.moveNumber}'},
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
