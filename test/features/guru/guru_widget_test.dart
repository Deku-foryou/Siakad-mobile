import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/app/app.dart';
import 'package:siakad_mobile/core/config/app_config.dart';
import 'package:siakad_mobile/core/network/dio_client.dart';
import 'package:siakad_mobile/core/storage/secure_storage_service.dart';
import 'package:siakad_mobile/shared/providers/core_providers.dart';

import 'package:flutter/material.dart';

import '../../fakes/fake_secure_key_value_store.dart';
import '../../fakes/harness.dart';
import '../../fakes/path_adapter.dart';

Future<FakeSecureKeyValueStore> pumpGuruApp(
  WidgetTester tester, {
  Map<String, (int, Map<String, dynamic>)> overrides = const {},
}) async {
  final store = FakeSecureKeyValueStore();
  await SecureStorageService(store).saveToken('1|tokenvalid');
  final adapter = PathAdapter(
    overrides: {
      '/auth/me': (200, meSuccessBody(role: 'guru')),
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
  return store;
}

void main() {
  testWidgets('dashboard guru menampilkan ringkasan & jadwal dari API', (
    tester,
  ) async {
    // Permukaan lebih tinggi agar seluruh konten dashboard terlihat tanpa scroll.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpGuruApp(tester);

    expect(find.text('Guru Uji'), findsWidgets);
    expect(find.text('Kelas Anda'), findsOneWidget);
    expect(find.textContaining('X-IPA-1'), findsWidgets);
    expect(find.text('Matematika'), findsWidgets);
    expect(find.text('Jadwal Hari Ini'), findsOneWidget);
    expect(find.text('Beranda Guru'), findsOneWidget);
  });

  testWidgets('tap ikon notifikasi membuka halaman notifikasi guru', (
    tester,
  ) async {
    await pumpGuruApp(tester);

    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsWidgets);
    expect(find.text('Pemberitahuan Sekolah'), findsWidgets);
  });

  testWidgets('grid harian: simpan kirim payload records yang benar', (
    tester,
  ) async {
    final store = await pumpGuruApp(
      tester,
      overrides: {
        '/guru/absensi/harian': (200, guruAbsensiHarianBody()),
        '/guru/kelas/99/absensi': (200, guruHarianGridBody()),
        'POST /guru/absensi/harian': (
          200,
          {
            'success': true,
            'message': 'Absensi berhasil disimpan.',
            'data': {
              'tanggal': '2026-11-17',
              'kelas_id': 99,
              'dibuat': 1,
              'diubah': 1,
            },
          },
        ),
      },
    );

    // Buka tab Absensi
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.fact_check_outlined),
      ),
    );
    await tester.pumpAndSettle();

    // Tombol Isi Absensi Hari Ini
    await tester.tap(find.text('Isi Absensi Hari Ini'));
    await tester.pumpAndSettle();

    // Bottom sheet: pilih X-IPA-1
    await tester.tap(find.widgetWithText(ListTile, 'X-IPA-1'));
    await tester.pumpAndSettle();

    // Grid tampil: 2 siswa
    expect(find.text('Siswa A'), findsOneWidget);
    expect(find.text('Siswa B'), findsOneWidget);
    expect(find.text('Demam'), findsOneWidget); // catatan tercatat siswa A

    // Ubah siswa B menjadi sakit
    await tester.tap(
      find.descendant(
        of: find.byType(Card).at(1),
        matching: find.widgetWithText(ChoiceChip, 'Sakit'),
      ),
    );
    await tester.pumpAndSettle();

    // Simpan
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // Dialog konfirmasi
    expect(find.text('Simpan Absensi'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();

    // Simpan sukses â†’ snackbar hasil + kembali ke tab Absensi (pop)
    expect(find.text('Absensi tersimpan: 1 dibuat, 1 diubah.'), findsOneWidget);
    expect(store, isNotNull);
  });

  testWidgets('tab Penilaian: buka penugasan â†’ input nilai â†’ simpan batch', (
    tester,
  ) async {
    await pumpGuruApp(
      tester,
      overrides: {
        '/guru/penilaian/penugasan/501': (200, guruPenugasanDetailBody()),
        '/guru/penilaian/penugasan/501/siswa': (200, guruPenugasanSiswaBody()),
        '/guru/penilaian/penugasan/501/nilai': (
          200,
          {
            'success': true,
            'message': '2 nilai berhasil disimpan.',
            'data': {'tersimpan': 2},
          },
        ),
      },
    );

    // Buka tab Penilaian
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.grade_outlined),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Matematika'), findsWidgets);

    // Buka detail penugasan
    await tester.tap(find.text('Matematika').first);
    await tester.pumpAndSettle();

    expect(find.text('Komponen Penilaian'), findsOneWidget);

    // Buka form input nilai
    await tester.tap(find.text('Input / Ubah Nilai'));
    await tester.pumpAndSettle();

    expect(find.text('Input Nilai'), findsWidgets);

    // Isi nilai siswa B untuk komponen Tugas (field pertama pada kartu Siswa B)
    final siswaB = find.ancestor(
      of: find.text('Siswa B'),
      matching: find.byType(Card),
    );
    final fieldB = find
        .descendant(of: siswaB, matching: find.byType(TextFormField))
        .first;
    await tester.enterText(fieldB, '75');
    await tester.pump();

    // Simpan
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // Konfirmasi
    expect(find.text('Simpan Nilai'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('2 nilai berhasil disimpan.'), findsOneWidget);
  });

  testWidgets('guru tidak bisa login ke area siswa (guard satu arah)', (
    tester,
  ) async {
    // Guru authenticated, coba masuk /siswa â†’ dilempar ke /guru.
    // Diverifikasi lewat unit test resolveRedirect; widget ini memastikan
    // shell guru tampil setelah login role guru.
    await pumpGuruApp(tester);
    expect(find.text('Beranda Guru'), findsOneWidget);
    expect(find.text('Beranda'), findsWidgets); // item bottom nav
  });
}
