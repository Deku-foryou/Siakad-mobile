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

Map<String, dynamic> berandaSuccessBody({
  String role = 'siswa',
  bool wajibGantiPassword = false,
}) => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'siswa': {
      'id': 1280,
      'nisn': '0012345678',
      'nis': 'NIS001',
      'nama': 'Siswa Uji',
      'tahun_masuk': 2024,
      'status': 'aktif',
    },
    'akun': {'username': 'siswa01', 'wajib_ganti_password': wajibGantiPassword},
    'konteks': {
      'valid': true,
      'peringatan': <String>[],
      'tahun_ajaran': {'id': 10, 'nama': 'TA-2026/2027'},
      'semester': {'id': 11, 'nama': 'Ganjil'},
    },
    'kelas': [
      {
        'id': 99,
        'nama': 'X-IPA-1',
        'tingkat': 'X',
        'jenis': 'Reguler',
        'rombel': 'A',
      },
    ],
    'nama_hari': 'Selasa',
    'jadwal_hari_ini': <Map<String, dynamic>>[],
  },
};

Map<String, dynamic> profilSuccessBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'id': 1280,
    'nisn': '0012345678',
    'nis': 'NIS001',
    'nama': 'Siswa Uji',
    'jenis_kelamin': 'L',
    'tahun_masuk': 2024,
    'status': 'aktif',
    'kelas': [
      {'id': 99, 'nama': 'X-IPA-1', 'tingkat': 'X'},
    ],
    'akun': {'username': 'siswa01', 'wajib_ganti_password': false},
  },
};

Map<String, dynamic> ringkasanKeuanganBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'total_kewajiban': 1500000,
    'total_dibayar': 500000,
    'sisa_kewajiban': 1000000,
    'saldo': 250000,
  },
};

Map<String, dynamic> tagihanListBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': <Map<String, dynamic>>[],
  'meta': {'current_page': 1, 'per_page': 15, 'last_page': 1, 'total': 0},
};

Map<String, dynamic> notifikasiListBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {'items': <Map<String, dynamic>>[], 'belum_dibaca': 0},
  'meta': {
    'current_page': 1,
    'per_page': 15,
    'last_page': 1,
    'total': 0,
    'from': null,
    'to': null,
  },
};

Map<String, dynamic> unreadCountBody({int count = 0}) => {
  'success': true,
  'message': 'Berhasil',
  'data': {'belum_dibaca': count},
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
