import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum GuestFeature { review, mistakeBank }

/// A persistent per-installation guest trial. Account sign-in removes the gate;
/// network errors and empty results never call consume().
class GuestFeatureTrial {
  const GuestFeatureTrial();
  static const limit = 2;
  static const _storage = FlutterSecureStorage();
  static Future<void>? _tail;

  Future<bool> consume(String identity, GuestFeature feature) async {
    final previous = _tail;
    Future<bool> consumeLocked() async {
      final key = 'guest.trial.v1.$identity.${feature.name}';
      final used = int.tryParse(await _storage.read(key: key) ?? '') ?? 0;
      if (used >= limit) return false;
      await _storage.write(key: key, value: '${used + 1}');
      return true;
    }

    final work = previous == null
        ? consumeLocked()
        : previous.then((_) => consumeLocked());
    final tail = work.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _tail = tail;
    tail.then((_) {
      if (identical(_tail, tail)) _tail = null;
    });
    return work;
  }
}
