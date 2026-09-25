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
      final String story = AcademyStoryLocalizations(language.code)
          .storyNarration(capture);
      expect(story, isNotEmpty, reason: language.code);
      expect(story, isNot(contains('{')), reason: language.code);
      expect(story, contains(capture.to), reason: language.code);
    }
  });

  test('Telugu speech copy expands raw chess coordinates', () {
    final AcademyLesson board = AcademyCatalog.forChapter(
      'Meet the chessboard',
    );
    final String speech = AcademyStoryLocalizations('te')
        .storyNarrationForSpeech(board);

    expect(speech, isNot(contains('a1')));
    expect(speech, isNot(contains('a8')));
    expect(speech, contains('ఏ ఒకటి'));
    expect(speech, contains('ఏ ఎనిమిది'));
  });

  test('piece micro-lessons reuse the complete 34-language catalog', () {
    const List<String> chapters = <String>[
      'Pawn: one or two squares',
      'Pawn: capture diagonally',
      'Pawn: promote on the last rank',
      'Rook: horizontal movement',
      'Rook: vertical movement',
      'Bishops and diagonals',
      'The knight jump',
      'Queen movement',
      'The king and legal moves',
      'Check and checkmate',
    ];
    for (final String chapter in chapters) {
      final AcademyLesson lesson = AcademyCatalog.forChapter(chapter);
      expect(lesson.title, chapter);
      for (final AppLanguage language in AppLanguageController.supported.skip(
        1,
      )) {
        expect(
          AcademyStoryLocalizations(language.code).storyNarration(lesson),
          isNotEmpty,
          reason: '$chapter ${language.code}',
        );
      }
    }
  });

  test('lesson action prompt never leaks English into Telugu UI', () {
    final AcademyLesson lesson = AcademyCatalog.forChapter(
      'Meet the chessboard',
    );
    final String prompt = AcademyStoryLocalizations('te')
        .lessonInstruction(lesson);

    expect(prompt, contains('a1 → a8'));
    expect(prompt, isNot(contains('Move the highlighted rook')));
    expect(prompt, startsWith('అధ్యాయం 1'));
  });

  test('foundation chapter numbers follow the actual lesson order', () {
    final AcademyStoryLocalizations copy = AcademyStoryLocalizations('te');
    final AcademyLesson pawnCapture = AcademyCatalog.forChapter(
      'Pawn: capture diagonally',
    );
    final AcademyLesson pawnPromotion = AcademyCatalog.forChapter(
      'Pawn: promote on the last rank',
    );

    expect(copy.storyChapter(pawnCapture), startsWith('అధ్యాయం 3 ·'));
    expect(copy.storyChapter(pawnPromotion), startsWith('అధ్యాయం 4 ·'));
    expect(copy.storyTitle(pawnCapture), isNot(contains('అధ్యాయం')));
    expect(copy.storyTitle(pawnCapture), isNot(contains('Pawn:')));
  });
}
