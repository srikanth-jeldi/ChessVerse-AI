import 'package:flutter/material.dart';

import '../../../core/layout/responsive_page.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../auth/data/auth_session_store.dart';
import '../data/game_analysis_api.dart';
import '../data/ai_coach_api.dart';
import '../domain/ai_review_report.dart';
import '../domain/learning_intelligence.dart';
import 'adaptive_ai_review.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late final Future<Map<String, int>> _cloudHistory = _loadCloudHistory();
  late final Future<AiCoachImpact?> _coachImpact = _loadCoachImpact();
  late final Future<AnalysisTrends?> _serverTrends = _loadServerTrends();

  Future<Map<String, int>> _loadCloudHistory() async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (session == null || session.token.isEmpty) return <String, int>{};
    try {
      return await const GameAnalysisApi().weaknessHistory(session.token);
    } on GameAnalysisApiException {
      return <String, int>{};
    }
  }

  Future<AiCoachImpact?> _loadCoachImpact() async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (session == null || session.token.isEmpty) return null;
    try {
      return await const AiCoachApi().impact(session.token);
    } on Object {
      return null;
    }
  }

  Future<AnalysisTrends?> _loadServerTrends() async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (session == null || session.token.isEmpty) return null;
    try {
      return await const GameAnalysisApi().trends(session.token);
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<SavedGameRecord> games = LocalGameArchive.games;
    final int totalMoves = games.fold<int>(
      0,
      (int total, SavedGameRecord game) => total + game.moves.length,
    );
    final int averageMoves =
        games.isEmpty ? 0 : (totalMoves / games.length).round();
    final int losses = games
        .where((SavedGameRecord game) =>
            game.result.toLowerCase().contains('loss'))
        .length;
    final SavedGameRecord? latest = games.isEmpty ? null : games.first;
    final AiReviewReport? latestReport = latest == null
        ? null
        : AiReviewReport.fromMoves(
            latest.moves,
            newestFirst: false,
            result: latest.result,
            knownReviews: latest.moveReviews,
            knownOpeningName: latest.openingName == null
                ? null
                : '${latest.openingEco ?? 'ECO'} • ${latest.openingName} • ${latest.bookPlies} book plies${latest.firstDeviationPly == null ? '' : ' • first deviation ply ${latest.firstDeviationPly}'}',
          );
    final String focus = _trainingFocus(games, averageMoves, losses);
    final LearningIntelligence intelligence = LearningIntelligence.fromGames(
      games,
      cloudScores: LocalGameArchive.cloudWeaknessScores,
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Analysis')),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ChessVerseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.analytics_rounded, size: 30),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Game Analysis',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    games.isEmpty
                        ? 'Play a game to unlock your first personalized AI training report.'
                        : 'Your AI coach reviewed ${games.length} saved game${games.length == 1 ? '' : 's'} and $totalMoves recorded moves.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('AI performance snapshot',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _AnalysisFeatureCard(
              icon: Icons.timeline_rounded,
              title: latestReport == null
                  ? '${games.length} games analyzed'
                  : '${latestReport.accuracy}% latest-game accuracy',
              subtitle: latestReport?.headline ??
                  '$averageMoves average recorded moves per game.',
            ),
            const SizedBox(height: 12),
            _AnalysisFeatureCard(
              icon: Icons.psychology_alt_rounded,
              title: 'Personalized training focus',
              subtitle: latestReport == null
                  ? focus
                  : '${latestReport.trainingFocus} Recommended: ${latestReport.recommendedLesson}.',
            ),
            const SizedBox(height: 12),
            _AnalysisFeatureCard(
              icon: Icons.warning_amber_rounded,
              title: latest == null ? 'Latest game report' : latest.result,
              subtitle: latest == null
                  ? 'Your latest result and coach recommendation will appear here.'
                  : latestReport?.turningPoint ??
                      '${latest.summary} • ${latest.detail}',
            ),
            const SizedBox(height: 18),
            Text('Weekly AI intelligence',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _WeeklyDashboard(report: intelligence.weekly),
            const SizedBox(height: 12),
            FutureBuilder<AiCoachImpact?>(
              future: _coachImpact,
              builder: (BuildContext context,
                  AsyncSnapshot<AiCoachImpact?> snapshot) {
                final AiCoachImpact? impact = snapshot.data;
                if (impact == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AnalysisFeatureCard(
                    icon: impact.enoughEvidence
                        ? Icons.verified_rounded
                        : Icons.hourglass_bottom_rounded,
                    title: impact.enoughEvidence
                        ? '${impact.improvementPercent >= 0 ? '+' : ''}${impact.improvementPercent}% measured move-quality change'
                        : 'AI impact measurement in progress',
                    subtitle:
                        '${impact.analyzedGames} analyzed games • ${impact.measuredMoves} measured moves • ${impact.helpfulPercent}% helpful feedback. ${impact.evidenceMessage}',
                  ),
                );
              },
            ),
            _ProgressTrend(points: intelligence.trend),
            const SizedBox(height: 12),
            FutureBuilder<AnalysisTrends?>(
              future: _serverTrends,
              builder: (BuildContext context,
                  AsyncSnapshot<AnalysisTrends?> snapshot) {
                final AnalysisTrends? trends = snapshot.data;
                if (trends == null) return const SizedBox.shrink();
                return Column(children: <Widget>[
                  ChessVerseCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('SERVER-VERIFIED 10 / 30 / 100 GAME TRENDS',
                            style: TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        for (final MapEntry<String, AnalysisWindowTrend> item
                            in trends.windows.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Text(
                              '${item.key.replaceFirst('last', 'Last ')} games: '
                              '${item.value.averageAccuracy}% accuracy • '
                              '${item.value.averageCentipawnLoss}cp average loss • '
                              '${item.value.blunders} blunders',
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trends.recommendationOutcomes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    _AnalysisFeatureCard(
                      icon: Icons.fact_check_rounded,
                      title:
                          'Recommendation outcomes by opening, colour and clock',
                      subtitle: trends.recommendationOutcomes
                          .take(6)
                          .map(
                            (RecommendationDimension item) =>
                                '${item.dimension} ${item.value}: ${item.successPercent}% improved (${item.resolved} measured)',
                          )
                          .join(' • '),
                    ),
                  ],
                  const SizedBox(height: 12),
                ]);
              },
            ),
            _AnalysisFeatureCard(
              icon: Icons.menu_book_rounded,
              title: 'Opening recommendation',
              subtitle: intelligence.openingRecommendation,
            ),
            const SizedBox(height: 18),
            Text('Today’s personalized plan',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ChessVerseCard(
              child: Column(
                children: <Widget>[
                  for (int index = 0;
                      index < intelligence.dailyPlan.length;
                      index++) ...<Widget>[
                    _DailyPlanRow(
                      index: index + 1,
                      item: intelligence.dailyPlan[index],
                    ),
                    if (index + 1 < intelligence.dailyPlan.length)
                      const Divider(height: 22),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, int>>(
              future: _cloudHistory,
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, int>> snapshot) {
                final Map<String, int> history =
                    snapshot.data ?? <String, int>{};
                if (history.isEmpty) return const SizedBox.shrink();
                final List<MapEntry<String, int>> ranked = history.entries
                    .toList()
                  ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
                      b.value.compareTo(a.value));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AnalysisFeatureCard(
                    icon: Icons.cloud_done_rounded,
                    title:
                        'Cloud weakness history • ${history.values.fold<int>(0, (int a, int b) => a + b)} events',
                    subtitle: ranked
                        .take(3)
                        .map((MapEntry<String, int> item) =>
                            '${item.key}: ${item.value}')
                        .join(' • '),
                  ),
                );
              },
            ),
            _WeaknessHistory(history: intelligence.weaknessHistory),
            const SizedBox(height: 18),
            ChessVerseButton(
              label:
                  games.isEmpty ? 'No saved game yet' : 'Open full AI review',
              icon: Icons.auto_graph_rounded,
              onPressed: games.isEmpty
                  ? null
                  : () => showAdaptiveAiReview(
                        context,
                        report: latestReport!,
                        openingEco: latest?.openingEco,
                        timeControl:
                            latest?.mode == 'Play vs AI' ? '10+0' : null,
                      ),
            ),
          ],
        ),
      ),
    );
  }

  String _trainingFocus(
    List<SavedGameRecord> games,
    int averageMoves,
    int losses,
  ) {
    if (games.isEmpty) {
      return 'Start with a Newcomer AI game, then review the board after every result.';
    }
    if (losses * 2 > games.length) {
      return 'Prioritize king safety and scan every opponent check, capture, and threat before moving.';
    }
    if (averageMoves > 55) {
      return 'Your games run long. Train endgame conversion and activate your king after queens are exchanged.';
    }
    if (averageMoves < 18) {
      return 'Strengthen opening development: control the center, develop minor pieces, and castle early.';
    }
    return 'Build tactical consistency: calculate forcing checks and captures before choosing a positional move.';
  }
}

