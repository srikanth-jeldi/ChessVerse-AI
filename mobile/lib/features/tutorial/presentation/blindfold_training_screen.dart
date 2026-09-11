import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/academy_story_localizations.dart';
import '../../../core/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../data/academy_progress_store.dart';
import '../domain/blindfold_exercise.dart';

class BlindfoldTrainingScreen extends StatefulWidget {
  const BlindfoldTrainingScreen({super.key});

  @override
  State<BlindfoldTrainingScreen> createState() =>
      _BlindfoldTrainingScreenState();
}

class _BlindfoldTrainingScreenState extends State<BlindfoldTrainingScreen> {
  static const AcademyProgressStore _progressStore = AcademyProgressStore();
  int _index = 0;
  int _score = 0;
  int _bestScore = 0;
  int _streak = 0;
  String _languageCode = AppLanguageController.resolveCode(
    AppLanguageController.systemCode,
  );
  String? _answer;
  bool _piecesVisible = false;
  Timer? _memoryTimer;

  BlindfoldExercise get _exercise => BlindfoldCatalog.exercises[_index];
  AcademyStoryLocalizations get _copy =>
      AcademyStoryLocalizations(_languageCode);

  @override
  void initState() {
    super.initState();
    _prepareRound();
    _loadProgress();
    AppLanguageController.effectiveLanguageChanges.addListener(
      _handleLanguageChange,
    );
    AppLanguageController.effectiveCode().then((String code) {
      if (mounted) setState(() => _languageCode = code);
    });
  }

  void _handleLanguageChange() {
    final String? code = AppLanguageController.effectiveLanguageChanges.value;
    if (code != null && mounted) setState(() => _languageCode = code);
  }

  Future<void> _loadProgress() async {
    try {
      final (int, int) progress = await (
        _progressStore.readBlindfoldBestScore(),
        _progressStore.readLearningStreak(),
      ).wait;
      if (mounted) {
        setState(() {
          _bestScore = progress.$1;
          _streak = progress.$2;
        });
      }
    } on Object {
      // Training stays playable if secure storage is unavailable.
    }
  }

  void _prepareRound() {
    _memoryTimer?.cancel();
    _answer = null;
    _piecesVisible = _exercise.type == BlindfoldExerciseType.positionMemory;
    if (_piecesVisible) {
      _memoryTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _piecesVisible = false);
      });
    }
  }

  @override
  void dispose() {
    _memoryTimer?.cancel();
    AppLanguageController.effectiveLanguageChanges.removeListener(
      _handleLanguageChange,
    );
    super.dispose();
  }

  void _choose(String value) {
    if (_answer != null || _piecesVisible) return;
    setState(() {
      _answer = value;
      if (_exercise.isCorrect(value)) _score++;
    });
  }

  Future<void> _next() async {
    if (_index == BlindfoldCatalog.exercises.length - 1) {
      try {
        await _progressStore.recordBlindfoldSession(_score);
      } on Object {
        // Finishing the session must not depend on persistence availability.
      }
      if (!mounted) return;
      Navigator.pop(context, _score);
      return;
    }
    _memoryTimer?.cancel();
    setState(() => _index++);
    _prepareRound();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF06131F),
    appBar: AppBar(
      title: Text(_copy.text('blindfold.title')),
      backgroundColor: const Color(0xFF071827),
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 760;
          final Widget board = _CoordinateBoard(
            pieces: _exercise.pieces,
            revealPieces: _piecesVisible,
          );
          final Widget coach = _coachPanel();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: board),
                          const SizedBox(width: 24),
                          Expanded(child: coach),
                        ],
                      )
                    : Column(
                        children: <Widget>[
                          board,
                          const SizedBox(height: 18),
                          coach,
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _coachPanel() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF0B2031),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF2C5E68)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _copy.text(
            'blindfold.mission',
            values: <String, String>{
              'current': '${_index + 1}',
              'total': '${BlindfoldCatalog.exercises.length}',
            },
          ),
          style: const TextStyle(
            color: AppColors.accentGold,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            Chip(
              label: Text(
                _copy.text(
                  'blindfold.score',
                  values: <String, String>{'score': '$_score'},
                ),
              ),
            ),
            Chip(
              label: Text(
                _copy.text(
                  'blindfold.best',
                  values: <String, String>{'score': '$_bestScore'},
                ),
              ),
            ),
            Chip(
              label: Text(
                _copy.text(
                  'blindfold.streak',
                  values: <String, String>{'days': '$_streak'},
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _piecesVisible
              ? _copy.text('blindfold.memorize')
              : _copy.text('blindfold.${_exercise.id}.prompt'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        if (_piecesVisible)
          FilledButton.icon(
            key: const ValueKey<String>('hide-blindfold-pieces'),
            onPressed: () {
              _memoryTimer?.cancel();
              setState(() => _piecesVisible = false);
            },
            icon: const Icon(Icons.visibility_off_rounded),
            label: Text(_copy.text('blindfold.hide')),
          )
        else
          for (final String option in _exercise.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                key: ValueKey<String>('blindfold-answer-$option'),
                onPressed: _answer == null ? () => _choose(option) : null,
                child: Text(switch (option) {
                  'Light' => _copy.text('blindfold.light'),
                  'Dark' => _copy.text('blindfold.dark'),
                  _ => option,
                }),
              ),
            ),
        if (_answer != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _copy.text(
              _exercise.isCorrect(_answer!)
                  ? 'blindfold.correct'
                  : 'blindfold.wrong',
            ),
            style: TextStyle(
              color: _exercise.isCorrect(_answer!)
                  ? const Color(0xFF63D2B8)
                  : const Color(0xFFFF8A72),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(_copy.text('blindfold.${_exercise.id}.explanation')),
          const SizedBox(height: 18),
          FilledButton(
            key: const ValueKey<String>('blindfold-next'),
            onPressed: _next,
            child: Text(
              _index == BlindfoldCatalog.exercises.length - 1
                  ? _copy.text(
                      'blindfold.finish',
                      values: <String, String>{
                        'score': '$_score',
                        'total': '${BlindfoldCatalog.exercises.length}',
                      },
                    )
                  : _copy.text('blindfold.next'),
            ),
          ),
        ],
      ],
    ),
  );
}

class _CoordinateBoard extends StatelessWidget {
  const _CoordinateBoard({required this.pieces, required this.revealPieces});
  final Map<String, String> pieces;
  final bool revealPieces;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemCount: 64,
        itemBuilder: (BuildContext context, int index) {
          final int row = index ~/ 8;
          final int file = index % 8;
          final int rank = 8 - row;
          final String square =
              '${String.fromCharCode('a'.codeUnitAt(0) + file)}$rank';
          final bool light = BlindfoldCatalog.isLightSquare(square);
          return ColoredBox(
            color: light ? const Color(0xFFBBA98A) : const Color(0xFF315466),
            child: Stack(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(
                    square,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xAAFFFFFF),
                    ),
                  ),
                ),
                if (revealPieces && pieces[square] != null)
                  Center(
                    child: Text(
                      pieces[square]!,
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
