import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/live_coach_localizations.dart';

void main() {
  test('daily counters and online statuses preserve all evidence', () {
    for (final language in liveCoachTranslations.keys.where((l) => l != 'en')) {
      final countdown = localizeLiveCoach(
          'Daily Checkmate complete. Next challenge unlocks in 8 hours 12 minutes 34 seconds.',
          language);
      for (final value in ['8', '12', '34']) {
        expect(countdown, contains(value));
      }
      expect(countdown, isNot(contains('Daily Checkmate')));
      final completion = localizeLiveCoach(
          "Brilliant! Today's easy - mate in 3 challenge is complete. A new Daily Checkmate is ready.",
          language);
      expect(completion, isNot(contains('easy')));
      expect(completion, isNot(contains('challenge is complete')));
      expect(
          localizeLiveCoach('Room CVDF6: waiting for your opponent.', language),
          contains('CVDF6'));
      expect(
          localizeLiveCoach(
              'Stockfish estimates a 1.7 pawn advantage for the side to move.',
              language),
          contains('1.7'));
      final move = localizeLiveCoach('Offline AI: N moves to f6.', language);
      expect(move, contains('N'));
      expect(move, contains('f6'));
      expect(move, isNot(contains('moves to')));
    }
  });
  test('narrative, hints and state rows cover all34 with exact placeholders',
      () {
    final placeholders = RegExp(r'\{[^}]+\}');
    final groups = {
      liveNarrativeKeys: liveNarrativeTranslations,
      liveHintKeys: liveHintTranslations,
      liveStateKeys: liveStateTranslations,
      liveDailyKeys: liveDailyTranslations,
      liveStatusKeys: liveStatusTranslations,
      liveMiniKeys: liveMiniTranslations,
      liveAnalysisSources: liveAnalysisTranslations,
      liveSheetKeys: liveSheetTranslations,
      liveResultKeys: liveResultTranslations,
    };
    for (final group in groups.entries) {
      for (final language in liveCoachTranslations.keys) {
        final row = group.value[language]!;
        expect(row.length, group.key.length, reason: language);
        for (var i = 0; i < row.length; i++) {
          expect(row[i], isNotEmpty);
          expect(
              placeholders.allMatches(row[i]).map((m) => m[0]).toSet(),
              placeholders
                  .allMatches(group.value['en']![i])
                  .map((m) => m[0])
                  .toSet(),
              reason: '$language ${group.key[i]}');
        }
      }
    }
  });
  test(
      'full local explanations translate all facts, including discovered check',
      () {
    const prose =
        'Good step - useful improvement. Bishop moved from e2 to c4. Discovered check: moving the bishop opened the rook attack from e1 onto the king at e8. The opponent must answer that revealed check. The bishop opens a diagonal; trace it until the first blocker.';
    for (final language in liveCoachTranslations.keys.where((l) => l != 'en')) {
      final output = localizeLiveCoach(prose, language);
      for (final square in ['e2', 'c4', 'e1', 'e8']) {
        expect(output, contains(square));
      }
      for (final english in [
        'Good step',
        'moved from',
        'Discovered check',
        'The opponent',
        'The bishop'
      ]) {
        expect(output, isNot(contains(english)), reason: language);
      }
    }
  });
  test('progressive hints and UI modes keep parameters in every locale', () {
    for (final language in liveCoachTranslations.keys.where((l) => l != 'en')) {
      final hint = localizeLiveCoach(
          'Hint 3/3 • Try e2 → e4. The pawn claims central space and opens lines for your pieces.',
          language);
      expect(hint, contains('e2 → e4'));
      expect(hint, isNot(contains('The pawn')));
      expect(localizeLiveCoach('PLAYER 2 • BLACK', language), contains('2'));
      expect(localizeLiveCoach('Checkmate in 3', language), contains('3'));
      expect(localizeLiveCoach('YOUR TURN', language), isNot('YOUR TURN'));
    }
  });
  test('every picker language has complete live-coach rows and parameters', () {
    final placeholders = RegExp(r'\{[^}]+\}');
    for (final language
        in AppLanguageController.supported.where((l) => l.code != 'system')) {
      final row = liveCoachTranslations[language.code]!;
      expect(row.length, liveCoachKeys.length, reason: language.code);
      for (var i = 0; i < row.length; i++) {
        expect(row[i], isNotEmpty);
        expect(
            placeholders.allMatches(row[i]).map((m) => m[0]).toSet(),
            placeholders
                .allMatches(liveCoachTranslations['en']![i])
                .map((m) => m[0])
                .toSet(),
            reason: '${language.code}: ${liveCoachKeys[i]}');
      }
    }
  });
  test('undo preserves piece, source and target count in every language', () {
    for (final language in liveCoachTranslations.keys) {
      final value =
          localizeLiveCoach('Move undone. Q from e4 has 17 options.', language);
      expect(value, contains('Q'));
      expect(value, contains('e4'));
      expect(value, contains('17'));
      if (language != 'en') expect(value, isNot(contains('Move undone.')));
    }
  });
  test('nudge and promotion keep notation; unknown prose stays untouched', () {
    for (final language in liveCoachTranslations.keys) {
      expect(
          localizeLiveCoach(
              'Need a nudge? Blue lights suggest d2 → d4. You can still choose any legal move.',
              language),
          contains('d2 → d4'));
      expect(localizeLiveCoach('Choose a promotion coin for a8.', language),
          contains('a8'));
      expect(localizeLiveCoach('Unrecognised user response', language),
          'Unrecognised user response');
    }
    expect(supportsLiveCoach('Move undone. Q from e4 has 17 options.'), isTrue);
    expect(supportsLiveCoach('Unrecognised user response'), isFalse);
  });
}
