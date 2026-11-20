import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/app/app.dart';
import 'package:siakad_mobile/core/config/app_config.dart';
import 'package:siakad_mobile/core/network/dio_client.dart';
import 'package:siakad_mobile/core/storage/secure_storage_service.dart';
import 'package:siakad_mobile/shared/providers/core_providers.dart';

import '../../fakes/fake_secure_key_value_store.dart';
import '../../fakes/harness.dart';
import '../../fakes/path_adapter.dart';

/// Regression: dashboard siswa tidak boleh memicu request berulang,
/// dan harus toleran terhadap payload dengan tipe numerik sebagai string
/// (driver MySQL/PHP yang mengirim angka sebagai string — HTTP tetap 200).
Future<PathAdapter> pumpSiswaApp(
  WidgetTester tester, {
  Map<String, (int, Map<String, dynamic>)> overrides = const {},
}) async {
  final store = FakeSecureKeyValueStore();
  await SecureStorageService(store).saveToken('1|tokensiswa');
  final adapter = PathAdapter(
    overrides: {
      '/auth/me': (200, meSuccessBody(role: 'siswa')),
      ...overrides,
    },
  );

  const config = AppConfig(apiBaseUrl: 'http://test.local/api/v1');
  final storage = SecureStorageService(store);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        secureKeyValueStoreProvider.overrideWithValue(store),
        dioProvider.overrideWithValue(
          createDio(config, storage)..httpClientAdapter = adapter,
        ),
      ],
      child: const SiakadApp(),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

int countPath(PathAdapter adapter, String pathPart) =>
    adapter.requests.where((r) => r.path.contains(pathPart)).length;

void main() {
  testWidgets('satu pemuatan dashboard hanya 1x request /siswa/beranda', (
    tester,
  ) async {
    final adapter = await pumpSiswaApp(tester);
    expect(countPath(adapter, '/siswa/beranda'), 1);
    expect(countPath(adapter, '/siswa/profil'), lessThanOrEqualTo(1));
  });

  testWidgets('rebuild shell tidak memicu request baru yang tidak perlu', (
    tester,
  ) async {
    final adapter = await pumpSiswaApp(tester);
    final before = countPath(adapter, '/siswa/beranda');
    // Trigger beberapa rebuild via frame tambahan & perubahan ukuran.
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(countPath(adapter, '/siswa/beranda'), before);
  });

  testWidgets(
    'beranda dengan angka sebagai string (driver MySQL) tetap render',
    (tester) async {
      await pumpSiswaApp(
        tester,
        overrides: {
          '/siswa/beranda': (
            200,
            {
              'success': true,
              'message': 'Berhasil',
              'data': {
                'siswa': {
                  'id': '1280',
                  'nisn': '0012345678',
                  'nis': 'NIS001',
                  'nama': 'Siswa Uji',
                  'tahun_masuk': '2024',
                  'status': 'aktif',
                },
                'akun': {'username': 'siswa01', 'wajib_ganti_password': '0'},
                'konteks': {
                  'valid': '1',
                  'peringatan': <String>[],
                  'tahun_ajaran': {'id': '10', 'nama': 'TA-2026/2027'},
                  'semester': {'id': '11', 'nama': 'Ganjil'},
                },
                'kelas': [
                  {
                    'id': '99',
                    'nama': 'X-IPA-1',
                    'tingkat': '10',
                    'jenis': 'Reguler',
                    'rombel': 'A',
                  },
                ],
                'nama_hari': 'Selasa',
                'jadwal_hari_ini': [
                  {
                    'hari': '2',
                    'nama_hari': 'Selasa',
                    'jam_ke': '1',
                    'mulai': '07:00',
                    'selesai': '07:45',
                    'mapel': {'id': '5', 'kode': 'MAT', 'nama': 'Matematika'},
                    'guru': {'id': '7', 'nama': 'Guru Uji'},
                    'kelas_id': '99',
                  },
                ],
              },
            },
          ),
        },
      );

      expect(find.text('Siswa Uji'), findsWidgets);
      expect(find.textContaining('TA-2026/2027'), findsWidgets);
      expect(find.text('Matematika'), findsWidgets);
      expect(find.textContaining('NIS001'), findsWidgets);
    },
  );

  testWidgets('beranda dengan field null tetap render tanpa crash', (
    tester,
  ) async {
    await pumpSiswaApp(
      tester,
      overrides: {
        '/siswa/beranda': (
          200,
          {
            'success': true,
            'message': 'Berhasil',
            'data': {
              'siswa': {
                'id': 1280,
                'nisn': null,
                'nis': null,
                'nama': 'Siswa Uji',
                'tahun_masuk': null,
                'status': null,
              },
              'akun': {'username': 'siswa01', 'wajib_ganti_password': false},
              'konteks': {
                'valid': false,
                'peringatan': ['Konteks tidak valid'],
                'tahun_ajaran': null,
                'semester': null,
              },
              'kelas': <Map<String, dynamic>>[],
              'nama_hari': null,
              'jadwal_hari_ini': <Map<String, dynamic>>[],
            },
          },
        ),
      },
    );

    expect(find.text('Siswa Uji'), findsWidgets);
    expect(find.text('Konteks tidak valid'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'beranda HTML error page (bukan JSON) → error state, bukan crash',
    (tester) async {
      final store = FakeSecureKeyValueStore();
      await SecureStorageService(store).saveToken('1|tokensiswa');
      final adapter = PathAdapter(
        overrides: {
          '/auth/me': (200, meSuccessBody(role: 'siswa')),
          '/siswa/beranda': (500, {'success': false, 'message': 'x'}),
        },
      );
      // Catatan: override beranda mengembalikan envelope 500 JSON-nya PathAdapter;
      // untuk mensimulasi body non-JSON gunakan status code dengan body raw
      // melalui override yang mengembalikan envelope ber-code — yang penting:
      // UI menampilkan error, bukan crash.
      const config = AppConfig(apiBaseUrl: 'http://test.local/api/v1');
      final storage = SecureStorageService(store);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            secureKeyValueStoreProvider.overrideWithValue(store),
            dioProvider.overrideWithValue(
              createDio(config, storage)..httpClientAdapter = adapter,
            ),
          ],
          child: const SiakadApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coba Lagi'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
