import 'package:chessverse_ai/features/tutorial/data/academy_progress_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('academy completion is isolated between signed-in accounts', () async {
    final DateTime expiry = DateTime.now().toUtc().add(const Duration(days: 1));
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth.token': 'account-a-token',
      'auth.expiresAt': expiry.toIso8601String(),
      'auth.displayName': 'Account A',
      'auth.username': 'account-a',
      'auth.email': 'a@example.com',
      'auth.rememberMe': 'true',
      'auth.isGuest': 'false',
    });
    const AcademyProgressStore store = AcademyProgressStore();
    const FlutterSecureStorage storage = FlutterSecureStorage();

    await store.markCompleted('pawn');
    expect(await store.readCompleted(), contains('pawn'));

    await storage.write(key: 'auth.token', value: 'account-b-token');
    await storage.write(key: 'auth.displayName', value: 'Account B');
    await storage.write(key: 'auth.username', value: 'account-b');
    await storage.write(key: 'auth.email', value: 'b@example.com');
    expect(await store.readCompleted(), isEmpty);

    await storage.write(key: 'auth.token', value: 'account-a-token');
    await storage.write(key: 'auth.displayName', value: 'Account A');
    await storage.write(key: 'auth.username', value: 'account-a');
    await storage.write(key: 'auth.email', value: 'a@example.com');
    expect(await store.readCompleted(), contains('pawn'));
  });

  test('identity hashing is stable and does not expose the email', () {
    final String key = AcademyProgressStore.identityHash(
      'account:private@example.com',
    );
    expect(key, hasLength(8));
    expect(key, isNot(contains('private')));
    expect(
      key,
      AcademyProgressStore.identityHash('account:private@example.com'),
    );
  });

  test('cloud lesson merge is written into the active account scope', () async {
    final DateTime expiry = DateTime.now().toUtc().add(const Duration(days: 1));
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth.token': 'cloud-token',
      'auth.expiresAt': expiry.toIso8601String(),
      'auth.displayName': 'Cloud Player',
      'auth.username': 'cloud-player',
      'auth.email': 'cloud@example.com',
      'auth.rememberMe': 'true',
      'auth.isGuest': 'false',
    });
    const AcademyProgressStore store = AcademyProgressStore();
    await store.writeCompleted(<String>{'pawn', 'rook'});

    expect(await store.readCompleted(), <String>{'pawn', 'rook'});
  });
}
