import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/app_language.dart';
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
import '../domain/ai_review_report.dart';
import '../domain/personal_ai_coach.dart';

class _ReactiveReviewLanguage extends StatelessWidget {
  const _ReactiveReviewLanguage(
      {required this.languageCode, required this.child});
  final String languageCode;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
        valueListenable: AppLanguageController.effectiveLanguageChanges,
        builder: (context, selected, _) => _ReviewLanguageScope(
            languageCode: selected ?? languageCode, child: child),
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
      code);
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

class _AiReviewWorkspace extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final String languageCode = _ReviewLanguageScope.of(context);
    final Widget overview = _ReviewOverview(
      report: report,
      onRetryPosition: onRetryPosition,
    );
    final Widget timeline = _MoveTimeline(
      report: report,
      openingEco: openingEco,
      timeControl: timeControl,
      onRetryPosition: onRetryPosition,
    );
    final int puzzleCount = report.insights
        .where((AiMoveInsight item) =>
            item.hasEngineEvidence &&
            const <String>{'Inaccuracy', 'Mistake', 'Blunder'}
                .contains(item.label))
        .length;
    final Widget puzzleAction = FilledButton.icon(
      onPressed: puzzleCount == 0 ? null : onGeneratePuzzles,
      icon: const Icon(Icons.extension_rounded),
      label: Text(puzzleCount == 0
          ? _reviewText('noMistakes', languageCode)
          : '${_reviewText('resumeMistakes', languageCode)} ($puzzleCount)'),
    );
    return Padding(
      padding: EdgeInsets.all(desktop ? 24 : 16),
      child: Column(children: <Widget>[
        Row(children: <Widget>[
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF59E4C8)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(_reviewText('title', languageCode),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                )),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ]),
        const Divider(),
        const SizedBox(height: 8),
        Expanded(
          child: desktop
              ? Row(children: <Widget>[
                  SizedBox(
                      width: 390,
                      child: SingleChildScrollView(
                        child: Column(children: <Widget>[
                          overview,
                          const SizedBox(height: 12),
                          SizedBox(width: double.infinity, child: puzzleAction),
                        ]),
                      )),
                  const SizedBox(width: 22),
                  Expanded(child: timeline),
                ])
              : ListView(children: <Widget>[
                  overview,
                  if (puzzleCount > 0) ...<Widget>[
                    const SizedBox(height: 12),
                    puzzleAction,
                  ],
                  const SizedBox(height: 18),
                  SizedBox(height: 430, child: timeline),
                ]),
        ),
      ]),
    );
  }
}

