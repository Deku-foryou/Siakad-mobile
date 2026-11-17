import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/app/app.dart';
import 'package:siakad_mobile/core/widgets/app_widgets.dart';
import 'package:siakad_mobile/core/config/app_config.dart';
import 'package:siakad_mobile/core/network/dio_client.dart';
import 'package:siakad_mobile/core/storage/secure_storage_service.dart';
import 'package:siakad_mobile/shared/providers/core_providers.dart';

import '../../fakes/fake_secure_key_value_store.dart';
import '../../fakes/harness.dart';
import '../../fakes/path_adapter.dart';

/// Pump the app dengan mock path-based; token siswa tersimpan.
Future<FakeSecureKeyValueStore> pumpSiswaApp(
  WidgetTester tester, {
  Map<String, (int, Map<String, dynamic>)> overrides = const {},
}) async {
  final store = FakeSecureKeyValueStore();
  await SecureStorageService(store).saveToken('1|tokenvalid');
  final adapter = PathAdapter(overrides: overrides);

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

Map<String, dynamic> berandaDenganJadwal() => {
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
    'akun': {'username': 'siswa01', 'wajib_ganti_password': false},
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
    'jadwal_hari_ini': [
      {
        'hari': 2,
        'nama_hari': 'Selasa',
        'jam_ke': 1,
        'mulai': '07:00',
        'selesai': '07:45',
        'mapel': {'id': 5, 'kode': 'MAT', 'nama': 'Matematika'},
        'guru': {'id': 7, 'nama': 'Guru Uji'},
        'kelas_id': 99,
      },
    ],
  },
};

Map<String, dynamic> absensiHarianBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'konteks': {'valid': true},
    'rekap_semester': {
      'total': 20,
      'hadir': 18,
      'sakit': 1,
      'izin': 1,
      'alpha': 0,
      'persen_hadir': '90,0%',
    },
    'ringkasan': {
      'total': 10,
      'hadir': 9,
      'sakit': 0,
      'izin': 1,
      'alpha': 0,
      'persen_hadir': '90,0%',
    },
    'filter': {'dari': null, 'sampai': null, 'status': null},
    'items': [
      {
        'tanggal': '2026-11-17',
        'status': 'hadir',
        'catatan': null,
        'kelas': {'id': 99, 'nama': 'X-IPA-1'},
      },
    ],
  },
  'meta': {
    'current_page': 1,
    'per_page': 15,
    'last_page': 1,
    'total': 1,
    'from': 1,
    'to': 1,
  },
};

Map<String, dynamic> absensiPerjamBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'rekap': {
      'total': 1,
      'hadir': 1,
      'sakit': 0,
      'izin': 0,
      'alpha': 0,
      'persen_hadir': '100,0%',
    },
    'rekap_total': {
      'total': 30,
      'hadir': 28,
      'sakit': 1,
      'izin': 1,
      'alpha': 0,
      'persen_hadir': '93,3%',
    },
    'filter': {'dari': null, 'sampai': null, 'status': null},
    'items': [
      {
        'tanggal': '2026-11-16',
        'hari': 1,
        'nama_hari': 'Senin',
        'jam_ke': 1,
        'waktu_mulai': '07:00',
        'waktu_selesai': '07:45',
        'status': 'hadir',
        'keterangan': null,
        'pertemuan_status': 'berlangsung',
        'kelas_nama': 'X-IPA-1',
        'mapel_nama': 'Matematika',
        'guru_nama': 'Guru Uji',
      },
    ],
  },
  'meta': {'current_page': 1, 'per_page': 15, 'last_page': 1, 'total': 1},
};

Map<String, dynamic> tagihanListBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': [
    {
      'id': 42,
      'nama': 'SPP November 2026',
      'nominal': 750000,
      'terbayar': 250000,
      'sisa': 500000,
      'status': 'belum_dibayar',
      'jatuh_tempo': '2026-11-30',
    },
  ],
  'meta': {'current_page': 1, 'per_page': 15, 'last_page': 1, 'total': 1},
};

