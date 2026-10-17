import '../../../core/analytics/app_analytics.dart';

import 'dart:async';

import '../../../core/ads/rewarded_coin_service.dart';
import '../../../core/monetization_copy.dart';

import '../data/personal_mistake_backup.dart';

import '../domain/mistake_bank_sync.dart';
import '../domain/mistake_review.dart';
import '../domain/mistake_challenge.dart';
import '../domain/mistake_lesson_engine.dart';
import '../data/engine_candidates_api.dart';
import '../../auth/data/auth_session_store.dart';

import 'package:flutter/material.dart';

import '../../../core/analysis_dashboard_localizations.dart';
import '../../../core/app_language.dart';
import '../../../core/widgets/ai_language_picker.dart';
import '../../../core/mistake_bank_localizations.dart';
import '../../../core/mistake_lesson_localizations.dart';
import '../../../core/mistake_practice_localizations.dart';
import '../../../core/coach_extra_localizations.dart';
import '../../../core/coach_localizations.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/review_narrative_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../../core/widgets/desktop_navigation_shell.dart';
import '../../tutorial/data/academy_progress_store.dart';
import '../domain/mistake_bank.dart';
import '../domain/pgn_position_reconstructor.dart';

class MistakeBankEntryCard extends StatelessWidget {
  const MistakeBankEntryCard({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: LocalGameArchive.activityRevision,
    builder: (context, _, _) => ValueListenableBuilder<String?>(
      valueListenable: AppLanguageController.effectiveLanguageChanges,
      builder: (context, selectedLanguage, _) {
        final String language = AppLanguageController.resolveCode(
          selectedLanguage ?? AppLanguageController.systemCode,
        );
        final int count = MistakeBank.all(LocalGameArchive.games).length;
        final String subtitle = count > 0
            ? '$count · ${CoachLocalizations(language).text('trainMistakes')}'
            : coachExtraText('completeGame', language);
        return ChessVerseCard(
          key: const ValueKey<String>('mistake-bank-card'),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => const MistakeBankScreen()),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF8A72).withValues(alpha: .12),
                  border: Border.all(color: const Color(0xFFFF8A72)),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Color(0xFFFF8A72),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      CoachLocalizations(language).text('trainMistakes'),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        );
      },
    ),
  );
}

class MistakeBankScreen extends StatefulWidget {
  const MistakeBankScreen({
    super.key,
    this.analyzePosition,
    this.showRewardedHint,
  });

  final Future<RewardedCoinOutcome> Function()? showRewardedHint;

  final Future<List<EngineCandidateLine>> Function(String fen)? analyzePosition;

  @override
  State<MistakeBankScreen> createState() => _MistakeBankScreenState();
}

class _MistakeBankScreenState extends State<MistakeBankScreen> {
  static const AcademyProgressStore _progressStore = AcademyProgressStore();
  late List<MistakeBankItem> _allItems;
  List<MistakeBankItem> _items = <MistakeBankItem>[];
  Map<String, MistakeReview> _reviews = {};
  bool _savingReview = false;
  bool _hadMistake = false;
  bool _loadingReviews = true;
  bool _languageReady = false;
  int _index = 0;
  String? _currentFen;
  String? _selectedSquare;
  String? _wrongTarget;
  int _lineIndex = 0;
  int _hintLevel = 0;
  bool _hintVideoPending = false;
  String? _hintVideoMessage;
  bool get _offersHintVideo =>
      _independent &&
      _hintLevel == 1 &&
      (widget.showRewardedHint != null || RewardedCoinService.hints.supported);

