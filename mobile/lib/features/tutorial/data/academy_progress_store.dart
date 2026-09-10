import '../../../core/app_preferences.dart';
import '../../../core/local_game_archive.dart';
import '../../auth/data/auth_session_store.dart';

class AcademyProgressStore {
  const AcademyProgressStore({
    this.preferences = const AppPreferences(),
    this.sessions = const AuthSessionStore(),
  });

  final AppPreferences preferences;
  final AuthSessionStore sessions;

  Future<Set<String>> readCompleted() async {
    final String stored = await preferences.readString(
      await _storageKey(),
      fallback: '',
    );
    return stored
        .split(',')
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet();
  }

  Future<Set<String>> markCompleted(String lessonId, {int stars = 1}) async {
    final Set<String> completed = (await readCompleted())..add(lessonId);
    await preferences.writeString(
      await _storageKey(),
      (completed.toList()..sort()).join(','),
    );
    final Map<String, int> mastery = await readMastery();
    final int safeStars = stars.clamp(1, 3);
    if ((mastery[lessonId] ?? 0) < safeStars) {
      mastery[lessonId] = safeStars;
      await _writeMastery(mastery);
    }
    LocalGameArchive.markAcademyLessonComplete(lessonId);
    return completed;
  }

  Future<Map<String, int>> readMastery() async {
    final String stored = await preferences.readString(
      '${await _storageKey()}.mastery',
      fallback: '',
    );
    return <String, int>{
      for (final String item in stored.split(','))
        if (item.contains(':'))
          item.split(':').first: int.tryParse(item.split(':').last) ?? 1,
    };
  }

  Future<void> _writeMastery(Map<String, int> mastery) async {
    final List<String> values = mastery.entries
        .map((MapEntry<String, int> entry) => '${entry.key}:${entry.value}')
        .toList()
      ..sort();
    await preferences.writeString(
      '${await _storageKey()}.mastery',
      values.join(','),
    );
  }

  Future<String?> readPlacement() async {
    final String value = await preferences.readString(
      '${await _storageKey()}.placement',
      fallback: '',
    );
    return value.isEmpty ? null : value;
  }

  Future<void> writePlacement(String level) async {
    await preferences.writeString(await _placementKey(level), level);
  }

  Future<String> _placementKey(String level) async {
    if (level != 'beginner' && level != 'intermediate') {
      throw ArgumentError.value(level, 'level');
    }
    return '${await _storageKey()}.placement';
  }

  Future<void> writeCompleted(Iterable<String> lessonIds) async {
    final List<String> completed = lessonIds.toSet().toList()..sort();
    await preferences.writeString(await _storageKey(), completed.join(','));
  }

  Future<void> clearCurrentIdentity() async {
    await preferences.writeString(await _storageKey(), '');
  }

  Future<String> _storageKey() async {
    final StoredAuthSession? session = await sessions.read();
    final String identity = session == null
        ? 'signed-out'
        : await sessions.progressIdentity(session);
    return 'academy.completed.v2.${identityHash(identity)}';
  }

  static String identityHash(String value) {
    int hash = 0x811C9DC5;
    for (final int byte in value.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
