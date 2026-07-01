import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredAuthSession {
  const StoredAuthSession({
    required this.token,
    required this.expiresAt,
    required this.displayName,
  });

  final String token;
  final DateTime expiresAt;
  final String displayName;

  bool get isExpired => !expiresAt.isAfter(DateTime.now().toUtc());
}

class AuthSessionStore {
  const AuthSessionStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static const String _tokenKey = 'auth.token';
  static const String _expiryKey = 'auth.expiresAt';
  static const String _displayNameKey = 'auth.displayName';

  Future<StoredAuthSession?> read() async {
    final Map<String, String> values = await _storage.readAll();
    final String? token = values[_tokenKey];
    final DateTime? expiresAt = DateTime.tryParse(values[_expiryKey] ?? '');
    final String? displayName = values[_displayNameKey];
    if (token == null || expiresAt == null || displayName == null) {
      await clear();
      return null;
    }

    final StoredAuthSession session = StoredAuthSession(
      token: token,
      expiresAt: expiresAt.toUtc(),
      displayName: displayName,
    );
    if (session.isExpired) {
      await clear();
      return null;
    }
    return session;
  }

  Future<void> write(StoredAuthSession session) async {
    await Future.wait(<Future<void>>[
      _storage.write(key: _tokenKey, value: session.token),
      _storage.write(
        key: _expiryKey,
        value: session.expiresAt.toUtc().toIso8601String(),
      ),
      _storage.write(key: _displayNameKey, value: session.displayName),
    ]);
  }

  Future<void> clear() => _storage.deleteAll();
}
