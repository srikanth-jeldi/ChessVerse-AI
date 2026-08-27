import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../domain/ai_review_report.dart';
import '../domain/personal_ai_coach.dart';

Future<void> showAdaptiveAiReview(
  BuildContext context, {
  required AiReviewReport report,
  ValueChanged<AiMoveInsight>? onRetryPosition,
  VoidCallback? onGeneratePuzzles,
}) {
  final Size viewport = MediaQuery.sizeOf(context);
  if (viewport.width >= 900 && viewport.height >= 620) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(28),
        backgroundColor: const Color(0xFF061722),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 760),
          child: _AiReviewWorkspace(
            report: report,
            desktop: true,
            onRetryPosition: onRetryPosition,
            onGeneratePuzzles: onGeneratePuzzles,
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF061722),
    builder: (BuildContext context) => FractionallySizedBox(
      heightFactor: .94,
      child: _AiReviewWorkspace(
        report: report,
        desktop: false,
        onRetryPosition: onRetryPosition,
        onGeneratePuzzles: onGeneratePuzzles,
      ),
    ),
  );
}

class _AiReviewWorkspace extends StatelessWidget {
  const _AiReviewWorkspace({
    required this.report,
    required this.desktop,
    this.onRetryPosition,
    this.onGeneratePuzzles,
  });

  final AiReviewReport report;
  final bool desktop;
  final ValueChanged<AiMoveInsight>? onRetryPosition;
  final VoidCallback? onGeneratePuzzles;

