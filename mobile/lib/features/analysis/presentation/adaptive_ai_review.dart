import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/app_language.dart';
import '../../../core/analysis_dashboard_localizations.dart';
import '../../../core/coach_localizations.dart';
import '../../../core/coach_extra_localizations.dart';
import '../../../core/review_narrative_localizations.dart';
import '../../../core/review_training_localizations.dart';
import '../../../core/personal_coach_localizations.dart';
import '../../../core/live_coach_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../../core/widgets/ai_language_picker.dart';
import '../../auth/data/auth_session_store.dart';
import '../data/ai_coach_api.dart';
import '../data/engine_candidates_api.dart';
import '../domain/ai_review_report.dart';
import '../domain/personal_ai_coach.dart';
import '../domain/pgn_position_reconstructor.dart';

class _ReactiveReviewLanguage extends StatelessWidget {
  const _ReactiveReviewLanguage({
    required this.languageCode,
    required this.child,
  });
  final String languageCode;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: AppLanguageController.effectiveLanguageChanges,
    builder: (context, selected, _) => _ReviewLanguageScope(
      languageCode: selected ?? languageCode,
      child: child,
    ),
  );
}

class _ReviewLanguageScope extends InheritedWidget {
  const _ReviewLanguageScope({
    required this.languageCode,
    required super.child,
  });

  final String languageCode;

  static String of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_ReviewLanguageScope>()
          ?.languageCode ??
      'en';

  @override
  bool updateShouldNotify(_ReviewLanguageScope oldWidget) =>
      languageCode != oldWidget.languageCode;
}

String _reviewText(String key, String code) {
  final copy = CoachLocalizations(code);
  final sharedKey = key == 'resumeMistakes' ? 'trainMistakes' : key;
  if (copy.contains(sharedKey)) return copy.text(sharedKey);
  if (coachExtraKeys.contains(key)) return coachExtraText(key, code);
  throw ArgumentError.value(key, 'key', 'Missing review translation key');
}

String _localizedReviewHeadline(String value, String code) =>
    localizeReviewNarrative(value, code);

String _localizedReviewSummary(String value, String code) =>
    localizeReviewNarrative(value, code);

String _localizedOpeningName(String value, String code) =>
    localizeReviewNarrative(value, code);

String _localizedReviewPhase(String value, String code) =>
    CoachLocalizations(code).source(value);

String _localizedReviewQuality(String value, String code) =>
    localizeReviewNarrative(CoachLocalizations(code).source(value), code);

String _localizedReviewExplanation(String value, String code) =>
    localizeLiveCoach(localizeReviewNarrative(value, code), code);

String _localizedReviewNarrative(String value, String code) {
  if (supportsReviewTraining(value)) return localizeReviewTraining(value, code);
  final translated = localizeLiveCoach(
    localizeReviewNarrative(CoachLocalizations(code).source(value), code),
    code,
  );
  if (translated != value) return translated;
  // Saved game feedback can retain a notation prefix before a local coach paragraph.
  final prefixed = RegExp(r'^(\S+) — (.+)$', dotAll: true).firstMatch(value);
  if (prefixed != null) {
    return '${prefixed[1]} — ${localizeLiveCoach(prefixed[2]!, code)}';
  }
  return value;
}

Future<void> showAdaptiveAiReview(
  BuildContext context, {
  required AiReviewReport report,
  String? openingEco,
  String? timeControl,
  ValueChanged<AiMoveInsight>? onRetryPosition,
  VoidCallback? onGeneratePuzzles,
}) async {
  final String languageCode = await AppLanguageController.effectiveCode();
  if (!context.mounted) return;
  final Size viewport = MediaQuery.sizeOf(context);
  if (viewport.width >= 900 && viewport.height >= 620) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(28),
        backgroundColor: const Color(0xFF061722),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 760),
          child: _ReactiveReviewLanguage(
            languageCode: languageCode,
            child: _AiReviewWorkspace(
              report: report,
              desktop: true,
              openingEco: openingEco,
              timeControl: timeControl,
              onRetryPosition: onRetryPosition,
              onGeneratePuzzles: onGeneratePuzzles,
            ),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: const Color(0xFF061722),
    builder: (BuildContext context) => FractionallySizedBox(
      heightFactor: .94,
      child: _ReactiveReviewLanguage(
        languageCode: languageCode,
        child: _AiReviewWorkspace(
          report: report,
          desktop: false,
          openingEco: openingEco,
          timeControl: timeControl,
          onRetryPosition: onRetryPosition,
          onGeneratePuzzles: onGeneratePuzzles,
        ),
      ),
    ),
  );
}

class _AiReviewWorkspace extends StatefulWidget {
  const _AiReviewWorkspace({
    required this.report,
    required this.desktop,
    this.openingEco,
    this.timeControl,
    this.onRetryPosition,
    this.onGeneratePuzzles,
  });

  final AiReviewReport report;
  final bool desktop;
  final String? openingEco;
  final String? timeControl;
  final ValueChanged<AiMoveInsight>? onRetryPosition;
  final VoidCallback? onGeneratePuzzles;

  @override
  State<_AiReviewWorkspace> createState() => _AiReviewWorkspaceState();
}

class _AiReviewWorkspaceState extends State<_AiReviewWorkspace> {
  bool _advanced = false;

  @override
  Widget build(BuildContext context) {
    final String languageCode = _ReviewLanguageScope.of(context);
    final int puzzleCount = widget.report.insights
        .where(
          (AiMoveInsight item) =>
              item.hasEngineEvidence &&
              const <String>{
                'Inaccuracy',
                'Mistake',
                'Blunder',
              }.contains(item.label),
        )
        .length;
    return Padding(
      padding: EdgeInsets.all(widget.desktop ? 24 : 16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF59E4C8)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _reviewText('title', languageCode),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (puzzleCount > 0 && widget.onGeneratePuzzles != null)
                IconButton(
                  tooltip:
                      '${_reviewText('resumeMistakes', languageCode)} ($puzzleCount)',
                  onPressed: widget.onGeneratePuzzles,
                  icon: const Icon(Icons.extension_rounded),
                ),
              IconButton(
                key: const ValueKey<String>('review-language'),
                tooltip: 'Languages (34)',
                onPressed: () => selectAndSaveAiLanguage(context),
                icon: const Icon(Icons.translate_rounded),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const Divider(),
          Center(
            child: SegmentedButton<bool>(
              key: const ValueKey<String>('review-mode-toggle'),
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.lightbulb_outline_rounded),
                  label: Text('Simple'),
                ),
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(Icons.analytics_outlined),
                  label: Text('Advanced'),
                ),
              ],
              selected: <bool>{_advanced},
              onSelectionChanged: (Set<bool> value) =>
                  setState(() => _advanced = value.first),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.desktop
                ? _DesktopCoachWorkspace(
                    report: widget.report,
                    advanced: _advanced,
                    openingEco: widget.openingEco,
                    timeControl: widget.timeControl,
                    onRetryPosition: widget.onRetryPosition,
                  )
                : _MobileCoachWorkspace(
                    report: widget.report,
                    advanced: _advanced,
                    openingEco: widget.openingEco,
                    timeControl: widget.timeControl,
                    onRetryPosition: widget.onRetryPosition,
                  ),
          ),
        ],
      ),
    );
  }
}

class _MobileCoachWorkspace extends StatefulWidget {
  const _MobileCoachWorkspace({
    required this.report,
    required this.advanced,
    this.openingEco,
    this.timeControl,
    this.onRetryPosition,
  });

  final AiReviewReport report;
  final bool advanced;
  final String? openingEco;
  final String? timeControl;
  final ValueChanged<AiMoveInsight>? onRetryPosition;

  @override
  State<_MobileCoachWorkspace> createState() => _MobileCoachWorkspaceState();
}

class _MobileCoachWorkspaceState extends State<_MobileCoachWorkspace> {
  int _selectedIndex = 0;
  bool _showSummary = true;

  @override
  void initState() {
    super.initState();
    final int first = widget.report.insights.indexWhere(
      (AiMoveInsight insight) => insight.hasEngineEvidence,
    );
    _selectedIndex = first < 0 ? 0 : first;
  }

