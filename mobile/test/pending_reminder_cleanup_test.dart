import 'package:chessverse_ai/core/notifications/pending_reminder_cleanup.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  var pendingIds = <int>[];

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    pendingIds = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'pendingNotificationRequests') {
        return [
          for (final id in pendingIds)
            {'id': id, 'title': 'Reminder', 'body': '', 'payload': ''},
        ];
      }
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'fresh install does not issue 28 unnecessary native cancellations',
    () async {
      await cancelObsoleteReminders(
        FlutterLocalNotificationsPlugin(),
        ownedIds: {for (var i = 0; i < 28; i++) 7720 + i},
      );
      expect(calls.map((c) => c.method), ['pendingNotificationRequests']);
    },
  );

  test('keeps replacement IDs and unrelated tournament reminders', () async {
    pendingIds = [7720, 7721, 7722, 100100];
    await cancelObsoleteReminders(
      FlutterLocalNotificationsPlugin(),
      ownedIds: {7720, 7721, 7722},
      retainedIds: {7721, 7722},
    );
    final cancellations = calls.where((c) => c.method == 'cancel');
    expect(cancellations.length, 1);
    expect((cancellations.single.arguments as Map)['id'], 7720);
  });

  test(
    'disable cancels every pending owned reminder but no unrelated IDs',
    () async {
      pendingIds = [7720, 7721, 100100];
      await cancelObsoleteReminders(
        FlutterLocalNotificationsPlugin(),
        ownedIds: {7720, 7721, 7722},
      );
      expect(
        calls
            .where((c) => c.method == 'cancel')
            .map((c) => (c.arguments as Map)['id']),
        [7720, 7721],
      );
    },
  );
}
