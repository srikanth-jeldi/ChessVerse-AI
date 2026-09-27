import 'package:chessverse_ai/core/app_language.dart';
import 'package:chessverse_ai/core/notifications/firebase_push_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'social, challenge and analysis pushes follow every selected language',
    () {
      for (final AppLanguage language in AppLanguageController.supported.where(
        (AppLanguage item) =>
            item.code != AppLanguageController.systemCode && item.code != 'en',
      )) {
        final challenge = localizePushCopy(
          actionType: 'CHALLENGE',
          title: 'New chess challenge',
          body: 'Maya challenged you to a 10 minute match.',
          languageCode: language.code,
        );
        final friend = localizePushCopy(
          actionType: 'FRIEND_ONLINE',
          title: 'Friend online',
          body: 'Maya is online now.',
          languageCode: language.code,
        );
        final analysis = localizePushCopy(
          actionType: 'ANALYSIS',
          title: 'Analysis complete',
          body: 'Your review is ready.',
          languageCode: language.code,
        );

        expect(
          challenge.$1,
          isNot('New chess challenge'),
          reason: language.code,
        );
        expect(
          challenge.$2,
          isNot(contains('Play a live opponent')),
          reason: language.code,
        );
        expect(friend.$1, isNot('Friend online'), reason: language.code);
        expect(
          friend.$2,
          isNot(contains('Your game is ready')),
          reason: language.code,
        );
        expect(analysis.$1, isNot('Analysis complete'), reason: language.code);
        expect(
          analysis.$2,
          isNot('Your review is ready.'),
          reason: language.code,
        );
      }
    },
  );
}