Map<String, dynamic> tagihanDetailBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'id': 42,
    'nama': 'SPP November 2026',
    'nominal': 750000,
    'terbayar': 250000,
    'sisa': 500000,
    'status': 'belum_dibayar',
    'jatuh_tempo': '2026-11-30',
  },
};

Map<String, dynamic> attemptCreatedBody() => {
  'success': true,
  'message': 'Pembayaran dibuat.',
  'data': {
    'id': 8,
    'order_id': 'PAY-2026-0008',
    'nominal': 500000,
    'status': 'created',
    'snap_token': 'snap-uji',
    'snap_redirect_url': 'https://app.sandbox.midtrans.com/snap/v2/vtweb/xyz',
  },
};

Map<String, dynamic> notifikasiListUnreadBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'items': [
      {
        'id': 9,
        'judul': 'Pemberitahuan Sekolah',
        'isi': 'Isi notifikasi.',
        'jenis': 'pengumuman',
        'prioritas': 'normal',
        'waktu_dibuat': '2026-11-17T08:00:00+07:00',
        'sumber_tabel': null,
        'sumber_id': null,
        'link': null,
        'dibaca': false,
        'dibaca_pada': null,
      },
    ],
    'belum_dibaca': 2,
  },
  'meta': {
    'current_page': 1,
    'per_page': 15,
    'last_page': 1,
    'total': 1,
    'from': 1,
    'to': 1,
  },
};

Map<String, dynamic> raporListBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'rapor': [
      {
        'semester': {
          'id': 11,
          'nama': 'Ganjil',
          'tahunajaran': {'id': 10, 'nama': 'TA-2026/2027'},
        },
        'kelas': {'id': 99, 'nama': 'X-IPA-1', 'tingkat': 'X'},
        'wali_kelas': 'Wali Uji',
        'difinalisasi_pada': '2026-11-15T10:00:00+07:00',
      },
    ],
  },
};

Map<String, dynamic> raporDetailBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'kelas': {'id': 99, 'nama': 'X-IPA-1', 'tingkat': 'X'},
    'semester': {
      'id': 11,
      'nama': 'Ganjil',
      'tahunajaran': {'id': 10, 'nama': 'TA-2026/2027'},
    },
    'is_final': true,
    'nilai': [
      {
        'mapel_id': 5,
        'mapel_kode': 'MAT',
        'mapel_nama': 'Matematika',
        'nilai_akhir': 88,
        'nilai_kktp': 75,
        'keterangan': 'Tuntas',
      },
    ],
    'rekap_kehadiran': {
      'hadir': 40,
      'sakit': 2,
      'izin': 1,
      'alpha': 0,
      'total': 43,
    },
    'catatan': 'Tingkatkan terus.',
    'nama_sekolah': 'SMA Uji',
  },
};

