import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/personal_coach_localizations.dart';
import 'package:chessverse_ai/core/review_training_group_a.dart';
import 'package:chessverse_ai/features/analysis/domain/ai_review_report.dart';
import 'package:chessverse_ai/features/analysis/domain/personal_ai_coach.dart';

void main() {
  test('group A supplies all 25 training messages for eight languages', () {
    expect(reviewTrainingGroupA.length, 8);
    for (final entry in reviewTrainingGroupA.entries) {
      expect(entry.value.split('|').length, 25, reason: entry.key);
      expect(entry.value.split('|').every((s) => s.trim().isNotEmpty), isTrue);
    }
  });
  final locales =
      AppLanguageController.supported.where((l) => l.code != 'system');
  test('all offered locales have complete nonempty UI, theme and API catalogs',
      () {
    expect(locales.length, 34);
    for (final locale in locales) {
      final row = personalCoachTranslations[locale.code]!;
      for (final key in ['boardSemantics', 'apiError']) {
        expect(personalCoachText(key, locale.code), isNotEmpty);
        if (locale.code != 'en') {
          expect(personalCoachText(key, locale.code),
              isNot(personalCoachText(key, 'en')));
        }
      }
      expect(row.length, personalCoachKeys.length, reason: locale.code);
      expect(row.every((s) => s.trim().isNotEmpty), isTrue);
      expect(personalCoachThemes[locale.code]!.length,
          personalCoachThemeKeys.length);
      expect(personalCoachApiTranslations[locale.code]!.length, 9);
      for (var i = 0; i < row.length; i++) {
        final placeholders =
            RegExp(r'\{[^}]+\}').allMatches(row[i]).map((m) => m[0]).toSet();
        final reference = RegExp(r'\{[^}]+\}')
            .allMatches(personalCoachTranslations['en']![i])
            .map((m) => m[0])
            .toSet();
        expect(placeholders, reference,
            reason: '${locale.code}/${personalCoachKeys[i]}');
      }
      for (var i = 0; i < 9; i++) {
        Set<String?> slots(String s) =>
            RegExp(r'\{[^}]+\}').allMatches(s).map((m) => m[0]).toSet();
        expect(slots(personalCoachApiTranslations[locale.code]![i]),
            slots(personalCoachApiTranslations['en']![i]));
      }
    }
  });
  const insight = AiMoveInsight(
      number: 3,
      notation: 'd2d4',
      side: 'White',
      phase: 'Opening',
      label: 'Good',
      explanation:
          'A quiet move. Compare it with forcing checks, captures, and direct threats.',
      bestMove: 'e2e4',
      opponentThreat: 'e7e5',
      centipawnLoss: 17,
      coachingTheme: 'opening',
      principalVariation: ['e2e4', 'e7e5', 'g1f3']);
  test(
      'quick answers preserve moves, score, practice count and localised explanation',
      () {
    for (final locale in locales) {
      for (final q in CoachQuestion.values) {
        final result = personalCoachAnswer(insight, q, locale.code);
        expect(result, contains('e2e4'));
        expect(result, contains('e7e5'));
        expect(result, contains('g1f3'));
        expect(result, isNot(contains('{count}')));
        if (q == CoachQuestion.whyBad) {
          expect(result, contains('d2d4'));
          expect(result, contains('17'));
          expect(result, isNot(contains('did not solve')));
        }
        if (q == CoachQuestion.practice) {
          expect(result, contains('3'));
        }
        if (locale.code != 'en') {
          expect(result, isNot(contains('A quiet move')));
        }
      }
    }
  });
  test('structured API answer keeps quoted input, every move and score', () {
    const source =
        'Following your earlier question, "my exact question": If you play d2 → d4, Stockfish grades it good with a 17 centipawn loss. It is a sound practical choice. The opponent\'s most forcing reply is e7 → e5. A concrete line is e2 → e4 → g1 → f3.';
    for (final locale in locales) {
      final translated = localizeCoachApiAnswer(source, locale.code);
      for (final data in [
        'my exact question',
        'd2 → d4',
        '17',
        'e7 → e5',
        'e2 → e4',
        'g1 → f3'
      ]) {
        expect(translated, contains(data), reason: locale.code);
      }
      if (locale.code != 'en') {
        expect(translated, isNot(contains('If you play')));
      }
    }
  });
  test('server default explanation is translated without deleting evidence',
      () {
    const source =
        'd2 → d4 was graded playable. A quiet move. Compare it with forcing checks, captures, and direct threats. A concrete line is e2 → e4 → e7 → e5.';
    for (final locale in locales.where((l) => l.code != 'en')) {
      final result = localizeCoachApiAnswer(source, locale.code);
      expect(result, contains('d2 → d4'));
      expect(result, contains('e2 → e4'));
      expect(result, isNot(contains('A quiet move')));
      expect(result, isNot(contains('was graded')));
    }
  });
  test('arbitrary prose is preserved, never fabricated as translated', () {
    expect(localizeCoachApiAnswer('Unknown explanation 937.', 'te'),
        'Unknown explanation 937.');
  });
  test(
      'every structured API branch keeps factual fields and translates grammar',
      () {
    const branches = <String>[
      'The immediate engine threat is e7 → e5. No forcing continuation was returned.',
      'd2 → d4 is a good move. It keeps the position under control.',
      'd2 → d4 gives the opponent a stronger reply. Prefer e2 → e4 and check their forcing move first.',
      'Play e2 → e4. It preserves more of your position and meets the immediate reply e7 → e5. No forcing continuation was returned.',
      'If you play d2 → d4, Stockfish grades it mistake with a 150 centipawn loss. The stronger move is e2 → e4. The opponent\'s most forcing reply is e7 → e5. No forcing continuation was returned.',
    ];
    for (final locale in locales.where((l) => l.code != 'en')) {
      for (final branch in branches) {
        final result = localizeCoachApiAnswer(branch, locale.code);
        for (final m in RegExp(r'[a-h][1-8] → [a-h][1-8]').allMatches(branch)) {
          expect(result, contains(m[0]!), reason: '${locale.code}: $branch');
        }
        for (final phrase in [
          'The immediate',
          'No forcing',
          'is a good move',
          'gives the opponent',
          'It preserves',
          'If you play',
          'The stronger',
          'centipawn loss'
        ]) {
          expect(result, isNot(contains(phrase)),
              reason: '${locale.code}: $branch');
        }
      }
    }
  });
}
