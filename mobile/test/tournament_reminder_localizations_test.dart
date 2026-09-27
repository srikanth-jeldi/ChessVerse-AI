import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/notifications/tournament_reminder_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all three tournament reminders follow every selected language', () {
    for (final language in AppLanguageController.supported.where(
      (item) => item.code != AppLanguageController.systemCode,
    )) {
      for (int index = 0; index < 3; index++) {
        final copy = localizeTournamentReminder(
          languageCode: language.code,
          tournamentName: 'Hyderabad Royal Cup',
          reminderIndex: index,
        );
        expect(copy.title, startsWith('Hyderabad Royal Cup'));
        expect(copy.title.trim(), isNot('Hyderabad Royal Cup'));
        expect(copy.body.trim(), isNotEmpty);
        if (language.code != 'en') {
          expect(
            copy.title,
            isNot(contains('starts')),
            reason: '${language.code} reminder $index',
          );
          expect(
            copy.body,
            isNot(contains('tournament')),
            reason: '${language.code} reminder $index',
          );
        }
      }
    }
  });

  test('Telugu tournament reminder copy is complete', () {
    expect(
      localizeTournamentReminder(
        languageCode: 'te',
        tournamentName: 'హైదరాబాద్ రాయల్ కప్',
        reminderIndex: 2,
      ),
      (
        title: 'హైదరాబాద్ రాయల్ కప్ 10 నిమిషాల్లో ప్రారంభమవుతుంది',
        body: 'టోర్నమెంట్ బ్రాకెట్‌ను తెరిచి ఆడటానికి సిద్ధంగా ఉండండి.',
      ),
    );
  });
}
