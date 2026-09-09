import 'package:chessverse_ai/core/notifications/daily_reminder_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('reminders use the device IANA identifier from timezone v5', () async {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const zoneChannel = MethodChannel('flutter_timezone');
    const notifications = MethodChannel('dexterous.com/flutter/local_notifications');
    messenger.setMockMethodCallHandler(zoneChannel, (_) async => {
      'identifier': 'Asia/Kolkata',
    });
    messenger.setMockMethodCallHandler(notifications, (call) async =>
      call.method == 'initialize' ? true : null);
    addTearDown(() {
      messenger.setMockMethodCallHandler(zoneChannel, null);
      messenger.setMockMethodCallHandler(notifications, null);
    });
    await DailyReminderService.instance.initialize();
    expect(tz.local.name, 'Asia/Kolkata');
  });
}
