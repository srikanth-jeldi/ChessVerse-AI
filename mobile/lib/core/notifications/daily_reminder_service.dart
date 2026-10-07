import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../academy_story_localizations.dart';
import '../app_language.dart';
import '../app_preferences.dart';
import '../live_coach_localizations.dart';
import 'tournament_reminder_localizations.dart';

@immutable
class NotificationOpenRequest {
  const NotificationOpenRequest({required this.actionType, this.actionId});

  final String actionType;
  final String? actionId;

  String encode() => jsonEncode(<String, String>{
    'actionType': actionType,
    if (actionId != null && actionId!.isNotEmpty) 'actionId': actionId!,
  });

  static NotificationOpenRequest? decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      final String actionType = (decoded['actionType'] as String? ?? '')
          .trim()
          .toUpperCase();
      if (actionType.isEmpty) return null;
      return NotificationOpenRequest(
        actionType: actionType,
        actionId: (decoded['actionId'] as String?)?.trim(),
      );
    } on FormatException {
      return null;
    }
  }
}

class DailyReminderService {
  DailyReminderService._();

  static final DailyReminderService instance = DailyReminderService._();
  static const int _notificationId = 7714;
  static const int _weeklyReportNotificationId = 7715;
  static const int _dailyPuzzleNotificationId = 7716;
  static const int _analysisReadyNotificationId = 7717;
  static const int _playReminderIdBase = 7720;
  static const int _scheduledPlayReminderCount = 28;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _enabled = false;
  static const AppPreferences _preferences = AppPreferences();
  static const String _activityKey = 'playReminderLastActivity';
  static const String _preferredHourKey = 'playReminderPreferredHour';
  bool _pendingPlayOpen = false;
  bool _pendingTournamentOpen = false;
  bool _pendingWeeklyReportOpen = false;
  final ValueNotifier<int> playOpenRequests = ValueNotifier<int>(0);
  final ValueNotifier<int> tournamentOpenRequests = ValueNotifier<int>(0);
  final ValueNotifier<int> weeklyReportOpenRequests = ValueNotifier<int>(0);
  final ValueNotifier<int> actionOpenRequests = ValueNotifier<int>(0);
  NotificationOpenRequest? _pendingActionOpen;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();
    try {
      final TimezoneInfo timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
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
    final NotificationAppLaunchDetails? launchDetails = await _plugin
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handleNotificationResponse(launchDetails!.notificationResponse!);
    }
    _initialized = true;
    AppLanguageController.effectiveLanguageChanges.addListener(
      _languageChanged,
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final NotificationOpenRequest? request = NotificationOpenRequest.decode(
      response.payload,
    );
    if (request != null) {
      openAction(request);
      return;
    }
    if (response.payload == 'open_play') {
      _pendingPlayOpen = true;
      playOpenRequests.value += 1;
    } else if (response.payload == 'open_tournaments') {
      _pendingTournamentOpen = true;
      tournamentOpenRequests.value += 1;
    } else if (response.payload == 'open_weekly_report') {
      _pendingWeeklyReportOpen = true;
      weeklyReportOpenRequests.value += 1;
    }
  }

  void openAction(NotificationOpenRequest request) {
    _pendingActionOpen = request;
    actionOpenRequests.value += 1;
  }

  NotificationOpenRequest? takePendingActionOpen() {
    final NotificationOpenRequest? request = _pendingActionOpen;
    _pendingActionOpen = null;
    return request;
  }

  bool get hasPendingPlayOpen => _pendingPlayOpen;

  bool takePendingPlayOpen() {
    if (!_pendingPlayOpen) return false;
    _pendingPlayOpen = false;
    return true;
  }

  bool get hasPendingTournamentOpen => _pendingTournamentOpen;

  bool takePendingTournamentOpen() {
    if (!_pendingTournamentOpen) return false;
    _pendingTournamentOpen = false;
    return true;
  }

  bool get hasPendingWeeklyReportOpen => _pendingWeeklyReportOpen;

  bool takePendingWeeklyReportOpen() {
    if (!_pendingWeeklyReportOpen) return false;
    _pendingWeeklyReportOpen = false;
    return true;
  }

  Future<bool> enable() async {
    if (kIsWeb) return false;
    await initialize();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final bool androidAllowed =
        await android?.requestNotificationsPermission() ?? true;
    final IOSFlutterLocalNotificationsPlugin? ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final bool iosAllowed =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    if (!androidAllowed || !iosAllowed) return false;

    _enabled = true;
    // Remove the legacy fixed 7 PM reminder when upgrading an installation.
    await _plugin.cancel(_notificationId);
    final String saved = await _preferences.readString(
      _activityKey,
      fallback: '',
    );
    final DateTime? previous = DateTime.tryParse(saved);
    final tz.TZDateTime activity = previous == null
        ? tz.TZDateTime.now(tz.local)
        : tz.TZDateTime.from(previous, tz.local);
    if (previous == null) {
      await _preferences.writeString(
        _activityKey,
        activity.toUtc().toIso8601String(),
      );
    }
    await _schedulePlayReminders(activity);
    await _scheduleDailyPuzzle(activity.hour);
    final String language = await AppLanguageController.effectiveCode();
    final AcademyStoryLocalizations academy = AcademyStoryLocalizations(
      language,
    );
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
      academy.text('report.title'),
      academy.text('report.empty'),
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
      payload: 'open_weekly_report',
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
    await _plugin.cancel(_dailyPuzzleNotificationId);
    await _cancelPlayReminders();
  }

