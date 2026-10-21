import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum GuestFeature { review, mistakeBank }

class GuestTrialStatus {
  const GuestTrialStatus(this.allowed, this.lockedUntil);
  final bool allowed;
  final DateTime? lockedUntil;
}

/// Device-local daily trials; a deferred login overrides daily resets for ten days.
class GuestFeatureTrial {
  const GuestFeatureTrial({this.now});
  final DateTime Function()? now;
  static const limit = 2;
  static const cooldown = Duration(days: 10);
  static const _storage = FlutterSecureStorage();
  static Future<void>? _tail;

  Future<T> _serial<T>(Future<T> Function() action) {
    final previous = _tail;
    final work = previous == null ? action() : previous.then((_) => action());
    final tail = work.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tail = tail;
    tail.then((_) {
      if (identical(_tail, tail)) _tail = null;
    });
    return work;
  }

  String _key(String identity, GuestFeature feature) =>
      'guest.trial.v2.$identity.${feature.name}';

  Future<GuestTrialStatus> attempt(
    String identity,
    GuestFeature feature,
  ) => _serial(() async {
    final current = (now ?? DateTime.now)();
    final day = DateTime(
      current.year,
      current.month,
      current.day,
    ).millisecondsSinceEpoch;
    final raw = await _storage.read(key: _key(identity, feature));
    final data = raw == null
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final later = data['later_clicked_timestamp'] as int?;
    final until = later == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(later).add(cooldown);
    if (until != null && current.isBefore(until)) {
      return GuestTrialStatus(false, until);
    }
    var used = (data['used'] as int?) ?? 0;
    final previousDay = (data['day'] as int?) ?? day;
    // An expired cooldown grants a fresh quota even on the same calendar day.
    if (until != null || day > previousDay) used = 0;
    if (used >= limit) return const GuestTrialStatus(false, null);
    await _storage.write(
      key: _key(identity, feature),
      value: jsonEncode({
        'day': day < previousDay ? previousDay : day,
        'used': used + 1,
      }),
    );
    return const GuestTrialStatus(true, null);
  });

  Future<bool> consume(String identity, GuestFeature feature) async =>
      (await attempt(identity, feature)).allowed;

  Future<DateTime> defer(String identity, GuestFeature feature) =>
      _serial(() async {
        final current = (now ?? DateTime.now)();
        final raw = await _storage.read(key: _key(identity, feature));
        final data = raw == null
            ? <String, dynamic>{}
            : jsonDecode(raw) as Map<String, dynamic>;
        final existing = data['later_clicked_timestamp'] as int?;
        if (existing != null) {
          final until = DateTime.fromMillisecondsSinceEpoch(existing)
              .add(cooldown);
          if (current.isBefore(until)) return until;
        }
        data['later_clicked_timestamp'] = current.millisecondsSinceEpoch;
        await _storage.write(
          key: _key(identity, feature),
          value: jsonEncode(data),
        );
        return current.add(cooldown);
      });
}