  @override
  Widget build(BuildContext context) {
    final String languageCode = _ReviewLanguageScope.of(context);
    if (_showSummary) {
      return _MobileReviewSummary(
        report: widget.report,
        languageCode: languageCode,
        onStartReview: widget.report.insights.isEmpty
            ? null
            : () => setState(() => _showSummary = false),
      );
    }
    final AiMoveInsight insight = widget.report.insights[_selectedIndex];
    final Color qualityColor = _qualityColor(insight.label);
    final List<AiBoardAnnotation> annotations = _reviewBoardAnnotations(
      insight,
      languageCode,
    );
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              tooltip: analysisDashboardText('latestReport', languageCode),
              onPressed: () => setState(() => _showSummary = true),
              icon: const Icon(Icons.assessment_outlined, size: 20),
            ),
            Expanded(
              child: Text(
                _coachCopy('moveReview', languageCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedIndex + 1} / ${widget.report.insights.length}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: LinearProgressIndicator(
            value: (_selectedIndex + 1) / widget.report.insights.length,
            minHeight: 5,
            backgroundColor: const Color(0xFF183249),
            color: qualityColor,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double boardSize = math.min(
                      constraints.maxWidth,
                      430,
                    );
                    return Center(
                      child: SizedBox(
                        width: boardSize,
                        height: boardSize - 24,
                        child: ChessVerseCard(
                          padding: const EdgeInsets.all(7),
                          child: insight.hasEngineEvidence
                              ? Row(
                                  children: <Widget>[
                                    _VerticalEvaluationBar(insight: insight),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: _CoachPositionBoard(
                                        fen: insight.fenBefore!,
                                        annotations: annotations,
                                        languageCode: languageCode,
                                      ),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    _coachCopy(
                                      'positionUnavailable',
                                      languageCode,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ChessVerseCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: qualityColor.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.psychology_alt_rounded,
                          color: qualityColor,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _moveHeading(insight, languageCode),
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${_classificationSymbol(insight.label)} ${_localizedReviewQuality(insight.label, languageCode)} • ${_coachTheme(insight, languageCode)}',
                              style: TextStyle(
                                color: qualityColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (widget.advanced)
                  _StructuredMoveExplanation(
                    insight: insight,
                    languageCode: languageCode,
                    color: qualityColor,
                  )
                else
                  _SimpleMoveExplanation(
                    insight: insight,
                    languageCode: languageCode,
                    color: qualityColor,
                  ),
                if (widget.advanced) ...<Widget>[
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: const Color(0xFF123E52),
                      foregroundColor: const Color(0xFF59E4C8),
                    ),
                    onPressed: () => _showInteractiveCoach(
                      context,
                      insight,
                      openingEco: widget.openingEco,
                      timeControl: widget.timeControl,
                    ),
                    icon: const Icon(Icons.forum_outlined),
                    label: Text(personalCoachText('askPosition', languageCode)),
                  ),
                ],
                const SizedBox(height: 10),
                if (widget.advanced)
                  _CandidateMovesPanel(
                    insight: insight,
                    languageCode: languageCode,
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                ),
                onPressed: _selectedIndex > 0
                    ? () => setState(() => _selectedIndex--)
                    : null,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(
                  _coachCopy('previousMove', languageCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                ),
                onPressed: _selectedIndex < widget.report.insights.length - 1
                    ? () => setState(() => _selectedIndex++)
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _coachCopy('nextMove', languageCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MobileReviewSummary extends StatelessWidget {
  const _MobileReviewSummary({
    required this.report,
    required this.languageCode,
    required this.onStartReview,
  });

  final AiReviewReport report;
  final String languageCode;
  final VoidCallback? onStartReview;

  @override
  Widget build(BuildContext context) {
    final int total = report.insights.length;
    final int engineReviewed = report.insights
        .where((AiMoveInsight item) => item.centipawnLoss != null)
        .length;
    int count(Set<String> labels) => report.insights
        .where((AiMoveInsight item) => labels.contains(item.label))
        .length;
    final int excellent = count(const <String>{
      'Best',
      'Great',
      'Excellent',
      'Power move',
    });
    final int solid = count(const <String>{
      'Good',
      'Playable',
      'Principled',
      'Tactical',
    });
    final int improve = count(const <String>{
      'Inaccuracy',
      'Mistake',
      'Blunder',
    });
    int percent(int value) => total == 0 ? 0 : (value * 100 / total).round();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ChessVerseCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Container(
                  key: const ValueKey<String>('ai-review-score-badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102C38),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF59E4C8),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${report.accuracy} / 100',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF59E4C8),
                      fontSize: 25,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _localizedReviewHeadline(report.headline, languageCode),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  engineReviewed == total && total > 0
                      ? analysisDashboardText(
                          'latestAccuracy',
                          languageCode,
                          <String, String>{'count': '${report.accuracy}'},
                        )
                      : analysisDashboardText('measurement', languageCode),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryMetric(
                  label: CoachLocalizations(languageCode).source('Great'),
                  count: excellent,
                  percent: percent(excellent),
                  color: const Color(0xFF59E4C8),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _SummaryMetric(
                  label: CoachLocalizations(languageCode).source('Good'),
                  count: solid,
                  percent: percent(solid),
                  color: const Color(0xFF73BFFF),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _SummaryMetric(
                  label: analysisDashboardText('nextFocus', languageCode),
                  count: improve,
                  percent: percent(improve),
                  color: const Color(0xFFFFA65C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SummarySection(
            icon: Icons.thumb_up_alt_outlined,
            title: analysisDashboardText('strongest', languageCode),
            body: localizeReviewNarrative(report.strength, languageCode),
            color: const Color(0xFF59E4C8),
          ),
          const SizedBox(height: 8),
          _SummarySection(
            icon: Icons.crisis_alert_rounded,
            title: _reviewText('turningPoint', languageCode),
            body: localizeReviewNarrative(report.turningPoint, languageCode),
            color: const Color(0xFFFFA65C),
          ),
          const SizedBox(height: 8),
          _SummarySection(
            icon: Icons.school_outlined,
            title: analysisDashboardText('nextFocus', languageCode),
            body: localizeReviewNarrative(report.trainingFocus, languageCode),
            color: AppColors.accentGold,
          ),
          const SizedBox(height: 8),
          _SummarySection(
            icon: Icons.checklist_rounded,
            title: analysisDashboardText('plan', languageCode),
            body: report.trainingRecommendations
                .map(
                  (String item) =>
                      '• ${localizeReviewNarrative(item, languageCode)}',
                )
                .join('\n'),
            color: const Color(0xFFB98AFF),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onStartReview,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(analysisDashboardText('openReview', languageCode)),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
  });

  final String label;
  final int count;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 11),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: color.withValues(alpha: .4)),
    ),
    child: Column(
      children: <Widget>[
        Text(
          '$percent%',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '$count $label',
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, height: 1.15),
        ),
      ],
    ),
  );
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) => ChessVerseCard(
    padding: const EdgeInsets.all(13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(height: 1.35)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DesktopCoachWorkspace extends StatefulWidget {
  const _DesktopCoachWorkspace({
    required this.report,
    required this.advanced,
    this.openingEco,
    this.timeControl,
    this.onRetryPosition,
  });

  final AiReviewReport report;
  final bool advanced;
  final String? openingEco;
  final String? timeControl;
  final ValueChanged<AiMoveInsight>? onRetryPosition;

  @override
  State<_DesktopCoachWorkspace> createState() => _DesktopCoachWorkspaceState();
}

class _DesktopCoachWorkspaceState extends State<_DesktopCoachWorkspace> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final int first = widget.report.insights.indexWhere(
      (AiMoveInsight insight) => insight.hasEngineEvidence,
    );
    _selectedIndex = first < 0 ? 0 : first;
  }

  @override
  Widget build(BuildContext context) {
    final String languageCode = _ReviewLanguageScope.of(context);
    final AiMoveInsight insight = widget.report.insights[_selectedIndex];
    final Color qualityColor = _qualityColor(insight.label);
    final List<AiBoardAnnotation> annotations = _reviewBoardAnnotations(
      insight,
      languageCode,
    );
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              _coachCopy('moveReview', languageCode),
              style: const TextStyle(
                color: AppColors.accentGold,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text('${_selectedIndex + 1} / ${widget.report.insights.length}'),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 420,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: ChessVerseCard(
                        padding: const EdgeInsets.all(10),
                        child: insight.hasEngineEvidence
                            ? Row(
                                children: <Widget>[
                                  _VerticalEvaluationBar(insight: insight),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Center(
                                      child: _CoachPositionBoard(
                                        fen: insight.fenBefore!,
                                        annotations: annotations,
                                        languageCode: languageCode,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Text(
                                  _coachCopy(
                                    'positionUnavailable',
                                    languageCode,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      flex: 3,
                      child: ChessVerseCard(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _coachCopy('moveList', languageCode),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.accentGold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: widget.report.insights.length,
                                itemBuilder: (context, index) {
                                  final AiMoveInsight item =
                                      widget.report.insights[index];
                                  final bool selected = index == _selectedIndex;
                                  return ListTile(
                                    dense: true,
                                    selected: selected,
                                    selectedTileColor: AppColors.accentGold
                                        .withValues(alpha: .12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    leading: Text('${item.number}.'),
                                    title: Text(
                                      item.notation,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${_classificationSymbol(item.label)} ${_localizedReviewQuality(item.label, languageCode)}',
                                      style: TextStyle(
                                        color: _qualityColor(item.label),
                                        fontSize: 10,
                                      ),
                                    ),
                                    onTap: () =>
                                        setState(() => _selectedIndex = index),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ChessVerseCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: qualityColor.withValues(
                              alpha: .16,
                            ),
                            foregroundColor: qualityColor,
                            child: const Icon(Icons.castle_rounded),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _moveHeading(insight, languageCode),
                                  style: const TextStyle(
                                    color: AppColors.accentGold,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${CoachLocalizations(languageCode).source(insight.side)} ${_coachCopy('toMove', languageCode)}',
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: qualityColor.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: qualityColor),
                            ),
                            child: Text(
                              '${_classificationSymbol(insight.label)} ${_localizedReviewQuality(insight.label, languageCode)}',
                              style: TextStyle(
                                color: qualityColor,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(_coachTheme(insight, languageCode)),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 4,
                              children: <Widget>[
                                TextButton.icon(
                                  onPressed: () => _showInteractiveCoach(
                                    context,
                                    insight,
                                    openingEco: widget.openingEco,
                                    timeControl: widget.timeControl,
                                  ),
                                  icon: const Icon(
                                    Icons.psychology_alt_rounded,
                                    size: 17,
                                  ),
                                  label: Text(
                                    _reviewText('explain', languageCode),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _showReviewDetail(
                                    context,
                                    _reviewText('threatTitle', languageCode),
                                    insight.opponentThreat?.isNotEmpty == true
                                        ? '${_reviewText('immediateReply', languageCode)}: ${insight.opponentThreat}.\n\n${_variationText(insight, languageCode)}'
                                        : _coachCopy(
                                            'noForcingThreat',
                                            languageCode,
                                          ),
                                    languageCode: languageCode,
                                  ),
                                  icon: const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 17,
                                  ),
                                  label: Text(
                                    _reviewText('showThreat', languageCode),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              if (widget.advanced)
                                _StructuredMoveExplanation(
                                  insight: insight,
                                  languageCode: languageCode,
                                  color: qualityColor,
                                )
                              else
                                _SimpleMoveExplanation(
                                  insight: insight,
                                  languageCode: languageCode,
                                  color: qualityColor,
                                ),
                              const SizedBox(height: 10),
                              if (widget.advanced)
                                _CandidateMovesPanel(
                                  insight: insight,
                                  languageCode: languageCode,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectedIndex > 0
                                  ? () => setState(() => _selectedIndex--)
                                  : null,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: Text(
                                _coachCopy('previousMove', languageCode),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  insight.hasEngineEvidence &&
                                      widget.onRetryPosition != null
                                  ? () => widget.onRetryPosition!(insight)
                                  : null,
                              icon: const Icon(Icons.replay_rounded),
                              label: Text(
                                _reviewText('retryPosition', languageCode),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: insight.hasEngineEvidence
                                  ? () => _showPositionEvidence(
                                      context,
                                      insight,
                                      languageCode,
                                    )
                                  : null,
                              icon: const Icon(Icons.grid_view_rounded),
                              label: Text(
                                _coachCopy('showOnBoard', languageCode),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  _selectedIndex <
                                      widget.report.insights.length - 1
                                  ? () => setState(() => _selectedIndex++)
                                  : null,
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(
                                _coachCopy('nextMove', languageCode),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Retained for the report-summary route while the focused coach workspace is
// the default review experience.
// ignore: unused_element
class _ReviewOverview extends StatelessWidget {
  // ignore: unused_element_parameter
  const _ReviewOverview({required this.report, this.onRetryPosition});
  final AiReviewReport report;
  final ValueChanged<AiMoveInsight>? onRetryPosition;

  @override
  Widget build(BuildContext context) {
    final String languageCode = _ReviewLanguageScope.of(context);
    final Map<String, int> counts = <String, int>{};
    for (final AiMoveInsight insight in report.insights) {
      final String quality = reviewQualityBucket(insight.label);
      counts[quality] = (counts[quality] ?? 0) + 1;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ChessVerseCard(
          child: Row(
            children: <Widget>[
              Container(
                key: const ValueKey<String>('ai-review-score-badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF102C38),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF59E4C8)),
                ),
                child: Text(
                  '${report.accuracy} / 100',
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF59E4C8),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _localizedReviewHeadline(report.headline, languageCode),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _localizedReviewSummary(report.summary, languageCode),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.menu_book_rounded,
          label: _reviewText('opening', languageCode),
          body: _localizedOpeningName(report.openingName, languageCode),
          color: const Color(0xFF50B8FF),
        ),
        if (report.insights
                .where((AiMoveInsight item) => item.evaluationAfterCp != null)
                .length >=
            2) ...<Widget>[
          const SizedBox(height: 12),
          _EvaluationGraph(report: report, onRetryPosition: onRetryPosition),
        ],
        const SizedBox(height: 12),
        ChessVerseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _reviewText('moveQuality', languageCode),
                style: const TextStyle(
                  color: AppColors.accentGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final String label in const <String>[
                    'Best',
                    'Great',
                    'Good',
                    'Inaccuracy',
                    'Mistake',
                    'Blunder',
                  ])
                    _QualityCount(
                      label: _localizedReviewQuality(label, languageCode),
                      count: counts[label] ?? 0,
                      color: _qualityColor(label),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.workspace_premium_rounded,
          label: _reviewText('strength', languageCode),
          body: _localizedReviewNarrative(report.strength, languageCode),
          color: const Color(0xFF59E4C8),
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.route_rounded,
          label: _reviewText('turningPoint', languageCode),
          body: _localizedReviewNarrative(report.turningPoint, languageCode),
          color: AppColors.accentGold,
        ),
        if (report.importantMistakes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _InsightCard(
            icon: Icons.priority_high_rounded,
            label: _reviewText('importantMoments', languageCode),
            body: report.importantMistakes
                .asMap()
                .entries
                .map(
                  (MapEntry<int, String> item) =>
                      '${item.key + 1}. ${_localizedReviewNarrative(item.value, languageCode)}',
                )
                .join('\n\n'),
            color: AppColors.accentGold,
          ),
        ],
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.psychology_alt_rounded,
          label: _reviewText('trainingFocus', languageCode),
          body:
              '${_localizedReviewNarrative(report.trainingFocus, languageCode)}\n\n${_reviewText('recommended', languageCode)}: ${_localizedReviewNarrative(report.recommendedLesson, languageCode)}',
          color: const Color(0xFF59E4C8),
        ),
        const SizedBox(height: 12),
        ChessVerseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _reviewText('trainingPlan', languageCode),
                style: const TextStyle(
                  color: Color(0xFF59E4C8),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                ),
              ),
              const SizedBox(height: 9),
              for (
                int index = 0;
                index < report.trainingRecommendations.length;
                index++
              )
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(
                    '${index + 1}. ${_localizedReviewNarrative(report.trainingRecommendations[index], languageCode)}',
                    style: const TextStyle(height: 1.35),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Converts both Stockfish verdicts and on-device coaching labels into the
/// same public quality scale. Without this normalization a fully populated
/// timeline made every summary counter display zero.
String reviewQualityBucket(String label) => switch (label.trim()) {
  'Best' => 'Best',
  'Great' || 'Excellent' || 'Power move' => 'Great',
  'Good' || 'Principled' || 'Tactical' || 'Playable' => 'Good',
  'Inaccuracy' => 'Inaccuracy',
  'Mistake' => 'Mistake',
  'Blunder' => 'Blunder',
  _ => 'Good',
};

class _EvaluationGraph extends StatefulWidget {
  const _EvaluationGraph({required this.report, this.onRetryPosition});

  final AiReviewReport report;
  final ValueChanged<AiMoveInsight>? onRetryPosition;

  @override
  State<_EvaluationGraph> createState() => _EvaluationGraphState();
}

class _EvaluationGraphState extends State<_EvaluationGraph> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final String languageCode = _ReviewLanguageScope.of(context);
    final List<AiMoveInsight> points = widget.report.insights
        .where((AiMoveInsight item) => item.evaluationAfterCp != null)
        .toList(growable: false);
    final List<int> values = points
        .map((AiMoveInsight item) => item.evaluationAfterCp!.clamp(-1200, 1200))
        .toList(growable: false);
    final int selected = (_selectedIndex ?? values.length - 1).clamp(
      0,
      values.length - 1,
    );
    final AiMoveInsight insight = points[selected];
    final int evaluation = values[selected];
    return ChessVerseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.show_chart_rounded,
                color: Color(0xFF59E4C8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _reviewText('evaluationGraph', languageCode),
                style: const TextStyle(
                  color: Color(0xFF59E4C8),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: localizeReviewNarrative(
              'Interactive Stockfish evaluation graph. Swipe or tap to inspect a move.',
              languageCode,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (TapDownDetails details) {
                final RenderBox box = context.findRenderObject()! as RenderBox;
                final double width = box.size.width.clamp(1, double.infinity);
                final int index =
                    ((details.localPosition.dx / width) * (values.length - 1))
                        .round()
                        .clamp(0, values.length - 1);
                setState(() => _selectedIndex = index);
                final AiMoveInsight selectedInsight = points[index];
                if (selectedInsight.hasEngineEvidence &&
                    widget.onRetryPosition != null) {
                  widget.onRetryPosition!(selectedInsight);
                }
              },
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                final RenderBox box = context.findRenderObject()! as RenderBox;
                final double width = box.size.width.clamp(1, double.infinity);
                final int index =
                    ((details.localPosition.dx / width) * (values.length - 1))
                        .round()
                        .clamp(0, values.length - 1);
                if (index != _selectedIndex) {
                  setState(() => _selectedIndex = index);
                }
              },
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(
                  painter: _EvaluationGraphPainter(values, selected),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      localizeReviewNarrative(
                        'Ply ${insight.number} • ${insight.side} ${insight.notation}',
                        languageCode,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      localizeReviewNarrative(
                        insight.mateAfter != null
                            ? 'Mate ${insight.mateAfter! > 0 ? '+' : ''}${insight.mateAfter}'
                            : '${evaluation >= 0 ? 'White' : 'Black'} advantage • ${(evaluation.abs() / 100).toStringAsFixed(2)}',
                        languageCode,
                      ),
                      style: TextStyle(
                        color: evaluation >= 0
                            ? const Color(0xFFE9EDF0)
                            : AppColors.accentGold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (insight.hasEngineEvidence && widget.onRetryPosition != null)
                TextButton.icon(
                  onPressed: () => widget.onRetryPosition!(insight),
                  icon: const Icon(Icons.replay_rounded, size: 17),
                  label: Text(_reviewText('retry', languageCode)),
                ),
            ],
          ),
          Text(
            _reviewText('graphHelp', languageCode),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationGraphPainter extends CustomPainter {
  const _EvaluationGraphPainter(this.values, this.selectedIndex);
  final List<int> values;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect plot = Rect.fromLTWH(0, 8, size.width, size.height - 18);
    canvas.drawRect(plot, Paint()..color = const Color(0x14FFFFFF));
    canvas.drawRect(
      Rect.fromLTRB(plot.left, plot.top, plot.right, plot.center.dy),
      Paint()..color = const Color(0x10FFFFFF),
    );
    canvas.drawRect(
      Rect.fromLTRB(plot.left, plot.center.dy, plot.right, plot.bottom),
      Paint()..color = const Color(0x142F89B8),
    );
    final Paint grid = Paint()
      ..color = const Color(0x664B6473)
      ..strokeWidth = 1;
    for (final double fraction in <double>[.25, .5, .75]) {
      final double y = plot.top + plot.height * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.length < 2) return;
    final Path path = Path();
    final List<Offset> offsets = <Offset>[];
    for (int index = 0; index < values.length; index++) {
      final double x = size.width * index / (values.length - 1);
      final double normalized = (values[index] / 1200).clamp(-1, 1);
      final double y = plot.center.dy - normalized * (plot.height * .46);
      offsets.add(Offset(x, y));
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF59E4C8)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    for (int index = 1; index < values.length; index++) {
      if ((values[index] - values[index - 1]).abs() >= 120) {
        canvas.drawCircle(
          offsets[index],
          4,
          Paint()..color = const Color(0xFFF0B94A),
        );
      }
    }
    final Offset selected = offsets[selectedIndex.clamp(0, offsets.length - 1)];
    canvas.drawLine(
      Offset(selected.dx, plot.top),
      Offset(selected.dx, plot.bottom),
      Paint()
        ..color = const Color(0x9959E4C8)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(selected, 7, Paint()..color = const Color(0xFF061722));
    canvas.drawCircle(selected, 5, Paint()..color = const Color(0xFF59E4C8));
  }

  @override
  bool shouldRepaint(covariant _EvaluationGraphPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      !listEquals(oldDelegate.values, values);
}

class _QualityCount extends StatelessWidget {
  const _QualityCount({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: .5)),
    ),
    child: Text(
      '$count $label',
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
    ),
  );
}

Color _qualityColor(String label) => switch (label) {
  'Best' || 'Power move' || 'Principled' => const Color(0xFF59E4C8),
  'Great' || 'Excellent' => const Color(0xFF50B8FF),
  'Good' || 'Playable' || 'Tactical' => const Color(0xFF7FD6A6),
  'Inaccuracy' => const Color(0xFFFFC857),
  'Mistake' => const Color(0xFFFF8A4C),
  'Blunder' => const Color(0xFFFF5263),
  _ => const Color(0xFF8EA4B7),
};

String _classificationSymbol(String label) => switch (label) {
  'Best' => '★',
  'Brilliant' || 'Great' || 'Excellent' || 'Power move' => '!!',
  'Good' || 'Playable' || 'Principled' || 'Tactical' => '✓',
  'Inaccuracy' => '?!',
  'Mistake' => '?',
  'Blunder' => '??',
  _ => '•',
};

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.label,
    required this.body,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) => ChessVerseCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                ),
              ),
              const SizedBox(height: 6),
              Text(body, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}

// Retained for the full timeline route; the focused workspace now navigates
// one position at a time.
// ignore: unused_element
class _MoveTimeline extends StatelessWidget {
  // ignore: unused_element_parameter
  const _MoveTimeline({
    required this.report,
    // ignore: unused_element_parameter
    this.openingEco,
    // ignore: unused_element_parameter
    this.timeControl,
    // ignore: unused_element_parameter
    this.onRetryPosition,
  });
  final AiReviewReport report;
  final String? openingEco;
  final String? timeControl;
  final ValueChanged<AiMoveInsight>? onRetryPosition;

  @override
  Widget build(BuildContext context) {
    final String languageCode = _ReviewLanguageScope.of(context);
    if (report.insights.isEmpty) {
      return Center(child: Text(_reviewText('completeGame', languageCode)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _reviewText('moveByMove', languageCode),
          style: const TextStyle(
            color: AppColors.accentGold,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: report.insights.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final AiMoveInsight insight = report.insights[index];
              final Color color = _qualityColor(insight.label);
              return ChessVerseCard(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: .16),
                      foregroundColor: color,
                      child: Text(
                        '${insight.number}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '${CoachLocalizations(languageCode).source(insight.side)} • ${insight.notation}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                _localizedReviewQuality(
                                  insight.label,
                                  languageCode,
                                ),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_localizedReviewPhase(insight.phase, languageCode)} · ${_coachTheme(insight, languageCode)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (insight.evaluationBeforeCp != null &&
                              insight.evaluationAfterCp != null) ...<Widget>[
                            const SizedBox(height: 5),
                            Text(
                              '${_coachCopy('evaluation', languageCode)}: ${_formatEvaluation(insight.evaluationBeforeCp!)} → ${_formatEvaluation(insight.evaluationAfterCp!)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (insight.centipawnLoss != null) ...<Widget>[
                            const SizedBox(height: 7),
                            Text(
                              insight.centipawnLoss == 0
                                  ? _reviewText('noEngineLoss', languageCode)
                                  : '${_reviewText('engineLoss', languageCode)}: ${insight.centipawnLoss} cp'
                                        '${insight.bestMove?.isNotEmpty == true ? ' • ${_reviewText('best', languageCode)}: ${insight.bestMove}' : ''}',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          _StructuredMoveExplanation(
                            insight: insight,
                            languageCode: languageCode,
                            color: color,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _ReviewAction(
                                icon: Icons.psychology_alt_rounded,
                                label: _reviewText('explain', languageCode),
                                onTap: () => _showInteractiveCoach(
                                  context,
                                  insight,
                                  openingEco: openingEco,
                                  timeControl: timeControl,
                                ),
                              ),
                              _ReviewAction(
                                icon: Icons.warning_amber_rounded,
                                label: _reviewText('showThreat', languageCode),
                                onTap: () => _showReviewDetail(
                                  context,
                                  _reviewText('threatTitle', languageCode),
                                  insight.opponentThreat?.isNotEmpty == true
                                      ? '${_reviewText('immediateReply', languageCode)}: ${insight.opponentThreat}.\n\n${_reviewText('alternative', languageCode)}: ${insight.bestMove ?? '—'}.\n\n${_variationText(insight, languageCode)}'
                                      : _reviewText('noThreat', languageCode),
                                  languageCode: languageCode,
                                ),
                              ),
                              if (insight.principalVariation.isNotEmpty)
                                _ReviewAction(
                                  icon: Icons.route_rounded,
                                  label: _coachCopy('bestLine', languageCode),
                                  onTap: () => _showReviewDetail(
                                    context,
                                    _coachCopy('bestLine', languageCode),
                                    insight.principalVariation
                                        .take(6)
                                        .join(' → '),
                                    languageCode: languageCode,
                                  ),
                                ),
                              _ReviewAction(
                                icon: Icons.grid_view_rounded,
                                label: CoachLocalizations(languageCode).text(
                                  'positionBefore',
                                  <String, String>{'move': insight.notation},
                                ),
                                onTap: insight.hasEngineEvidence
                                    ? () => _showPositionEvidence(
                                        context,
                                        insight,
                                        languageCode,
                                      )
                                    : null,
                              ),
                              _ReviewAction(
                                icon: Icons.replay_circle_filled_rounded,
                                label: _reviewText(
                                  'retryPosition',
                                  languageCode,
                                ),
                                onTap:
                                    insight.hasEngineEvidence &&
                                        onRetryPosition != null
                                    ? () => onRetryPosition!(insight)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CandidateMovesPanel extends StatefulWidget {
  const _CandidateMovesPanel({
    required this.insight,
    required this.languageCode,
  });

  final AiMoveInsight insight;
  final String languageCode;

  @override
  State<_CandidateMovesPanel> createState() => _CandidateMovesPanelState();
}

class _VerticalEvaluationBar extends StatelessWidget {
  const _VerticalEvaluationBar({required this.insight});

  final AiMoveInsight insight;

  @override
  Widget build(BuildContext context) {
    final int evaluation =
        insight.evaluationAfterCp ?? insight.evaluationBeforeCp ?? 0;
    final double whiteShare = (.5 + evaluation.clamp(-1000, 1000) / 2000).clamp(
      .06,
      .94,
    );
    final int? mate = insight.mateAfter ?? insight.mateBefore;
    final String label = mate == null
        ? '${evaluation >= 0 ? '+' : ''}${(evaluation / 100).toStringAsFixed(1)}'
        : '${mate < 0 ? '-' : ''}M${mate.abs()}';
    return Tooltip(
      message: 'Evaluation $label',
      child: SizedBox(
        key: const ValueKey<String>('vertical-evaluation-bar'),
        width: 28,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Expanded(
                    flex: ((1 - whiteShare) * 1000).round(),
                    child: const ColoredBox(color: Color(0xFF11151C)),
                  ),
                  Expanded(
                    flex: (whiteShare * 1000).round(),
                    child: const ColoredBox(color: Color(0xFFF3F0E8)),
                  ),
                ],
              ),
              Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    color: const Color(0xCC123E52),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinePlayerDialog extends StatefulWidget {
  const _LinePlayerDialog({
    required this.initialFen,
    required this.line,
    required this.languageCode,
  });

  final String initialFen;
  final EngineCandidateLine line;
  final String languageCode;

  @override
  State<_LinePlayerDialog> createState() => _LinePlayerDialogState();
}

class _LinePlayerDialogState extends State<_LinePlayerDialog> {
  late final List<String> _positions;
  Timer? _timer;
  int _index = 0;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _positions = replayUciLine(
      widget.initialFen,
      widget.line.principalVariation,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    if (_index >= _positions.length - 1) _index = 0;
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(milliseconds: 850), (Timer timer) {
      if (!mounted) return;
      if (_index >= _positions.length - 1) {
        timer.cancel();
        setState(() {
          _playing = false;
          _index = 0;
        });
        return;
      }
      setState(() => _index++);
    });
  }

  void _seek(int index) {
    _timer?.cancel();
    setState(() {
      _playing = false;
      _index = index.clamp(0, _positions.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Try this line'),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: _CoachPositionBoard(
              fen: _positions[_index],
              annotations: const <AiBoardAnnotation>[],
              languageCode: widget.languageCode,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _index == 0
                ? 'Original position'
                : '$_index/${_positions.length - 1}  ${_readableUci(widget.line.principalVariation[_index - 1])}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              IconButton(
                tooltip: 'Restart',
                onPressed: () => _seek(0),
                constraints: const BoxConstraints.tightFor(
                  width: 52,
                  height: 52,
                ),
                padding: const EdgeInsets.all(12),
                visualDensity: VisualDensity.standard,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
              IconButton(
                tooltip: 'Previous',
                onPressed: _index > 0 ? () => _seek(_index - 1) : null,
                constraints: const BoxConstraints.tightFor(
                  width: 52,
                  height: 52,
                ),
                padding: const EdgeInsets.all(12),
                visualDensity: VisualDensity.standard,
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              IconButton.filled(
                tooltip: _playing ? 'Pause' : 'Play',
                onPressed: _positions.length > 1 ? _togglePlay : null,
                constraints: const BoxConstraints.tightFor(
                  width: 56,
                  height: 56,
                ),
                padding: const EdgeInsets.all(14),
                visualDensity: VisualDensity.standard,
                icon: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: _index < _positions.length - 1
                    ? () => _seek(_index + 1)
                    : null,
                constraints: const BoxConstraints.tightFor(
                  width: 52,
                  height: 52,
                ),
                padding: const EdgeInsets.all(12),
                visualDensity: VisualDensity.standard,
                icon: const Icon(Icons.skip_next_rounded),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ],
  );
}

class _CandidateMovesPanelState extends State<_CandidateMovesPanel> {
  Future<List<EngineCandidateLine>>? _engineCandidates;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _CandidateMovesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.insight.fenBefore != widget.insight.fenBefore) _load();
  }

  void _load() {
    final String? fen = widget.insight.fenBefore;
    _engineCandidates = fen == null || fen.isEmpty
        ? null
        : _loadCandidates(fen);
  }

  Future<List<EngineCandidateLine>> _loadCandidates(String fen) async {
    try {
      final session = await const AuthSessionStore().read();
      if (session == null) return const <EngineCandidateLine>[];
      return await const EngineCandidatesApi().analyze(session.token, fen: fen);
    } catch (_) {
      return const <EngineCandidateLine>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_CoachCandidate> fallback = _candidateMoves(
      widget.insight,
      widget.languageCode,
    );
    final String? fen = widget.insight.fenBefore;
    if (fen != null && fen.isNotEmpty && fallback.length < 5) {
      final Set<String> seen = fallback
          .map((candidate) => _candidateIdentity(candidate.move))
          .toSet();
      for (final CoachMoveCandidate candidate in coachMoveCandidates(
        fen,
        limit: 12,
      )) {
        if (fallback.length >= 5) break;
        final String move = _readableUci(candidate.move);
        if (!seen.add(_candidateIdentity(move))) continue;
        fallback.add(
          _CoachCandidate(
            move,
            _CandidateKind.possible,
            _coachCopy('possibleMoveExplanation', widget.languageCode),
          ),
        );
      }
    }
    if (fallback.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<EngineCandidateLine>>(
      future: _engineCandidates,
      builder: (context, snapshot) {
        final List<EngineCandidateLine> verifiedLines =
            snapshot.data ?? const <EngineCandidateLine>[];
        final List<_CoachCandidate> candidates = verifiedLines.isNotEmpty
            ? _verifiedCandidateMoves(
                widget.insight,
                verifiedLines,
                widget.languageCode,
              )
            : <_CoachCandidate>[];
        final Set<String> seen = candidates
            .map((candidate) => _candidateIdentity(candidate.move))
            .toSet();
        for (final _CoachCandidate candidate in fallback) {
          if (candidates.length >= 5) break;
          if (seen.add(_candidateIdentity(candidate.move))) {
            candidates.add(candidate);
          }
        }
        return _buildCard(
          candidates,
          snapshot.connectionState == ConnectionState.waiting,
          engineVerified: verifiedLines.length >= 5,
        );
      },
    );
  }

  Widget _buildCard(
    List<_CoachCandidate> candidates,
    bool loading, {
    required bool engineVerified,
  }) {
    return ChessVerseCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.account_tree_outlined,
                color: Color(0xFF59E4C8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  engineVerified
                      ? _coachCopy('movesToCompare', widget.languageCode)
                      : _coachCopy(
                          'possibleMovesToCompare',
                          widget.languageCode,
                        ),
                  style: const TextStyle(
                    color: Color(0xFF59E4C8),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            engineVerified
                ? _coachCopy('candidateIntro', widget.languageCode)
                : _coachCopy('possibleCandidateIntro', widget.languageCode),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          if (loading) ...<Widget>[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 10),
          ],
          for (int index = 0; index < candidates.length; index++) ...<Widget>[
            _CandidateMoveTile(
              number: index + 1,
              candidate: candidates[index],
              languageCode: widget.languageCode,
              initialFen: widget.insight.fenBefore,
            ),
            if (index < candidates.length - 1) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _CandidateMoveTile extends StatelessWidget {
  const _CandidateMoveTile({
    required this.number,
    required this.candidate,
    required this.languageCode,
    required this.initialFen,
  });

  final int number;
  final _CoachCandidate candidate;
  final String languageCode;
  final String? initialFen;

  @override
  Widget build(BuildContext context) {
    final Color color = candidate.kind == _CandidateKind.best
        ? AppColors.accentGold
        : candidate.kind == _CandidateKind.played
        ? const Color(0xFF59E4C8)
        : const Color(0xFF73BFFF);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 15,
            backgroundColor: color.withValues(alpha: .18),
            child: Text(
              '$number',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 7,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      candidate.move,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _candidateLabel(candidate.kind, languageCode),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  candidate.explanation,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                if (candidate.line?.principalVariation.isNotEmpty == true &&
                    initialFen?.isNotEmpty == true) ...<Widget>[
                  const SizedBox(height: 7),
                  OutlinedButton.icon(
                    key: ValueKey<String>('try-line-$number'),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (BuildContext context) => _LinePlayerDialog(
                        initialFen: initialFen!,
                        line: candidate.line!,
                        languageCode: languageCode,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Try this line'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _CandidateKind { best, played, alternative, possible }

class _CoachCandidate {
  const _CoachCandidate(this.move, this.kind, this.explanation, {this.line});

  final String move;
  final _CandidateKind kind;
  final String explanation;
  final EngineCandidateLine? line;
}

List<_CoachCandidate> _candidateMoves(
  AiMoveInsight insight,
  String languageCode,
) {
  final List<_CoachCandidate> result = <_CoachCandidate>[];
  final Set<String> seen = <String>{};
  void add(String? move, _CandidateKind kind, String explanation) {
    final String value = (move ?? '').trim();
    if (value.isEmpty || !seen.add(value.toLowerCase())) return;
    result.add(_CoachCandidate(value, kind, explanation));
  }

  add(
    insight.bestMove,
    _CandidateKind.best,
    _engineChoiceExplanation(insight, languageCode),
  );
  add(
    insight.playedMove ?? insight.notation,
    _CandidateKind.played,
    _playedChoiceExplanation(insight, languageCode),
  );

  // Do not present locally generated legal moves as engine-ranked candidates.
  // A legal move is not necessarily a good move, and repeating generic advice
  // beside those moves made the review look authoritative while providing no
  // Stockfish evidence. The panel now compares only the engine choice and the
  // player's actual choice; the verified principal variation is explained as
  // the expected continuation of the engine choice.
  return result;
}

List<_CoachCandidate> _verifiedCandidateMoves(
  AiMoveInsight insight,
  List<EngineCandidateLine> lines,
  String languageCode,
) {
  final List<_CoachCandidate> result = <_CoachCandidate>[];
  final Set<String> seen = <String>{};
  for (int index = 0; index < lines.length && result.length < 5; index++) {
    final EngineCandidateLine line = lines[index];
    if (!seen.add(line.move.toLowerCase())) continue;
    final String evaluation = line.mateIn == null
        ? _formatEvaluation(line.evaluationCp)
        : '${line.mateIn! > 0 ? '+' : '-'}M${line.mateIn!.abs()}';
    final String reply = line.principalVariation.length > 1
        ? line.principalVariation[1]
        : _coachCopy('noForcingThreat', languageCode);
    final int gap = (lines.first.evaluationCp - line.evaluationCp).abs();
    final String consequence = index == 0
        ? _coachCopy('keepsBestResult', languageCode)
        : '${_coachCopy('costVsBest', languageCode)}: $gap cp';
    result.add(
      _CoachCandidate(
        _readableUci(line.move),
        index == 0 ? _CandidateKind.best : _CandidateKind.alternative,
        '${_coachCopy('evaluation', languageCode)}: $evaluation. '
        '${_coachCopy('expectedReply', languageCode)}: ${_readableUci(reply)}. '
        '$consequence. ${_coachCopy('bestLine', languageCode)}: '
        '${line.principalVariation.take(5).map(_readableUci).join(' → ')}.',
        line: line,
      ),
    );
  }
  final String played = (insight.playedMove ?? insight.notation).trim();
  if (played.isNotEmpty && seen.add(played.toLowerCase())) {
    result.add(
      _CoachCandidate(
        _readableUci(played),
        _CandidateKind.played,
        _playedChoiceExplanation(insight, languageCode),
      ),
    );
  }
  return result;
}

String _readableUci(String move) {
  final String value = move.trim();
  if (!RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$').hasMatch(value)) {
    return value;
  }
  final String promotion = value.length == 5
      ? '=${value[4].toUpperCase()}'
      : '';
  return '${value.substring(0, 2)} → ${value.substring(2, 4)}$promotion';
}

String _candidateIdentity(String move) =>
    move.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

String _engineChoiceExplanation(AiMoveInsight insight, String languageCode) {
  final String evaluation = insight.evaluationBeforeCp == null
      ? ''
      : ' ${_coachCopy('evaluation', languageCode)}: ${_formatEvaluation(insight.evaluationBeforeCp!)}.';
  final String line = insight.principalVariation.isEmpty
      ? ''
      : ' ${_coachCopy('bestLine', languageCode)}: ${insight.principalVariation.take(5).join(' → ')}.';
  return '${CoachLocalizations(languageCode).text('best')}.$evaluation$line';
}

String _playedChoiceExplanation(AiMoveInsight insight, String languageCode) {
  final String evaluation =
      insight.evaluationBeforeCp != null && insight.evaluationAfterCp != null
      ? '${_coachCopy('evaluation', languageCode)}: ${_formatEvaluation(insight.evaluationBeforeCp!)} → ${_formatEvaluation(insight.evaluationAfterCp!)}.'
      : insight.explanation;
  final String loss = insight.centipawnLoss == null
      ? ''
      : ' ${personalCoachText('loss', languageCode)}: ${insight.centipawnLoss} cp.';
  final String reply = insight.opponentThreat?.trim().isNotEmpty == true
      ? ' ${_reviewText('immediateReply', languageCode)}: ${insight.opponentThreat}.'
      : '';
  return '$evaluation$loss$reply';
}

String _candidateLabel(_CandidateKind kind, String languageCode) =>
    switch (kind) {
      _CandidateKind.best => _coachCopy('engineBest', languageCode),
      _CandidateKind.played => _coachCopy('yourMove', languageCode),
      _CandidateKind.alternative => _coachCopy(
        'engineAlternative',
        languageCode,
      ),
      _CandidateKind.possible => _coachCopy('possibleMove', languageCode),
    };

class _SimpleMoveExplanation extends StatelessWidget {
  const _SimpleMoveExplanation({
    required this.insight,
    required this.languageCode,
    required this.color,
  });

  final AiMoveInsight insight;
  final String languageCode;
  final Color color;

  @override
  Widget build(BuildContext context) => ChessVerseCard(
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.lightbulb_outline_rounded, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            localizeReviewNarrative(insight.explanation, languageCode),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _StructuredMoveExplanation extends StatelessWidget {
  const _StructuredMoveExplanation({
    required this.insight,
    required this.languageCode,
    required this.color,
  });

  final AiMoveInsight insight;
  final String languageCode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final String played = insight.playedMove ?? insight.notation;
    final String best = insight.bestMove?.isNotEmpty == true
        ? insight.bestMove!
        : _coachCopy('noAlternative', languageCode);
    final String threat = insight.opponentThreat?.isNotEmpty == true
        ? '${insight.opponentThreat!}. ${_coachCopy('replyReason', languageCode)}'
        : '${_readableUci(played)} — ${_coachCopy('noForcingThreat', languageCode)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x99061120),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ArrowLegend(languageCode: languageCode),
          const SizedBox(height: 10),
          _EvidenceRow(
            icon: Icons.play_circle_outline_rounded,
            label: personalCoachText('whyBad', languageCode),
            value: _simpleMoveExplanation(insight, played, languageCode),
            color: color,
          ),
          const SizedBox(height: 8),
          _EvidenceRow(
            icon: Icons.insights_rounded,
            label: personalCoachText('played', languageCode),
            value: _playedResultExplanation(insight, languageCode),
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            _coachCopy('whatChanged', languageCode),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _moveEffects(insight, languageCode)
                .map(
                  (effect) => _MoveEffectChip(
                    icon: effect.$1,
                    title: effect.$2,
                    value: effect.$3,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          _EvidenceRow(
            icon: Icons.auto_awesome_rounded,
            label: CoachLocalizations(languageCode).text('alternative'),
            value: _betterChoiceExplanation(insight, best, languageCode),
            color: const Color(0xFF59E4C8),
          ),
          const SizedBox(height: 8),
          _EvidenceRow(
            icon: Icons.shield_outlined,
            label: _coachCopy('bestReply', languageCode),
            value: threat,
            color: const Color(0xFFFFA65C),
          ),
          if (insight.principalVariation.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _EvidenceRow(
              icon: Icons.route_rounded,
              label: _coachCopy('bestContinuation', languageCode),
              value: insight.principalVariation.take(6).join(' → '),
              color: const Color(0xFF73BFFF),
            ),
          ],
          const SizedBox(height: 8),
          _EvidenceRow(
            icon: Icons.warning_amber_rounded,
            label: _coachCopy('beCareful', languageCode),
            value: _moveCaution(insight, languageCode),
            color: const Color(0xFFFFA65C),
          ),
          const SizedBox(height: 8),
          _EvidenceRow(
            icon: Icons.lightbulb_outline_rounded,
            label: _coachCopy('coachInsight', languageCode),
            value: _coachInsight(insight, languageCode),
            color: const Color(0xFFB98AFF),
          ),
          const SizedBox(height: 8),
          _EvidenceRow(
            icon: Icons.school_outlined,
            label: _coachCopy('howToImprove', languageCode),
            value: _moveImprovement(insight, languageCode),
            color: AppColors.accentGold,
          ),
        ],
      ),
    );
  }
}

class _ArrowLegend extends StatelessWidget {
  const _ArrowLegend({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 6,
    children: <Widget>[
      _item(const Color(0xE6FF5263), _coachCopy('playedArrow', languageCode)),
      _item(const Color(0xE659E4C8), _coachCopy('bestArrow', languageCode)),
      _item(
        const Color(0xE650B8FF),
        _coachCopy('alternativeArrow', languageCode),
      ),
    ],
  );

  Widget _item(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: 18,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _MoveEffectChip extends StatelessWidget {
  const _MoveEffectChip({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 132),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF102236),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0x334DA6D8)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 17, color: const Color(0xFF59E4C8)),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontSize: 10)),
            Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    ),
  );
}

String _formatEvaluation(int cp) {
  final double pawns = cp / 100;
  return '${pawns >= 0 ? '+' : ''}${pawns.toStringAsFixed(1)}';
}

String _moveHeading(AiMoveInsight insight, String languageCode) {
  final int moveNumber = (insight.number + 1) ~/ 2;
  return '${_coachCopy('move', languageCode)} $moveNumber · ${insight.notation}';
}

String _coachTheme(AiMoveInsight insight, String languageCode) {
  final String move = insight.notation;
  if (move.contains('x')) return _coachCopy('tacticalMaterial', languageCode);
  return switch ((insight.coachingTheme ?? '').toLowerCase()) {
    'king_safety' ||
    'king safety' => _coachCopy('strategicKingSafety', languageCode),
    'development' => _coachCopy('strategicDevelopment', languageCode),
    'endgame' => _coachCopy('techniqueEndgame', languageCode),
    'opening' => _coachCopy('principledOpening', languageCode),
    _ => _coachCopy('calculationDecision', languageCode),
  };
}

String _simpleMoveExplanation(
  AiMoveInsight insight,
  String played,
  String languageCode,
) {
  if (played.isEmpty) return personalCoachText('unavailable', languageCode);
  return _localizedReviewExplanation(insight.explanation, languageCode);
}

String _playedResultExplanation(AiMoveInsight insight, String languageCode) {
  final int? before = insight.evaluationBeforeCp;
  final int? after = insight.evaluationAfterCp;
  final int? loss = insight.centipawnLoss;
  if (before == null || after == null || loss == null) {
    return '${personalCoachText('unavailable', languageCode)} ${personalCoachText('calculate', languageCode)}';
  }
  return '${_coachCopy('evaluation', languageCode)}: ${_formatEvaluation(before)} → ${_formatEvaluation(after)} · ${personalCoachText('loss', languageCode)}: $loss cp.';
}

String _betterChoiceExplanation(
  AiMoveInsight insight,
  String best,
  String languageCode,
) {
  final String played = (insight.playedMove ?? insight.notation).trim();
  if (insight.bestMove?.isNotEmpty != true) return best;
  if (played.toLowerCase() == insight.bestMove!.trim().toLowerCase()) {
    return '$best — ${CoachLocalizations(languageCode).text('bestFound')}';
  }
  final String continuation = insight.principalVariation.isEmpty
      ? personalCoachText('calculate', languageCode)
      : '${CoachLocalizations(languageCode).text('continuation')}: ${insight.principalVariation.take(5).join(' → ')}.';
  return '${CoachLocalizations(languageCode).text('best')}: $best. $continuation';
}

List<(IconData, String, String)> _moveEffects(
  AiMoveInsight insight,
  String languageCode,
) {
  final String move = insight.notation;
  return <(IconData, String, String)>[
    if (move.contains('x'))
      (
        Icons.balance_rounded,
        _coachCopy('material', languageCode),
        '${_readableUci(insight.playedMove ?? insight.notation)} · ${_coachCopy('materialChanged', languageCode)}',
      ),
    (
      Icons.open_with_rounded,
      _coachCopy('activity', languageCode),
      '${_readableUci(insight.playedMove ?? insight.notation)} · ${_localizedReviewQuality(insight.label, languageCode)}',
    ),
    (
      Icons.health_and_safety_outlined,
      _coachCopy('kingSafety', languageCode),
      insight.opponentThreat?.isNotEmpty == true
          ? '${_coachCopy('checkReply', languageCode)}: ${insight.opponentThreat}'
          : _coachCopy('noImmediateDanger', languageCode),
    ),
  ];
}

String _coachInsight(AiMoveInsight insight, String languageCode) {
  final String classification = _localizedReviewQuality(
    insight.label,
    languageCode,
  );
  final String explanation = _localizedReviewExplanation(
    insight.explanation,
    languageCode,
  );
  return '$classification · ${_readableUci(insight.playedMove ?? insight.notation)} — $explanation';
}

String _moveCaution(AiMoveInsight insight, String languageCode) {
  if (insight.opponentThreat?.trim().isNotEmpty == true) {
    return '${insight.opponentThreat!.trim()} · ${personalCoachText('calculate', languageCode)}';
  }
  final String evidence = insight.centipawnLoss == null
      ? _localizedReviewExplanation(insight.explanation, languageCode)
      : '${personalCoachText('loss', languageCode)}: ${insight.centipawnLoss} cp';
  return '${_readableUci(insight.playedMove ?? insight.notation)} · $evidence';
}

String _moveImprovement(AiMoveInsight insight, String languageCode) {
  final String? best = insight.bestMove?.trim();
  if (best != null && best.isNotEmpty) {
    final String line = insight.principalVariation.isEmpty
        ? personalCoachText('calculate', languageCode)
        : '${CoachLocalizations(languageCode).text('continuation')}: ${insight.principalVariation.take(5).map(_readableUci).join(' → ')}';
    return '${CoachLocalizations(languageCode).text('best')}: ${_readableUci(best)} · $line';
  }
  return '${_coachTheme(insight, languageCode)} · ${_localizedReviewExplanation(insight.explanation, languageCode)}';
}

String _coachCopy(String key, String languageCode) {
  const english = <String, String>{
    'evaluation': 'Evaluation',
    'move': 'Move',
    'toMove': 'to move',
    'tacticalMaterial': 'Tactical · Material',
    'strategicKingSafety': 'Strategic · King safety',
    'strategicDevelopment': 'Strategic · Development',
    'techniqueEndgame': 'Technique · Endgame',
    'principledOpening': 'Principled · Opening',
    'calculationDecision': 'Calculation · Decision making',
    'whatChanged': 'What changed?',
    'bestReply': "Opponent's best reply",
    'bestContinuation': 'Best continuation',
    'bestLine': 'Best line',
    'beCareful': 'Be careful',
    'coachInsight': 'Coach insight',
    'howToImprove': 'How to improve',
    'noAlternative': 'The engine best move is marked by the green arrow.',
    'playedArrow': 'Played mistake',
    'bestArrow': 'Engine best',
    'alternativeArrow': 'Other options',
    'noForcingThreat': 'No immediate forcing reply was found. This move is about improving the position, not creating a direct threat.',
    'replyReason': 'Check whether this reply challenges the moved piece or creates counterplay.',
    'captureChecklist': 'Can the opponent recapture, give a check, launch a counterattack, or trap the capturing piece?',
    'improveRoutine': 'Before every capture, check: Checks → Captures → Threats → Recaptures. Then compare the final material.',
    'material': 'Material',
    'activity': 'Activity',
    'kingSafety': 'King safety',
    'materialChanged': 'Exchange changed',
    'pieceActivity': 'Piece repositioned',
    'noImmediateDanger': 'No forcing reply found',
    'checkReply': 'Forcing reply exists',
    'captureInsight':
        'Winning material is useful only if the capturing piece stays safe.',
    'generalInsight':
        "Before committing, ask: What is my opponent's strongest reply?",
    'moveList': 'Move list',
    'moveReview': 'Move-by-move coaching',
    'movesToCompare': '5 engine-verified choices',
    'candidateIntro': 'Compare five Stockfish-ranked plans from this exact position. Each option shows the expected reply, continuation and cost versus the best move.',
    'possibleMovesToCompare': '5 possible moves to compare',
    'possibleCandidateIntro': 'Compare these legal choices from this exact position while engine verification loads or is unavailable.',
    'possibleMoveExplanation': 'A legal candidate from this position. Compare its checks, captures, threats and the opponent reply before choosing it.',
    'possibleMove': 'POSSIBLE MOVE',
    'engineBest': 'ENGINE BEST',
    'engineAlternative': 'ENGINE ALTERNATIVE',
    'yourMove': 'YOUR MOVE',
    'expectedReply': 'Expected opponent reply',
    'keepsBestResult': 'Keeps the strongest available result',
    'costVsBest': 'Difference from the best move',
    'showOnBoard': 'Show on board',
    'previousMove': 'Previous move',
    'nextMove': 'Next move',
    'positionUnavailable': 'Board evidence is unavailable for this move.',
  };
  if (AppLanguageController.resolveCode(languageCode) == 'en') {
    return english[key] ?? key;
  }
  final coach = CoachLocalizations(languageCode);
  String dashboard(String value) => analysisDashboardText(value, languageCode);
  final localized = <String, String>{
    'evaluation': dashboard('analysis'),
    'move': reviewNarrativeText('move', languageCode, const <String, String>{
      'count': '',
    }).trim(),
    'toMove': coach
        .text('findContinuation', <String, String>{'side': ''})
        .split('·')
        .first
        .trim(),
    'tacticalMaterial':
        '${dashboard('tactics')} · ${dashboard('hangingPieces')}',
    'strategicKingSafety': '${dashboard('focus')} · ${dashboard('kingSafety')}',
    'strategicDevelopment': '${dashboard('focus')} · ${coach.text('opening')}',
    'techniqueEndgame': '${dashboard('calculation')} · ${dashboard('endgame')}',
    'principledOpening':
        '${coach.text('principled')} · ${coach.text('opening')}',
    'calculationDecision':
        '${dashboard('calculation')} · ${dashboard('focus')}',
    'whatChanged': dashboard('improved'),
    'bestReply': coach.text('immediateReply'),
    'bestContinuation': coach.text('continuation'),
    'bestLine': coach.text('continuation'),
    'beCareful': personalCoachText('opponentThreat', languageCode),
    'coachInsight': dashboard('focus'),
    'howToImprove': dashboard('nextFocus'),
    'noAlternative': coach.text('bestFound'),
    'playedArrow': personalCoachText('played', languageCode),
    'bestArrow': coach.text('best'),
    'alternativeArrow': coach.text('alternative'),
    'noForcingThreat': coachExtraText('noThreat', languageCode),
    'replyReason': personalCoachText('calculate', languageCode),
    'captureChecklist': dashboard('focusLoss'),
    'improveRoutine': dashboard('slowDetail'),
    'material': dashboard('hangingPieces'),
    'activity': dashboard('focus'),
    'kingSafety': dashboard('kingSafety'),
    'materialChanged': dashboard('improved'),
    'pieceActivity': coach.text('principledExplanation'),
    'noImmediateDanger': coachExtraText('noThreat', languageCode),
    'checkReply': coach.text('immediateReply'),
    'captureInsight': dashboard('focusLoss'),
    'generalInsight': dashboard('slowDetail'),
    'moveList': dashboard('movesReviewed'),
    'moveReview': coach.text('moveByMove'),
    'movesToCompare': personalCoachText('compare', languageCode),
    'candidateIntro': dashboard('slowDetail'),
    'possibleMovesToCompare': personalCoachText('compare', languageCode),
    'possibleCandidateIntro': personalCoachText('calculate', languageCode),
    'possibleMoveExplanation': dashboard('slowDetail'),
    'possibleMove': coach.text('playable'),
    'engineBest': coach.text('best'),
    'engineAlternative': coach.text('alternative'),
    'yourMove': personalCoachText('played', languageCode),
    'expectedReply': coach.text('immediateReply'),
    'keepsBestResult': coach.text('bestFound'),
    'costVsBest': personalCoachText('loss', languageCode),
    'showOnBoard': personalCoachText('boardSemantics', languageCode),
    'previousMove':
        '${coach.text('back')} ${reviewNarrativeText('move', languageCode, const <String, String>{'count': ''}).trim()}',
    'nextMove': coachExtraText('nextPuzzle', languageCode),
    'positionUnavailable': personalCoachText('unavailable', languageCode),
  };
  if (localized.containsKey(key)) return localized[key]!;
  return english[key] ?? key;
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
              fontSize: 12,
            ),
            children: <InlineSpan>[
              TextSpan(
                text: '$label: ',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    ],
  );
}

Future<void> _showPositionEvidence(
  BuildContext context,
  AiMoveInsight insight,
  String languageCode,
) {
  final List<AiBoardAnnotation> annotations = <AiBoardAnnotation>[
    ..._reviewBoardAnnotations(insight, languageCode),
    if ((insight.opponentThreat ?? '').length >= 4)
      AiBoardAnnotation(
        insight.opponentThreat!.substring(0, 2),
        insight.opponentThreat!.substring(2, 4),
        'threat',
        _reviewText('threatTitle', languageCode),
      ),
  ];
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        CoachLocalizations(languageCode)
            .text('positionBefore', <String, String>{'move': insight.notation}),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _CoachPositionBoard(
                fen: insight.fenBefore!,
                annotations: annotations,
                languageCode: languageCode,
              ),
              const SizedBox(height: 12),
              _StructuredMoveExplanation(
                insight: insight,
                languageCode: languageCode,
                color: _qualityColor(insight.label),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(CoachLocalizations(languageCode).text('gotIt')),
        ),
      ],
    ),
  );
}

String _variationText(AiMoveInsight insight, String languageCode) =>
    insight.principalVariation.isEmpty
    ? _reviewText('noVariation', languageCode)
    : '${_reviewText('continuation', languageCode)}: ${insight.principalVariation.take(6).join(' → ')}';

Future<void> _showInteractiveCoach(
  BuildContext context,
  AiMoveInsight insight, {
  String? openingEco,
  String? timeControl,
}) {
  final String initialLanguageCode = _ReviewLanguageScope.of(context);
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => _InteractiveCoachDialog(
      insight,
      initialLanguageCode: initialLanguageCode,
      openingEco: openingEco,
      timeControl: timeControl,
    ),
  );
}

class _InteractiveCoachDialog extends StatefulWidget {
  const _InteractiveCoachDialog(
    this.insight, {
    required this.initialLanguageCode,
    this.openingEco,
    this.timeControl,
  });
  final AiMoveInsight insight;
  final String initialLanguageCode;
  final String? openingEco;
  final String? timeControl;

  @override
  State<_InteractiveCoachDialog> createState() =>
      _InteractiveCoachDialogState();
}

String _coachDialogText(String key, String code) =>
    personalCoachText(key, code);

String _localizedCoachQuestion(CoachQuestion question, String code) =>
    questionLabel(question, code);

String _localizedPersonalCoachAnswer(
  AiMoveInsight insight,
  CoachQuestion question,
  String code,
) => personalCoachAnswer(insight, question, code);

class _InteractiveCoachDialogState extends State<_InteractiveCoachDialog> {
  CoachQuestion _question = CoachQuestion.whyBad;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _candidatesController = TextEditingController();
  bool _loading = false;
  String? _answer;
  AiCoachAnswer? _cloudAnswer;
  String? _token;
  String? _sessionId;
  late String _languageCode;
  int _requestGeneration = 0;
  String? _lastSubmittedQuestion;
  bool _lastWasFreeText = false;

  @override
  void initState() {
    super.initState();
    _languageCode = widget.initialLanguageCode;
    _answer = _localizedPersonalCoachAnswer(
      widget.insight,
      _question,
      _languageCode,
    );
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await const AuthSessionStore().read();
    if (mounted) {
      setState(() {
        _token = session?.token;
      });
    }
  }

  Future<String?> _ensureToken() async {
    final String? existing = _token;
    if (existing != null && existing.isNotEmpty) return existing;
    final session = await const AuthSessionStore().read();
    final String? loaded = session?.token;
    if (mounted && loaded != null && loaded.isNotEmpty) {
      setState(() => _token = loaded);
    }
    return loaded;
  }

  Future<void> _ask({String? presetQuestion, String? retryQuestion}) async {
    final String question =
        (retryQuestion ?? presetQuestion ?? _controller.text).trim();
    final String? fen = widget.insight.fenBefore;
    if (question.isEmpty || _loading) return;
    if (fen == null || fen.isEmpty) {
      setState(() {
        _lastSubmittedQuestion = question;
        _lastWasFreeText = presetQuestion == null;
        _answer = <String>{
          _localizedPersonalCoachAnswer(
            widget.insight,
            CoachQuestion.whyBad,
            _languageCode,
          ),
          _localizedPersonalCoachAnswer(
            widget.insight,
            CoachQuestion.opponentThreat,
            _languageCode,
          ),
          _localizedPersonalCoachAnswer(
            widget.insight,
            CoachQuestion.bestPlan,
            _languageCode,
          ),
        }.join('\n\n');
      });
      return;
    }
    final String? token = await _ensureToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() => _answer = personalCoachText('signin', _languageCode));
      return;
    }
    setState(() {
      _loading = true;
      _answer = personalCoachText('loading', _languageCode);
    });
    final int generation = ++_requestGeneration;
    final String requestLanguage = _languageCode;
    _lastSubmittedQuestion = question;
    _lastWasFreeText = presetQuestion == null;
    try {
      final List<String> candidates = _candidatesController.text
          .split(RegExp(r'[,\s]+'))
          .map((String value) => value.trim().toLowerCase())
          .where(
            (String value) =>
                RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$').hasMatch(value),
          )
          .take(3)
          .toList(growable: false);
      final AiCoachAnswer result = await const AiCoachApi().ask(
        token,
        fen: fen,
        playedMove: widget.insight.playedMove ?? widget.insight.notation,
        question: question,
        sessionId: _sessionId,
        candidateMoves: candidates,
        languageCode: requestLanguage,
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        // Never replace an actual free-text answer with an unrelated preset
        // merely because its script differs from the selected language.
        _answer = localizeCoachApiAnswer(result.answer, requestLanguage);
        _cloudAnswer = result;
        _sessionId = result.sessionId;
      });
    } on AiCoachApiException catch (error) {
      if (mounted && generation == _requestGeneration) {
        setState(() {
          // Every reviewed move already carries deterministic engine evidence.
          // Keep answering custom questions with that evidence when the coach
          // endpoint is temporarily unavailable instead of showing a dead end.
          _answer =
              _localizedPersonalCoachAnswer(
                widget.insight,
                presetQuestion == null ? CoachQuestion.whyBad : _question,
                _languageCode,
              ) +
              (presetQuestion == null
                  ? '\n\n${_localizedPersonalCoachAnswer(widget.insight, CoachQuestion.opponentThreat, _languageCode)}\n\n${_localizedPersonalCoachAnswer(widget.insight, CoachQuestion.bestPlan, _languageCode)}'
                  : '');
          _cloudAnswer = null;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _askPreset(CoachQuestion question) async {
    setState(() {
      _requestGeneration++;
      _loading = false;
      _lastWasFreeText = false;
      _question = question;
      _answer = _localizedPersonalCoachAnswer(
        widget.insight,
        question,
        _languageCode,
      );
      _cloudAnswer = null;
    });
    // Always ask the Stockfish-backed endpoint. Session restoration is
    // asynchronous on web; checking the cached token here used to leave a
    // generic local answer when a preset was tapped immediately.
    await _ask(presetQuestion: PersonalAiCoach.label(question));
  }

  Future<void> _sendFeedback(bool helpful) async {
    final AiCoachAnswer? answer = _cloudAnswer;
    final String? token = _token;
    if (answer == null || token == null) return;
    try {
      await Future.wait(<Future<void>>[
        const AiCoachApi().feedback(token, answer.interactionId, helpful),
        const AiCoachApi().recommendationOutcome(
          token,
          answer.interactionId,
          recommendationType: widget.insight.coachingTheme ?? 'calculation',
          openingEco: widget.openingEco,
          playerColor: widget.insight.side,
          timeControl: widget.timeControl,
          accepted: helpful,
        ),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              helpful
                  ? personalCoachText('feedbackHelpfulSaved', _languageCode)
                  : personalCoachText('feedbackSaved', _languageCode),
            ),
          ),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(personalCoachText('feedbackError', _languageCode)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _candidatesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: <Widget>[
        const Icon(Icons.auto_awesome_rounded, color: Color(0xFF59E4C8)),
        const SizedBox(width: 9),
        Expanded(child: Text(_coachDialogText('title', _languageCode))),
        TextButton.icon(
          key: const ValueKey<String>('coach-language'),
          onPressed: () async {
            final String? selected = await selectAndSaveAiLanguage(context);
            if (selected != null && mounted) {
              final String effective =
                  await AppLanguageController.effectiveCode();
              if (!mounted) return;
              setState(() {
                _requestGeneration++;
                _languageCode = effective;
                _loading = false;
                _cloudAnswer = null;
                _sessionId = null;
              });
              if (_lastWasFreeText && _lastSubmittedQuestion != null) {
                setState(
                  () => _answer = personalCoachText('loading', _languageCode),
                );
                await _ask(retryQuestion: _lastSubmittedQuestion);
              } else {
                await _askPreset(_question);
              }
            }
          },
          icon: const Icon(Icons.translate_rounded, size: 18),
          label: Text(
            _languageCode == AppLanguageController.systemCode
                ? personalCoachText('autoLanguage', _languageCode)
                : AppLanguageController.byCode(_languageCode).nativeName,
          ),
        ),
      ],
    ),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              _answer ?? _coachDialogText('loading', _languageCode),
              style: const TextStyle(height: 1.45),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              maxLength: 500,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _ask(),
              decoration: InputDecoration(
                labelText: _coachDialogText('askPosition', _languageCode),
                hintText: _coachDialogText('example', _languageCode),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _ask,
                        icon: const Icon(Icons.send_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _candidatesController,
              decoration: InputDecoration(
                labelText: _coachDialogText('compare', _languageCode),
                hintText: 'e2e4, d2d4, g1f3',
                prefixIcon: const Icon(Icons.compare_arrows_rounded),
              ),
            ),
            if (_cloudAnswer != null) ...<Widget>[
              const SizedBox(height: 12),
              _CoachPositionBoard(
                fen: widget.insight.fenBefore!,
                annotations: _cloudAnswer!.annotations,
                languageCode: _languageCode,
              ),
              if (_cloudAnswer!.comparisons.isNotEmpty) ...<Widget>[
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: <Widget>[
                    for (final AiCandidateComparison item
                        in _cloudAnswer!.comparisons)
                      Chip(
                        avatar: const Icon(Icons.analytics_rounded, size: 16),
                        label: Text(
                          '${item.move} • ${_localizedReviewQuality(item.classification, _languageCode)} • ${item.centipawnLoss}cp',
                        ),
                      ),
                  ],
                ),
              ],
              Text(
                personalCoachText(
                  'remaining',
                  _languageCode,
                ).replaceAll('{count}', '${_cloudAnswer!.remainingToday}'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Row(
                children: <Widget>[
                  Text(
                    personalCoachText('useful', _languageCode),
                    style: const TextStyle(fontSize: 12),
                  ),
                  IconButton(
                    tooltip: personalCoachText('helpful', _languageCode),
                    onPressed: () => _sendFeedback(true),
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: personalCoachText('notHelpful', _languageCode),
                    onPressed: () => _sendFeedback(false),
                    icon: const Icon(Icons.thumb_down_alt_outlined, size: 18),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _coachDialogText('followUp', _languageCode),
              style: const TextStyle(
                color: AppColors.accentGold,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: <Widget>[
                for (final CoachQuestion question in CoachQuestion.values)
                  ChoiceChip(
                    label: Text(
                      _localizedCoachQuestion(question, _languageCode),
                    ),
                    selected: _question == question,
                    onSelected: (_) => _askPreset(question),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: <Widget>[
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(_coachDialogText('back', _languageCode)),
      ),
    ],
  );
}

class _CoachPositionBoard extends StatefulWidget {
  const _CoachPositionBoard({
    required this.fen,
    required this.annotations,
    required this.languageCode,
  });
  final String fen;
  final List<AiBoardAnnotation> annotations;
  final String languageCode;

  @override
  State<_CoachPositionBoard> createState() => _CoachPositionBoardState();
}

class _CoachPositionBoardState extends State<_CoachPositionBoard> {
  List<AiBoardAnnotation> _candidateAnnotations = const <AiBoardAnnotation>[];

  @override
  void initState() {
    super.initState();
    _loadCandidateArrows();
  }

  @override
  void didUpdateWidget(covariant _CoachPositionBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String oldSignature = oldWidget.annotations
        .map((item) => '${item.from}${item.to}:${item.kind}')
        .join('|');
    final String newSignature = widget.annotations
        .map((item) => '${item.from}${item.to}:${item.kind}')
        .join('|');
    if (oldWidget.fen != widget.fen || oldSignature != newSignature) {
      _candidateAnnotations = const <AiBoardAnnotation>[];
      _loadCandidateArrows();
    }
  }

  Future<void> _loadCandidateArrows() async {
    final String requestedFen = widget.fen;
    try {
      final StoredAuthSession? session = await const AuthSessionStore().read();
      if (session == null) return;
      final List<EngineCandidateLine> candidates =
          await const EngineCandidatesApi().analyze(
            session.token,
            fen: requestedFen,
          );
      if (!mounted || widget.fen != requestedFen) return;
      final Set<String> primaryMoves = widget.annotations
          .map((AiBoardAnnotation item) => '${item.from}${item.to}')
          .toSet();
      final List<AiBoardAnnotation> alternatives = <AiBoardAnnotation>[];
      final bool alreadyHasBest = widget.annotations.any(
        (AiBoardAnnotation item) =>
            item.kind == 'best' || item.kind == 'played-correct',
      );
      for (int index = 0; index < candidates.length; index++) {
        final EngineCandidateLine candidate = candidates[index];
        final String move = candidate.move.trim().toLowerCase();
        if (move.length < 4) continue;
        final String moveKey = move.substring(0, 4);
        final bool isBest = index == 0 && !alreadyHasBest;
        if (!isBest && !primaryMoves.add(moveKey)) continue;
        alternatives.add(
          AiBoardAnnotation(
            move.substring(0, 2),
            move.substring(2, 4),
            isBest ? 'best' : 'candidate',
            _reviewText(isBest ? 'best' : 'alternative', widget.languageCode),
          ),
        );
        primaryMoves.add(moveKey);
        if (alternatives.length == 4) break;
      }
      setState(() => _candidateAnnotations = alternatives);
    } on Object {
      // Keep only the played and best arrows. Showing guessed alternatives
      // before Stockfish responds makes blue arrows visibly change in place.
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> pieces = _fenPieces(widget.fen);
    final List<AiBoardAnnotation> visibleAnnotations = _mergeCoachAnnotations(
      <AiBoardAnnotation>[...widget.annotations, ..._candidateAnnotations],
    );
    return Semantics(
      label: personalCoachText('boardSemantics', widget.languageCode),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            return Stack(
              children: <Widget>[
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                  ),
                  itemCount: 64,
                  itemBuilder: (BuildContext context, int index) {
                    final int rank = 7 - index ~/ 8;
                    final int file = index % 8;
                    final String square =
                        '${String.fromCharCode(97 + file)}${rank + 1}';
                    return ColoredBox(
                      color: (rank + file).isEven
                          ? const Color(0xFFBDD0D8)
                          : const Color(0xFF416A7C),
                      child: Center(
                        child: pieces[square] == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: EdgeInsets.all(box.maxWidth / 145),
                                child: Image.asset(
                                  _coachPieceAsset(pieces[square]!),
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  semanticLabel: _coachPieceLabel(
                                    pieces[square]!,
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CoachArrowPainter(visibleAnnotations),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Map<String, String> _fenPieces(String fen) {
    final Map<String, String> result = <String, String>{};
    final List<String> ranks = fen.split(' ').first.split('/');
    for (int row = 0; row < ranks.length && row < 8; row++) {
      int file = 0;
      for (final int rune in ranks[row].runes) {
        final String token = String.fromCharCode(rune);
        final int? empty = int.tryParse(token);
        if (empty != null) {
          file += empty;
        } else if (file < 8) {
          result['${String.fromCharCode(97 + file)}${8 - row}'] = token;
          file++;
        }
      }
    }
    return result;
  }

  static String _coachPieceAsset(String token) {
    const Map<String, String> names = <String, String>{
      'k': 'king',
      'q': 'queen',
      'r': 'rook',
      'b': 'bishop',
      'n': 'knight',
      'p': 'pawn',
    };
    final String colour = token == token.toUpperCase() ? 'white' : 'black';
    return 'assets/pieces/staunton_${colour}_${names[token.toLowerCase()]}.png';
  }

  static String _coachPieceLabel(String token) {
    const Map<String, String> names = <String, String>{
      'k': 'king',
      'q': 'queen',
      'r': 'rook',
      'b': 'bishop',
      'n': 'knight',
      'p': 'pawn',
    };
    final String colour = token == token.toUpperCase() ? 'White' : 'Black';
    return '$colour ${names[token.toLowerCase()]}';
  }
}

class _CoachArrowPainter extends CustomPainter {
  const _CoachArrowPainter(this.annotations);
  final List<AiBoardAnnotation> annotations;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 8;
    for (final AiBoardAnnotation annotation in annotations) {
      final Color color = switch (annotation.kind) {
        'threat' => const Color(0xE6FF5263),
        'candidate' => const Color(0xE650B8FF),
        'played-wrong' => const Color(0xE6FF5263),
        'best' || 'played-correct' => const Color(0xE659E4C8),
        _ => const Color(0xE68B7CFF),
      };
      final Offset from = _center(annotation.from, cell);
      final Offset to = _center(annotation.to, cell);
      final Paint paint = Paint()
        ..color = color
        ..strokeWidth = cell * .16
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, to, paint);
      final double angle = (to - from).direction;
      final Path head = Path()
        ..moveTo(to.dx, to.dy)
        ..lineTo(
          to.dx - cell * .35 * math.cos(angle - .55),
          to.dy - cell * .35 * math.sin(angle - .55),
        )
        ..lineTo(
          to.dx - cell * .35 * math.cos(angle + .55),
          to.dy - cell * .35 * math.sin(angle + .55),
        )
        ..close();
      canvas.drawPath(head, paint);
    }
  }

  Offset _center(String square, double cell) {
    final int file = square.codeUnitAt(0) - 97;
    final int rank = int.parse(square[1]) - 1;
    return Offset((file + .5) * cell, (7 - rank + .5) * cell);
  }

  @override
  bool shouldRepaint(covariant _CoachArrowPainter oldDelegate) =>
      !listEquals(oldDelegate.annotations, annotations);
}

List<AiBoardAnnotation> _reviewBoardAnnotations(
  AiMoveInsight insight,
  String languageCode,
) {
  final String? played = _uciMove(insight.playedMove ?? insight.notation);
  final String? best = _uciMove(insight.bestMove);
  return _mergeCoachAnnotations(<AiBoardAnnotation>[
    if (played != null)
      AiBoardAnnotation(
        played.substring(0, 2),
        played.substring(2, 4),
        played == best ? 'played-correct' : 'played-wrong',
        insight.label,
      ),
    if (best != null)
      AiBoardAnnotation(
        best.substring(0, 2),
        best.substring(2, 4),
        'best',
        _reviewText('best', languageCode),
      ),
  ]);
}

String? _uciMove(String? value) {
  if (value == null) return null;
  final RegExpMatch? match = RegExp(
    r'([a-h][1-8])\s*(?:[-x>→:]*)\s*([a-h][1-8])',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) return null;
  return '${match.group(1)}${match.group(2)}'.toLowerCase();
}

List<AiBoardAnnotation> _mergeCoachAnnotations(
  List<AiBoardAnnotation> annotations,
) {
  int priority(String kind) => switch (kind) {
    'best' || 'played-correct' => 4,
    'played-wrong' => 3,
    'threat' => 2,
    _ => 1,
  };
  final Map<String, AiBoardAnnotation> merged = <String, AiBoardAnnotation>{};
  for (final AiBoardAnnotation annotation in annotations) {
    final String key = '${annotation.from}${annotation.to}';
    final AiBoardAnnotation? existing = merged[key];
    if (existing == null ||
        priority(annotation.kind) > priority(existing.kind)) {
      merged[key] = annotation;
    }
  }
  return merged.values.toList(growable: false);
}

class _ReviewAction extends StatelessWidget {
  const _ReviewAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16),
    label: Text(label),
  );
}

Future<void> _showReviewDetail(
  BuildContext context,
  String title,
  String message, {
  required String languageCode,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_reviewText('gotIt', languageCode)),
        ),
      ],
    ),
  );
}
