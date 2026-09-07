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
  static const int _playReminderIdBase = 7720;
  static const int _scheduledPlayReminderCount = 28;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _enabled = false;
  bool _pendingPlayOpen = false;
  final ValueNotifier<int> playOpenRequests = ValueNotifier<int>(0);

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
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    final NotificationAppLaunchDetails? launchDetails =
        await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handleNotificationResponse(launchDetails!.notificationResponse!);
    }
    _initialized = true;
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.payload != 'open_play') return;
    _pendingPlayOpen = true;
    playOpenRequests.value += 1;
  }

  bool get hasPendingPlayOpen => _pendingPlayOpen;

  bool takePendingPlayOpen() {
    if (!_pendingPlayOpen) return false;
    _pendingPlayOpen = false;
    return true;
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

    _enabled = true;
    // Remove the legacy fixed 7 PM reminder when upgrading an installation.
    await _plugin.cancel(_notificationId);
    await _schedulePlayReminders(tz.TZDateTime.now(tz.local));
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
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
    _enabled = false;
    await _plugin.cancel(_notificationId);
    await _plugin.cancel(_weeklyReportNotificationId);
    await _cancelPlayReminders();
  }

  /// Resets the inactivity clock whenever the player opens Play or starts a
  /// game. Any unopened follow-up is cancelled immediately.
  Future<void> recordPlayOpened() async {
    if (kIsWeb || !_enabled) return;
    await initialize();
    await _schedulePlayReminders(tz.TZDateTime.now(tz.local));
  }

  Future<void> _cancelPlayReminders() async {
    for (int index = 0; index < _scheduledPlayReminderCount; index++) {
      await _plugin.cancel(_playReminderIdBase + index);
    }
  }

  Future<void> _schedulePlayReminders(tz.TZDateTime lastActivity) async {
    await _cancelPlayReminders();
    final List<tz.TZDateTime> plan = buildPlayReminderPlan(lastActivity);
    for (int index = 0; index < plan.length; index++) {
      final bool followUp = index.isOdd;
      await _plugin.zonedSchedule(
        _playReminderIdBase + index,
        followUp ? 'Your next move is waiting ♟️' : 'Let’s Play Chess ♟️',
        followUp
            ? 'A quick game is ready whenever you are.'
            : 'Challenge a rival, solve a puzzle, or continue your tournament.',
        plan[index],
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'play_inactivity_reminders',
            'Play reminders',
            channelDescription:
                'Helpful reminders after you have been away from ChessVerseAI',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'open_play',
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
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
          channelDescription:
              'Time-sensitive ChessVerseAI social and match alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

/// Builds fourteen days of spam-safe reminders. Each day contains one main
/// reminder and at most one follow-up. Quiet hours are 10 PM–8 AM.
List<tz.TZDateTime> buildPlayReminderPlan(tz.TZDateTime lastActivity) {
  tz.TZDateTime first = _outsideQuietHours(
    lastActivity.add(const Duration(hours: 8)),
  );
  final List<tz.TZDateTime> result = <tz.TZDateTime>[];
  for (int day = 0; day < 14; day++) {
    final tz.TZDateTime reminder =
        _outsideQuietHours(first.add(Duration(days: day)));
    final tz.TZDateTime followUp =
        _outsideQuietHours(reminder.add(const Duration(hours: 2)));
    result
      ..add(reminder)
      ..add(followUp);
  }
  return result;
}

tz.TZDateTime _outsideQuietHours(tz.TZDateTime value) {
  if (value.hour >= 22) {
    return tz.TZDateTime(
      value.location,
      value.year,
      value.month,
      value.day + 1,
      8,
    );
  }
  if (value.hour < 8) {
    return tz.TZDateTime(
      value.location,
      value.year,
      value.month,
      value.day,
      8,
    );
  }
  return value;
}
