import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/academy_story_localizations.dart';
import '../../../core/app_language.dart';
import '../../../core/chess_piece_appearance.dart';
import '../../../core/coach_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../../core/widgets/ai_language_picker.dart';
import '../data/academy_progress_store.dart';
import '../domain/academy_lesson.dart';

enum _LessonPhase { demonstration, practice, success }

enum _NarrationState { stopped, playing, paused }

String _ttsLocale(String code) =>
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

class InteractiveAcademyLessonScreen extends StatefulWidget {
  const InteractiveAcademyLessonScreen({required this.lesson, super.key});

  final AcademyLesson lesson;

  @override
  State<InteractiveAcademyLessonScreen> createState() =>
      _InteractiveAcademyLessonScreenState();
}

class _InteractiveAcademyLessonScreenState
    extends State<InteractiveAcademyLessonScreen>
    with SingleTickerProviderStateMixin {
  static const AcademyProgressStore _progressStore = AcademyProgressStore();
  static const MethodChannel _voiceSettingsChannel = MethodChannel(
    'com.epitomehub.chessverse/tts_settings',
  );
  late final AnimationController _controller;
  late final Animation<double> _movement;
  late final FlutterTts _narrator;
  _LessonPhase _phase = _LessonPhase.demonstration;
  _NarrationState _narrationState = _NarrationState.stopped;
  Timer? _practiceTimer;
  String? _selected;
  String? _feedback;
  bool _loadingProgress = true;
  bool _narratorVoiceReady = false;
  Set<String> _completed = <String>{};
  Map<String, int> _mastery = <String, int>{};
  int _attempts = 0;
  String? _candidateFeedback;
  int _demoStepIndex = 0;
  String _languageCode = AppLanguageController.resolveCode(
    AppLanguageController.systemCode,
  );

  AcademyStoryLocalizations get _copy =>
      AcademyStoryLocalizations(_languageCode);
  CoachLocalizations get _coachCopy => CoachLocalizations(_languageCode);
  int get _earnedStars => _attempts == 0 ? 3 : (_attempts <= 2 ? 2 : 1);
  AcademyLesson? get _nextLesson {
    final int index = AcademyCatalog.lessons.indexWhere(
      (AcademyLesson lesson) => lesson.id == widget.lesson.id,
    );
    return index >= 0 && index + 1 < AcademyCatalog.lessons.length
        ? AcademyCatalog.lessons[index + 1]
        : null;
  }

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
    _narrator = FlutterTts()
      ..setStartHandler(() => _setNarrationState(_NarrationState.playing))
      ..setCompletionHandler(() => _setNarrationState(_NarrationState.stopped))
      ..setCancelHandler(() => _setNarrationState(_NarrationState.stopped))
      ..setErrorHandler((_) => _setNarrationState(_NarrationState.stopped))
      ..setPauseHandler(() => _setNarrationState(_NarrationState.paused))
      ..setContinueHandler(() => _setNarrationState(_NarrationState.playing));
    AppLanguageController.effectiveLanguageChanges.addListener(
      _handleLanguageChange,
    );
    unawaited(_loadLanguage());
    unawaited(_prepareNarrator());
    _controller.addStatusListener(_handleAnimationStatus);
    unawaited(_loadProgress());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.lesson.usesDecisionCheckpoint) {
        _showDecisionCheckpoint();
      } else {
        _playDemonstration();
      }
    });
  }

  Future<void> _loadLanguage() async {
    final String code = await AppLanguageController.effectiveCode();
    if (!mounted) return;
    setState(() => _languageCode = code);
    try {
      await _narrator.stop();
    } on Object {
      // Language copy must still update when TTS is unavailable.
    }
    await _prepareNarrator();
  }

  void _handleLanguageChange() {
    final String? code = AppLanguageController.effectiveLanguageChanges.value;
    if (code == null || !mounted) return;
    setState(() => _languageCode = code);
    unawaited(_resetNarratorLanguage());
  }

  Future<void> _chooseLanguage() async {
    final String? code = await selectAndSaveAiLanguage(context);
    if (code == null || !mounted) return;
    setState(() => _languageCode = code);
    try {
      await _narrator.stop();
    } on Object {
      // Language copy must still update when TTS is unavailable.
    }
    await _prepareNarrator();
  }

  Future<void> _resetNarratorLanguage() async {
    try {
      await _narrator.stop();
    } on Object {
      // The selected captions remain usable without a speech engine.
    }
    await _prepareNarrator();
  }

  void _continueLearning() {
    unawaited(_narrator.stop());
    final AcademyLesson? next = _nextLesson;
    if (next == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => InteractiveAcademyLessonScreen(lesson: next),
      ),
    );
  }

  Future<void> _showDecisionCheckpoint() async {
    if (!mounted) return;
    _candidateFeedback = null;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) =>
            AlertDialog(
              backgroundColor: const Color(0xFF091C2C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: <Widget>[
                  const Icon(
                    Icons.psychology_alt_rounded,
                    color: AppColors.accentGold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_copy.text('ui.thinkTitle'))),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      _copy.decisionQuestion(widget.lesson.stage),
                      style: const TextStyle(
                        color: Color(0xFFEAF2F6),
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final String square in widget.lesson.decisionOptions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (square == widget.lesson.to) {
                              Navigator.of(dialogContext).pop();
                              _playDemonstration(
                                coachFeedback: _copy.decisionInsight(
                                  widget.lesson,
                                ),
                              );
                            } else {
                              setDialogState(() {
                                _candidateFeedback = _copy.text(
                                  'feedback.wrong',
                                  values: <String, String>{'square': square},
                                );
                              });
                            }
                          },
                          icon: const Icon(Icons.route_rounded),
                          label: Text('${widget.lesson.from} → $square'),
                        ),
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _candidateFeedback == null
                          ? Text(
                              _copy.text('ui.candidateRule'),
                              key: const ValueKey<String>('candidate-rule'),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            )
                          : Text(
                              _candidateFeedback!,
                              key: ValueKey<String>(_candidateFeedback!),
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  void _setNarrationState(_NarrationState state) {
    if (mounted) setState(() => _narrationState = state);
  }

  Future<bool> _prepareNarrator() async {
    try {
      final String requestedLocale = _ttsLocale(_languageCode);
      final String? locale = await _resolveNarratorLocale(requestedLocale);
      if (locale == null) {
        _narratorVoiceReady = false;
        return false;
      }
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final dynamic installed = await _narrator.isLanguageInstalled(locale);
        if (installed != true) {
          _narratorVoiceReady = false;
          return false;
        }
      }
      final dynamic selected =
          kIsWeb ? true : await _narrator.setLanguage(locale);
      if (selected == false || selected == 0) {
        _narratorVoiceReady = false;
        return false;
      }
      if (!kIsWeb) await _selectBestNarratorVoice(locale);
      await _narrator.setSpeechRate(.47);
      await _narrator.setPitch(1.0);
      await _narrator.setVolume(1);
      _narratorVoiceReady = true;
      return true;
    } on Object {
      // Captions keep every lesson usable when a device has no TTS voice.
      _narratorVoiceReady = false;
      return false;
    }
  }

  Future<String?> _resolveNarratorLocale(String requestedLocale) async {
    if (kIsWeb) {
      final String? browserLocale = await _resolveWebNarratorLocale(
        requestedLocale,
      );
      if (browserLocale != null) return browserLocale;
    }
    final dynamic directlyAvailable = await _narrator.isLanguageAvailable(
      requestedLocale,
    );
    if (directlyAvailable == true) return requestedLocale;

    final dynamic rawLanguages = await _narrator.getLanguages;
    if (rawLanguages is! Iterable<dynamic>) return null;
    final String requestedLanguage = requestedLocale
        .replaceAll('_', '-')
        .toLowerCase()
        .split('-')
        .first;
    for (final dynamic rawLanguage in rawLanguages) {
      final String candidate = rawLanguage.toString().replaceAll('_', '-');
      if (candidate.toLowerCase().split('-').first == requestedLanguage) {
        return candidate;
      }
    }
    return null;
  }

  Future<String?> _resolveWebNarratorLocale(String requestedLocale) async {
    final String normalizedRequest = requestedLocale
        .replaceAll('_', '-')
        .toLowerCase();
    final String requestedLanguage = normalizedRequest.split('-').first;
    for (int attempt = 0; attempt < 6; attempt++) {
      final dynamic rawVoices = await _narrator.getVoices;
      if (rawVoices is Iterable<dynamic>) {
        final List<Map<String, String>> exact = <Map<String, String>>[];
        final List<Map<String, String>> compatible = <Map<String, String>>[];
        for (final dynamic rawVoice in rawVoices) {
          if (rawVoice is! Map<dynamic, dynamic>) continue;
          final String locale = (rawVoice['locale'] ?? '')
              .toString()
              .replaceAll('_', '-');
          final Map<String, String> voice = <String, String>{
            'name': (rawVoice['name'] ?? '').toString(),
            'locale': locale,
          };
          final String normalizedLocale = locale.toLowerCase();
          if (normalizedLocale == normalizedRequest) exact.add(voice);
          if (normalizedLocale.split('-').first == requestedLanguage) {
            compatible.add(voice);
          }
        }
        final List<Map<String, String>> candidates = exact.isNotEmpty
            ? exact
            : compatible;
        if (candidates.isNotEmpty) {
          candidates.sort(
            (Map<String, String> a, Map<String, String> b) =>
                _narratorVoiceQuality(b['name']!).compareTo(
                  _narratorVoiceQuality(a['name']!),
                ),
          );
          await _narrator.setVoice(candidates.first);
          return candidates.first['locale'];
        }
      }
      if (attempt < 5) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
    return null;
  }

  Future<void> _selectBestNarratorVoice(String requestedLocale) async {
    final dynamic rawVoices = await _narrator.getVoices;
    if (rawVoices is! Iterable<dynamic>) return;
    final String normalizedRequest = requestedLocale
        .replaceAll('_', '-')
        .toLowerCase();
    final String requestedLanguage = normalizedRequest.split('-').first;
    final List<Map<String, String>> exact = <Map<String, String>>[];
    final List<Map<String, String>> compatible = <Map<String, String>>[];
    for (final dynamic rawVoice in rawVoices) {
      if (rawVoice is! Map<dynamic, dynamic>) continue;
      final String locale = (rawVoice['locale'] ?? '')
          .toString()
          .replaceAll('_', '-');
      final Map<String, String> voice = <String, String>{
        'name': (rawVoice['name'] ?? '').toString(),
        'locale': locale,
      };
      final String normalizedLocale = locale.toLowerCase();
      if (normalizedLocale == normalizedRequest) exact.add(voice);
      if (normalizedLocale.split('-').first == requestedLanguage) {
        compatible.add(voice);
      }
    }
    final List<Map<String, String>> candidates = exact.isNotEmpty
        ? exact
        : compatible;
    if (candidates.isEmpty) return;
    candidates.sort(
      (Map<String, String> a, Map<String, String> b) =>
          _narratorVoiceQuality(b['name']!).compareTo(
            _narratorVoiceQuality(a['name']!),
          ),
    );
    await _narrator.setVoice(candidates.first);
  }

  int _narratorVoiceQuality(String name) {
    final String normalized = name.toLowerCase();
    int score = 0;
    if (normalized.contains('natural')) score += 50;
    if (normalized.contains('neural')) score += 45;
    if (normalized.contains('premium')) score += 40;
    if (normalized.contains('enhanced')) score += 35;
    if (normalized.contains('google')) score += 25;
    if (normalized.contains('microsoft')) score += 20;
    return score;
  }

  Future<bool> _ensureNarratorVoice() async {
    if (_narratorVoiceReady || await _prepareNarrator()) return true;
    if (!mounted) return false;
    final AppLanguage language = AppLanguageController.byCode(_languageCode);
    if (kIsWeb) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${language.nativeName} speech voice is not available in this '
              'browser. The complete translated lesson is still shown on screen.',
            ),
          ),
        );
      return false;
    }
    final bool install =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF091C2C),
            title: Text('${language.nativeName} voice required'),
            content: Text(
              'The lesson is translated, but this phone does not have the '
              '${language.englishName} speech voice installed. Install it to '
              'hear the complete story. On-screen lessons remain available offline.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('NOT NOW'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('INSTALL VOICE'),
              ),
            ],
          ),
        ) ??
        false;
    if (install && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _voiceSettingsChannel.invokeMethod<void>('installVoiceData');
      } on PlatformException {
        // The captions remain the reliable fallback on restricted devices.
      }
    }
    return false;
  }

  Future<void> _speakStory() async {
    if (!await _ensureNarratorVoice()) return;
    await _narrator.stop();
    await _narrator.speak(_copy.storyNarration(widget.lesson), focus: true);
  }

  Future<void> _toggleNarration() async {
    try {
      if (_narrationState == _NarrationState.playing) {
        await _narrator.pause();
        return;
      }
      await _speakStory();
    } on Object {
      _setNarrationState(_NarrationState.stopped);
    }
  }

  Future<void> _replayNarration() async {
    try {
      await _speakStory();
    } on Object {
      _setNarrationState(_NarrationState.stopped);
    }
  }

  Future<void> _loadProgress() async {
    try {
      _completed = await _progressStore.readCompleted();
      _mastery = await _progressStore.readMastery();
    } on Object {
      // Lessons remain fully usable in privacy-restricted browsers and test
      // environments where secure storage is unavailable.
    }
    if (!mounted) return;
    setState(() {
      _loadingProgress = false;
    });
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _practiceTimer?.cancel();
    if (_demoStepIndex + 1 < widget.lesson.demonstrationLine.length) {
      _practiceTimer = Timer(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        setState(() => _demoStepIndex++);
        _controller.forward(from: 0);
      });
      return;
    }
    _practiceTimer = Timer(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      setState(() {
        _phase = _LessonPhase.practice;
        _selected = null;
        _feedback = _languageCode == 'en'
            ? widget.lesson.coachPrompt
            : '${_copy.storyChapter(widget.lesson)} · '
                  '${widget.lesson.from} → ${widget.lesson.to}';
      });
    });
  }

  void _playDemonstration({String? coachFeedback}) {
    _practiceTimer?.cancel();
    setState(() {
      _phase = _LessonPhase.demonstration;
      _demoStepIndex = 0;
      _selected = null;
      _feedback =
          coachFeedback ??
          (_languageCode == 'en'
              ? 'Watch the AI coach demonstrate the move.'
              : _copy.storyChapter(widget.lesson));
    });
    _controller.forward(from: 0);
  }

  Future<void> _completeLesson() async {
    try {
      _completed = await _progressStore.markCompleted(
        widget.lesson.id,
        stars: _earnedStars,
      );
      _mastery = await _progressStore.readMastery();
    } on Object {
      // Keep the current-session completion state even if persistence fails.
      _completed.add(widget.lesson.id);
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
        _feedback = _languageCode == 'en'
            ? widget.lesson.successMessage
            : _coachCopy.text('bestFound');
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
    if (_languageCode != 'en') {
      return '${_coachCopy.text('goodTry')} '
          '${widget.lesson.from} → ${widget.lesson.to}';
    }
    final AcademyPiece? piece = widget.lesson.pieces[widget.lesson.from];
    final String name = _pieceName(piece?.symbol);
    return switch (piece?.symbol) {
      'P' =>
        'Not quite. Pawns move straight ahead; look again at ${widget.lesson.to}.',
      'N' =>
        'Try the L-shape: two squares, then one sideways. Find ${widget.lesson.to}.',
      'B' => 'Keep the bishop on its diagonal. $square leaves that diagonal.',
      'R' => 'A rook needs a straight rank or file. Trace the glowing line.',
      'Q' =>
        'The queen needs a clear straight or diagonal line to ${widget.lesson.to}.',
      'K' =>
        'The king moves one safe square. Check the highlighted escape square.',
      _ =>
        'That is not the strongest $name move here. Follow the animated route once more.',
    };
  }

  @override
  void dispose() {
    _practiceTimer?.cancel();
    AppLanguageController.effectiveLanguageChanges.removeListener(
      _handleLanguageChange,
    );
    unawaited(_narrator.stop());
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size viewport = MediaQuery.sizeOf(context);
    final bool desktop = viewport.width >= 900 && viewport.height >= 620;
    final bool phoneLandscape =
        viewport.width > viewport.height && viewport.shortestSide < 600;
    return Scaffold(
      backgroundColor: const Color(0xFF04111B),
      appBar: AppBar(
        backgroundColor: const Color(0xF2071827),
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _languageCode == 'en'
                  ? widget.lesson.title
                  : _copy.storyChapter(widget.lesson),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              _languageCode == 'en'
                  ? widget.lesson.eyebrow
                  : '${widget.lesson.from} → ${widget.lesson.to}',
              style: const TextStyle(
                color: AppColors.accentGold,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: OutlinedButton.icon(
              key: const ValueKey<String>('lesson-language-picker'),
              onPressed: _chooseLanguage,
              icon: const Icon(Icons.translate_rounded, size: 18),
              label: Text(
                AppLanguageController.byCode(_languageCode).nativeName,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentGold,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Replay demonstration',
            onPressed: _playDemonstration,
            icon: const Icon(Icons.replay_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: phoneLandscape
            ? _buildPhoneLandscape(context)
            : desktop
            ? _buildDesktop(context)
            : _buildMobile(context),
      ),
    );
  }

  Widget _buildPhoneLandscape(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Center(
            child: _AnimatedAcademyBoard(
              lesson: widget.lesson,
              demoStepIndex: _demoStepIndex,
              movement: _movement,
              phase: _phase,
              selected: _selected,
              onSquareTap: _onSquareTap,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 330,
          child: SingleChildScrollView(
            child: _CoachPanel(
              lesson: widget.lesson,
              phase: _phase,
              feedback: _feedback,
              attempts: _attempts,
              completed: _completed.contains(widget.lesson.id),
              loading: _loadingProgress,
              onReplay: _playDemonstration,
              onPracticeAgain: _resetPractice,
              onContinueLearning: _continueLearning,
              nextLesson: _nextLesson,
              narrationState: _narrationState,
              onToggleNarration: () => unawaited(_toggleNarration()),
              onReplayNarration: () => unawaited(_replayNarration()),
              copy: _copy,
              masteryStars: _phase == _LessonPhase.success
                  ? _earnedStars
                  : (_mastery[widget.lesson.id] ?? 0),
            ),
          ),
        ),
      ],
    ),
  );

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
                demoStepIndex: _demoStepIndex,
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
          child: SingleChildScrollView(
            child: _CoachPanel(
              lesson: widget.lesson,
              phase: _phase,
              feedback: _feedback,
              attempts: _attempts,
              completed: _completed.contains(widget.lesson.id),
              loading: _loadingProgress,
              onReplay: _playDemonstration,
              onPracticeAgain: _resetPractice,
              onContinueLearning: _continueLearning,
              nextLesson: _nextLesson,
              narrationState: _narrationState,
              onToggleNarration: () => unawaited(_toggleNarration()),
              onReplayNarration: () => unawaited(_replayNarration()),
              copy: _copy,
              masteryStars: _phase == _LessonPhase.success
                  ? _earnedStars
                  : (_mastery[widget.lesson.id] ?? 0),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildMobile(BuildContext context) => CustomScrollView(
    slivers: <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
        sliver: SliverList.list(
          children: <Widget>[
            _MobileLessonProgress(phase: _phase),
            const SizedBox(height: 12),
            _AnimatedAcademyBoard(
              lesson: widget.lesson,
              demoStepIndex: _demoStepIndex,
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
              onContinueLearning: _continueLearning,
              nextLesson: _nextLesson,
              narrationState: _narrationState,
              onToggleNarration: () => unawaited(_toggleNarration()),
              onReplayNarration: () => unawaited(_replayNarration()),
              copy: _copy,
              masteryStars: _phase == _LessonPhase.success
                  ? _earnedStars
                  : (_mastery[widget.lesson.id] ?? 0),
            ),
          ],
        ),
      ),
    ],
  );

  void _resetPractice() {
    setState(() {
      _phase = _LessonPhase.practice;
      _selected = null;
      _attempts = 0;
      _feedback = _languageCode == 'en'
          ? widget.lesson.coachPrompt
          : '${_copy.storyChapter(widget.lesson)} · '
                '${widget.lesson.from} → ${widget.lesson.to}';
    });
  }
}

class _AnimatedAcademyBoard extends StatelessWidget {
  const _AnimatedAcademyBoard({
    required this.lesson,
    required this.demoStepIndex,
    required this.movement,
    required this.phase,
    required this.selected,
    required this.onSquareTap,
  });

  final AcademyLesson lesson;
  final int demoStepIndex;
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
        border: Border.all(color: const Color(0xFF2A91F2), width: 2.4),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x662A91F2), blurRadius: 30),
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
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
                final List<AcademyDemoMove> line = lesson.demonstrationLine;
                final int activeIndex = demoStepIndex.clamp(0, line.length - 1);
                for (int index = 0; index < activeIndex; index++) {
                  final AcademyDemoMove step = line[index];
                  final AcademyPiece? piece = pieces.remove(step.from);
                  pieces.remove(step.to);
                  if (piece != null) pieces[step.to] = piece;
                }
                final AcademyDemoMove activeStep = line[activeIndex];
                if (moved) {
                  final AcademyPiece? piece = pieces.remove(activeStep.from);
                  pieces.remove(activeStep.to);
                  if (piece != null) pieces[activeStep.to] = piece;
                }
                return Stack(
                  children: <Widget>[
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
                          hidePiece:
                              demonstrating &&
                              _squareName(row, col) == activeStep.from,
                          onTap: onSquareTap,
                        ),
                    if (demonstrating)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _AcademyRoutePainter(
                              from: activeStep.from,
                              to: activeStep.to,
                              progress: movement.value,
                              curved: pieces[activeStep.from]?.symbol == 'N',
                            ),
                          ),
                        ),
                      ),
                    if (demonstrating)
                      _MovingPiece(
                        piece: pieces[activeStep.from]!,
                        from: activeStep.from,
                        to: activeStep.to,
                        progress: movement.value,
                        squareSize: square,
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: phase == _LessonPhase.demonstration
                                ? const Color(0xEE6D42D8)
                                : const Color(0xEE0E5277),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x6659E4C8),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            child: Text(
                              phase == _LessonPhase.demonstration
                                  ? '1  AI DEMO'
                                  : phase == _LessonPhase.practice
                                  ? '2  YOUR TURN'
                                  : '3  MASTERED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (phase == _LessonPhase.success)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF2A91F2),
                                width: 5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
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
    final bool target =
        phase == _LessonPhase.practice && squareName == lesson.to;
    final Color base = light
        ? const Color(0xFFD8C5A7)
        : const Color(0xFF6D4A32);
    return Positioned(
      left: col * size,
      top: row * size,
      width: size,
      height: size,
      child: Semantics(
        button: true,
        label:
            '$squareName ${piece == null ? 'empty' : _pieceName(piece!.symbol)}',
        child: InkWell(
          onTap: () => onTap(squareName),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF59E4C8)
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
            child: Stack(
              children: <Widget>[
                if (col == 0)
                  Positioned(
                    left: 5,
                    top: 3,
                    child: Text(
                      '${8 - row}',
                      style: TextStyle(
                        color: light
                            ? const Color(0xFF6D4A32)
                            : const Color(0xFFD8C5A7),
                        fontSize: math.max(9, size * .15),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                if (row == 7)
                  Positioned(
                    right: 5,
                    bottom: 2,
                    child: Text(
                      String.fromCharCode(97 + col),
                      style: TextStyle(
                        color: light
                            ? const Color(0xFF6D4A32)
                            : const Color(0xFFD8C5A7),
                        fontSize: math.max(9, size * .15),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
                  Center(
                    child: _PieceGlyph(piece: piece!, size: size * .72),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AcademyRoutePainter extends CustomPainter {
  const _AcademyRoutePainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.curved,
  });

  final String from;
  final String to;
  final double progress;
  final bool curved;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 8;
    final Offset fromSquare = _squareOffset(from);
    final Offset toSquare = _squareOffset(to);
    final Offset start = Offset(
      (fromSquare.dx + .5) * cell,
      (fromSquare.dy + .5) * cell,
    );
    final Offset target = Offset(
      (toSquare.dx + .5) * cell,
      (toSquare.dy + .5) * cell,
    );
    final Offset delta = target - start;
    if (delta.distance < 1) return;
    final Offset direction = delta / delta.distance;
    final Offset normal = Offset(-direction.dy, direction.dx);
    final Path fullRoute = Path()..moveTo(start.dx, start.dy);
    if (curved) {
      final Offset control =
          Offset.lerp(start, target, .5)! + normal * cell * .28;
      fullRoute.quadraticBezierTo(control.dx, control.dy, target.dx, target.dy);
    } else {
      fullRoute.lineTo(target.dx, target.dy);
    }
    final metric = fullRoute.computeMetrics().first;
    final Path route = metric.extractPath(0, metric.length * progress);
    final Offset end =
        metric.getTangentForOffset(metric.length * progress)?.position ?? start;
    final Paint glow = Paint()
      ..color = const Color(0x8859E4C8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = cell * .17
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final Paint line = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFF5EEAD4), Color(0xFF2A91F2)],
      ).createShader(Rect.fromPoints(start, target))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = cell * .055;
    canvas
      ..drawPath(route, glow)
      ..drawPath(route, line)
      ..drawCircle(
        target,
        cell * (.13 + .05 * math.sin(progress * math.pi * 4).abs()),
        Paint()..color = const Color(0x9959E4C8),
      )
      ..drawCircle(end, cell * .075, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_AcademyRoutePainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.curved != curved ||
      oldDelegate.progress != progress;
}

class _MovingPiece extends StatelessWidget {
  const _MovingPiece({
    required this.piece,
    required this.from,
    required this.to,
    required this.progress,
    required this.squareSize,
  });

  final AcademyPiece piece;
  final String from;
  final String to;
  final double progress;
  final double squareSize;

  @override
  Widget build(BuildContext context) {
    final Offset fromOffset = _squareOffset(from);
    final Offset toOffset = _squareOffset(to);
    final Offset current = Offset.lerp(fromOffset, toOffset, progress)!;
    final bool isKnight = piece.symbol == 'N';
    final double lift =
        math.sin(progress * math.pi) * squareSize * (isKnight ? .34 : .06);
    return Positioned(
      left: current.dx * squareSize,
      top: current.dy * squareSize - lift,
      width: squareSize,
      height: squareSize,
      child: IgnorePointer(
        child: Transform.scale(
          scale: 1 + math.sin(progress * math.pi) * (isKnight ? .16 : .06),
          child: _PieceGlyph(
            piece: piece,
            size: squareSize * .76,
            glowing: true,
          ),
        ),
      ),
    );
  }
}

class _PieceGlyph extends StatelessWidget {
  const _PieceGlyph({
    required this.piece,
    required this.size,
    this.glowing = false,
  });

  final AcademyPiece piece;
  final double size;
  final bool glowing;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<ChessPieceAppearance>(
    valueListenable: ChessPieceAppearanceController.current,
    builder: (BuildContext context, ChessPieceAppearance appearance, _) {
      final double scale = switch (appearance.size) {
        ChessPieceVisualSize.large => 1.14,
        ChessPieceVisualSize.extraLarge => 1.28,
        ChessPieceVisualSize.doubleExtraLarge => 1.40,
      };
      final Widget visual;
      if (appearance.style == ChessPieceVisualStyle.classic2d) {
        visual = Text(
          _pieceGlyph(piece),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: size * .9,
            height: 1,
            color: piece.white
                ? const Color(0xFFFFF4D0)
                : const Color(0xFF111722),
            shadows: const <Shadow>[
              Shadow(color: Colors.black87, blurRadius: 3),
            ],
          ),
        );
      } else {
        Widget image = Image.asset(
          _academyPieceAsset(piece),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel:
              '${piece.white ? 'White' : 'Black'} ${_pieceName(piece.symbol)}',
        );
        if (appearance.style == ChessPieceVisualStyle.highContrast) {
          image = ColorFiltered(
            colorFilter: ColorFilter.mode(
              piece.white ? const Color(0xFFFFF0B8) : const Color(0xFF89BFFF),
              BlendMode.modulate,
            ),
            child: image,
          );
        }
        visual = image;
      }
      return SizedBox.square(
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
          child: Transform.scale(scale: scale, child: visual),
        ),
      );
    },
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
    required this.onContinueLearning,
    required this.nextLesson,
    required this.narrationState,
    required this.onToggleNarration,
    required this.onReplayNarration,
    required this.copy,
    required this.masteryStars,
  });

  final AcademyLesson lesson;
  final _LessonPhase phase;
  final String? feedback;
  final int attempts;
  final bool completed;
  final bool loading;
  final VoidCallback onReplay;
  final VoidCallback onPracticeAgain;
  final VoidCallback onContinueLearning;
  final AcademyLesson? nextLesson;
  final _NarrationState narrationState;
  final VoidCallback onToggleNarration;
  final VoidCallback onReplayNarration;
  final AcademyStoryLocalizations copy;
  final int masteryStars;

  @override
  Widget build(BuildContext context) {
    final Color accent = phase == _LessonPhase.success
        ? const Color(0xFF59E4C8)
        : phase == _LessonPhase.practice
        ? AppColors.accentGold
        : AppColors.accentGold;
    return ChessVerseCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.psychology_alt_rounded, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      copy.text('ui.aiCoach'),
                      style: const TextStyle(
                        color: Color(0xFF59E4C8),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      copy.text('ui.strapline'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (!loading && completed)
                const Icon(Icons.verified_rounded, color: Color(0xFF59E4C8)),
            ],
          ),
          const SizedBox(height: 18),
          if (lesson.id.startsWith('clock-')) ...<Widget>[
            _TimePressureBanner(phase: phase),
            const SizedBox(height: 14),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0x332A91F2), Color(0x2259E4C8)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x6659E4C8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  copy.storyChapter(lesson),
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  copy.storyNarration(lesson),
                  style: const TextStyle(
                    color: Color(0xFFEAF2F6),
                    height: 1.42,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: onToggleNarration,
                      icon: Icon(
                        narrationState == _NarrationState.playing
                            ? Icons.pause_rounded
                            : Icons.volume_up_rounded,
                      ),
                      label: Text(
                        narrationState == _NarrationState.playing
                            ? copy.text('ui.pause')
                            : narrationState == _NarrationState.paused
                            ? copy.text('ui.continue')
                            : copy.text('ui.listen'),
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: copy.text('ui.restart'),
                      onPressed: onReplayNarration,
                      icon: const Icon(Icons.replay_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (copy.code == 'en') ...<Widget>[
            Text(
              lesson.explanation,
              style: const TextStyle(
                color: Color(0xFFD9E4EB),
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
          ],
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
          if (phase == _LessonPhase.success) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0x2259E4C8),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0x7759E4C8)),
              ),
              child: Row(
                children: <Widget>[
                  for (int star = 1; star <= 3; star++)
                    Icon(
                      star <= masteryStars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.accentGold,
                    ),
                  const Spacer(),
                  Text(
                    '+${masteryStars * 25} XP',
                    style: const TextStyle(
                      color: Color(0xFF59E4C8),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (phase == _LessonPhase.success)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FilledButton.icon(
                  key: const ValueKey<String>('next-academy-lesson'),
                  onPressed: onContinueLearning,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: const Color(0xFF071827),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 6,
                  ),
                  icon: Icon(
                    nextLesson == null
                        ? Icons.school_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    nextLesson == null
                        ? copy.text('academy.title').toUpperCase()
                        : copy
                              .text(
                                'path.next',
                                values: <String, String>{
                                  'lesson': copy.storyChapter(nextLesson!),
                                },
                              )
                              .toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onPracticeAgain,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    copy.code == 'en'
                        ? 'PRACTICE AGAIN'
                        : copy.text('ui.restart'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReplay,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: Text(
                      copy.code == 'en' ? 'REPLAY' : copy.text('ui.restart'),
                    ),
                  ),
                ),
                if (phase == _LessonPhase.practice &&
                    copy.code == 'en') ...<Widget>[
                  const SizedBox(width: 10),
                  Chip(
                    avatar: const Icon(Icons.touch_app_rounded, size: 17),
                    label: Text(
                      attempts == 0 ? 'Your turn' : '$attempts tries',
                    ),
                  ),
                ],
              ],
            ),
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
        const Text(
          'LESSON FLOW',
          style: TextStyle(
            color: AppColors.accentGold,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 18),
        const _RailStep(
          number: '01',
          title: 'Watch',
          icon: Icons.animation_rounded,
        ),
        const _RailLine(),
        const _RailStep(
          number: '02',
          title: 'Understand',
          icon: Icons.psychology_rounded,
        ),
        const _RailLine(),
        const _RailStep(
          number: '03',
          title: 'Practice',
          icon: Icons.touch_app_rounded,
        ),
        const _RailLine(),
        const _RailStep(
          number: '04',
          title: 'Master',
          icon: Icons.workspace_premium_rounded,
        ),
        const Spacer(),
        Text(
          lesson.eyebrow,
          style: const TextStyle(
            color: Color(0xFF59E4C8),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lesson.title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _RailStep extends StatelessWidget {
  const _RailStep({
    required this.number,
    required this.title,
    required this.icon,
  });
  final String number;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
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
            Text(
              number,
              style: const TextStyle(
                color: AppColors.accentGold,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    ],
  );
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

class _TimePressureBanner extends StatelessWidget {
  const _TimePressureBanner({required this.phase});

  final _LessonPhase phase;

  @override
  Widget build(BuildContext context) {
    final bool solved = phase == _LessonPhase.success;
    return AnimatedContainer(
      key: const ValueKey<String>('time-pressure-banner'),
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: solved
              ? const <Color>[Color(0xFF164C46), Color(0xFF0C2D31)]
              : const <Color>[Color(0xFF48282B), Color(0xFF211B27)],
        ),
        border: Border.all(
          color: solved ? const Color(0xFF59E4C8) : const Color(0xFFFF8A72),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            solved ? Icons.timer_outlined : Icons.timer_rounded,
            color: solved ? const Color(0xFF59E4C8) : const Color(0xFFFF8A72),
          ),
          const SizedBox(width: 10),
          Text(
            solved ? '+ 00:02' : '00:10',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          for (final IconData icon in const <IconData>[
            Icons.add_circle_outline_rounded,
            Icons.close_fullscreen_rounded,
            Icons.bolt_rounded,
          ]) ...<Widget>[
            Icon(icon, size: 17, color: AppColors.accentGold),
            const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
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
