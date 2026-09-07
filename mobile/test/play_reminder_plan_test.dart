import 'package:chessverse_ai/core/notifications/daily_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('first reminder follows eight hours of inactivity', () {
    final tz.Location location = tz.getLocation('Asia/Kolkata');
    final tz.TZDateTime activity = tz.TZDateTime(location, 2026, 9, 7, 9);
    final List<tz.TZDateTime> plan = buildPlayReminderPlan(activity);

    expect(plan, hasLength(28));
    expect(plan.first, tz.TZDateTime(location, 2026, 9, 7, 17));
    expect(plan[1], tz.TZDateTime(location, 2026, 9, 7, 19));
  });

  test('quiet-hours reminders move to eight in the morning', () {
    final tz.Location location = tz.getLocation('Asia/Kolkata');
    final tz.TZDateTime activity = tz.TZDateTime(location, 2026, 9, 7, 18);
    final List<tz.TZDateTime> plan = buildPlayReminderPlan(activity);

    expect(plan.first, tz.TZDateTime(location, 2026, 9, 8, 8));
    expect(plan[1], tz.TZDateTime(location, 2026, 9, 8, 10));
    expect(
        plan.every((tz.TZDateTime value) => value.hour >= 8 && value.hour < 22),
        isTrue);
  });

  test('plan limits reminders to two per calendar day', () {
    final tz.Location location = tz.getLocation('Asia/Kolkata');
    final List<tz.TZDateTime> plan = buildPlayReminderPlan(
      tz.TZDateTime(location, 2026, 9, 7, 8),
    );
    final Map<String, int> perDay = <String, int>{};
    for (final tz.TZDateTime reminder in plan) {
      final String day = '${reminder.year}-${reminder.month}-${reminder.day}';
      perDay[day] = (perDay[day] ?? 0) + 1;
    }

    expect(perDay.values.every((int count) => count <= 2), isTrue);
  });
}
