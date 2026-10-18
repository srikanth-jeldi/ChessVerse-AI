import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/game_feedback_localizations.dart';
import 'package:chessverse_ai/core/live_coach_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('result and puzzle feedback supports all 34 languages', () {
    final codes = AppLanguageController.supported
        .where((l) => l.code != AppLanguageController.systemCode)
        .map((l) => l.code)
        .toSet();
    expect(gameFeedbackTranslations.keys.toSet(), codes);
    for (final code in codes) {
      expect(
        gameFeedbackTranslations[code],
        hasLength(gameFeedbackKeys.length),
      );
      for (final key in gameFeedbackKeys) {
        expect(gameFeedbackText(key, code).trim(), isNotEmpty);
        if (code != 'en') {
          expect(
            gameFeedbackText(key, code),
            isNot(gameFeedbackText(key, 'en')),
          );
        }
      }
      if (code != 'en') {
        expect(localizeLiveCoach('YOUR TURN', code), isNot('YOUR TURN'));
        expect(
          localizeLiveCoach(
            'Easy Puzzle 01 solved. Continue with the next puzzle anytime.',
            code,
          ),
          isNot(contains('Easy Puzzle')),
        );
        expect(
          localizeLiveCoach('Hard Puzzle 07: checkmate in 2 moves.', code),
          isNot(contains('Hard Puzzle')),
        );
      }
    }
    expect(localizedPuzzleTitle('Easy Puzzle 01', 'te'), 'సులభమైన పజిల్ 01');
    expect(localizedPuzzleTitle('My custom puzzle', 'te'), 'My custom puzzle');
  });
}
