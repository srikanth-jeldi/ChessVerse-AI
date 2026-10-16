import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/post_game_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completed-game actions are present in all 34 supported languages', () {
    final codes = AppLanguageController.supported
        .where((language) => language.code != AppLanguageController.systemCode)
        .map((language) => language.code)
        .toSet();
    expect(postGameTranslations.keys.toSet(), codes);
    for (final code in codes) {
      expect(postGameTranslations[code], hasLength(postGameKeys.length));
      for (final key in postGameKeys) {
        expect(postGameText(key, code).trim(), isNotEmpty);
      }
    }
    expect(postGameText('View result', 'te'), 'ఫలితం చూడండి');
  });
}
