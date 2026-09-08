import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/review_training_localizations.dart';
import 'package:chessverse_ai/core/coach_extra_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final codes = AppLanguageController.supported
      .where((language) => language.code != 'system')
      .map((language) => language.code)
      .toSet();
  test('every training recommendation has all 34 offline translations', () {
    expect(reviewTrainingTranslations.keys.toSet(), codes);
    for (final code in codes) {
      expect(reviewTrainingTranslations[code]!.length,
          reviewTrainingSources.length,
          reason: code);
      for (final source in reviewTrainingSources) {
        final translated = localizeReviewTraining(source, code);
        expect(translated.trim(), isNotEmpty, reason: code);
        if (code != 'en') {
          expect(translated, isNot(source), reason: '$code $source');
        }
      }
    }
  });
  test('extra dialog catalog preserves all placeholders in every language', () {
    expect(coachExtraTranslations.keys.toSet(), codes);
    final placeholders = RegExp(r'\{\w+\}');
    for (final code in codes) {
      final row = coachExtraTranslations[code]!;
      expect(row.length, coachExtraKeys.length, reason: code);
      for (var i = 0; i < row.length; i++) {
        expect(row[i].trim(), isNotEmpty);
        expect(
            placeholders.allMatches(row[i]).map((m) => m[0]).toSet(),
            placeholders
                .allMatches(coachExtraTranslations['en']![i])
                .map((m) => m[0])
                .toSet(),
            reason: '$code ${coachExtraKeys[i]}');
      }
    }
  });
}
