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

  Future<Set<String>> markCompleted(String lessonId) async {
    final Set<String> completed = (await readCompleted())..add(lessonId);
    await preferences.writeString(
      await _storageKey(),
      (completed.toList()..sort()).join(','),
    );
    LocalGameArchive.markAcademyLessonComplete(lessonId);
    return completed;
  }

  Future<void> writeCompleted(Iterable<String> lessonIds) async {
    final List<String> completed = lessonIds.toSet().toList()..sort();
    await preferences.writeString(await _storageKey(), completed.join(','));
  }

  Future<String> _storageKey() async {
    final StoredAuthSession? session = await sessions.read();
    String identity;
    if (session == null) {
      identity = 'signed-out';
    } else if (session.isGuest) {
      identity = 'guest:${await sessions.installationId()}';
    } else {
      identity =
          'account:${session.email?.trim().toLowerCase() ?? session.username?.trim().toLowerCase() ?? session.displayName.trim().toLowerCase()}';
    }
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