void main() {
  testWidgets('dashboard menampilkan data beranda dari API', (tester) async {
    await pumpSiswaApp(
      tester,
      overrides: {'/siswa/beranda': (200, berandaDenganJadwal())},
    );

    expect(find.text('Siswa Uji'), findsWidgets);
    expect(find.textContaining('X-IPA-1'), findsWidgets);
    expect(find.text('Jadwal Hari Ini'), findsOneWidget);
    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Selasa'), findsWidgets);
  });

  testWidgets('dashboard error API menampilkan tombol Coba Lagi', (
    tester,
  ) async {
    await pumpSiswaApp(
      tester,
      overrides: {
        '/siswa/beranda': (
          500,
          {
            'success': false,
            'message': 'Kesalahan server. Silakan coba lagi.',
            'code': 'SERVER_ERROR',
          },
        ),
      },
    );

    expect(find.textContaining('Gagal memuat data'), findsWidgets);
    expect(find.text('Coba Lagi'), findsWidgets);
  });

  testWidgets('badge notifikasi tampil di beranda saat ada yang belum dibaca', (
    tester,
  ) async {
    await pumpSiswaApp(
      tester,
      overrides: {
        '/siswa/beranda': (200, berandaDenganJadwal()),
        '/siswa/notifikasi/unread-count': (200, unreadCountBody(count: 2)),
      },
    );

    await tester.scrollUntilVisible(
      find.text('Notifikasi (2)'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Notifikasi (2)'), findsOneWidget);
  });

  testWidgets('absensi harian menampilkan rekap dan histori', (tester) async {
    await pumpSiswaApp(
      tester,
      overrides: {'/siswa/absensi/harian': (200, absensiHarianBody())},
    );

    // Buka menu Akademik → Absensi
    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuCard, 'Absensi'));
    await tester.pumpAndSettle();

    expect(find.text('Rekap Semester Ini'), findsOneWidget);
    expect(find.textContaining('90,0%'), findsWidgets);
    expect(find.text('Hadir'), findsWidgets);
    expect(find.text('Kelas X-IPA-1'), findsWidgets);
  });

  testWidgets(
    'absensi periode: tombol tampilkan nonaktif sampai tanggal dipilih',
    (tester) async {
      await pumpSiswaApp(tester);

      await tester.tap(find.byIcon(Icons.school_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuCard, 'Absensi'));
      await tester.pumpAndSettle();

      // Pindah ke tab Periode
      await tester.tap(find.text('Periode'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tampilkan Rekap'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('absensi per jam menampilkan snapshot pertemuan', (tester) async {
    await pumpSiswaApp(
      tester,
      overrides: {'/siswa/absensi/perjam': (200, absensiPerjamBody())},
    );

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuCard, 'Absensi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Per Jam'));
    await tester.pumpAndSettle();

    expect(find.text('Matematika'), findsOneWidget);
    expect(find.textContaining('Guru Uji'), findsWidgets);
    expect(find.text('Total Per Jam (Seluruh Riwayat)'), findsOneWidget);
  });

  testWidgets('keuangan: ringkasan dan daftar tagihan dari API', (
    tester,
  ) async {
    await pumpSiswaApp(
      tester,
      overrides: {'/keuangan/tagihan': (200, tagihanListBody())},
    );

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Kewajiban'), findsOneWidget);
    expect(find.text('Rp 1.000.000'), findsWidgets); // sisa kewajiban data mock
    expect(find.text('SPP November 2026'), findsOneWidget);
    expect(find.text('Belum Dibayar'), findsWidgets);
  });

  testWidgets('tagihan detail: tombol Bayar membuat payment attempt', (
    tester,
  ) async {
    await pumpSiswaApp(
      tester,
      overrides: {
        '/keuangan/tagihan': (200, tagihanListBody()),
        '/keuangan/tagihan/42': (200, tagihanDetailBody()),
        '/keuangan/pembayaran/attempts': (201, attemptCreatedBody()),
      },
    );

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SPP November 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Tagihan'), findsOneWidget);
    expect(find.text('SPP November 2026'), findsWidgets);

    // Gulir ke tombol Bayar bila di bawah lipatan
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Bayar Rp 500.000'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Bayar Rp 500.000'));
    await tester.pumpAndSettle();

    // Dialog konfirmasi
    expect(find.text('Buat Pembayaran'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Lanjutkan'));
    // pumpAndSettle bisa macet bila ada animasi berkelanjutan; gunakan pump terbatas.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Dialog hasil attempt: nomor order dari backend, bukan nominal invented
    expect(find.text('Instruksi Pembayaran Dibuat'), findsOneWidget);
    expect(find.text('PAY-2026-0008'), findsOneWidget);
    expect(find.text('Rp 500.000'), findsWidgets);
  });

  testWidgets('pembayaran detail: dokumen 404 menampilkan pesan backend', (
    tester,
  ) async {
    await pumpSiswaApp(
      tester,
      overrides: {
        '/keuangan/pembayaran': (
          200,
          {
            'success': true,
            'message': 'Berhasil',
            'data': [
              {
                'id': 17,
                'nominal': 500000,
                'metode': 'midtrans',
                'status': 'success',
                'dibayar_pada': '2026-11-17T09:00:00+07:00',
              },
            ],
            'meta': {
              'current_page': 1,
              'per_page': 15,
              'last_page': 1,
              'total': 1,
            },
          },
        ),
        '/keuangan/pembayaran/17': (
          200,
          {
            'success': true,
            'message': 'Berhasil',
            'data': {
              'id': 17,
              'nominal': 500000,
              'metode': 'midtrans',
              'status': 'success',
              'dibayar_pada': '2026-11-17T09:00:00+07:00',
            },
          },
        ),
        '/keuangan/pembayaran/17/bukti': (
          404,
          {
            'success': false,
            'message': 'Bukti pembayaran tidak tersedia.',
            'code': 'BUKTI_NOT_FOUND',
          },
        ),
      },
    );

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();

    // Buka Riwayat Pembayaran
    await tester.tap(find.text('Riwayat Pembayaran'));
    await tester.pumpAndSettle();

    // Buka detail pembayaran
    await tester.tap(find.text('Rp 500.000'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Pembayaran'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Bukti Pembayaran'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Bukti Pembayaran'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Bukti pembayaran tidak tersedia.'),
      findsOneWidget,
    );
  });

  testWidgets('notifikasi: detail dan tombol Tandai Dibaca', (tester) async {
    await pumpSiswaApp(
      tester,
      overrides: {
        '/siswa/notifikasi': (200, notifikasiListUnreadBody()),
        '/siswa/notifikasi/9': (
          200,
          {
            'success': true,
            'message': 'Berhasil',
            'data': {
              'id': 9,
              'judul': 'Pemberitahuan Sekolah',
              'isi': 'Detail isi notifikasi.',
              'jenis': 'pengumuman',
              'prioritas': 'normal',
              'waktu_dibuat': '2026-11-17T08:00:00+07:00',
              'sumber_tabel': null,
              'sumber_id': null,
              'link': null,
              'dibaca': false,
              'dibaca_pada': null,
            },
          },
        ),
        '/siswa/notifikasi/9/read': (
          200,
          {
            'success': true,
            'message': 'Notifikasi ditandai sudah dibaca.',
            'data': {
              'id': 9,
              'dibaca': true,
              'dibaca_pada': '2026-11-17T10:00:00+07:00',
            },
          },
        ),
      },
    );

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Pemberitahuan Sekolah'), findsOneWidget);

    await tester.tap(find.text('Pemberitahuan Sekolah'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Tandai Dibaca'));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi ditandai dibaca.'), findsOneWidget);
  });

  testWidgets('rapor: daftar dan detail rapor dari API', (tester) async {
    await pumpSiswaApp(
      tester,
      overrides: {
        '/siswa/rapor': (200, raporListBody()),
        '/siswa/rapor/11/99': (200, raporDetailBody()),
      },
    );

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();

    // MenuRapor berada di bawah lipatan pada layar kecil — gulir dulu.
    await tester.scrollUntilVisible(
      find.widgetWithText(MenuCard, 'Rapor'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(MenuCard, 'Rapor'));
    await tester.pumpAndSettle();

    expect(find.text('Semester Ganjil · Kelas X-IPA-1'), findsOneWidget);

    await tester.tap(find.text('Semester Ganjil · Kelas X-IPA-1'));
    await tester.pumpAndSettle();

    expect(find.text('SMA Uji'), findsOneWidget);
    expect(find.text('FINAL'), findsOneWidget);
    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Tingkatkan terus.'), findsOneWidget);
  });
}