  /// Resets the inactivity clock whenever the player opens Play or starts a
  /// game. Any unopened follow-up is cancelled immediately.
  Future<void> recordPlayOpened() async {
    if (kIsWeb || !_enabled) return;
    await initialize();
    final tz.TZDateTime activity = tz.TZDateTime.now(tz.local);
    await _preferences.writeString(
      _activityKey,
      activity.toUtc().toIso8601String(),
    );
    await _preferences.writeString(_preferredHourKey, '${activity.hour}');
    await _schedulePlayReminders(activity);
    await _scheduleDailyPuzzle(activity.hour);
  }

  Future<void> _cancelPlayReminders() async {
    for (int index = 0; index < _scheduledPlayReminderCount; index++) {
      await _plugin.cancel(_playReminderIdBase + index);
    }
  }

  Future<void> _schedulePlayReminders(tz.TZDateTime lastActivity) async {
    await _cancelPlayReminders();
    final String language = await AppLanguageController.effectiveCode();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final int elapsedDays = now.difference(lastActivity).inDays;
    final tz.TZDateTime anchor = elapsedDays > 1
        ? lastActivity.add(Duration(days: elapsedDays - 1))
        : lastActivity;
    final List<tz.TZDateTime> plan = buildPlayReminderPlan(anchor);
    for (int index = 0; index < plan.length; index++) {
      if (!plan[index].isAfter(now)) continue;
      final bool followUp = index.isOdd;
      await _plugin.zonedSchedule(
        _playReminderIdBase + index,
        followUp
            ? '${localizeLiveCoach('Your turn.', language)} ♟️'
            : '${localizeLiveCoach('ONLINE BATTLE', language)} ♟️',
        followUp
            ? localizeLiveCoach('Waiting for an online opponent.', language)
            : localizeLiveCoach('Play a live opponent', language),
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

  Future<void> _scheduleDailyPuzzle(int preferredHour) async {
    await _plugin.cancel(_dailyPuzzleNotificationId);
    final String language = await AppLanguageController.effectiveCode();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final int safeHour = preferredHour.clamp(8, 21);
    tz.TZDateTime next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      safeHour,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      _dailyPuzzleNotificationId,
      localizeLiveCoach('DAILY CHALLENGE', language),
      localizeLiveCoach('A new Daily Checkmate is ready.', language),
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_puzzle',
          'Daily puzzle',
          channelDescription: 'One daily puzzle at your preferred play time',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: const NotificationOpenRequest(actionType: 'DAILY_PUZZLE')
          .encode(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _languageChanged() {
    if (!_enabled) return;
    Future<void>(() async {
      final String saved = await _preferences.readString(
        _activityKey,
        fallback: '',
      );
      final DateTime? previous = DateTime.tryParse(saved);
      final tz.TZDateTime activity = previous == null
          ? tz.TZDateTime.now(tz.local)
          : tz.TZDateTime.from(previous, tz.local);
      final int preferredHour =
          int.tryParse(
            await _preferences.readString(
              _preferredHourKey,
              fallback: '${activity.hour}',
            ),
          ) ??
          activity.hour;
      await _schedulePlayReminders(activity);
      await _scheduleDailyPuzzle(preferredHour);
    });
  }

  Future<void> scheduleTournamentReminders({
    required String tournamentId,
    required String tournamentName,
    required DateTime startsAt,
  }) async {
    if (kIsWeb) return;
    await initialize();
    final int base = _tournamentNotificationBase(tournamentId);
    await cancelTournamentReminders(tournamentId);
    final tz.TZDateTime start = tz.TZDateTime.from(startsAt, tz.local);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final String language = await AppLanguageController.effectiveCode();
    const List<Duration> offsets = <Duration>[
      Duration(hours: 24),
      Duration(hours: 1),
      Duration(minutes: 10),
    ];
    for (int index = 0; index < offsets.length; index++) {
      final copy = localizeTournamentReminder(
        languageCode: language,
        tournamentName: tournamentName,
        reminderIndex: index,
      );
      final tz.TZDateTime when = start.subtract(offsets[index]);
      if (!when.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        base + index,
        copy.title,
        copy.body,
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'tournament_match_reminders',
            'Tournament and match reminders',
            channelDescription: 'Reminders for tournaments you registered for',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'open_tournaments',
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelTournamentReminders(String tournamentId) async {
    if (kIsWeb) return;
    await initialize();
    final int base = _tournamentNotificationBase(tournamentId);
    for (int index = 0; index < 3; index++) {
      await _plugin.cancel(base + index);
    }
  }

  int _tournamentNotificationBase(String value) {
    int hash = 17;
    for (final int unit in value.codeUnits) {
      hash = ((hash * 31) + unit) & 0x3fffffff;
    }
    return 100000 + (hash % 800000) * 3;
  }

  Future<void> showRealtime(
    int id,
    String title,
    String body, {
    String? actionType,
    String? actionId,
  }) async {
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
      payload: actionType == null || actionType.trim().isEmpty
          ? null
          : NotificationOpenRequest(
              actionType: actionType.trim().toUpperCase(),
              actionId: actionId,
            ).encode(),
    );
  }

  Future<void> showAnalysisReady() async {
    if (kIsWeb) return;
    await initialize();
    final String language = await AppLanguageController.effectiveCode();
    final AcademyStoryLocalizations copy = AcademyStoryLocalizations(language);
    await _plugin.show(
      _analysisReadyNotificationId,
      copy.text('report.title'),
      copy.text('report.empty'),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'analysis_complete',
          'AI analysis complete',
          channelDescription: 'Completed Stockfish and AI review alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'open_weekly_report',
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
    final tz.TZDateTime reminder = _outsideQuietHours(
      first.add(Duration(days: day)),
    );
    final tz.TZDateTime followUp = _outsideQuietHours(
      reminder.add(const Duration(hours: 2)),
    );
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
    return tz.TZDateTime(value.location, value.year, value.month, value.day, 8);
  }
  return value;
}
