import '../features/tutorial/domain/academy_lesson.dart';
import 'academy_story_translations_europe.dart';
import 'academy_story_translations_global.dart';
import 'academy_story_translations_indic.dart';
import 'app_language.dart';

/// Fully bundled Academy copy. Nothing is sent to a translation service.
class AcademyStoryLocalizations {
  AcademyStoryLocalizations(String code)
    : code = AppLanguageController.resolveCode(code);

  final String code;

  static const Map<String, Map<String, String>> _translations =
      <String, Map<String, String>>{
        ...academyStoryIndicTranslations,
        ...academyStoryEuropeTranslations,
        ...academyStoryGlobalTranslations,
      };

  Map<String, String>? get _copy => _translations[code];

  String storyChapter(AcademyLesson lesson) =>
      _copy?['${lesson.id}.chapter'] ?? lesson.storyChapter;

  String storyNarration(AcademyLesson lesson) {
    final String value = _copy?['${lesson.id}.story'] ?? lesson.storyNarration;
    final String localized = value
        .replaceAll('{from}', lesson.from)
        .replaceAll('{to}', lesson.to)
        .replaceAll('{square}', lesson.to);
    return localized.contains(lesson.to)
        ? localized
        : '$localized ${lesson.from} → ${lesson.to}.';
  }

  static bool hasOfflineCatalog(String code) {
    final Map<String, String>? copy = _translations[code];
    return copy != null && _requiredKeys.every(copy.containsKey);
  }

  static const Set<String> _requiredKeys = <String>{
    'board.chapter',
    'board.story',
    'pawn.chapter',
    'pawn.story',
    'rook.chapter',
    'rook.story',
    'bishop.chapter',
    'bishop.story',
    'knight.chapter',
    'knight.story',
    'queen.chapter',
    'queen.story',
    'king.chapter',
    'king.story',
    'capture.chapter',
    'capture.story',
    'ui.thinkTitle',
    'ui.candidateRule',
    'ui.listen',
    'ui.pause',
    'ui.continue',
    'ui.restart',
    'ui.aiCoach',
    'ui.strapline',
    'decision.safety',
    'decision.tactics',
    'decision.endgame',
    'insight.safety',
    'insight.tactics',
    'insight.endgame',
    'feedback.wrong',
  };

  String text(String key, {Map<String, String> values = const {}}) {
    String result = _copy?[key] ?? _english[key] ?? key;
    for (final MapEntry<String, String> entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  String decisionQuestion(AcademyStage stage) => text(switch (stage) {
    AcademyStage.safety => 'decision.safety',
    AcademyStage.tactics => 'decision.tactics',
    AcademyStage.endgame => 'decision.endgame',
    AcademyStage.foundation => 'decision.foundation',
  });

  String decisionInsight(AcademyLesson lesson) => text(
    switch (lesson.stage) {
      AcademyStage.safety => 'insight.safety',
      AcademyStage.tactics => 'insight.tactics',
      AcademyStage.endgame => 'insight.endgame',
      AcademyStage.foundation => 'insight.foundation',
    },
    values: <String, String>{'to': lesson.to},
  );

  static const Map<String, String> _english = <String, String>{
    'ui.thinkTitle': 'THINK BEFORE THE DEMO',
    'ui.candidateRule':
        'Coach rule: compare at least three candidates before committing.',
    'ui.listen': 'LISTEN TO STORY',
    'ui.pause': 'PAUSE STORY',
    'ui.continue': 'CONTINUE STORY',
    'ui.restart': 'Start narration again',
    'ui.aiCoach': 'AI COACH',
    'ui.strapline': 'WATCH • UNDERSTAND • PRACTICE',
    'decision.foundation': 'Which destination completes the mission?',
    'decision.safety':
        'Before the coach moves: which square best protects the king?',
    'decision.tactics':
        'Before the coach moves: which candidate creates the strongest forcing idea?',
    'decision.endgame':
        'Before the coach moves: which candidate follows the key endgame principle?',
    'insight.foundation': '{to} completes the mission.',
    'insight.safety':
        '{to} is safest because it answers the immediate danger before making a new threat.',
    'insight.tactics':
        '{to} is strongest. Scan checks, captures, and threats first; forcing moves reduce the opponent’s choices.',
    'insight.endgame':
        '{to} follows the essential endgame principle. Activity and precise king or pawn placement matter more than speed.',
    'feedback.wrong':
        '{square} looks possible, but it misses the position’s priority. Check the opponent’s reply and compare again.',
  };
}
