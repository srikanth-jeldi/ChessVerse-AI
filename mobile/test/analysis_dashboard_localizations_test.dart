import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/analysis_dashboard_localizations.dart';
import 'package:chessverse_ai/features/analysis/presentation/analysis_screen.dart';
import 'package:chessverse_ai/features/analysis/domain/learning_intelligence.dart';

void main() {
  test(
      'deterministic learning intelligence prose is translated in every locale',
      () {
    final report = LearningIntelligence.fromGames([]);
    final sources = <String>[
      report.openingRecommendation,
      report.weekly.strongestSkill,
      report.weekly.focusArea,
      for (final item in report.dailyPlan) ...[item.title, item.detail],
      ...report.weaknessHistory.keys,
      'Your most familiar opening is Sicilian Defence. Review its first 8 moves, then add one response to the opponent’s main alternative.',
    ];
    for (final locale in AppLanguageController.supported
        .where((l) => l.code != 'system' && l.code != 'en')) {
      for (final source in sources) {
        final output = localizeAnalysisDashboardNarrative(source, locale.code);
        // A translated single-word label can legitimately equal English,
        // e.g. Dutch "Opening". Check prose, not lexical inequality.
        if (source.contains(' ')) {
          expect(output, isNot(source), reason: '${locale.code}: $source');
        }
        expect(output, isNot(contains('{')));
      }
    }
  });
  test('all 34 dashboard catalogs preserve every metric placeholder', () {
    expect(analysisDashboardKeys.length, analysisDashboardEnglish.length);
    final locales =
        AppLanguageController.supported.where((l) => l.code != 'system');
    expect(locales.length, 34);
    Set<String?> placeholders(String v) =>
        RegExp(r'\{[^}]+\}').allMatches(v).map((m) => m[0]).toSet();
    for (final locale in locales) {
      final row = analysisDashboardTranslations[locale.code]!;
      expect(row.length, analysisDashboardKeys.length, reason: locale.code);
      for (var i = 0; i < row.length; i++) {
        expect(row[i].trim(), isNotEmpty);
        expect(placeholders(row[i]), placeholders(analysisDashboardEnglish[i]),
            reason: '${locale.code}/${analysisDashboardKeys[i]}');
        final rendered =
            analysisDashboardText(analysisDashboardKeys[i], locale.code, {
          for (final slot in placeholders(row[i]))
            slot!.substring(1, slot.length - 1): '257',
        });
        expect(rendered, isNot(contains('{')));
      }
    }
  });
  testWidgets(
      'analysis dashboard refreshes subcards when selected locale changes',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({'settings.language': 'hi'});
    await tester.pumpWidget(const MaterialApp(home: AnalysisScreen()));
    await tester.pumpAndSettle();
    expect(
        find.text(analysisDashboardText('gameAnalysis', 'hi')), findsOneWidget);
    expect(find.text('Game analysis'), findsNothing);
    await AppLanguageController.select('ru');
    await tester.pumpAndSettle();
    expect(
        find.text(analysisDashboardText('gameAnalysis', 'ru')), findsOneWidget);
    expect(
        find.text(analysisDashboardText('gameAnalysis', 'hi')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    AppLanguageController.effectiveLanguageChanges.value = null;
  });
}
