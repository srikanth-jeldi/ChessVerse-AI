import 'dart:async';

import '../domain/mistake_bank_sync.dart';
import '../domain/mistake_review.dart';

import 'package:flutter/material.dart';

import '../../../core/analysis_dashboard_localizations.dart';
import '../../../core/app_language.dart';
import '../../../core/coach_extra_localizations.dart';
import '../../../core/coach_localizations.dart';
import '../../../core/desktop_navigation_bridge.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/review_narrative_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../../core/widgets/coin_balance_badge.dart';
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
                    const Text(
                      'Mistake Bank',
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
  const MistakeBankScreen({super.key});

  @override
  State<MistakeBankScreen> createState() => _MistakeBankScreenState();
}

class _MistakeBankScreenState extends State<MistakeBankScreen> {
  static const AcademyProgressStore _progressStore = AcademyProgressStore();
  late final List<MistakeBankItem> _allItems;
  List<MistakeBankItem> _items = <MistakeBankItem>[];
  Map<String, MistakeReview> _reviews = {};
  bool _savingReview = false;
  bool _hadMistake = false;
  bool _loadingReviews = true;
  int _index = 0;
  String? _currentFen;
  String? _selectedSquare;
  String? _wrongTarget;
  int _lineIndex = 0;
  int _hintLevel = 0;
  bool _completed = false;
  String _language = AppLanguageController.resolveCode(
    AppLanguageController.systemCode,
  );

  String t(String key, [Map<String, String> values = const {}]) =>
      analysisDashboardText(key, _language, values);

  @override
  void initState() {
    super.initState();
    _allItems = MistakeBank.all(LocalGameArchive.games);
    _items = _allItems.take(5).toList(growable: false);
    if (_items.isNotEmpty) _currentFen = _items.first.review.fenBefore;
    AppLanguageController.effectiveLanguageChanges.addListener(_onLanguage);
    AppLanguageController.effectiveCode().then((String code) {
      if (mounted) setState(() => _language = code);
    });
    _loadSolved();
  }

