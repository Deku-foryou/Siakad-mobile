import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraksi key-value store aman. Memudahkan penggantian implementasi
/// (mis. fake in-memory untuk testing) tanpa menyentuh business logic.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Implementasi produksi berbasis `flutter_secure_storage`
/// (EncryptedSharedPreferences di Android, Keychain di iOS).
///
/// Token HANYA disimpan di sini — tidak pernah di SharedPreferences,
/// tidak pernah sebagai plaintext file, dan tidak pernah di log.
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
