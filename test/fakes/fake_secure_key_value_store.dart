import 'package:siakad_mobile/core/storage/secure_key_value_store.dart';

/// Fake in-memory secure store untuk testing (bukan platform channel).
class FakeSecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}
