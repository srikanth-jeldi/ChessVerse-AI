import 'package:chessverse_ai/core/app_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every offered language resolves without switching to English', () {
    final languages = AppLanguageController.supported.where(
      (language) => language.code != AppLanguageController.systemCode,
    );
    expect(languages.length, 34);
    for (final language in languages) {
      expect(AppLanguageController.resolveCode(language.code), language.code);
      expect(
        AppLanguageController.resolveCode('${language.code}_IN'),
        language.code,
      );
      expect(
        AppLanguageController.resolveCode('system', deviceCode: language.code),
        language.code,
      );
    }
  });

  test('unsupported device languages fall back explicitly to English', () {
    expect(AppLanguageController.resolveCode('system', deviceCode: 'xx'), 'en');
    expect(AppLanguageController.resolveCode('HI-in'), 'hi');
  });

  test('picker languages are alphabetical after device language', () {
    final languages = AppLanguageController.pickerLanguages;
    expect(languages.first.code, AppLanguageController.systemCode);
    final names = languages
        .skip(1)
        .map((language) => language.englishName)
        .toList();
    final sorted = List<String>.of(names)..sort();
    expect(names, sorted);
  });
}
