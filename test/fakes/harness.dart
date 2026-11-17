import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siakad_mobile/core/config/app_config.dart';
import 'package:siakad_mobile/core/network/dio_client.dart';
import 'package:siakad_mobile/core/storage/secure_storage_service.dart';
import 'package:siakad_mobile/shared/providers/core_providers.dart';

import 'fake_http_client_adapter.dart';
import 'fake_secure_key_value_store.dart';

/// Rakit ProviderContainer dengan dependency ter-fake:
/// secure storage in-memory + Dio dengan FakeHttpClientAdapter.
/// Tidak menyentuh platform channel / jaringan sungguhan.
({
  ProviderContainer container,
  FakeSecureKeyValueStore store,
  FakeHttpClientAdapter adapter,
})
buildTestHarness() {
  final store = FakeSecureKeyValueStore();
  final storage = SecureStorageService(store);
  final adapter = FakeHttpClientAdapter();

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        const AppConfig(apiBaseUrl: 'http://test.local/api/v1'),
      ),
      secureKeyValueStoreProvider.overrideWithValue(store),
      dioProvider.overrideWithValue(
        createDio(
          const AppConfig(apiBaseUrl: 'http://test.local/api/v1'),
          storage,
        )..httpClientAdapter = adapter,
      ),
    ],
  );

  return (container: container, store: store, adapter: adapter);
}

/// Buang event microtask sehingga Notifier.build() (yang memanggil
/// restoreSession lewat microtask) selesai.
Future<void> pumpMicrotasks([int times = 10]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Map<String, dynamic> loginSuccessBody({
  String token = '1|testtoken123',
  String role = 'siswa',
  bool wajibGantiPassword = false,
}) => {
  'success': true,
  'message': 'Login berhasil',
  'data': {
    'token': token,
    'token_type': 'Bearer',
    'expires_at': '2026-12-17T08:00:00+07:00',
    'wajib_ganti_password': wajibGantiPassword,
    'user': {
      'id': 1280,
      'name': 'Siswa Uji',
      'username': 'siswa01',
      'email': 'siswa@example.test',
      'level': role,
      'status_akun': 'aktif',
      'wajib_ganti_password': wajibGantiPassword,
    },
  },
};

Map<String, dynamic> meSuccessBody({
  String role = 'siswa',
  bool wajibGantiPassword = false,
}) => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'user': {
      'id': 1280,
      'name': 'Siswa Uji',
      'username': 'siswa01',
      'email': 'siswa@example.test',
      'level': role,
      'status_akun': 'aktif',
      'wajib_ganti_password': wajibGantiPassword,
    },
    'token': {
      'name': 'Flutter Android',
      'last_used_at': '2026-11-17T09:00:00+07:00',
      'expires_at': '2026-12-17T08:00:00+07:00',
    },
  },
};
