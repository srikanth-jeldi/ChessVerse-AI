import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/academy_story_localizations.dart';
import '../../../core/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../data/academy_progress_store.dart';
import '../domain/academy_lesson.dart';

class AcademyBossChallengeScreen extends StatefulWidget {
  const AcademyBossChallengeScreen({
    required this.courseId,
    required this.courseTitle,
    required this.lessons,
    required this.accent,
    super.key,
  });

  final String courseId;
  final String courseTitle;
  final List<AcademyLesson> lessons;
  final Color accent;

  @override
  State<AcademyBossChallengeScreen> createState() =>
      _AcademyBossChallengeScreenState();
}

class _AcademyBossChallengeScreenState
    extends State<AcademyBossChallengeScreen> {
  static const AcademyProgressStore _store = AcademyProgressStore();
  int _round = 0;
  int _score = 0;
  String? _chosen;
  bool _finished = false;
  bool _passed = false;
  String _languageCode = AppLanguageController.resolveCode(
    AppLanguageController.systemCode,
  );
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

  AcademyLesson get _lesson => widget.lessons[_round];

  void _choose(String square) {
    if (_chosen != null) return;
    setState(() {
      _chosen = square;
      if (square == _lesson.to) _score++;
    });
  }

  Future<void> _next() async {
    if (_round < widget.lessons.length - 1) {
      setState(() {
        _round++;
        _chosen = null;
      });
      return;
    }
    final bool passed = _score >= 2;
    if (passed) await _store.awardCertificate(widget.courseId);
    if (!mounted) return;
    setState(() {
      _finished = true;
      _passed = passed;
    });
  }

  void _retry() => setState(() {
    _round = 0;
    _score = 0;
    _chosen = null;
    _finished = false;
    _passed = false;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF04111B),
    appBar: AppBar(
      backgroundColor: const Color(0xFF071827),
      title: Text(
        _copy.text(
          'boss.title',
          values: <String, String>{'course': widget.courseTitle},
        ),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _finished ? _buildResult() : _buildRound(),
          ),
        ),
      ),
    ),
  );

  Widget _buildRound() => ChessVerseCard(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.military_tech_rounded, color: widget.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _copy.text(
                      'boss.position',
                      values: <String, String>{
                        'current': '${_round + 1}',
                        'total': '${widget.lessons.length}',
                      },
                    ),
                    style: TextStyle(
                      color: widget.accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    _copy.text('boss.noHints'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              '$_score ★',
              style: const TextStyle(
                color: AppColors.accentGold,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          _lesson.storyChapter,
          style: const TextStyle(
            color: AppColors.accentGold,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _lesson.decisionQuestion,
          style: const TextStyle(
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        for (final String square in _lesson.decisionOptions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: BorderSide(color: _answerColor(square)),
              ),
              onPressed: () => _choose(square),
              icon: Icon(Icons.route_rounded, color: _answerColor(square)),
              label: Text('${_lesson.from} → $square'),
            ),
          ),
        if (_chosen != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _chosen == _lesson.to
                ? _lesson.decisionInsight
                : 'Not this time. ${_lesson.to} was the strongest candidate. Compare the immediate reply before committing.',
            style: TextStyle(
              color: _chosen == _lesson.to
                  ? const Color(0xFF59E4C8)
                  : AppColors.accentGold,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(
              _copy.text(
                _round == widget.lessons.length - 1
                    ? 'boss.result'
                    : 'boss.next',
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Color _answerColor(String square) {
    if (_chosen == null) return const Color(0x6659E4C8);
    if (square == _lesson.to) return const Color(0xFF59E4C8);
    if (square == _chosen) return const Color(0xFFE15F5F);
    return const Color(0x334E6575);
  }

  Widget _buildResult() => ChessVerseCard(
    padding: const EdgeInsets.all(28),
    child: Column(
      children: <Widget>[
        Icon(
          _passed ? Icons.workspace_premium_rounded : Icons.replay_rounded,
          size: 82,
          color: _passed ? AppColors.accentGold : AppColors.textSecondary,
        ),
        const SizedBox(height: 14),
        Text(
          _copy.text(_passed ? 'boss.certificate' : 'boss.retryTitle'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _copy.text(
            _passed ? 'boss.passedBody' : 'boss.failedBody',
            values: <String, String>{
              'course': widget.courseTitle,
              'score': '$_score/${widget.lessons.length}',
            },
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        if (_passed)
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text:
                      '${_copy.text('boss.passedBody', values: <String, String>{'course': widget.courseTitle, 'score': '$_score/${widget.lessons.length}'})} ♟️',
                ),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_copy.text('boss.copied'))),
                );
              }
            },
            icon: const Icon(Icons.ios_share_rounded),
            label: Text(_copy.text('boss.share')),
          )
        else
          FilledButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(_copy.text('boss.tryAgain')),
          ),
      ],
    ),
  );
}
