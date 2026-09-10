import 'package:chessverse_ai/core/academy_story_localizations.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/features/tutorial/domain/academy_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'every selectable non-English language has a complete offline catalog',
    () {
      final Iterable<String> codes = AppLanguageController.supported
          .map((AppLanguage language) => language.code)
          .where(
            (String code) =>
                code != AppLanguageController.systemCode && code != 'en',
          );

      expect(codes, hasLength(33));
      for (final String code in codes) {
        expect(
          AcademyStoryLocalizations.hasOfflineCatalog(code),
          isTrue,
          reason: '$code Academy catalog is incomplete',
        );
      }
    },
  );

  test('localized stories safely substitute chess notation placeholders', () {
    final AcademyLesson capture = AcademyCatalog.forChapter(
      'Captures and piece value',
    );
    for (final AppLanguage language in AppLanguageController.supported.skip(
      2,
    )) {
      final String story = AcademyStoryLocalizations(
        language.code,
      ).storyNarration(capture);
      expect(story, isNotEmpty, reason: language.code);
      expect(story, isNot(contains('{')), reason: language.code);
      expect(story, contains(capture.to), reason: language.code);
    }
  });
}
