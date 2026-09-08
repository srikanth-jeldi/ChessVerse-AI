import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/coach_localizations.dart';
import 'package:chessverse_ai/core/coach_review_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final codes = AppLanguageController.supported
      .where((language) => language.code != 'system')
      .map((language) => language.code)
      .toSet();
  test('offline coaching catalog contains all 34 offered languages', () {
    expect(reviewLabelTranslations.keys.toSet(), codes);
    for (final code in codes) {
      expect(reviewLabelTranslations[code]!.length, reviewLabelKeys.length,
          reason: code);
      for (final key in reviewLabelKeys) {
        expect(CoachLocalizations(code).contains(key), isTrue,
            reason: '$code:$key');
        expect(CoachLocalizations(code).text(key).trim(), isNotEmpty);
      }
    }
    expect(CoachLocalizations.translations.keys.toSet(), codes);
    for (final code in codes) {
      final row = CoachLocalizations.translations[code]!;
      expect(row.length, CoachLocalizations.keys.length, reason: code);
      expect(row.every((text) => text.trim().isNotEmpty), isTrue, reason: code);
      for (var index = 0; index < row.length; index++) {
        final placeholders = RegExp(r'\{\w+\}');
        expect(
            placeholders.allMatches(row[index]).map((m) => m[0]).toSet(),
            placeholders
                .allMatches(CoachLocalizations.translations['en']![index])
                .map((m) => m[0])
                .toSet(),
            reason: '$code ${CoachLocalizations.keys[index]}');
      }
    }
  });
  test(
      'reported screenshot sentences are translated in every non-English locale',
      () {
    for (final code in codes.where((code) => code != 'en')) {
      final copy = CoachLocalizations(code);
      for (final source in [
        'Complete one centre-control lesson before the next rated game.',
        'Play one slower game and apply the same thinking routine.',
        'This move improves central influence or development. Keep king safety in view.',
        'White',
        'Black',
        'Principled',
      ]) {
        expect(copy.source(source), isNot(source), reason: '$code: $source');
      }
    }
  });
  test('chess notation and unknown source content are never rewritten', () {
    for (final code in codes) {
      final copy = CoachLocalizations(code);
      expect(copy.text('preferred', {'move': 'e7e8q'}), contains('e7e8q'));
      expect(copy.source('Custom engine explanation e2e4'),
          'Custom engine explanation e2e4');
      expect(copy.text('positionBefore', {'move': '13'}), contains('13'));
    }
  });
}
