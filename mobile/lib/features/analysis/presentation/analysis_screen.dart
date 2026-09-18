import 'package:flutter/material.dart';

import '../../../core/layout/responsive_page.dart';
import '../../../core/analysis_dashboard_localizations.dart';
import '../../../core/analysis_metadata_localizations.dart';
import '../../../core/app_language.dart';
import '../../../core/coach_localizations.dart';
import '../../../core/review_narrative_localizations.dart';
import '../../../core/review_training_localizations.dart';
import '../../../core/live_coach_localizations.dart';
import '../../../core/local_game_archive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chessverse_button.dart';
import '../../../core/widgets/chessverse_card.dart';
import '../../auth/data/auth_session_store.dart';
import '../data/game_analysis_api.dart';
import '../../../core/widgets/ai_language_picker.dart';
import '../data/ai_coach_api.dart';
import '../domain/ai_review_report.dart';
import '../domain/learning_intelligence.dart';
import 'adaptive_ai_review.dart';

class _AnalysisLocale extends InheritedWidget {
  const _AnalysisLocale({required this.code, required super.child});
  final String code;
  static String of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AnalysisLocale>()?.code ??
      AppLanguageController.resolveCode('system');
  @override
  bool updateShouldNotify(_AnalysisLocale oldWidget) => oldWidget.code != code;
}

String _d(
  BuildContext context,
  String key, [
  Map<String, String> values = const {},
]) => analysisDashboardText(key, _AnalysisLocale.of(context), values);

@visibleForTesting
String localizeAnalysisDashboardNarrative(String value, String code) =>
    _analysisNarrative(value, code);

