import '../../../core/app_preferences.dart';
import '../../auth/data/auth_session_store.dart';
import 'academy_progress_store.dart';

class OpeningProgressStore {
  static Future<String> identityKey() async {
    const sessions = AuthSessionStore();
    final session = await sessions.read();
    final identity = session == null
        ? 'signed-out'
        : await sessions.progressIdentity(session);
    return AcademyProgressStore.identityHash(identity);
  }

  static Future<void> complete(String line, bool white) async {
    await const AppPreferences().writeString(
      'opening.practice.${await identityKey()}.$line.$white',
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  static Future<bool> completedToday(
    String line,
    bool white,
    DateTime now,
  ) async {
    final raw = await const AppPreferences().readString(
      'opening.practice.${await identityKey()}.$line.$white',
      fallback: '',
    );
    final date = DateTime.tryParse(raw);
    return date != null &&
        date.toUtc().toIso8601String().substring(0, 10) ==
            now.toUtc().toIso8601String().substring(0, 10);
  }
}