class _ReviewOverview extends StatelessWidget {
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
          child: Row(children: <Widget>[
            SizedBox(
              width: 82,
              height: 82,
              child: Stack(alignment: Alignment.center, children: <Widget>[
                CircularProgressIndicator(
                  value: report.accuracy / 100,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFF263A46),
                  color: const Color(0xFF59E4C8),
                ),
                Text('${report.accuracy}%',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(_localizedReviewHeadline(report.headline, languageCode),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(_localizedReviewSummary(report.summary, languageCode),
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.35)),
                ],
              ),
            ),
          ]),
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
          _EvaluationGraph(
            report: report,
            onRetryPosition: onRetryPosition,
          ),
        ],
        const SizedBox(height: 12),
        ChessVerseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(_reviewText('moveQuality', languageCode),
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                  )),
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
                .map((MapEntry<int, String> item) =>
                    '${item.key + 1}. ${_localizedReviewNarrative(item.value, languageCode)}')
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
              Text(_reviewText('trainingPlan', languageCode),
                  style: const TextStyle(
                    color: Color(0xFF59E4C8),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                  )),
              const SizedBox(height: 9),
              for (int index = 0;
                  index < report.trainingRecommendations.length;
                  index++)
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
    final int selected =
        (_selectedIndex ?? values.length - 1).clamp(0, values.length - 1);
    final AiMoveInsight insight = points[selected];
    final int evaluation = values[selected];
    return ChessVerseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            const Icon(Icons.show_chart_rounded,
                color: Color(0xFF59E4C8), size: 18),
            const SizedBox(width: 8),
            Text(_reviewText('evaluationGraph', languageCode),
                style: const TextStyle(
                  color: Color(0xFF59E4C8),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                )),
          ]),
          const SizedBox(height: 10),
          Semantics(
            label: localizeReviewNarrative(
                'Interactive Stockfish evaluation graph. Swipe or tap to inspect a move.',
                languageCode),
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
          Row(children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    localizeReviewNarrative(
                        'Ply ${insight.number} • ${insight.side} ${insight.notation}',
                        languageCode),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    localizeReviewNarrative(
                        insight.mateAfter != null
                            ? 'Mate ${insight.mateAfter! > 0 ? '+' : ''}${insight.mateAfter}'
                            : '${evaluation >= 0 ? 'White' : 'Black'} advantage • ${(evaluation.abs() / 100).toStringAsFixed(2)}',
                        languageCode),
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
          ]),
          Text(_reviewText('graphHelp', languageCode),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
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
            offsets[index], 4, Paint()..color = const Color(0xFFF0B94A));
      }
    }
    final Offset selected = offsets[selectedIndex.clamp(0, offsets.length - 1)];
    canvas.drawLine(
        Offset(selected.dx, plot.top),
        Offset(selected.dx, plot.bottom),
        Paint()
          ..color = const Color(0x9959E4C8)
          ..strokeWidth = 1);
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
        child: Text('$count $label',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w900)),
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
                      Text(label,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .9,
                          )),
                      const SizedBox(height: 6),
                      Text(body, style: const TextStyle(height: 1.4)),
                    ]),
              ),
            ]),
      );
}

class _MoveTimeline extends StatelessWidget {
  const _MoveTimeline({
    required this.report,
    this.openingEco,
    this.timeControl,
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
          Text(_reviewText('moveByMove', languageCode),
              style: const TextStyle(
                color: AppColors.accentGold,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              )),
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
                  child: Row(children: <Widget>[
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: .16),
                      foregroundColor: color,
                      child: Text('${insight.number}',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(children: <Widget>[
                              Expanded(
                                child: Text(
                                    '${CoachLocalizations(languageCode).source(insight.side)} • ${insight.notation}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900)),
                              ),
                              Text(
                                  _localizedReviewQuality(
                                      insight.label, languageCode),
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11)),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                                '${_localizedReviewPhase(insight.phase, languageCode)}: ${_localizedReviewExplanation(insight.explanation, languageCode)}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.35)),
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
                                  label:
                                      _reviewText('showThreat', languageCode),
                                  onTap: () => _showReviewDetail(
                                    context,
                                    _reviewText('threatTitle', languageCode),
                                    insight.opponentThreat?.isNotEmpty == true
                                        ? '${_reviewText('immediateReply', languageCode)}: ${insight.opponentThreat}.\n\n${_reviewText('alternative', languageCode)}: ${insight.bestMove ?? '—'}.\n\n${_variationText(insight, languageCode)}'
                                        : _reviewText('noThreat', languageCode),
                                    languageCode: languageCode,
                                  ),
                                ),
                                _ReviewAction(
                                  icon: Icons.replay_circle_filled_rounded,
                                  label: _reviewText(
                                      'retryPosition', languageCode),
                                  onTap: insight.hasEngineEvidence &&
                                          insight.bestMove?.isNotEmpty ==
                                              true &&
                                          onRetryPosition != null
                                      ? () => onRetryPosition!(insight)
                                      : null,
                                ),
                              ],
                            ),
                          ]),
                    ),
                  ]),
                );
              },
            ),
          ),
        ]);
  }
}

