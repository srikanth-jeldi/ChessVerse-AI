import 'package:chessverse_ai/features/auth/data/auth_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('expired access token can be restored only for valid refresh', () async {
    final now = DateTime.now().toUtc();
    FlutterSecureStorage.setMockInitialValues({
      'auth.token': 'expired',
      'auth.displayName': 'Guest',
      'auth.expiresAt': now
          .subtract(const Duration(minutes: 1))
          .toIso8601String(),
      'auth.refreshToken': 'valid-refresh',
      'auth.refreshExpiresAt': now
          .add(const Duration(days: 1))
          .toIso8601String(),
    });
    const store = AuthSessionStore();
    expect(
      (await store.read(allowRefresh: true))?.refreshToken,
      'valid-refresh',
    );
    expect(await store.read(), isNull);
    expect((await store.read(allowRefresh: true))?.refreshToken, 'valid-refresh');
  });
  test(
    'activity recreation preserves a valid session; near expiry rotates',
    () {
      final now = DateTime.utc(2026, 10, 16);
      StoredAuthSession session(Duration remaining) => StoredAuthSession(
        token: 'token',
        expiresAt: now.add(remaining),
        displayName: 'Guest',
        refreshToken: 'refresh',
      );
      expect(session(const Duration(days: 29)).needsRefreshAt(now), false);
      expect(session(const Duration(minutes: 6)).needsRefreshAt(now), false);
      expect(session(const Duration(minutes: 5)).needsRefreshAt(now), true);
      expect(session(const Duration(seconds: -1)).needsRefreshAt(now), true);
    },
  );
}