class _WeeklyDashboard extends StatelessWidget {
  const _WeeklyDashboard({required this.report});
  final WeeklyProgressReport report;

  @override
  Widget build(BuildContext context) => ChessVerseCard(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: <Widget>[
                const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF59E4C8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'This week: ${report.games} games • ${report.wins} wins',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                _MetricChip('${report.averageAccuracy}%', 'accuracy'),
                _MetricChip('${report.reviewedMoves}', 'moves reviewed'),
                _MetricChip(
                    '${report.accuracyChange >= 0 ? '+' : ''}${report.accuracyChange}',
                    'weekly trend'),
              ]),
              const SizedBox(height: 12),
              Text(
                  'Strongest: ${report.strongestSkill} • Next focus: ${report.focusArea}',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ]),
      );
}

class _MetricChip extends StatelessWidget {
  const _MetricChip(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x1859E4C8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x6659E4C8)),
        ),
        child: Text('$value $label',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      );
}

class _ProgressTrend extends StatelessWidget {
  const _ProgressTrend({required this.points});
  final List<ProgressTrendPoint> points;
  @override
  Widget build(BuildContext context) => ChessVerseCard(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('ACCURACY TREND',
                  style: TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: .8)),
              const SizedBox(height: 12),
              if (points.isEmpty)
                const Text(
                    'Complete an engine-reviewed game to start your trend.',
                    style: TextStyle(color: AppColors.textSecondary))
              else
                SizedBox(
                  height: 105,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        for (final ProgressTrendPoint point in points)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    Text('${point.accuracy}',
                                        style: const TextStyle(fontSize: 9)),
                                    const SizedBox(height: 3),
                                    Container(
                                      height: 8 +
                                          point.accuracy.clamp(0, 100) * .65,
                                      decoration: BoxDecoration(
                                        color: point.accuracy == 0
                                            ? const Color(0xFF304552)
                                            : const Color(0xFF59E4C8),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(point.label,
                                        style: const TextStyle(fontSize: 9)),
                                  ]),
                            ),
                          ),
                      ]),
                ),
            ]),
      );
}

