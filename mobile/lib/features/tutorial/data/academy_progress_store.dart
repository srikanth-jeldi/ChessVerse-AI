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
    await _recordPractice(lessonId, DateTime.now().toUtc());
    LocalGameArchive.markAcademyLessonComplete(lessonId);
    return completed;
  }

  Future<Map<String, DateTime>> readLastPracticed() async {
    final String stored = await preferences.readString(
      '${await _storageKey()}.practice',
      fallback: '',
    );
    final Map<String, DateTime> result = <String, DateTime>{};
    for (final String item in stored.split(',')) {
      final int separator = item.indexOf(':');
      if (separator < 1) continue;
      final DateTime? date = DateTime.tryParse(item.substring(separator + 1));
      if (date != null) result[item.substring(0, separator)] = date.toUtc();
    }
    return result;
  }

  Future<void> _recordPractice(String lessonId, DateTime practicedAt) async {
    final Map<String, DateTime> values = await readLastPracticed();
    values[lessonId] = DateTime.utc(
      practicedAt.year,
      practicedAt.month,
      practicedAt.day,
    );
    final List<String> encoded = values.entries
        .map((MapEntry<String, DateTime> entry) =>
            '${entry.key}:${entry.value.toIso8601String()}')
        .toList()
      ..sort();
    await preferences.writeString(
      '${await _storageKey()}.practice',
      encoded.join(','),
    );
    final Set<String> activity = await _readActivityDays();
    activity.add(values[lessonId]!.toIso8601String());
    final List<String> recent = activity.toList()..sort();
    await preferences.writeString(
      '${await _storageKey()}.activity',
      recent.skip(recent.length > 60 ? recent.length - 60 : 0).join(','),
    );
  }

  Future<Set<String>> _readActivityDays() async => (await preferences.readString(
        '${await _storageKey()}.activity',
        fallback: '',
      ))
          .split(',')
          .where((String value) => value.isNotEmpty)
          .toSet();

  Future<List<String>> readReviewDue({DateTime? now}) async {
    final DateTime today = (now ?? DateTime.now()).toUtc();
    final Map<String, int> mastery = await readMastery();
    final Map<String, DateTime> practiced = await readLastPracticed();
    final List<String> due = <String>[];
    for (final MapEntry<String, int> entry in mastery.entries) {
      final DateTime? last = practiced[entry.key];
      if (last == null) continue;
      final int intervalDays = switch (entry.value) { 1 => 1, 2 => 3, _ => 7 };
      if (!last.add(Duration(days: intervalDays)).isAfter(today)) {
        due.add(entry.key);
      }
    }
    due.sort((String a, String b) {
      final int starOrder = (mastery[a] ?? 1).compareTo(mastery[b] ?? 1);
      if (starOrder != 0) return starOrder;
      return practiced[a]!.compareTo(practiced[b]!);
    });
    return due;
  }

  Future<int> readLearningStreak({DateTime? now}) async {
    final Set<DateTime> days = (await _readActivityDays())
        .map(DateTime.parse)
        .map((DateTime date) => date.toUtc())
        .toSet();
    DateTime cursor = (now ?? DateTime.now()).toUtc();
    cursor = DateTime.utc(cursor.year, cursor.month, cursor.day);
    if (!days.contains(cursor) && days.contains(cursor.subtract(const Duration(days: 1)))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    int streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
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

  Future<Set<String>> readCertificates() async => (await preferences.readString(
        '${await _storageKey()}.certificates',
        fallback: '',
      ))
          .split(',')
          .where((String value) => value.isNotEmpty)
          .toSet();

  Future<Set<String>> awardCertificate(String courseId) async {
    final Set<String> certificates = await readCertificates()..add(courseId);
    await preferences.writeString(
      '${await _storageKey()}.certificates',
      (certificates.toList()..sort()).join(','),
    );
    return certificates;
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
