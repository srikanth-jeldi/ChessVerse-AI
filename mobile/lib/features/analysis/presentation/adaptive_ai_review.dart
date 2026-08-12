import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../domain/ai_review_report.dart';

Future<void> showAdaptiveAiReview(
  BuildContext context, {
  required AiReviewReport report,
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
          child: _AiReviewWorkspace(report: report, desktop: true),
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
      child: _AiReviewWorkspace(report: report, desktop: false),
    ),
  );
}

class _AiReviewWorkspace extends StatelessWidget {
  const _AiReviewWorkspace({required this.report, required this.desktop});

  final AiReviewReport report;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final Widget overview = _ReviewOverview(report: report);
    final Widget timeline = _MoveTimeline(report: report);
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
                      child: SingleChildScrollView(child: overview)),
                  const SizedBox(width: 22),
                  Expanded(child: timeline),
                ])
              : ListView(children: <Widget>[
                  overview,
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
  Widget build(BuildContext context) => Column(
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
        ],
      );
}

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
  const _MoveTimeline({required this.report});
  final AiReviewReport report;

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
                final Color color = switch (insight.label) {
                  'Power move' => const Color(0xFF59E4C8),
                  'Excellent' => AppColors.info,
                  'Tactical' => AppColors.accentGold,
                  'Principled' => const Color(0xFF59E4C8),
                  _ => const Color(0xFF8EA4B7),
                };
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
