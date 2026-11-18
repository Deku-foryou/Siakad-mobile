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

/// Pump aplikasi dengan sesi wali tersimpan.
Future<FakeSecureKeyValueStore> pumpWaliApp(
  WidgetTester tester, {
  Map<String, (int, Map<String, dynamic>)> overrides = const {},
}) async {
  final store = FakeSecureKeyValueStore();
  await SecureStorageService(store).saveToken('1|tokenwali');
  final withMe = <String, (int, Map<String, dynamic>)>{
    '/auth/me': (200, meSuccessBody(role: 'wali')),
    ...overrides,
  };
  final adapter = PathAdapter(overrides: withMe);

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
  return store;
}

void main() {
  testWidgets('shell wali: beranda menampilkan identitas & anak terhubung', (
    tester,
  ) async {
    await pumpWaliApp(tester);

    expect(find.text('Wali Uji'), findsWidgets);
    expect(find.text('Ringkasan Relasi'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Anak Terhubung'), 300);
    expect(find.text('Anak Terhubung'), findsOneWidget);
    expect(find.text('Andi Anak'), findsWidgets);
  });

  testWidgets('tab Anak: status pending terlihat, verified bisa diklik', (
    tester,
  ) async {
    await pumpWaliApp(tester);

    await tester.tap(find.text('Anak'));
    await tester.pumpAndSettle();

    expect(find.text('Anak Saya'), findsOneWidget);
    expect(find.text('Andi Anak'), findsWidgets);
    expect(find.text('Budi Anak'), findsWidgets);
    // Status relasi ditampilkan (verified & pending).
    expect(find.text('Terverifikasi'), findsWidgets);
    expect(find.text('Menunggu Verifikasi'), findsWidgets);
  });

  testWidgets('buka detail anak verified dari tab Anak', (tester) async {
    await pumpWaliApp(tester);

    await tester.tap(find.text('Anak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Andi Anak').first);
    await tester.pumpAndSettle();

    expect(find.text('Detail Anak'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Hubungan Anda'), 100);
    expect(find.text('Hubungan Anda'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Data Siswa'), 300);
    expect(find.text('Data Siswa'), findsOneWidget);
  });

  testWidgets('detail anak pending menampilkan status terkunci', (
    tester,
  ) async {
    await pumpWaliApp(tester);

    await tester.tap(find.text('Anak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budi Anak').first);
    await tester.pumpAndSettle();

    expect(find.text('Detail Anak'), findsOneWidget);
    // Tidak ada menu akademik/keuangan; banner penjelasan tampil.
    expect(find.text('Akademik'), findsNothing);
    expect(find.textContaining('menunggu verifikasi'), findsOneWidget);
  });

  testWidgets('tab Keuangan: tanpa anak verified → status informatif', (
    tester,
  ) async {
    await pumpWaliApp(
      tester,
      overrides: {
        '/wali/anak': (
          200,
          waliAnakListBody(
            anak: [
              {
                'relasi_id': 502,
                'hubungan': 'ibu',
                'status_hubungan': 'pending',
                'tanggal_mulai': '2026-09-01',
                'tanggal_berhenti': null,
                'tanggal_verifikasi': null,
                'bisa_akses_akademik': false,
                'kelas': 'VIII-A',
                'siswa': {
                  'id': 202,
                  'nisn': '002',
                  'nis': 'NIS202',
                  'nama': 'Budi Anak',
                  'jenis_kelamin': 'L',
                  'tahun_masuk': 2025,
                  'status': 'aktif',
                },
              },
            ],
          ),
        ),
      },
    );

    await tester.tap(find.text('Keuangan'));
    await tester.pumpAndSettle();

    expect(find.text('Belum Ada Anak Terverifikasi'), findsOneWidget);
  });

  testWidgets('tab Keuangan: dengan anak verified → ringkasan tampil', (
    tester,
  ) async {
    await pumpWaliApp(tester);

    await tester.tap(find.text('Keuangan'));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Kewajiban'), findsOneWidget);
    expect(find.textContaining('Data keuangan'), findsOneWidget);
  });
}
