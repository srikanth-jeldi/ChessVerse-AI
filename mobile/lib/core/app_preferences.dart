import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppPreferences {
  const AppPreferences();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  Future<bool> readBool(String key, {required bool fallback}) async {
    final String? value = await _storage.read(key: 'settings.$key');
    return value == null ? fallback : value == 'true';
  }

  Future<String> readString(String key, {required String fallback}) async {
    return await _storage.read(key: 'settings.$key') ?? fallback;
  }

  Future<void> writeBool(String key, bool value) =>
      _storage.write(key: 'settings.$key', value: value.toString());

  Future<void> writeString(String key, String value) =>
      _storage.write(key: 'settings.$key', value: value);
}
