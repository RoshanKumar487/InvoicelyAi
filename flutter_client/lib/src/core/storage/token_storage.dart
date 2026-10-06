import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _tokenKey = 'invoicely_jwt';
  static const _storage = FlutterSecureStorage();

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readValue(String key) => _storage.read(key: key);

  Future<void> writeValue(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> deleteValue(String key) => _storage.delete(key: key);

  Future<void> clearToken() async {
    final values = await _storage.readAll();
    for (final key in values.keys) {
      if (key == _tokenKey ||
          key.startsWith('invoicely_cache_') ||
          key.startsWith('invoicely_ai_chat_')) {
        await _storage.delete(key: key);
      }
    }
  }
}