String _variationText(AiMoveInsight insight, String languageCode) => insight
        .principalVariation.isEmpty
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
        AiMoveInsight insight, CoachQuestion question, String code) =>
    personalCoachAnswer(insight, question, code);

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

  Future<void> _ask({String? presetQuestion, String? retryQuestion}) async {
    final String question =
        (retryQuestion ?? presetQuestion ?? _controller.text).trim();
    final String? fen = widget.insight.fenBefore;
    if (question.isEmpty || fen == null || fen.isEmpty || _loading) return;
    final String? token = _token;
    if (token == null || token.isEmpty) {
      setState(() => _answer = personalCoachText('signin', _languageCode));
      return;
    }
    setState(() => _loading = true);
    final int generation = ++_requestGeneration;
    final String requestLanguage = _languageCode;
    _lastSubmittedQuestion = question;
    _lastWasFreeText = presetQuestion == null;
    try {
      final List<String> candidates = _candidatesController.text
          .split(RegExp(r'[,\s]+'))
          .map((String value) => value.trim().toLowerCase())
          .where((String value) =>
              RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$').hasMatch(value))
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
    } on AiCoachApiException {
      if (mounted && generation == _requestGeneration) {
        setState(() => _answer = personalCoachText('apiError', _languageCode));
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
    if (_token?.isNotEmpty == true) {
      await _ask(presetQuestion: PersonalAiCoach.label(question));
    }
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
              content: Text(helpful
                  ? personalCoachText('feedbackHelpfulSaved', _languageCode)
                  : personalCoachText('feedbackSaved', _languageCode))),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(personalCoachText('feedbackError', _languageCode))),
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
        title: Row(children: <Widget>[
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
                  setState(() =>
                      _answer = personalCoachText('loading', _languageCode));
                  await _ask(retryQuestion: _lastSubmittedQuestion);
                } else {
                  await _askPreset(_question);
                }
              }
            },
            icon: const Icon(Icons.translate_rounded, size: 18),
            label: Text(_languageCode == AppLanguageController.systemCode
                ? personalCoachText('autoLanguage', _languageCode)
                : AppLanguageController.byCode(_languageCode).nativeName),
          ),
        ]),
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
                            avatar:
                                const Icon(Icons.analytics_rounded, size: 16),
                            label: Text(
                                '${item.move} • ${_localizedReviewQuality(item.classification, _languageCode)} • ${item.centipawnLoss}cp'),
                          ),
                      ],
                    ),
                  ],
                  Text(
                      personalCoachText('remaining', _languageCode).replaceAll(
                          '{count}', '${_cloudAnswer!.remainingToday}'),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                  Row(children: <Widget>[
                    Text(personalCoachText('useful', _languageCode),
                        style: const TextStyle(fontSize: 12)),
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
                  ]),
                ],
                const SizedBox(height: 8),
                Text(_coachDialogText('followUp', _languageCode),
                    style: const TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: <Widget>[
                    for (final CoachQuestion question in CoachQuestion.values)
                      ChoiceChip(
                        label: Text(
                            _localizedCoachQuestion(question, _languageCode)),
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

class _CoachPositionBoard extends StatelessWidget {
  const _CoachPositionBoard(
      {required this.fen,
      required this.annotations,
      required this.languageCode});
  final String fen;
  final List<AiBoardAnnotation> annotations;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final Map<String, String> pieces = _fenPieces(fen);
    return Semantics(
      label: personalCoachText('boardSemantics', languageCode),
      child: AspectRatio(
        aspectRatio: 1,
        child:
            LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
          return Stack(children: <Widget>[
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8),
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
                    child: Text(pieces[square] ?? '',
                        style: TextStyle(fontSize: box.maxWidth / 12.5)),
                  ),
                );
              },
            ),
            Positioned.fill(
                child: CustomPaint(painter: _CoachArrowPainter(annotations))),
          ]);
        }),
      ),
    );
  }

  static Map<String, String> _fenPieces(String fen) {
    const Map<String, String> glyph = <String, String>{
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
          result['${String.fromCharCode(97 + file)}${8 - row}'] =
              glyph[token] ?? '';
          file++;
        }
      }
    }
    return result;
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
        _ => const Color(0xE659E4C8),
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
        ..lineTo(to.dx - cell * .35 * math.cos(angle - .55),
            to.dy - cell * .35 * math.sin(angle - .55))
        ..lineTo(to.dx - cell * .35 * math.cos(angle + .55),
            to.dy - cell * .35 * math.sin(angle + .55))
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
