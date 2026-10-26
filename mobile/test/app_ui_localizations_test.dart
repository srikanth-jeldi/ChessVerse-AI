import 'dart:convert';

import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/app_ui_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all bundled languages retain keys and interpolation parameters', () async {
    final source = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString('assets/i18n/ui/en.json')) as Map,
    );
    final placeholders = RegExp(r'\{\d+\}');
    final brands = RegExp(r'ChessVerse(?:\s*AI)?', caseSensitive: false);
    for (final language in AppLanguageController.supported.where(
      (language) => language.code != 'system',
    )) {
      final catalog = Map<String, dynamic>.from(
        jsonDecode(
          await rootBundle.loadString('assets/i18n/ui/${language.code}.json'),
        ) as Map,
      );
      expect(catalog.keys.toSet(), source.keys.toSet(), reason: language.code);
      for (final entry in catalog.entries) {
        expect(entry.value, isA<String>());
        expect(
          (entry.value as String).trim(),
          isNotEmpty,
          reason: '${language.code}: ${entry.key}',
        );
        final expected =
            placeholders
                .allMatches(entry.key)
                .map((match) => match[0]!)
                .toList()
              ..sort();
        final actual =
            placeholders
                .allMatches(entry.value as String)
                .map((match) => match[0]!)
                .toList()
              ..sort();
        expect(actual, expected, reason: '${language.code}: ${entry.key}');
        final sourceBrands =
            brands.allMatches(entry.key).map((m) => m[0]!).toList()..sort();
        final translatedBrands =
            brands.allMatches(entry.value as String).map((m) => m[0]!).toList()
              ..sort();
        expect(
          translatedBrands,
          sourceBrands,
          reason:
              'Product name must stay unchanged: ${language.code}: ${entry.key}',
        );
      }
    }
  });

  test(
    'brand and uppercase wordmark fragments never translate in any locale',
    () async {
      for (final language in AppLanguageController.supported.where(
        (l) => l.code != 'system',
      )) {
        await UiCopy.load(language.code);
        expect(UiCopy.text('CHESSVERSE'), 'ChessVerse', reason: language.code);
        expect(
          UiCopy.text('ChessVerseAI'),
          'ChessVerseAI',
          reason: language.code,
        );
        expect(
          UiCopy.text('CHESSVERSE AI'),
          'ChessVerseAI',
          reason: language.code,
        );
      }
      await UiCopy.load('en');
    },
  );

  test('format preserves user values and chess notation without recursive replacement', () async {
    await UiCopy.load('en');
    expect(
      UiCopy.format('Player {0}: {1}', ['Name {1}', 'e2e4']),
      'Player Name {1}: e2e4',
    );
    expect(
      UiCopy.text('Unknown user supplied club'),
      'Unknown user supplied club',
    );
  });

  test('latest language request wins', () async {
    final first = UiCopy.load('te');
    final last = UiCopy.load('ar');
    await Future.wait([first, last]);
    expect(UiCopy.language.value, 'ar');
    await UiCopy.load('en');
    expect(UiCopy.text('Cancel'), 'Cancel');
  });
}
