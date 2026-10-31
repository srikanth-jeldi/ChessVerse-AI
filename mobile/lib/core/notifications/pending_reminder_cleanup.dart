import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Cancel only obsolete scheduled reminders owned by this caller. Cancelling
/// absent IDs still asks Android for a PendingIntent through a binder call.
/// A schedule using the same ID replaces it, so retained IDs need no cancel.
Future<void> cancelObsoleteReminders(
  FlutterLocalNotificationsPlugin plugin, {
  required Set<int> ownedIds,
  Set<int> retainedIds = const <int>{},
}) async {
  final pending = await plugin.pendingNotificationRequests();
  final obsolete = pending
      .map((request) => request.id)
      .where((id) => ownedIds.contains(id) && !retainedIds.contains(id))
      .toSet();
  for (final id in obsolete) {
    await plugin.cancel(id);
  }
}