/// Domain objects keep canonical text for calculations and storage; only their
/// presentation is translated. Unknown user/server data is never rewritten.
String _analysisNarrative(String value, String code) {
  if (value == 'White wins' || value == 'Black wins') {
    return localizeLiveCoach('$value.', code);
  }
  if (value.toLowerCase() == 'white' || value.toLowerCase() == 'black') {
    return CoachLocalizations(code)
        .source(value.toLowerCase() == 'white' ? 'White' : 'Black');
  }
  if (value == 'unknown') return '—';
  const direct = <String, String>{
    'Targeted puzzles': 'targeted',
    'Mistake replay': 'mistakeReplay',
    'Slow practice game': 'slowPractice',
    'Retry the biggest Stockfish swing from your latest game.': 'bigSwing',
    'Use checks, captures, threats, then compare two candidates.': 'slowDetail',
    'Build a simple repertoire: King’s Pawn as White and Caro-Kann against 1.e4.':
        'repertoire',
    'Measured from your latest 100 engine-reviewed moves. Lower centipawn loss means improvement.':
        'impactEnough',
    'Complete at least 10 analyzed games and 100 reviewed moves before improvement is claimed.':
        'impactNotEnough',
    'Opening': 'opening',
    'King safety': 'kingSafety',
    'Piece safety': 'hangingPieces',
    'Capture scan': 'missedCaptures',
    'Time management': 'timeManagement',
    'Endgame': 'endgame',
    'Tactical vision': 'tactics',
    'Calculation': 'calculation',
    'opening': 'opening',
    'kingSafety': 'kingSafety',
    'hangingPieces': 'hangingPieces',
    'missedCaptures': 'missedCaptures',
    'timeManagement': 'timeManagement',
    'endgame': 'endgame',
    'tactics': 'tactics',
    'calculation': 'calculation',
  };
  final key = direct[value];
  if (key != null) return analysisDashboardText(key, code);
  final familiar = RegExp(
    r'^Your most familiar opening is (.+)\. Review its first 8 moves, then add one response to the opponent’s main alternative\.$',
  ).firstMatch(value);
  if (familiar != null) {
    return analysisDashboardText('familiar', code, {
      'opening': localizeReviewNarrative(familiar[1]!, code),
    });
  }
  final focused = RegExp(r'^5 positions focused on (.+)\.$').firstMatch(value);
  if (focused != null) {
    return analysisDashboardText('focusedPositions', code, {
      'focus': _analysisNarrative(focused[1]!, code),
    });
  }
  return localizeLiveCoach(
    localizeAnalysisMetadata(
      localizeReviewTraining(
        localizeReviewNarrative(CoachLocalizations(code).source(value), code),
        code,
      ),
      code,
    ),
    code,
  );
}

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final bool _usePremiumDashboard = true;
  String _language = AppLanguageController.resolveCode('system');
  bool _languageReady = false;
  String t(String key, [Map<String, String> values = const {}]) =>
      analysisDashboardText(key, _language, values);
  String n(String value) => _analysisNarrative(value, _language);
  @override
  void initState() {
    super.initState();
    AppLanguageController.effectiveLanguageChanges.addListener(
      _languageChanged,
    );
    AppLanguageController.effectiveCode()
        .then((code) {
          if (mounted) {
            setState(() {
              _language =
                  AppLanguageController.effectiveLanguageChanges.value ?? code;
              _languageReady = true;
            });
          }
        })
        .catchError((Object error) {
          if (mounted) setState(() => _languageReady = true);
        });
  }

  void _languageChanged() {
    final code = AppLanguageController.effectiveLanguageChanges.value;
    if (mounted && code != null) {
      setState(() {
        _language = code;
        _languageReady = true;
      });
    }
  }

  @override
  void dispose() {
    AppLanguageController.effectiveLanguageChanges.removeListener(
      _languageChanged,
    );
    super.dispose();
  }

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
    if (!_languageReady) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<SavedGameRecord> games = LocalGameArchive.games;
    final int totalMoves = games.fold<int>(
      0,
      (int total, SavedGameRecord game) => total + game.moves.length,
    );
    final int averageMoves = games.isEmpty
        ? 0
        : (totalMoves / games.length).round();
    final int losses = games
        .where(
          (SavedGameRecord game) => game.result.toLowerCase().contains('loss'),
        )
        .length;
    final SavedGameRecord? latest = games.isEmpty ? null : games.first;
    final AiReviewReport? latestReport = latest == null
        ? null
        : AiReviewReport.fromMoves(
            latest.moves,
            newestFirst: false,
            result: latest.result,
            knownReviews: latest.moveReviews,
            initialFen: latest.initialFen,
            knownOpeningName: latest.openingName == null
                ? null
                : '${latest.openingEco ?? 'ECO'} • ${n(latest.openingName!)} • ${t('bookMetadata', {'count': '${latest.bookPlies}'})}${latest.firstDeviationPly == null ? '' : ' • ${t('deviation', {'count': '${latest.firstDeviationPly}'})}'}',
          );
    final String focus = _trainingFocus(games, averageMoves, losses);
    final LearningIntelligence intelligence = LearningIntelligence.fromGames(
      games,
      cloudScores: LocalGameArchive.cloudWeaknessScores,
    );
    return _AnalysisLocale(
      code: _language,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t('analysis')),
          actions: <Widget>[
            TextButton.icon(
              key: const ValueKey<String>('analysis-ai-language'),
              onPressed: () => chooseAndSaveAiLanguage(context),
              icon: const Icon(Icons.translate_rounded),
              label: Text(t('language')),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ResponsivePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_usePremiumDashboard)
                _PremiumAnalysisDashboard(
                  games: games,
                  intelligence: intelligence,
                  latestReport: latestReport,
                  narrative: n,
                  onReview: (SavedGameRecord game) {
                    final AiReviewReport report = AiReviewReport.fromMoves(
                      game.moves,
                      newestFirst: false,
                      result: game.result,
                      knownReviews: game.moveReviews,
                      knownOpeningName: game.openingName,
                      playerSide: game.playerSide,
                      reviewScope: game.reviewScope,
                      initialFen: game.initialFen,
                    );
                    showAdaptiveAiReview(
                      context,
                      report: report,
                      openingEco: game.openingEco,
                      timeControl: game.mode == 'Play vs AI' ? '10+0' : null,
                    );
                  },
                ),
              if (!_usePremiumDashboard) ...<Widget>[
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
                        t('gameAnalysis'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        games.isEmpty
                            ? t('unlock')
                            : t('reviewedIntro', {
                                'games': '${games.length}',
                                'moves': '$totalMoves',
                              }),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  t('snapshot'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _AnalysisFeatureCard(
                  icon: Icons.timeline_rounded,
                  title: latestReport == null
                      ? t('analyzed', {'count': '${games.length}'})
                      : t('latestAccuracy', {
                          'count': '${latestReport.accuracy}',
                        }),
                  subtitle: latestReport == null
                      ? t('averageMoves', {'count': '$averageMoves'})
                      : n(latestReport.headline),
                ),
                const SizedBox(height: 12),
                _AnalysisFeatureCard(
                  icon: Icons.psychology_alt_rounded,
                  title: t('focus'),
                  subtitle: latestReport == null
                      ? focus
                      : '${n(latestReport.trainingFocus)} ${t('recommended')}: ${n(latestReport.recommendedLesson)}.',
                ),
                const SizedBox(height: 12),
                _AnalysisFeatureCard(
                  icon: Icons.warning_amber_rounded,
                  title: latest == null ? t('latestReport') : n(latest.result),
                  subtitle: latest == null
                      ? t('latestEmpty')
                      : n(
                          latestReport?.turningPoint ??
                              '${latest.summary} • ${latest.detail}',
                        ),
                ),
                const SizedBox(height: 18),
                Text(
                  t('weekly'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _WeeklyDashboard(report: intelligence.weekly),
                const SizedBox(height: 12),
                FutureBuilder<AiCoachImpact?>(
                  future: _coachImpact,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<AiCoachImpact?> snapshot,
                      ) {
                        final AiCoachImpact? impact = snapshot.data;
                        if (impact == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnalysisFeatureCard(
                            icon: impact.enoughEvidence
                                ? Icons.verified_rounded
                                : Icons.hourglass_bottom_rounded,
                            title: impact.enoughEvidence
                                ? t('qualityChange', {
                                    'count':
                                        '${impact.improvementPercent >= 0 ? '+' : ''}${impact.improvementPercent}',
                                  })
                                : t('measurement'),
                            subtitle:
                                '${t('impactStats', {'games': '${impact.analyzedGames}', 'moves': '${impact.measuredMoves}', 'percent': '${impact.helpfulPercent}'})} ${n(impact.evidenceMessage)}',
                          ),
                        );
                      },
                ),
                _ProgressTrend(points: intelligence.trend),
                const SizedBox(height: 12),
                FutureBuilder<AnalysisTrends?>(
                  future: _serverTrends,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<AnalysisTrends?> snapshot,
                      ) {
                        final AnalysisTrends? trends = snapshot.data;
                        if (trends == null) return const SizedBox.shrink();
                        return Column(
                          children: <Widget>[
                            ChessVerseCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    t('serverTrends'),
                                    style: TextStyle(
                                      color: AppColors.accentGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  for (final MapEntry<
                                        String,
                                        AnalysisWindowTrend
                                      >
                                      item
                                      in trends.windows.entries)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 7),
                                      child: Text(
                                        t('trendLine', {
                                          'games': item.key.replaceFirst(
                                            'last',
                                            '',
                                          ),
                                          'accuracy':
                                              '${item.value.averageAccuracy}',
                                          'loss':
                                              '${item.value.averageCentipawnLoss}',
                                          'blunders': '${item.value.blunders}',
                                        }),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (trends
                                .recommendationOutcomes
                                .isNotEmpty) ...<Widget>[
                              const SizedBox(height: 12),
                              _AnalysisFeatureCard(
                                icon: Icons.fact_check_rounded,
                                title: t('outcomeTitle'),
                                subtitle: trends.recommendationOutcomes
                                    .take(6)
                                    .map(
                                      (RecommendationDimension item) =>
                                          t('outcomeLine', {
                                            'dimension': n(item.dimension),
                                            'value': n(item.value),
                                            'percent': '${item.successPercent}',
                                            'count': '${item.resolved}',
                                          }),
                                    )
                                    .join(' • '),
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                ),
                _AnalysisFeatureCard(
                  icon: Icons.menu_book_rounded,
                  title: t('openingRec'),
                  subtitle: n(intelligence.openingRecommendation),
                ),
                const SizedBox(height: 18),
                Text(t('plan'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ChessVerseCard(
                  child: Column(
                    children: <Widget>[
                      for (
                        int index = 0;
                        index < intelligence.dailyPlan.length;
                        index++
                      ) ...<Widget>[
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
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<Map<String, int>> snapshot,
                      ) {
                        final Map<String, int> history =
                            snapshot.data ?? <String, int>{};
                        if (history.isEmpty) return const SizedBox.shrink();
                        final List<MapEntry<String, int>> ranked =
                            history.entries.toList()..sort(
                              (
                                MapEntry<String, int> a,
                                MapEntry<String, int> b,
                              ) => b.value.compareTo(a.value),
                            );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnalysisFeatureCard(
                            icon: Icons.cloud_done_rounded,
                            title: t('cloudHistory', {
                              'count':
                                  '${history.values.fold<int>(0, (int a, int b) => a + b)}',
                            }),
                            subtitle: ranked
                                .take(3)
                                .map(
                                  (MapEntry<String, int> item) =>
                                      '${n(item.key)}: ${item.value}',
                                )
                                .join(' • '),
                          ),
                        );
                      },
                ),
                _WeaknessHistory(history: intelligence.weaknessHistory),
                const SizedBox(height: 18),
                ChessVerseButton(
                  label: games.isEmpty ? t('noSaved') : t('openReview'),
                  icon: Icons.auto_graph_rounded,
                  onPressed: games.isEmpty
                      ? null
                      : () => showAdaptiveAiReview(
                          context,
                          report: latestReport!,
                          openingEco: latest?.openingEco,
                          timeControl: latest?.mode == 'Play vs AI'
                              ? '10+0'
                              : null,
                        ),
                ),
              ],
            ],
          ),
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
      return t('focusEmpty');
    }
    if (losses * 2 > games.length) {
      return t('focusLoss');
    }
    if (averageMoves > 55) {
      return t('focusLong');
    }
    if (averageMoves < 18) {
      return t('focusShort');
    }
    return t('focusDefault');
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
        Row(
          children: <Widget>[
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF59E4C8)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _d(context, 'weeklyStats', {
                  'games': '${report.games}',
                  'wins': '${report.wins}',
                }),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _MetricChip('${report.averageAccuracy}%', _d(context, 'accuracy')),
            _MetricChip(
              '${report.reviewedMoves}',
              _d(context, 'movesReviewed'),
            ),
            _MetricChip(
              '${report.accuracyChange >= 0 ? '+' : ''}${report.accuracyChange}',
              _d(context, 'weeklyTrend'),
            ),
            _MetricChip('${report.mistakes}', _d(context, 'mistakeReplay')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Icon(
              report.mistakeChange <= 0
                  ? Icons.trending_down_rounded
                  : Icons.trending_up_rounded,
              color: report.mistakeChange <= 0
                  ? const Color(0xFF63D2B8)
                  : const Color(0xFFF08A6B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                report.mistakeChange == 0
                    ? _d(context, 'measurement')
                    : '${report.mistakeChange.abs()} ${_d(context, 'mistakeReplay')} • ${report.mistakeChange < 0 ? '↓' : '↑'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${_d(context, 'strongest')}: ${_analysisNarrative(report.strongestSkill, _AnalysisLocale.of(context))} • ${_d(context, 'nextFocus')}: ${_analysisNarrative(report.focusArea, _AnalysisLocale.of(context))}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
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
    child: Text(
      '$value $label',
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
    ),
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
        Text(
          _d(context, 'accuracyTrend'),
          style: TextStyle(
            color: AppColors.accentGold,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 12),
        if (points.isEmpty)
          Text(
            _d(context, 'emptyTrend'),
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          SizedBox(
            height: 105,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final ProgressTrendPoint point in points)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            '${point.accuracy}',
                            style: const TextStyle(fontSize: 9),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: 8 + point.accuracy.clamp(0, 100) * .65,
                            decoration: BoxDecoration(
                              color: point.accuracy == 0
                                  ? const Color(0xFF304552)
                                  : const Color(0xFF59E4C8),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            point.label.replaceFirst('G', ''),
                            semanticsLabel: _d(context, 'gameLabel', {
                              'count': point.label.replaceFirst('G', ''),
                            }),
                            style: const TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _DailyPlanRow extends StatelessWidget {
  const _DailyPlanRow({required this.index, required this.item});
  final int index;
  final DailyPlanItem item;
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      CircleAvatar(radius: 16, child: Text('$index')),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _analysisNarrative(item.title, _AnalysisLocale.of(context)),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              _analysisNarrative(item.detail, _AnalysisLocale.of(context)),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      Text(
        _d(context, 'minutes', {'count': '${item.minutes}'}),
        style: const TextStyle(
          color: AppColors.accentGold,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    ],
  );
}

class _WeaknessHistory extends StatelessWidget {
  const _WeaknessHistory({required this.history});
  final Map<String, List<int>> history;
  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, List<int>>> active =
        history.entries
            .where(
              (MapEntry<String, List<int>> item) =>
                  item.value.fold<int>(0, (int a, int b) => a + b) > 0,
            )
            .toList()
          ..sort((a, b) => b.value.last.compareTo(a.value.last));
    return ChessVerseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _d(context, 'history'),
            style: TextStyle(
              color: AppColors.accentGold,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 10),
          if (active.isEmpty)
            Text(
              _d(context, 'historyEmpty'),
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            for (final MapEntry<String, List<int>> item in active.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 105,
                      child: Text(
                        _analysisNarrative(
                          item.key,
                          _AnalysisLocale.of(context),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    for (final int value in item.value)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: LinearProgressIndicator(
                            value: (value / 8).clamp(0, 1),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
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

class _PremiumAnalysisDashboard extends StatefulWidget {
  const _PremiumAnalysisDashboard({
    required this.games,
    required this.intelligence,
    required this.latestReport,
    required this.narrative,
    required this.onReview,
  });

  final List<SavedGameRecord> games;
  final LearningIntelligence intelligence;
  final AiReviewReport? latestReport;
  final String Function(String) narrative;
  final ValueChanged<SavedGameRecord> onReview;

  @override
  State<_PremiumAnalysisDashboard> createState() =>
      _PremiumAnalysisDashboardState();
}

class _PremiumAnalysisDashboardState extends State<_PremiumAnalysisDashboard> {
  String _filter = 'recent';

  @override
  Widget build(BuildContext context) {
    final int reviewed = widget.games.fold<int>(
      0,
      (total, game) => total + game.moveReviews.length,
    );
    final int mistakes = widget.games.fold<int>(
      0,
      (total, game) =>
          total +
          game.moveReviews
              .where(
                (review) => const <String>{
                  'Inaccuracy',
                  'Mistake',
                  'Blunder',
                }.contains(review.classification),
              )
              .length,
    );
    final int accuracy = widget.latestReport?.accuracy ?? 0;
    final List<SavedGameRecord> visible = _filteredGames().take(6).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF2777C8)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x5538BDF8), blurRadius: 24),
        ],
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF03111F), Color(0xFF061C34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Column(
          children: <Widget>[
            _PremiumHero(
              gameCount: widget.games.length,
              title: _d(context, 'gameAnalysis'),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool wide = constraints.maxWidth >= 920;
                  final Widget summary = _PremiumSummary(
                    accuracy: accuracy,
                    games: widget.games.length,
                    reviewed: reviewed,
                    mistakes: mistakes,
                    trend: widget.intelligence.weekly.accuracyChange,
                  );
                  final Widget content = Column(
                    children: <Widget>[
                      _PremiumFilters(
                        selected: _filter,
                        onChanged: (value) => setState(() => _filter = value),
                      ),
                      const SizedBox(height: 14),
                      if (visible.isEmpty)
                        const _PremiumEmptyState()
                      else
                        for (
                          int index = 0;
                          index < visible.length;
                          index++
                        ) ...[
                          _PremiumGameCard(
                            game: visible[index],
                            index: index,
                            narrative: widget.narrative,
                            onReview: () => widget.onReview(visible[index]),
                          ),
                          if (index + 1 < visible.length)
                            const SizedBox(height: 12),
                        ],
                    ],
                  );
                  if (!wide) {
                    return Column(
                      children: <Widget>[
                        summary,
                        const SizedBox(height: 16),
                        content,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(width: 310, child: summary),
                      const SizedBox(width: 18),
                      Expanded(child: content),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Iterable<SavedGameRecord> _filteredGames() => switch (_filter) {
    'reviewed' => widget.games.where((game) => game.moveReviews.isNotEmpty),
    'mistakes' => widget.games.where(
      (game) => game.moveReviews.any(
        (review) => const <String>{
          'Inaccuracy',
          'Mistake',
          'Blunder',
        }.contains(review.classification),
      ),
    ),
    'wins' => widget.games.where(
      (game) =>
          (game.playerOutcome ?? game.result).toLowerCase().contains('win'),
    ),
    _ => widget.games,
  };
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({required this.gameCount, required this.title});
  final int gameCount;
  final String title;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0x6645B8FF))),
      gradient: LinearGradient(
        colors: <Color>[Color(0xFF041426), Color(0xFF083665)],
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 24,
      runSpacing: 12,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFFFE489), Color(0xFFD18B16)],
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x99EABF61), blurRadius: 18),
                ],
                border: Border.all(color: const Color(0xFFFFE8A3)),
              ),
              child: const Icon(
                Icons.psychology_alt_rounded,
                color: Color(0xFF07182B),
                size: 34,
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD87C),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Text(
                    'Deeper insights. Faster learning. Better chess.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFFD5E8FF)),
                  ),
                ],
              ),
            ),
          ],
        ),
        Text(
          gameCount == 0
              ? '“Every game is a lesson.”'
              : '$gameCount games ready for intelligent review',
          style: const TextStyle(
            color: Color(0xFFBFD8F6),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _PremiumSummary extends StatelessWidget {
  const _PremiumSummary({
    required this.accuracy,
    required this.games,
    required this.reviewed,
    required this.mistakes,
    required this.trend,
  });
  final int accuracy, games, reviewed, mistakes, trend;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      _GlassPanel(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'YOUR PROGRESS',
                style: TextStyle(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 128,
              height: 128,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: accuracy / 100,
                      strokeWidth: 13,
                      backgroundColor: const Color(0xFF12355C),
                      color: const Color(0xFFFFD35F),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$accuracy%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(child: _MiniMetric('$games', 'GAMES')),
                const SizedBox(width: 8),
                Expanded(child: _MiniMetric('$reviewed', 'MOVES')),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniMetric('${trend >= 0 ? '+' : ''}$trend', 'TREND'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'REVIEW SIGNALS',
              style: TextStyle(
                color: Color(0xFFFFD35F),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _Signal(
              Icons.auto_awesome_rounded,
              '$reviewed analyzed moves',
              const Color(0xFF56E5C5),
            ),
            const SizedBox(height: 9),
            _Signal(
              Icons.warning_amber_rounded,
              '$mistakes learning moments',
              const Color(0xFFFF8A65),
            ),
            const SizedBox(height: 9),
            const _Signal(
              Icons.lightbulb_rounded,
              'AI explanations grounded in engine evidence',
              Color(0xFFFFD35F),
            ),
          ],
        ),
      ),
    ],
  );
}

class _PremiumFilters extends StatelessWidget {
  const _PremiumFilters({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children:
        <(String, String, IconData)>[
          ('recent', 'RECENT', Icons.schedule_rounded),
          ('reviewed', 'REVIEWED', Icons.workspace_premium_rounded),
          ('mistakes', 'MISTAKES', Icons.analytics_outlined),
          ('wins', 'WINS', Icons.star_rounded),
        ].map((item) {
          final bool active = selected == item.$1;
          return ChoiceChip(
            selected: active,
            onSelected: (_) => onChanged(item.$1),
            avatar: Icon(
              item.$3,
              size: 18,
              color: active ? const Color(0xFF07182B) : Colors.white70,
            ),
            label: Text(item.$2),
            labelStyle: TextStyle(
              color: active ? const Color(0xFF07182B) : Colors.white,
              fontWeight: FontWeight.w900,
            ),
            selectedColor: const Color(0xFFFFCE58),
            backgroundColor: const Color(0xFF071A30),
            side: const BorderSide(color: Color(0xFF285C8F)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }).toList(),
  );
}

class _PremiumGameCard extends StatelessWidget {
  const _PremiumGameCard({
    required this.game,
    required this.index,
    required this.narrative,
    required this.onReview,
  });
  final SavedGameRecord game;
  final int index;
  final String Function(String) narrative;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final AiReviewReport report = AiReviewReport.fromMoves(
      game.moves,
      newestFirst: false,
      result: game.result,
      knownReviews: game.moveReviews,
      knownOpeningName: game.openingName,
      playerSide: game.playerSide,
      reviewScope: game.reviewScope,
      initialFen: game.initialFen,
    );
    final int mistakes = game.moveReviews
        .where(
          (review) => const <String>{
            'Inaccuracy',
            'Mistake',
            'Blunder',
          }.contains(review.classification),
        )
        .length;
    return _GlassPanel(
      glow: index == 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 650;
          final Widget emblem = Container(
            width: compact ? 64 : 105,
            height: compact ? 64 : 105,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF347EBB)),
              gradient: LinearGradient(
                colors: <Color>[
                  const Color(0xFF153E68),
                  index.isEven
                      ? const Color(0xFF07131F)
                      : const Color(0xFF2E180B),
                ],
              ),
            ),
            child: Icon(
              <IconData>[
                Icons.emoji_events_rounded,
                Icons.psychology_rounded,
                Icons.castle_rounded,
              ][index % 3],
              color: index.isEven
                  ? const Color(0xFF75C9FF)
                  : const Color(0xFFFFC85B),
              size: compact ? 38 : 58,
            ),
          );
          final Widget details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      game.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusPill(
                    game.moveReviews.isEmpty
                        ? 'READY TO ANALYZE'
                        : 'REVIEW READY',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 5,
                children: <Widget>[
                  _Meta(
                    Icons.calendar_today_rounded,
                    '${game.playedAt.day}/${game.playedAt.month}/${game.playedAt.year}',
                  ),
                  _Meta(Icons.bolt_rounded, game.mode),
                  _Meta(
                    Icons.query_stats_rounded,
                    '${report.accuracy}% accuracy',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                narrative(report.headline),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFB7CCE3)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _OutlineTag(
                    Icons.lightbulb_rounded,
                    '${game.moveReviews.length} analyzed',
                  ),
                  _OutlineTag(
                    Icons.warning_amber_rounded,
                    '$mistakes learning moments',
                  ),
                  FilledButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('OPEN AI REVIEW'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC84D),
                      foregroundColor: const Color(0xFF07182B),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[emblem, const SizedBox(height: 12), details],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              emblem,
              const SizedBox(width: 16),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.glow = false});
  final Widget child;
  final bool glow;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xD9071A30),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: glow ? const Color(0xFF36C8FF) : const Color(0xFF28577F),
      ),
      boxShadow: glow
          ? const <BoxShadow>[
              BoxShadow(color: Color(0x4438BDF8), blurRadius: 15),
            ]
          : null,
    ),
    child: child,
  );
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF081E37),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF1E5D91)),
    ),
    child: Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF63E3C4),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8EA9C5),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _Signal extends StatelessWidget {
  const _Signal(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0x3312D69C),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF3DD7A7)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF62E6BC),
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, size: 15, color: const Color(0xFF9AB4D0)),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(color: Color(0xFFBCD0E5), fontSize: 11),
      ),
    ],
  );
}

class _OutlineTag extends StatelessWidget {
  const _OutlineTag(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF315E8B)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: const Color(0xFFFFCC58)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _PremiumEmptyState extends StatelessWidget {
  const _PremiumEmptyState();
  @override
  Widget build(BuildContext context) => const _GlassPanel(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: <Widget>[
          Icon(Icons.auto_awesome_rounded, size: 46, color: Color(0xFFFFD35F)),
          SizedBox(height: 12),
          Text(
            'Play or import a game to unlock your AI review.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}