  @override
  Widget build(BuildContext context) {
    final Widget overview = _ReviewOverview(report: report);
    final Widget timeline = _MoveTimeline(
      report: report,
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
          ? 'No reviewed mistakes to train'
          : 'Resume all $puzzleCount mistake ${puzzleCount == 1 ? 'position' : 'positions'}'),
    );
    return Padding(
      padding: EdgeInsets.all(desktop ? 24 : 16),
      child: Column(children: <Widget>[
        Row(children: <Widget>[
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF59E4C8)),
          const SizedBox(width: 9),
          const Expanded(
            child: Text('AI GAME REVIEW',
                style: TextStyle(
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
  const _ReviewOverview({required this.report});
  final AiReviewReport report;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> counts = <String, int>{};
    for (final AiMoveInsight insight in report.insights) {
      counts[insight.label] = (counts[insight.label] ?? 0) + 1;
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
                  Text(report.headline,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(report.summary,
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
          label: 'OPENING',
          body: report.openingName,
          color: const Color(0xFF50B8FF),
        ),
        if (report.insights
                .where((AiMoveInsight item) => item.evaluationAfterCp != null)
                .length >=
            2) ...<Widget>[
          const SizedBox(height: 12),
          _EvaluationGraph(report: report),
        ],
        const SizedBox(height: 12),
        ChessVerseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('MOVE QUALITY',
                  style: TextStyle(
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
                    'Inaccuracy',
                    'Mistake',
                    'Blunder',
                  ])
                    _QualityCount(
                      label: label,
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
          label: 'YOUR STRENGTH',
          body: report.strength,
          color: const Color(0xFF59E4C8),
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.route_rounded,
          label: 'TURNING POINT',
          body: report.turningPoint,
          color: AppColors.accentGold,
        ),
        if (report.importantMistakes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _InsightCard(
            icon: Icons.priority_high_rounded,
            label: '3 IMPORTANT MOMENTS',
            body: report.importantMistakes
                .asMap()
                .entries
                .map((MapEntry<int, String> item) =>
                    '${item.key + 1}. ${item.value}')
                .join('\n\n'),
            color: AppColors.accentGold,
          ),
        ],
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.psychology_alt_rounded,
          label: 'NEXT TRAINING FOCUS',
          body:
              '${report.trainingFocus}\n\nRecommended: ${report.recommendedLesson}',
          color: const Color(0xFF59E4C8),
        ),
        const SizedBox(height: 12),
        ChessVerseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('PERSONAL TRAINING PLAN',
                  style: TextStyle(
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
                    '${index + 1}. ${report.trainingRecommendations[index]}',
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

class _EvaluationGraph extends StatelessWidget {
  const _EvaluationGraph({required this.report});

  final AiReviewReport report;

  @override
  Widget build(BuildContext context) {
    final List<int> values = report.insights
        .where((AiMoveInsight item) => item.evaluationAfterCp != null)
        .map((AiMoveInsight item) => item.evaluationAfterCp!.clamp(-1000, 1000))
        .toList(growable: false);
    return ChessVerseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(children: <Widget>[
            Icon(Icons.show_chart_rounded, color: Color(0xFF59E4C8), size: 18),
            SizedBox(width: 8),
            Text('EVALUATION GRAPH',
                style: TextStyle(
                  color: Color(0xFF59E4C8),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                )),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            height: 112,
            width: double.infinity,
            child: CustomPaint(painter: _EvaluationGraphPainter(values)),
          ),
          const SizedBox(height: 6),
          const Text('Stockfish score after each reviewed player move',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EvaluationGraphPainter extends CustomPainter {
  const _EvaluationGraphPainter(this.values);
  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint grid = Paint()
      ..color = const Color(0xFF38505F)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), grid);
    if (values.length < 2) return;
    final Path path = Path();
    for (int index = 0; index < values.length; index++) {
      final double x = size.width * index / (values.length - 1);
      final double normalized = (values[index] / 1000).clamp(-1, 1);
      final double y = size.height / 2 - normalized * (size.height * .44);
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
  }

  @override
  bool shouldRepaint(covariant _EvaluationGraphPainter oldDelegate) =>
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
      'Inaccuracy' => const Color(0xFFFFC857),
      'Mistake' => const Color(0xFFFF8A4C),
      'Blunder' => const Color(0xFFFF5263),
      'Tactical' => AppColors.accentGold,
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
  const _MoveTimeline({required this.report, this.onRetryPosition});
  final AiReviewReport report;
  final ValueChanged<AiMoveInsight>? onRetryPosition;

  @override
  Widget build(BuildContext context) {
    if (report.insights.isEmpty) {
      return const Center(
          child: Text('Complete a game to unlock move review.'));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('MOVE-BY-MOVE COACHING',
              style: TextStyle(
                color: AppColors.accentGold,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              )),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: report.insights.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                                    '${insight.side} • ${insight.notation}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900)),
                              ),
                              Text(insight.label,
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11)),
                            ]),
                            const SizedBox(height: 4),
                            Text('${insight.phase}: ${insight.explanation}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.35)),
                            if (insight.centipawnLoss != null) ...<Widget>[
                              const SizedBox(height: 7),
                              Text(
                                insight.centipawnLoss == 0
                                    ? 'Engine: no evaluation lost'
                                    : 'Engine loss: ${insight.centipawnLoss} centipawns'
                                        '${insight.bestMove?.isNotEmpty == true ? ' • Best: ${insight.bestMove}' : ''}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                            if (insight.hasEngineEvidence) ...<Widget>[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  _ReviewAction(
                                    icon: Icons.psychology_alt_rounded,
                                    label: 'Ask AI Coach',
                                    onTap: () =>
                                        _showInteractiveCoach(context, insight),
                                  ),
                                  _ReviewAction(
                                    icon: Icons.warning_amber_rounded,
                                    label: 'Show threat',
                                    onTap: () => _showReviewDetail(
                                      context,
                                      'Opponent threat',
                                      insight.opponentThreat?.isNotEmpty == true
                                          ? 'Immediate opponent reply: ${insight.opponentThreat}.\n\nBest alternative: ${insight.bestMove ?? '—'}.\n\n${_variationText(insight)}'
                                          : 'No forcing opponent threat was returned for this position.',
                                    ),
                                  ),
                                  _ReviewAction(
                                    icon: Icons.replay_circle_filled_rounded,
                                    label: 'Retry position',
                                    onTap: onRetryPosition == null
                                        ? null
                                        : () => onRetryPosition!(insight),
                                  ),
                                ],
                              ),
                            ],
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

String _variationText(AiMoveInsight insight) => insight
        .principalVariation.isEmpty
    ? 'No additional principal variation was returned.'
    : 'Engine continuation: ${insight.principalVariation.take(6).join(' → ')}';

Future<void> _showInteractiveCoach(
  BuildContext context,
  AiMoveInsight insight,
) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => _InteractiveCoachDialog(insight),
  );
}

class _InteractiveCoachDialog extends StatefulWidget {
  const _InteractiveCoachDialog(this.insight);
  final AiMoveInsight insight;

  @override
  State<_InteractiveCoachDialog> createState() =>
      _InteractiveCoachDialogState();
}

class _InteractiveCoachDialogState extends State<_InteractiveCoachDialog> {
  CoachQuestion _question = CoachQuestion.whyBad;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Row(children: <Widget>[
          Icon(Icons.auto_awesome_rounded, color: Color(0xFF59E4C8)),
          SizedBox(width: 9),
          Text('Personal AI Coach'),
        ]),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  PersonalAiCoach.answer(widget.insight, _question),
                  style: const TextStyle(height: 1.45),
                ),
                const SizedBox(height: 18),
                const Text('ASK A FOLLOW-UP',
                    style: TextStyle(
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
                        label: Text(PersonalAiCoach.label(question)),
                        selected: _question == question,
                        onSelected: (_) => setState(() => _question = question),
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
            child: const Text('Back to review'),
          ),
        ],
      );
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
  String message,
) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