  Future<void> _requestHint() async {
    if (_hintVideoPending || _completed || _replyPending || _hintLevel >= 2) {
      return;
    }
    if (!_offersHintVideo) {
      setState(() {
        _usedHelp = true;
        _hintLevel++;
      });
      return;
    }
    final attempt = _attempt;
    final fen = _currentFen;
    final index = _index;
    setState(() {
      _hintVideoPending = true;
      _hintVideoMessage = null;
    });
    try {
      final outcome =
          await (widget.showRewardedHint?.call() ??
              RewardedCoinService.hints.show(playerId: '', token: ''));
      if (!mounted ||
          attempt != _attempt ||
          fen != _currentFen ||
          index != _index ||
          _completed ||
          !_independent) {
        return;
      }
      setState(() {
        if (outcome == RewardedCoinOutcome.earned) {
          _usedHelp = true;
          _hintLevel = 2;
        } else if (outcome == RewardedCoinOutcome.unavailable) {
          _hintVideoMessage = monetizationText('unavailable', _language);
        }
      });
    } on Object {
      if (mounted && attempt == _attempt && index == _index) {
        setState(
          () => _hintVideoMessage = monetizationText('unavailable', _language),
        );
      }
    } finally {
      if (mounted) setState(() => _hintVideoPending = false);
    }
  }

  bool _completed = false;
  bool _independent = false;
  bool _usedHelp = false;
  bool _verifiedIndependent = false;
  List<String>? _activeLine;
  List<String> _previewPositions = [];
  int _previewIndex = 0;
  String? _feedback;
  String? _attemptedMove;
  bool get _previewing => _previewPositions.isNotEmpty;
  bool _replyPending = false;
  int _attempt = 0;
  String _language = AppLanguageController.resolveCode(
    AppLanguageController.systemCode,
  );

  String t(String key, [Map<String, String> values = const {}]) =>
      analysisDashboardText(key, _language, values);

  @override
  void initState() {
    super.initState();
    unawaited(AppAnalytics.logFeature(FeatureEvent.mistake_bank_viewed));
    _allItems = MistakeBank.all(LocalGameArchive.games);
    _items = _allItems.take(5).toList(growable: false);
    if (_items.isNotEmpty) _currentFen = _items.first.review.fenBefore;
    AppLanguageController.effectiveLanguageChanges.addListener(_onLanguage);
    AppLanguageController.effectiveCode().then((String code) {
      if (mounted) {
        setState(() {
          _language = code;
          _languageReady = true;
        });
      }
    });
    _loadSolved();
  }

