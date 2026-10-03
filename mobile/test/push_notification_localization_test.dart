import 'package:flutter_test/flutter_test.dart';
import 'package:chessverse_ai/core/notifications/firebase_push_service.dart';

void main() {
  test('streak reminder follows the selected Telugu language', () {
    final (String, String) copy = localizePushCopy(
      actionType: 'STREAK_REMINDER_DAY_3',
      title: 'English server fallback',
      body: 'English server fallback',
      languageCode: 'te',
    );

    expect(copy.$1, contains('సీరియస్ ప్లేయర్'));
    expect(copy.$2, contains('3 రోజుల స్ట్రీక్'));
  });

  test('day seven milestone follows the selected Telugu language', () {
    final (String, String) copy = localizePushCopy(
      actionType: 'STREAK_MILESTONE',
      title: 'Congratulations, champ!',
      body: 'You completed a 7-day streak.',
      languageCode: 'te',
    );

    expect(copy.$1, contains('కాంగ్రాట్స్'));
    expect(copy.$2, contains('7 రోజుల స్ట్రీక్'));
  });
}