  Future<void> _loadSolved() async {
    try {
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

  @override
  void dispose() {
    AppLanguageController.effectiveLanguageChanges.removeListener(_onLanguage);
    super.dispose();
  }

  List<String> get _challengeLine {
    final MistakeBankItem item = _items[_index];
    final List<String> pv = item.review.principalVariation
        .where(
          (move) =>
              RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$')
                  .hasMatch(move.trim().toLowerCase()),
        )
        .map((move) => move.trim().toLowerCase())
        .take(5)
        .toList();
    final String best = item.review.bestMove.trim().toLowerCase();
    if (pv.isEmpty || pv.first != best) pv.insert(0, best);
    return pv.take(5).toList();
  }

  Future<void> _playSquare(String square) async {
    if (_completed ||
        _savingReview ||
        _loadingReviews ||
        _lineIndex >= _challengeLine.length) {
      return;
    }
    if (_selectedSquare == null) {
      setState(() {
        _selectedSquare = square;
        _wrongTarget = null;
      });
      return;
    }
    final String attempted = '$_selectedSquare$square'.toLowerCase();
    final String expected = _challengeLine[_lineIndex];
    if (!expected.startsWith(attempted)) {
      setState(() {
        _wrongTarget = square;
        _selectedSquare = null;
      });
      if (!_hadMistake) {
        _hadMistake = true;
        await _saveReview(false);
      }
      return;
    }
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
    });
    if (_lineIndex < _challengeLine.length) {
      final String reply = _challengeLine[_lineIndex];
      final List<String> replyPositions = replayUciLine(_currentFen!, <String>[
        reply,
      ]);
      if (replyPositions.length > 1) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!mounted) return;
        setState(() {
          _currentFen = replyPositions.last;
          _lineIndex++;
        });
      }
    }
    if (_lineIndex >= _challengeLine.length) await _completeChallenge();
  }

  Future<void> _completeChallenge() async {
    await _saveReview(true);
    if (mounted) setState(() => _completed = true);
  }

  Future<void> _saveReview(bool correct) async {
    _savingReview = true;
    final id = _items[_index].id;
    try {
      _reviews[id] = await _progressStore.recordMistakeReview(id, correct);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review progress could not be saved. Please retry.'),
          ),
        );
      }
    } finally {
      _savingReview = false;
    }
    unawaited(syncAcademyMistakeBank());
  }

  void _retry() => setState(() {
    _currentFen = _items[_index].review.fenBefore;
    _selectedSquare = null;
    _wrongTarget = null;
    _lineIndex = 0;
    _hintLevel = 0;
    _completed = false;
    _hadMistake = false;
  });

  void _next() {
    if (_savingReview) return;
    if (_index >= _items.length - 1) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _index++;
      _currentFen = _items[_index].review.fenBefore;
      _selectedSquare = null;
      _wrongTarget = null;
      _lineIndex = 0;
      _hintLevel = 0;
      _completed = false;
      _hadMistake = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingReviews) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_items.isEmpty) {
      return DesktopNavigationShell(
        selected: 'Learn',
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Mistake Bank'),
            actions: <Widget>[_coinBadge(), const SizedBox(width: 8)],
          ),
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
                      _allItems.isEmpty ? t('historyEmpty') : 'All reviews are up to date. Come back when your next review is due.',
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
    final MistakePatternInsight insight = MistakeBank.insightFor(
      _allItems,
      item,
    );
    final String expected =
        _challengeLine[_lineIndex.clamp(0, _challengeLine.length - 1)];
    return DesktopNavigationShell(
      selected: 'Learn',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: const Color(0xFF071827),
          title: const Text('Mistake Bank'),
          actions: <Widget>[_coinBadge(), const SizedBox(width: 8)],
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
                          const Text(
                            'Spaced review · 1, 3, 7, 14 and 30 days. A mistake brings the next review back to tomorrow.',
                          ),
                          if (_completed && _reviews[item.id] != null)
                            Text(
                              'Next review: ${_reviews[item.id]!.nextReview.toLocal().toString().split(' ').first}',
                            ),
                          _MistakeProgress(
                            current: _index + 1,
                            total: _items.length,
                            solved: _reviews.values
                                .where((r) => r.successes > 0)
                                .length,
                          ),
                          const SizedBox(height: 16),
                          _MistakeBoard(
                            fen: _currentFen ?? item.review.fenBefore,
                            selectedSquare: _selectedSquare,
                            wrongTarget: _wrongTarget,
                            hintFrom: _hintLevel >= 1
                                ? expected.substring(0, 2)
                                : null,
                            hintTo: _hintLevel >= 2
                                ? expected.substring(2, 4)
                                : null,
                            onSquare: _playSquare,
                          ),
                          const SizedBox(height: 16),
                          ChessVerseCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  '${item.game.summary} · ${t('gameLabel', <String, String>{'count': '${_index + 1}'})}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Personal Game Challenge',
                                  style: TextStyle(
                                    color: Color(0xFF59E4C8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${item.review.classification} · ${item.review.centipawnLoss} cp',
                                  style: const TextStyle(
                                    color: AppColors.accentGold,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _MistakeIntelligenceCard(insight: insight),
                                const SizedBox(height: 16),
                                Text(
                                  _completed
                                      ? '${CoachLocalizations(_language).text('bestFound')} · ${item.review.centipawnLoss} cp'
                                      : CoachLocalizations(_language).text(
                                          'findContinuation',
                                          <String, String>{
                                            'side':
                                                item.review.fenBefore.split(
                                                      ' ',
                                                    )[1] ==
                                                    'w'
                                                ? CoachLocalizations(_language)
                                                      .text('white')
                                                : CoachLocalizations(_language)
                                                      .text('black'),
                                          },
                                        ),
                                  style: const TextStyle(height: 1.4),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _retry,
                                        icon: const Icon(Icons.replay_rounded),
                                        label: Text(
                                          CoachLocalizations(_language)
                                              .text('retry'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _completed
                                            ? null
                                            : () => setState(
                                                () => _hintLevel =
                                                    (_hintLevel + 1).clamp(
                                                      0,
                                                      2,
                                                    ),
                                              ),
                                        icon: const Icon(
                                          Icons.lightbulb_outline_rounded,
                                        ),
                                        label: Text('Hint ${_hintLevel + 1}/3'),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_completed) ...<Widget>[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF63D2B8)
                                          .withValues(alpha: .11),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0xFF63D2B8),
                                      ),
                                    ),
                                    child: Text(
                                      localizeReviewNarrative(
                                        item.review.explanation,
                                        _language,
                                      ),
                                      style: const TextStyle(height: 1.45),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  FilledButton.icon(
                                    key: const ValueKey<String>('mistake-next'),
                                    onPressed: _next,
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                    ),
                                    label: const Text('Next Challenge'),
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
        ),
      ),
    );
  }

  Widget _coinBadge() => ValueListenableBuilder<int?>(
    valueListenable: DesktopNavigationBridge.coinBalance,
    builder: (BuildContext context, int? coins, Widget? child) =>
        CoinBalanceBadge(balance: coins ?? 0, compact: true),
  );
}

class _MistakeIntelligenceCard extends StatelessWidget {
  const _MistakeIntelligenceCard({required this.insight});

  final MistakePatternInsight insight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF59E4C8).withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF59E4C8).withValues(alpha: .55)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'ChessVerseAI understands your chess.',
          style: TextStyle(
            color: Color(0xFF59E4C8),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          insight.similarPreviousGames == 0
              ? 'This is a new pattern in your reviewed games.'
              : 'You made this type of mistake in ${insight.similarPreviousGames} previous ${insight.similarPreviousGames == 1 ? 'game' : 'games'} (${insight.similarOccurrences} reviewed positions).',
        ),
        const SizedBox(height: 8),
        Text(
          'Biggest weakness: ${insight.biggestWeakness} · ${insight.biggestWeaknessOccurrences} occurrences',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          'Personalized training: ${insight.trainingTitle}',
          style: const TextStyle(
            color: AppColors.accentGold,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          insight.trainingReason,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
        ),
      ],
    ),
  );
}

class _MistakeProgress extends StatelessWidget {
  const _MistakeProgress({
    required this.current,
    required this.total,
    required this.solved,
  });
  final int current;
  final int total;
  final int solved;

  @override
  Widget build(BuildContext context) => ChessVerseCard(
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
          '$current/$total · ✓$solved',
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
  });
  final String fen;
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
  Widget build(BuildContext context) {
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
                final int row = index ~/ 8;
                final int col = index % 8;
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
                    child: Center(child: _piece(board['$row-$col'])),
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
        'assets/pieces/premium_individual/mobile-readable/$colour/$name.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: '${white ? 'White' : 'Black'} $name',
      ),
    );
  }
}