  Future<void> _loadSolved() async {
    try {
      if (_allItems.isEmpty) {
        await PersonalMistakeBackup.instance.sync();
      } else {
        unawaited(PersonalMistakeBackup.instance.sync());
      }
      if (!mounted) return;
      _allItems = MistakeBank.all(LocalGameArchive.games);
      final value = await _progressStore.readMistakeReviews();
      if (mounted) {
        setState(() {
          _reviews = value;
          final now = DateTime.now().toUtc();
          _items = _allItems
              .where((item) => value[item.id]?.due(now) ?? true)
              .take(5)
              .toList(growable: false);
          _index = 0;
          _currentFen = _items.isEmpty ? null : _items.first.review.fenBefore;
        });
      }
    } on Object {
      // Offline practice is still available when storage cannot be read.
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
    unawaited(syncAcademyMistakeBank());
  }

  void _onLanguage() {
    final String? code = AppLanguageController.effectiveLanguageChanges.value;
    if (code != null && mounted) setState(() => _language = code);
  }

  Widget _languageButton() => TextButton.icon(
    key: const ValueKey('mistake-language-picker'),
    onPressed: () async {
      final String? selected = await showAiLanguagePicker(context);
      if (selected == null || !mounted) return;
      await AppLanguageController.select(selected);
    },
    icon: const Icon(Icons.translate_rounded, size: 20),
    label: SizedBox(
      width: 90,
      child: Text(
        AppLanguageController.byCode(_language).nativeName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    style: TextButton.styleFrom(foregroundColor: const Color(0xFF63D2B8)),
  );

  @override
  void dispose() {
    AppLanguageController.effectiveLanguageChanges.removeListener(_onLanguage);
    super.dispose();
  }

  List<String> get _challengeLine =>
      _activeLine ?? mistakeChallengeLine(_items[_index].review);

  String m(String key, [Map<String, String> values = const {}]) =>
      mistakeBankText(key, _language, values);

  String p(String key, [Map<String, String> values = const {}]) =>
      mistakePracticeText(key, _language, values);

  Future<List<EngineCandidateLine>> _analyze(String fen) async {
    try {
      if (widget.analyzePosition != null) {
        return await widget.analyzePosition!(fen).timeout(
          const Duration(seconds: 6),
        );
      }
      final session = await const AuthSessionStore().read();
      if (session == null || session.isExpired) return [];
      return await const EngineCandidatesApi()
          .analyze(session.token, fen: fen)
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      return [];
    }
  }

  void _startPractice(bool independent) {
    if (_replyPending || _savingReview) return;
    _retry();
    setState(() {
      _independent = independent;
    });
  }

  Future<void> _showComparison(bool better) async {
    if (_replyPending || _savingReview) return;
    final review = _items[_index].review;
    final original = _attemptedMove ?? review.playedMove.trim().toLowerCase();
    final fen = _attemptedMove == null ? review.fenBefore : _currentFen!;
    final moves = better ? mistakeChallengeLine(review) : [original];
    var positions = replayUciLine(
      better ? review.fenBefore : fen,
      moves,
      requireLegalMoves: true,
    );
    final generation = _attempt;
    if (positions.length < 2) return;
    setState(() {
      _usedHelp = true;
      _replyPending = true;
      _feedback = p('checking');
    });
    if (!better) {
      final lines = await _analyze(positions.last);
      if (!mounted || generation != _attempt) return;
      final reply = lines.isEmpty
          ? <String>[]
          : validCandidateContinuation(positions.last, lines.first);
      if (reply.isNotEmpty) {
        positions = [
          ...positions,
          ...replayUciLine(positions.last, [
            reply.first,
          ], requireLegalMoves: true).skip(1),
        ];
        _feedback = p('reply', {'move': _readableMove(reply.first)});
      } else {
        _feedback = p('noReply');
      }
    } else {
      _feedback = lesson('better', {
        'move': _readableMove(_activeLine?.firstOrNull ?? review.bestMove),
      });
    }
    if (!mounted || generation != _attempt) return;
    setState(() {
      _replyPending = false;
      _previewPositions = positions;
      _previewIndex = 1;
    });
  }

  String lesson(String key, [Map<String, String> values = const {}]) =>
      mistakeLessonText(key, _language, values);

  String _readableMove(String move) {
    final value = move.trim().toLowerCase();
    if (!RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$').hasMatch(value)) return move;
    final promotion = value.length == 5
        ? ' = ${m(value[4].toUpperCase())}'
        : '';
    return '${value.substring(0, 2)} → ${value.substring(2, 4)}$promotion';
  }

  String _goal(MistakeBankItem item) {
    final theme = item.review.coachingTheme;
    final focus =
        const {
          'opening',
          'kingSafety',
          'hangingPieces',
          'missedCaptures',
          'timeManagement',
          'endgame',
          'tactics',
        }.contains(theme)
        ? theme
        : 'calculation';
    return lesson('goal', {'focus': t(focus)});
  }

  Widget _lessonCard(MistakeBankItem item) {
    final review = item.review;
    final moveNumber =
        int.tryParse(review.fenBefore.trim().split(RegExp(r'\s+')).last) ??
        ((review.ply + 1) ~/ 2);
    final explanation = review.explanation.trim();
    return ChessVerseCard(
      key: const ValueKey('mistake-lesson'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            lesson('context', {'move': '$moveNumber'}),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            lesson('played', {'move': _readableMove(review.playedMove)}),
            key: const ValueKey('mistake-original-move'),
          ),
          Text(
            CoachLocalizations(_language).source(review.classification),
            style: const TextStyle(color: AppColors.accentGold),
          ),
          const SizedBox(height: 8),
          if (_completed) ...[
            Text(
              lesson('better', {
                'move': _readableMove(
                  _activeLine?.firstOrNull ?? review.bestMove,
                ),
              }),
              key: const ValueKey('mistake-better-move'),
              style: const TextStyle(
                color: Color(0xFF59E4C8),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              lesson('complete'),
              key: const ValueKey('mistake-completion-explanation'),
            ),
          ],
          const SizedBox(height: 8),
          if (!_independent || _completed || _previewing)
            ExpansionTile(
              key: ValueKey(
                'mistake-explanation-$_index-$_independent-$_completed-$_previewing',
              ),
              initiallyExpanded: _completed || _previewing,
              tilePadding: EdgeInsets.zero,
              title: Text(
                lesson('analysis'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              children: [
                Text(
                  explanation.isEmpty
                      ? lesson('missing')
                      : localizeReviewNarrative(explanation, _language),
                  key: const ValueKey('mistake-reason'),
                ),
              ],
            ),
          if (_completed &&
              _verifiedIndependent &&
              _reviews[item.id] != null) ...[
            const SizedBox(height: 8),
            Text(
              lesson('nextReview', {
                'date': _reviews[item.id]!.nextReview
                    .toLocal()
                    .toString()
                    .split(' ')
                    .first,
              }),
              key: const ValueKey('mistake-next-review'),
            ),
          ],
        ],
      ),
    );
  }

  String _piecePrompt(String move) {
    final from = move.substring(0, 2);
    final row = 8 - int.parse(from[1]);
    final col = from.codeUnitAt(0) - 97;
    final token = _MistakeBoard(
      fen: _currentFen!,
      onSquare: (_) {},
    ).pieces['$row-$col'];
    if (token == null) return '';
    return m('piecePrompt', {'square': from, 'piece': m(token.toUpperCase())});
  }

  String get _instructions => _completed
      ? p(
          _verifiedIndependent
              ? 'independentDone'
              : _independent
              ? 'assistedDone'
              : 'guidedDone',
        )
      : _replyPending
      ? p('checking')
      : _feedback != null
      ? _feedback!
      : m('instructions');

  final PlayActivityTracker _practiceActivity = PlayActivityTracker();

  Future<void> _playSquare(String square) async {
    if (_completed ||
        _previewing ||
        _replyPending ||
        _savingReview ||
        _loadingReviews ||
        _lineIndex >= _challengeLine.length) {
      return;
    }
    final board = _MistakeBoard(fen: _currentFen!, onSquare: (_) {}).pieces;
    final row = 8 - int.parse(square[1]);
    final col = square.codeUnitAt(0) - 97;
    final piece = board['$row-$col'];
    final white = _currentFen!.split(' ')[1] == 'w';
    final ownPiece = piece != null && (piece == piece.toUpperCase()) == white;
    if (ownPiece) {
      setState(() {
        _selectedSquare = _selectedSquare == square ? null : square;
        _wrongTarget = null;
      });
      return;
    }
    if (_selectedSquare == null) return;
    if (_practiceActivity.acceptHumanMove()) {
      unawaited(
        AppAnalytics.logFeature(
          FeatureEvent.mistake_practice_started,
          assisted: !_independent,
        ),
      );
    }
    final String attempted = '$_selectedSquare$square'.toLowerCase();
    var expected = _challengeLine[_lineIndex];
    if (!expected.startsWith(attempted)) {
      final fen = _currentFen!;
      var candidateMove = attempted;
      {
        final from = _selectedSquare!;
        final source =
            board['${8 - int.parse(from[1])}-${from.codeUnitAt(0) - 97}'];
        if (source?.toUpperCase() == 'P' &&
            (square[1] == '1' || square[1] == '8')) {
          candidateMove += 'q';
        }
      }
      final legal =
          replayUciLine(fen, [candidateMove], requireLegalMoves: true).length ==
          2;
      final generation = _attempt;
      setState(() {
        _replyPending = true;
        _feedback = p('checking');
      });
      final candidates = legal ? await _analyze(fen) : <EngineCandidateLine>[];
      if (!mounted || generation != _attempt) return;
      final candidate = candidates
          .where((line) => line.move.toLowerCase() == candidateMove)
          .firstOrNull;
      final accepted =
          candidate != null && isComparableLessonMove(candidates, candidate);
      final continuation = accepted
          ? validCandidateContinuation(fen, candidate)
          : <String>[];
      if (continuation.isNotEmpty) {
        _activeLine = [..._challengeLine.take(_lineIndex), ...continuation];
        expected = continuation.first;
        _replyPending = false;
      } else {
        setState(() {
          _hadMistake = true;
          _replyPending = false;
          _wrongTarget = !legal || candidate != null ? square : null;
          _selectedSquare = null;
          _attemptedMove = legal ? candidateMove : null;
          _feedback = legal ? '${p('unverified')}\n${m('wrong')}' : m('wrong');
          if (candidate != null &&
              candidate.mateIn == null &&
              candidates.every((c) => c.mateIn == null)) {
            final best = candidates
                .map((c) => c.evaluationCp)
                .reduce((a, b) => a > b ? a : b);
            _feedback = p('lower', {
              'loss': ((best - candidate.evaluationCp) / 100).toStringAsFixed(
                2,
              ),
            });
          }
        });
        return;
      }
    }
    final attempt = _attempt;
    final List<String> positions = replayUciLine(_currentFen!, <String>[
      expected,
    ]);
    if (positions.length < 2) return;
    setState(() {
      _currentFen = positions.last;
      _lineIndex++;
      _selectedSquare = null;
      _wrongTarget = null;
      _hintLevel = 0;
      _hintVideoMessage = null;
      _feedback = null;
      _attemptedMove = null;
      _replyPending = true;
    });
    if (_lineIndex < _challengeLine.length) {
      final String reply = _challengeLine[_lineIndex];
      final List<String> replyPositions = replayUciLine(_currentFen!, <String>[
        reply,
      ]);
      if (replyPositions.length > 1) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!mounted || attempt != _attempt) return;
        setState(() {
          _currentFen = replyPositions.last;
          _lineIndex++;
        });
      }
    }
    if (!mounted || attempt != _attempt) return;
    if (_lineIndex >= _challengeLine.length) await _completeChallenge();
    if (mounted && attempt == _attempt) setState(() => _replyPending = false);
  }

  Future<void> _completeChallenge() async {
    if (_completed || _savingReview) return;
    _verifiedIndependent = _independent && !_usedHelp && !_hadMistake;
    unawaited(
      AppAnalytics.logFeature(
        FeatureEvent.mistake_practice_completed,
        assisted: !_verifiedIndependent,
      ),
    );
    await _saveReview(true);
    if (mounted) setState(() => _completed = true);
  }

  Future<void> _saveReview(bool correct) async {
    _savingReview = true;
    final id = _items[_index].id;
    try {
      _reviews[id] = await _progressStore.recordMistakeReview(
        id,
        correct,
        assisted: !_verifiedIndependent,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(m('saveError'))));
      }
    } finally {
      _savingReview = false;
    }
    unawaited(syncAcademyMistakeBank());
  }

  void _retry() => setState(() {
    _attempt++;
    _practiceActivity.reset();
    _activeLine = null;
    _previewPositions = [];
    _feedback = null;
    _attemptedMove = null;
    _usedHelp = false;
    _verifiedIndependent = false;
    _replyPending = false;
    _currentFen = _items[_index].review.fenBefore;
    _selectedSquare = null;
    _wrongTarget = null;
    _lineIndex = 0;
    _hintLevel = 0;
    _hintVideoMessage = null;
    _completed = false;
    _hadMistake = false;
  });

  void _next() {
    if (_savingReview || _replyPending) return;
    _attempt++;
    _practiceActivity.reset();
    if (_index >= _items.length - 1) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _index++;
      _activeLine = null;
      _previewPositions = [];
      _feedback = null;
      _attemptedMove = null;
      _usedHelp = false;
      _verifiedIndependent = false;
      _currentFen = _items[_index].review.fenBefore;
      _selectedSquare = null;
      _wrongTarget = null;
      _lineIndex = 0;
      _hintLevel = 0;
      _hintVideoMessage = null;
      _completed = false;
      _hadMistake = false;
    });
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: const {'ar', 'ur', 'fa', 'he'}.contains(_language)
        ? TextDirection.rtl
        : TextDirection.ltr,
    child: Builder(builder: _buildScreen),
  );

  Widget _buildScreen(BuildContext context) {
    if (_loadingReviews || !_languageReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_items.isEmpty) {
      return DesktopNavigationShell(
        selected: 'Learn',
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: Text(m('title')), actions: [_languageButton()]),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ChessVerseCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.verified_rounded,
                      size: 64,
                      color: Color(0xFF63D2B8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _allItems.isEmpty
                          ? t('historyEmpty')
                          : coachExtraText('noMistakes', _language),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final MistakeBankItem item = _items[_index];
    final String expected = _challengeLine.isEmpty
        ? ''
        : _challengeLine[_lineIndex.clamp(0, _challengeLine.length - 1)];
    return DesktopNavigationShell(
      selected: 'Learn',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          actions: [_languageButton()],
          toolbarHeight:
              64 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
          backgroundColor: const Color(0xFF071827),
          title: Text(
            m('title'),
            maxLines: 3,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                SingleChildScrollView(
                  primary: true,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    72 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _MistakeProgress(
                            current: _index + 1,
                            total: _items.length,
                          ),
                          const SizedBox(height: 12),
                          if (!_completed)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    key: const ValueKey('mistake-learn'),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: !_independent
                                          ? const Color(0xFF174C48)
                                          : null,
                                    ),
                                    onPressed: _replyPending || _savingReview
                                        ? null
                                        : () => _startPractice(false),
                                    child: Text(
                                      p('learn'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    key: const ValueKey('mistake-try-own'),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: _independent
                                          ? const Color(0xFF174C48)
                                          : null,
                                    ),
                                    onPressed: _replyPending || _savingReview
                                        ? null
                                        : () => _startPractice(true),
                                    child: Text(
                                      p('tryOwn'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (!_completed) ...[
                            Text(
                              lesson('played', {
                                'move': _readableMove(item.review.playedMove),
                              }),
                              key: const ValueKey('mistake-original-summary'),
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (_challengeLine.isNotEmpty)
                              Text(
                                _goal(item),
                                key: const ValueKey('mistake-goal'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF59E4C8),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                          const SizedBox(height: 12),
                          if (!_completed)
                            Text(
                              _challengeLine.isEmpty
                                  ? m('unavailable')
                                  : CoachLocalizations(_language)
                                        .text('findContinuation', {
                                          'side': CoachLocalizations(_language)
                                              .text(
                                                item.review.fenBefore.split(
                                                          ' ',
                                                        )[1] ==
                                                        'w'
                                                    ? 'white'
                                                    : 'black',
                                              ),
                                        }),
                              key: const ValueKey('mistake-turn'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accentGold,
                              ),
                            ),
                          const SizedBox(height: 6),
                          if (_challengeLine.isNotEmpty &&
                              !_previewing &&
                              (_completed ||
                                  _replyPending ||
                                  _feedback != null ||
                                  _independent))
                            Text(
                              _instructions,
                              key: const ValueKey('mistake-instructions'),
                              semanticsLabel: _instructions,
                            ),
                          if (!_completed &&
                              !_replyPending &&
                              (!_independent || _hintLevel >= 1) &&
                              expected.length >= 4)
                            Text(
                              _piecePrompt(expected),
                              key: const ValueKey('mistake-piece-prompt'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF59E4C8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (!_completed &&
                              (!_independent || _hintLevel >= 2) &&
                              expected.length >= 4)
                            Text(
                              '${expected.substring(0, 2)} → ${expected.substring(2, 4)}',
                              key: const ValueKey('mistake-hint-move'),
                            ),
                          if (_previewing) ...[
                            Text(
                              _feedback ?? '',
                              key: const ValueKey('mistake-preview-feedback'),
                            ),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                IconButton(
                                  key: const ValueKey(
                                    'mistake-preview-previous',
                                  ),
                                  onPressed: _previewIndex == 0
                                      ? null
                                      : () => setState(() => _previewIndex--),
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text(
                                  '${_previewIndex + 1}/${_previewPositions.length}',
                                ),
                                IconButton(
                                  key: const ValueKey('mistake-preview-next'),
                                  onPressed:
                                      _previewIndex ==
                                          _previewPositions.length - 1
                                      ? null
                                      : () => setState(() => _previewIndex++),
                                  icon: const Icon(Icons.chevron_right),
                                ),
                                TextButton(
                                  key: const ValueKey('mistake-preview-close'),
                                  onPressed: () => setState(() {
                                    _previewPositions = [];
                                    _feedback = null;
                                  }),
                                  child: Text(p('back')),
                                ),
                              ],
                            ),
                          ],
                          if (_challengeLine.isNotEmpty)
                            _MistakeBoard(
                              language: _language,
                              fen: _previewing
                                  ? _previewPositions[_previewIndex]
                                  : _currentFen ?? item.review.fenBefore,
                              flipped:
                                  item.review.fenBefore
                                      .split(' ')
                                      .elementAtOrNull(1) ==
                                  'b',
                              selectedSquare: _previewing
                                  ? null
                                  : _selectedSquare,
                              wrongTarget: _wrongTarget,
                              hintFrom:
                                  !_completed &&
                                      !_previewing &&
                                      !_replyPending &&
                                      (!_independent || _hintLevel >= 1) &&
                                      expected.length >= 4
                                  ? expected.substring(0, 2)
                                  : null,
                              hintTo:
                                  !_completed &&
                                      !_previewing &&
                                      (!_independent || _hintLevel >= 2) &&
                                      expected.length >= 4
                                  ? expected.substring(2, 4)
                                  : null,
                              onSquare: _playSquare,
                            ),
                          if (_completed) ...[
                            const SizedBox(height: 12),
                            if (!_verifiedIndependent)
                              FilledButton(
                                key: const ValueKey('mistake-self-test'),
                                onPressed: _savingReview || _replyPending
                                    ? null
                                    : () => _startPractice(true),
                                child: Text(p('tryOwn')),
                              ),
                            if (_verifiedIndependent)
                              FilledButton.icon(
                                key: const ValueKey('mistake-next'),
                                onPressed: _savingReview || _replyPending
                                    ? null
                                    : _next,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: Text(
                                  coachExtraText(
                                    _index == _items.length - 1
                                        ? 'finishSet'
                                        : 'nextPuzzle',
                                    _language,
                                  ),
                                ),
                              )
                            else
                              TextButton(
                                key: const ValueKey('mistake-next'),
                                onPressed: _savingReview || _replyPending
                                    ? null
                                    : _next,
                                child: Text(
                                  coachExtraText(
                                    _index == _items.length - 1
                                        ? 'finishSet'
                                        : 'nextPuzzle',
                                    _language,
                                  ),
                                ),
                              ),
                          ],
                          if (!_completed)
                            Wrap(
                              spacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  key: const ValueKey('mistake-hint'),
                                  onPressed:
                                      _completed ||
                                          _replyPending ||
                                          _challengeLine.isEmpty ||
                                          _hintVideoPending ||
                                          _hintLevel >= 2
                                      ? null
                                      : _requestHint,
                                  icon: Icon(
                                    _offersHintVideo
                                        ? Icons.ondemand_video
                                        : Icons.lightbulb_outline_rounded,
                                  ),
                                  label: _hintVideoPending
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _offersHintVideo
                                              ? monetizationText(
                                                  'hintVideo',
                                                  _language,
                                                )
                                              : m('hint'),
                                        ),
                                ),
                                TextButton(
                                  key: const ValueKey('mistake-skip'),
                                  onPressed: _savingReview || _replyPending
                                      ? null
                                      : _next,
                                  child: Text(m('skip')),
                                ),
                              ],
                            ),
                          if (_hintVideoMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _hintVideoMessage!,
                                key: const ValueKey('hint-video-message'),
                              ),
                            ),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                key: const ValueKey('mistake-show-played'),
                                onPressed: _replyPending || _savingReview
                                    ? null
                                    : () => _showComparison(false),
                                child: Text(p('showPlayed')),
                              ),
                              TextButton(
                                key: const ValueKey('mistake-show-better'),
                                onPressed: _replyPending || _savingReview
                                    ? null
                                    : () => _showComparison(true),
                                child: Text(p('showBetter')),
                              ),
                            ],
                          ),
                          _lessonCard(item),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _MistakeProgress extends StatelessWidget {
  const _MistakeProgress({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: <Widget>[
        const Icon(Icons.psychology_alt_rounded, color: AppColors.accentGold),
        const SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : current / total,
            backgroundColor: AppColors.border,
            color: const Color(0xFF63D2B8),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$current/$total',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _MistakeBoard extends StatelessWidget {
  const _MistakeBoard({
    required this.fen,
    required this.onSquare,
    this.selectedSquare,
    this.wrongTarget,
    this.hintFrom,
    this.hintTo,
    this.flipped = false,
    this.language = 'en',
  });
  final String fen;
  final bool flipped;
  final String language;
  final ValueChanged<String> onSquare;
  final String? selectedSquare;
  final String? wrongTarget;
  final String? hintFrom;
  final String? hintTo;

  Map<String, String> get pieces {
    final List<String> ranks = fen.split(' ').first.split('/');
    final Map<String, String> result = <String, String>{};
    for (int row = 0; row < ranks.length && row < 8; row++) {
      int file = 0;
      for (final String token in ranks[row].split('')) {
        final int? empty = int.tryParse(token);
        if (empty != null) {
          file += empty;
        } else if (file < 8) {
          result['$row-$file'] = token;
          file++;
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: _buildBoard(context),
  );

  Widget _buildBoard(BuildContext context) {
    final Map<String, String> board = pieces;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: GridView.builder(
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 64,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (BuildContext context, int index) {
                final int row = flipped ? 7 - index ~/ 8 : index ~/ 8;
                final int col = flipped ? 7 - index % 8 : index % 8;
                final String square =
                    '${String.fromCharCode(97 + col)}${8 - row}';
                final bool selected = square == selectedSquare;
                final bool wrong = square == wrongTarget;
                final bool hint = square == hintFrom || square == hintTo;
                return InkWell(
                  key: ValueKey<String>('mistake-square-$square'),
                  onTap: () => onSquare(square),
                  child: ColoredBox(
                    color: wrong
                        ? const Color(0xFFFF6B6B)
                        : selected
                        ? const Color(0xFF73BFFF)
                        : hint
                        ? const Color(0xFF59E4C8)
                        : (row + col).isEven
                        ? const Color(0xFFD8C5A7)
                        : const Color(0xFF6D4A32),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Center(child: _piece(board['$row-$col'])),
                        ),
                        if (col == (flipped ? 7 : 0))
                          Positioned(
                            top: 1,
                            left: 2,
                            child: Text(
                              '${8 - row}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        if (row == (flipped ? 0 : 7))
                          Positioned(
                            bottom: 1,
                            right: 2,
                            child: Text(
                              String.fromCharCode(97 + col),
                              style: const TextStyle(
                                fontSize: 9,
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
        ),
      ),
    );
  }

  Widget _piece(String? token) {
    if (token == null) return const SizedBox.shrink();
    const Map<String, String> names = <String, String>{
      'k': 'king',
      'q': 'queen',
      'r': 'rook',
      'b': 'bishop',
      'n': 'knight',
      'p': 'pawn',
    };
    final bool white = token == token.toUpperCase();
    final String colour = white ? 'white' : 'black';
    final String name = names[token.toLowerCase()]!;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Image.asset(
        // Mistake training always uses the regular, readable 3D set. Premium
        // collection equipment must not leak into this analysis board.
        'assets/pieces/staunton_${colour}_$name.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel:
            '${CoachLocalizations(language).text(white ? 'white' : 'black')} ${mistakeBankText(token.toUpperCase(), language)}',
      ),
    );
  }
}
