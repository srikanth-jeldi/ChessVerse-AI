import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class StoredAuthSession {
  const StoredAuthSession({
    required this.token,
    required this.expiresAt,
    required this.displayName,
    this.username,
    this.email,
    this.photoUrl,
    this.isGuest = false,
    this.refreshToken,
    this.refreshExpiresAt,
    this.sessionId,
  });

  final String token;
  final DateTime expiresAt;
  final String displayName;
  final String? username;
  final String? email;
  final String? photoUrl;
  final bool isGuest;
  final String? refreshToken;
  final DateTime? refreshExpiresAt;
  final String? sessionId;

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
  static const String _isGuestKey = 'auth.isGuest';
  static const String _refreshTokenKey = 'auth.refreshToken';
  static const String _refreshExpiryKey = 'auth.refreshExpiresAt';
  static const String _sessionIdKey = 'auth.sessionId';
  static const String _installationIdKey = 'device.installationId';

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
      isGuest: values[_isGuestKey] == 'true',
      refreshToken: values[_refreshTokenKey],
      refreshExpiresAt:
          DateTime.tryParse(values[_refreshExpiryKey] ?? '')?.toUtc(),
      sessionId: values[_sessionIdKey],
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
      _storage.write(key: _isGuestKey, value: session.isGuest.toString()),
      _storage.write(key: _refreshTokenKey, value: session.refreshToken),
      _storage.write(
        key: _refreshExpiryKey,
        value: session.refreshExpiresAt?.toUtc().toIso8601String(),
      ),
      _storage.write(key: _sessionIdKey, value: session.sessionId),
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
      _storage.delete(key: _isGuestKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _refreshExpiryKey),
      _storage.delete(key: _sessionIdKey),
    ]);
  }

  Future<String> installationId() async {
    final String? existing = await _storage.read(key: _installationIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final String created = const Uuid().v4();
    await _storage.write(key: _installationIdKey, value: created);
    return created;
  }

  Future<String> progressIdentity(StoredAuthSession session) async {
    if (session.isGuest) {
      return 'guest:${await installationId()}';
    }
    final String account = session.email?.trim().toLowerCase() ??
        session.username?.trim().toLowerCase() ??
        session.displayName.trim().toLowerCase();
    return 'account:$account';
  }

  Future<void> clear() => clearSession();
}
