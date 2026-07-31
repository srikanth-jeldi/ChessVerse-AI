import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredAuthSession {
  const StoredAuthSession({
    required this.token,
    required this.expiresAt,
    required this.displayName,
    this.username,
    this.email,
    this.photoUrl,
  });

  final String token;
  final DateTime expiresAt;
  final String displayName;
  final String? username;
  final String? email;
  final String? photoUrl;

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
  static const String _usernameKey = 'auth.username';
  static const String _emailKey = 'auth.email';
  static const String _photoUrlKey = 'auth.photoUrl';
  static const String _rememberMeKey = 'auth.rememberMe';

  Future<StoredAuthSession?> read() async {
    final Map<String, String> values = await _storage.readAll();
    if (values[_rememberMeKey] == 'false') {
      await clearSession();
      return null;
    }
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
      username: values[_usernameKey],
      email: values[_emailKey],
      photoUrl: values[_photoUrlKey],
    );
    if (session.isExpired) {
      await clear();
      return null;
    }
    return session;
  }

  Future<bool> rememberMeEnabled() async {
    return await _storage.read(key: _rememberMeKey) != 'false';
  }

  Future<void> setRememberMe(bool value) {
    return _storage.write(key: _rememberMeKey, value: value.toString());
  }

  Future<void> write(StoredAuthSession session) async {
    await setRememberMe(true);
    // Write the token last. A partially written session is therefore never
    // treated as authenticated after an abrupt process termination.
    await Future.wait(<Future<void>>[
      _storage.write(
        key: _expiryKey,
        value: session.expiresAt.toUtc().toIso8601String(),
      ),
      _storage.write(key: _displayNameKey, value: session.displayName),
      _storage.write(key: _usernameKey, value: session.username),
      _storage.write(key: _emailKey, value: session.email),
      _storage.write(key: _photoUrlKey, value: session.photoUrl),
    ]);
    await _storage.write(key: _tokenKey, value: session.token);
  }

  Future<void> clearSession() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _expiryKey),
      _storage.delete(key: _displayNameKey),
      _storage.delete(key: _usernameKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _photoUrlKey),
    ]);
  }

  Future<void> clear() => clearSession();
}
