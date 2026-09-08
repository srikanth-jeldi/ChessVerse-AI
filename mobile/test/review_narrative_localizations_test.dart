import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/review_narrative_localizations.dart';
import 'package:chessverse_ai/core/review_training_group_b.dart';
import 'package:chessverse_ai/core/review_training_localizations.dart';
import 'package:chessverse_ai/core/coach_localizations.dart';
import 'package:chessverse_ai/core/local_game_archive.dart';
import 'package:chessverse_ai/features/analysis/domain/ai_review_report.dart';
import 'package:chessverse_ai/core/analysis_dashboard_group_b.dart';
import 'package:chessverse_ai/core/analysis_dashboard_localizations.dart';

void main() {
  final codes = AppLanguageController.supported
      .where((l) => l.code != 'system')
      .map((l) => l.code)
      .toSet();
  Set<String> placeholders(String text) =>
      RegExp(r'\{\w+\}').allMatches(text).map((m) => m.group(0)!).toSet();
  test('every supported locale has every narrative key and exact placeholders',
      () {
    expect(reviewNarrativeTranslations.keys.toSet(), codes);
    final english = reviewNarrativeTranslations['en']!;
    for (final code in codes) {
      final row = reviewNarrativeTranslations[code]!;
      expect(row.length, reviewNarrativeKeys.length, reason: code);
      for (var i = 0; i < row.length; i++) {
        expect(row[i].trim(), isNotEmpty,
            reason: '$code ${reviewNarrativeKeys[i]}');
        expect(placeholders(row[i]), placeholders(english[i]),
            reason: '$code ${reviewNarrativeKeys[i]}');
      }
    }
  });
  test('every static source uses its full translated template', () {
    for (final source in reviewNarrativeSources.entries) {
      expect(supportsReviewNarrative(source.key), isTrue);
      for (final code in codes.where((c) => c != 'en')) {
        expect(
            localizeReviewNarrative(source.key, code),
            reviewNarrativeTranslations[code]![
                reviewNarrativeKeys.indexOf(source.value)],
            reason: '$code ${source.key}');
      }
    }
  });
  test(
      'engine evidence and review numbering survive translation in all locales',
      () {
    const source =
        'Move 13: a2a4 • This gives the opponent a major tactical opportunity. e2e4 was stronger; the immediate opponent threat is e7e5.';
    expect(supportsReviewNarrative(source), isTrue);
    for (final code in codes) {
      final actual = localizeReviewNarrative(source, code);
      for (final evidence in ['13', 'a2a4', 'e2e4', 'e7e5']) {
        expect(actual, contains(evidence), reason: code);
      }
      if (code != 'en') expect(actual, isNot(contains('tactical opportunity')));
      final summary = localizeReviewNarrative(
          '69 half-moves reviewed across opening, middlegame, and endgame decisions.',
          code);
      expect(summary, contains('69'));
      final count = localizeReviewNarrative(
          '7 of 69 reviewed moves were Best or Great.', code);
      expect(count, contains('7'));
      expect(count, contains('69'));
    }
  });
  test('mate and null-engine threat tokens remain verbatim', () {
    for (final code in codes) {
      final actual = localizeReviewNarrative(
          'The move is playable, but it misses a more accurate continuation. a7a8q was stronger; the immediate opponent threat is (none).',
          code);
      expect(actual, contains('a7a8q'));
      expect(actual, contains('(none)'));
    }
  });
  test(
      'cloud saved-review templates translate without losing centipawn evidence',
      () {
    const matched = 'This matched Stockfish’s strongest continuation.';
    const loss = 'e2e4 was stronger by 173 centipawns.';
    for (final source in [matched, loss, 'Move 9: a2a4 • $loss']) {
      expect(supportsReviewNarrative(source), isTrue);
      for (final code in codes) {
        final actual = localizeReviewNarrative(source, code);
        if (code != 'en') expect(actual, isNot(source));
        if (source.contains('173')) {
          expect(actual, contains('173'));
          expect(actual, contains('e2e4'));
        }
      }
    }
  });
  test('saved turning points and mistake prefixes preserve all engine evidence',
      () {
    const examples = [
      'a2a4 — e2e4 was stronger.',
      'a2a4 • Prefer e2e4. This gives the opponent a major tactical opportunity. e2e4 was stronger; the immediate opponent threat is e7e5.',
      'a2a4 • Prefer e2e4. e2e4 was more accurate.',
    ];
    for (final source in examples) {
      expect(supportsReviewNarrative(source), isTrue);
      for (final code in codes) {
        final actual = localizeReviewNarrative(source, code);
        expect(actual, contains('a2a4'));
        expect(actual, contains('e2e4'));
        if (source.contains('e7e5')) expect(actual, contains('e7e5'));
        if (code != 'en') expect(actual, isNot(source));
      }
    }
  });
  test('opening metadata preserves ECO, book count and deviation', () {
    const source =
        'B20 • Sicilian Defence • 8 book plies • first deviation ply 9';
    for (final code in codes) {
      final actual = localizeReviewNarrative(source, code);
      for (final evidence in ['B20', '8', '9']) {
        expect(actual, contains(evidence));
      }
    }
  });
  test('unknown arbitrary prose is not replaced with invented advice', () {
    const unknown = 'This queen sacrifice wins because the rook is pinned.';
    expect(supportsReviewNarrative(unknown), isFalse);
    for (final code in codes) {
      expect(localizeReviewNarrative(unknown, code), unknown);
      expect(localizeReviewNarrative('Move 3: Qh7 • $unknown', code),
          'Move 3: Qh7 • $unknown');
    }
  });
  test('graph evidence survives translation and side labels are localized', () {
    for (final code in codes) {
      for (final source in [
        'Ply 69 • White f4f5',
        'Mate -3',
        'Black advantage • -1.25'
      ]) {
        expect(supportsReviewNarrative(source), isTrue);
        final actual = localizeReviewNarrative(source, code);
        final numbers = RegExp(r'[+-]?\d+(?:\.\d+)?')
            .allMatches(source)
            .map((m) => m.group(0)!);
        for (final number in numbers) {
          expect(actual, contains(number), reason: '$code $source');
        }
        if (source.contains('f4f5')) expect(actual, contains('f4f5'));
        if (code != 'en') expect(actual, isNot(contains('White')));
      }
    }
  });
  test('training group B has all25 complete sentences for its8 locales', () {
    expect(reviewTrainingGroupB.keys.toSet(),
        {'pl', 'nl', 'sv', 'el', 'he', 'ar', 'fa', 'tr'});
    for (final entry in reviewTrainingGroupB.entries) {
      final row = entry.value.split('|');
      expect(row.length, 25, reason: entry.key);
      expect(row.every((v) => v.trim().isNotEmpty), isTrue);
      expect(row[8], contains('10'));
      expect(row[9], contains('5'));
      expect(row[11], contains('5'));
      expect(row[15], contains('5'));
    }
  });
  test(
      'complete deterministic reports have coverage for every field in all34 locales',
      () {
    final reports = <AiReviewReport>[
      AiReviewReport.fromMoves([]),
      for (final accuracy in [50, 75, 90])
        AiReviewReport.fromMoves(
            ['e2e4', 'e7e5', 'Nf3', 'Nc6', 'O-O', 'Qh5+', 'exd5', 'a3'],
            newestFirst: false, knownAccuracy: accuracy),
      AiReviewReport.fromMoves(List.filled(40, 'a3'), newestFirst: false),
      AiReviewReport.fromMoves(['a3', 'a6'],
          newestFirst: false, result: 'loss'),
      for (final theme in [
        'kingSafety',
        'hangingPieces',
        'endgame',
        'tactics',
        'opening',
        'calculation'
      ])
        AiReviewReport.fromMoves(['e2e4'],
            newestFirst: false,
            knownReviews: [
              SavedMoveReview(
                  ply: 1,
                  fenBefore: 'fixture',
                  playedMove: 'e2e4',
                  bestMove: 'd2d4',
                  classification: 'Mistake',
                  coachingTheme: theme,
                  centipawnLoss: 80,
                  opponentThreat: 'e7e5',
                  explanation:
                      'This concedes a clear advantage that can be avoided. d2d4 was stronger; the immediate opponent threat is e7e5.',
                  principalVariation: ['d2d4', 'e7e5']),
            ]),
    ];
    for (final report in reports) {
      final fields = [
        report.headline,
        report.summary,
        report.strength,
        report.trainingFocus,
        report.turningPoint,
        report.recommendedLesson,
        report.openingName,
        ...report.importantMistakes,
        ...report.trainingRecommendations,
        for (final insight in report.insights) ...[
          insight.explanation,
          insight.label,
          insight.side,
          insight.phase
        ]
      ];
      for (final field in fields) {
        final narrative = supportsReviewNarrative(field);
        final training = supportsReviewTraining(field);
        final shared = CoachLocalizations('hi').source(field) != field;
        expect(narrative || training || shared, isTrue,
            reason: 'Uncovered report field: $field');
        for (final code in codes) {
          final translated = narrative
              ? localizeReviewNarrative(field, code)
              : training
                  ? localizeReviewTraining(field, code)
                  : CoachLocalizations(code).source(field);
          expect(translated.trim(), isNotEmpty, reason: '$code $field');
          // Shared labels can legitimately be identical (Dutch "Opening").
          if (code != 'en' &&
              !shared &&
              !reviewNarrativeSources.containsKey(field)) {
            expect(translated, isNot(field), reason: '$code $field');
          }
        }
      }
    }
  });
  test('dashboard groupB has all64 templates with exact placeholder parity',
      () {
    expect(analysisDashboardGroupB.keys.toSet(), {
      'he',
      'ar',
      'fa',
      'tr',
      'zh',
      'ja',
      'ko',
      'id',
      'ms',
      'th',
      'vi',
      'sw'
    });
    for (final entry in analysisDashboardGroupB.entries) {
      final row = entry.value.split('|');
      expect(row.length, analysisDashboardEnglish.length, reason: entry.key);
      for (var i = 0; i < row.length; i++) {
        expect(row[i].trim(), isNotEmpty);
        expect(placeholders(row[i]), placeholders(analysisDashboardEnglish[i]),
            reason: '${entry.key} ${analysisDashboardKeys[i]}');
      }
    }
  });
}