class _DailyPlanRow extends StatelessWidget {
  const _DailyPlanRow({required this.index, required this.item});
  final int index;
  final DailyPlanItem item;
  @override
  Widget build(BuildContext context) => Row(children: <Widget>[
        CircleAvatar(radius: 16, child: Text('$index')),
        const SizedBox(width: 11),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
              Text(item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(item.detail,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ])),
        Text('${item.minutes} min',
            style: const TextStyle(
                color: AppColors.accentGold,
                fontWeight: FontWeight.w800,
                fontSize: 12)),
      ]);
}

class _WeaknessHistory extends StatelessWidget {
  const _WeaknessHistory({required this.history});
  final Map<String, List<int>> history;
  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, List<int>>> active = history.entries
        .where((MapEntry<String, List<int>> item) =>
            item.value.fold<int>(0, (int a, int b) => a + b) > 0)
        .toList()
      ..sort((a, b) => b.value.last.compareTo(a.value.last));
    return ChessVerseCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('4-WEEK WEAKNESS HISTORY',
                style: TextStyle(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: .8)),
            const SizedBox(height: 10),
            if (active.isEmpty)
              const Text('Reviewed mistakes will build your long-term history.',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              for (final MapEntry<String, List<int>> item in active.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(children: <Widget>[
                    SizedBox(
                        width: 105,
                        child: Text(item.key,
                            style: const TextStyle(fontSize: 12))),
                    for (final int value in item.value)
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: LinearProgressIndicator(
                            value: (value / 8).clamp(0, 1),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8)),
                      )),
                  ]),
                ),
          ]),
    );
  }
}

class _AnalysisFeatureCard extends StatelessWidget {
  const _AnalysisFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ChessVerseCard(
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.accentGold),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
