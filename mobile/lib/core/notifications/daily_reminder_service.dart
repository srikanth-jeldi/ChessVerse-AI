import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DailyReminderService {
  DailyReminderService._();

  static final DailyReminderService instance = DailyReminderService._();
  static const int _notificationId = 7714;
  static const int _weeklyReportNotificationId = 7715;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();
    try {
      final dynamic timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.name as String));
    } on Object {
      // tz.local remains UTC only when a platform cannot report its timezone;
      // Android and iOS normally always provide it.
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  Future<bool> enable() async {
    if (kIsWeb) return false;
    await initialize();
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool androidAllowed =
        await android?.requestNotificationsPermission() ?? true;
    final IOSFlutterLocalNotificationsPlugin? ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final bool iosAllowed = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
    if (!androidAllowed || !iosAllowed) return false;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime next =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      _notificationId,
      'Your board is waiting ♟️',
      'Come and play ChessVerseAI — keep your daily streak alive!',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_chess_reminder',
          'Daily chess reminder',
          channelDescription: 'A daily reminder to play ChessVerseAI',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    tz.TZDateTime weekly = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10,
    );
    while (weekly.weekday != DateTime.sunday || !weekly.isAfter(now)) {
      weekly = weekly.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _weeklyReportNotificationId,
      'Your weekly AI report is ready',
      'See your strongest skill, biggest weakness, and next 5-minute lesson.',
      weekly,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_ai_report',
          'Weekly AI improvement report',
          channelDescription:
              'One useful weekly summary of your ChessVerseAI progress',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    return true;
  }

  Future<void> disable() async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancel(_notificationId);
    await _plugin.cancel(_weeklyReportNotificationId);
  }

  Future<void> showRealtime(int id, String title, String body) async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'social_and_match_alerts',
          'Friends, challenges and community',
          channelDescription: 'Time-sensitive ChessVerseAI social and match alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
