import 'package:chessverse_ai/core/notifications/daily_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification action payload preserves destination and id', () {
    const NotificationOpenRequest original = NotificationOpenRequest(
      actionType: 'MATCH',
      actionId: 'match-42',
    );

    final NotificationOpenRequest? decoded = NotificationOpenRequest.decode(
      original.encode(),
    );

    expect(decoded?.actionType, 'MATCH');
    expect(decoded?.actionId, 'match-42');
  });

  test('notification action payload normalizes action names', () {
    final NotificationOpenRequest? decoded = NotificationOpenRequest.decode(
      '{"actionType":"daily_puzzle"}',
    );

    expect(decoded?.actionType, 'DAILY_PUZZLE');
    expect(decoded?.actionId, isNull);
  });

  test('invalid notification payload is ignored safely', () {
    expect(NotificationOpenRequest.decode(null), isNull);
    expect(NotificationOpenRequest.decode('open_play'), isNull);
    expect(
      NotificationOpenRequest.decode('{"actionId":"missing-type"}'),
      isNull,
    );
  });
}
