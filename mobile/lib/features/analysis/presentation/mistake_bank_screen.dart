import 'package:flutter/material.dart';

import '../../../core/analysis_dashboard_localizations.dart';
import '../../../core/app_language.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/review_narrative_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../tutorial/data/academy_progress_store.dart';
import '../domain/mistake_bank.dart';

class MistakeBankScreen extends StatefulWidget {
  const MistakeBankScreen({super.key});

  @override
  State<MistakeBankScreen> createState() => _MistakeBankScreenState();
}

class _MistakeBankScreenState extends State<MistakeBankScreen> {
  static const AcademyProgressStore _progressStore = AcademyProgressStore();
  late final List<MistakeBankItem> _items;
  Set<String> _solved = <String>{};
  int _index = 0;
  String? _choice;
  String _language = AppLanguageController.resolveCode(
    AppLanguageController.systemCode,
  );

  String t(String key, [Map<String, String> values = const {}]) =>
      analysisDashboardText(key, _language, values);

  @override
  void initState() {
    super.initState();
    _items = MistakeBank.weekly(LocalGameArchive.games);
    AppLanguageController.effectiveLanguageChanges.addListener(_onLanguage);
    AppLanguageController.effectiveCode().then((String code) {
      if (mounted) setState(() => _language = code);
    });
    _loadSolved();
  }

  Future<void> _loadSolved() async {
    try {
      final Set<String> value = await _progressStore.readSolvedMistakes();
      if (mounted) setState(() => _solved = value);
    } on Object {
      // Practice remains available if secure storage is unavailable.
    }
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

  Future<void> _choose(String move) async {
    if (_choice != null) return;
    setState(() => _choice = move);
    final MistakeBankItem item = _items[_index];
    if (move == item.review.bestMove) {
      try {
        _solved = await _progressStore.markMistakeSolved(item.id);
        if (mounted) setState(() {});
      } on Object {
        if (mounted) setState(() => _solved.add(item.id));
      }
    }
  }

  void _next() {
    if (_index >= _items.length - 1) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _index++;
      _choice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(t('mistakeReplay'))),
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
                  Text(t('historyEmpty'), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final MistakeBankItem item = _items[_index];
    final bool answered = _choice != null;
    final bool correct = _choice == item.review.bestMove;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        title: Text(t('mistakeReplay')),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _MistakeProgress(
                        current: _index + 1,
                        total: _items.length,
                        solved: _solved.length,
                      ),
                      const SizedBox(height: 16),
                      _MistakeBoard(fen: item.review.fenBefore),
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
                            Text(
                              '${item.review.classification} · ${item.review.centipawnLoss} cp',
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final String move in item.choices)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: OutlinedButton.icon(
                                  key: ValueKey<String>('mistake-choice-$move'),
                                  onPressed: answered
                                      ? null
                                      : () => _choose(move),
                                  icon: Icon(
                                    answered && move == item.review.bestMove
                                        ? Icons.check_circle_rounded
                                        : Icons.route_rounded,
                                  ),
                                  label: Text(move),
                                ),
                              ),
                            if (answered) ...<Widget>[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      (correct
                                              ? const Color(0xFF63D2B8)
                                              : const Color(0xFFFF8A72))
                                          .withValues(alpha: .11),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: correct
                                        ? const Color(0xFF63D2B8)
                                        : const Color(0xFFFF8A72),
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
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: Text(t('recommended')),
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
  const _MistakeBoard({required this.fen});
  final String fen;

  static const Map<String, String> symbols = <String, String>{
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
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 64,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (BuildContext context, int index) {
                final int row = index ~/ 8;
                final int col = index % 8;
                return ColoredBox(
                  color: (row + col).isEven
                      ? const Color(0xFFD8C5A7)
                      : const Color(0xFF6D4A32),
                  child: Center(
                    child: FittedBox(
                      child: Text(
                        symbols[board['$row-$col']] ?? '',
                        style: const TextStyle(fontSize: 46, height: 1),
                      ),
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
}
