import 'dart:async';

import 'package:chessverse_ai/core/notifications/daily_reminder_service.dart';
import 'package:chessverse_ai/features/notifications/data/notification_api.dart';
import 'package:chessverse_ai/features/notifications/presentation/notification_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    expect(NotificationOpenRequest.decode('{"actionType":1}'), isNull);
    expect(
      NotificationOpenRequest.decode('{"actionType":"MATCH","actionId":1}')
          ?.actionId,
      isNull,
    );
  });

  test('legacy and current social actions preserve the exact target', () {
    const cases = {
      'friend_request': 0,
      'challenge_received': 0,
      'club_invite': 1,
      'tournament_registered': 2,
      'tournament_rescheduled': 2,
      'message_received': 3,
    };
    for (final entry in cases.entries) {
      final request = NotificationOpenRequest.fromData(
        actionType: ' ',
        actionId: ' target-42 ',
        fallbackType: entry.key,
      );
      expect(request.communitySection, entry.value);
      expect(request.actionId, 'target-42');
    }
    final request = NotificationOpenRequest.fromData(
      actionType: ' Match ',
      actionId: 'board-42',
      fallbackType: 'TOURNAMENT_MATCH_READY',
    );
    expect(request.actionType, 'MATCH');
    expect(request.actionId, 'board-42');
  });

  testWidgets('inbox tap routes while marking read fails in background', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'auth.token': 'test-token',
      'auth.expiresAt': DateTime.now().toUtc().add(const Duration(days: 1))
          .toIso8601String(),
      'auth.displayName': 'Test Player',
    });
    final api = _DelayedReadApi();
    final opened = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            child: const Text('Open inbox'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotificationCenterScreen(
                  api: api,
                  onAction: (item) async {
                    opened.add(item.actionId);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open inbox'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tournament reminder'));
    await tester.pumpAndSettle();
    expect(opened, ['tournament-42']);
    expect(api.pendingRead.isCompleted, isFalse);
    expect(find.text('Open inbox'), findsOneWidget);
    api.pendingRead.completeError(const NotificationException('Offline'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class _DelayedReadApi extends NotificationApi {
  final pendingRead = Completer<NotificationInboxDto>();

  @override
  Future<NotificationInboxDto> load(String token) async => NotificationInboxDto(
    unreadCount: 1,
    notifications: [
      PlayerNotificationDto(
        id: 'notification-1',
        type: 'TOURNAMENT_REMINDER',
        title: 'Tournament reminder',
        body: 'Your event starts soon.',
        actionType: 'TOURNAMENT',
        actionId: 'tournament-42',
        createdAt: DateTime.now(),
        read: false,
      ),
    ],
  );

  @override
  Future<NotificationInboxDto> read(String token, String id) =>
      pendingRead.future;
}
