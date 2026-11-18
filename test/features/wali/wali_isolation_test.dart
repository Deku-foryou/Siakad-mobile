import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/features/wali/application/wali_absensi_notifiers.dart';
import 'package:siakad_mobile/features/wali/application/wali_providers.dart';
import 'package:siakad_mobile/features/wali/data/models/wali.dart';

import '../../fakes/harness.dart';

/// Isolasi cache antar-anak:
/// - family provider keyed by siswaId → data anak A tidak pernah
///   tertukar dengan anak B;
/// - notifikasi wali user-scoped (tidak keyed per anak);
/// - anakAktif default = anak verified pertama; relasi pending diabaikan.
void main() {
  Map<String, dynamic> jadwalBody(int hari, String mapel) => {
    'success': true,
    'message': 'Berhasil',
    'data': {
      'tanggal': null,
      'hari': hari,
      'nama_hari': hari == 2 ? 'Selasa' : 'Rabu',
      'konteks': {'valid': true},
      'jadwal': [
        {
          'hari': hari,
          'nama_hari': hari == 2 ? 'Selasa' : 'Rabu',
          'jam_ke': 1,
          'mulai': '07:00',
          'selesai': '07:45',
          'mapel': {'id': 1, 'kode': 'MAT', 'nama': mapel},
          'guru': {'id': 7, 'nama': 'Guru Uji'},
          'kelas_id': 99,
        },
      ],
    },
  };

  test('family provider: jadwal anak A dan anak B terisolasi', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    h.adapter.respondJson(200, jadwalBody(2, 'Matematika'));
    h.adapter.respondJson(200, jadwalBody(3, 'Bahasa Indonesia'));

    final anakA = await h.container.read(
      anakJadwalProvider((201, null, null)).future,
    );
    final anakB = await h.container.read(
      anakJadwalProvider((202, null, null)).future,
    );

    expect(anakA.jadwal.single.mapelNama, 'Matematika');
    expect(anakB.jadwal.single.mapelNama, 'Bahasa Indonesia');

    final paths = h.adapter.requests.map((r) => r.path).toList();
    expect(paths, contains('/wali/anak/201/jadwal'));
    expect(paths, contains('/wali/anak/202/jadwal'));
  });

  test('family provider: notifikasi wali tidak membawa siswa_id', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);
    h.adapter.respondJson(200, notifikasiListBody());

    await h.container.read(waliRepositoryProvider).notifikasi();

    final request = h.adapter.requests.single;
    expect(request.path, '/wali/notifikasi');
    expect(request.queryParameters.containsKey('siswa_id'), isFalse);
  });

  test('absensi family notifier: state anak A dan anak B terpisah', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    Map<String, dynamic> absensiBody(String mapelTanggal) => {
      'success': true,
      'message': 'Berhasil',
      'data': {
        'konteks': {'valid': true},
        'rekap_semester': {
          'total': 10,
          'hadir': 9,
          'sakit': 1,
          'izin': 0,
          'alpha': 0,
          'persen_hadir': '90,0%',
        },
        'ringkasan': {
          'total': 1,
          'hadir': 1,
          'sakit': 0,
          'izin': 0,
          'alpha': 0,
          'persen_hadir': '100,0%',
        },
        'filter': {'dari': null, 'sampai': null, 'status': null},
        'items': [
          {
            'tanggal': mapelTanggal,
            'status': 'hadir',
            'catatan': null,
            'kelas': {'id': 99, 'nama': 'X-IPA-1'},
          },
        ],
      },
      'meta': {'current_page': 1, 'per_page': 15, 'last_page': 1, 'total': 1},
    };

    h.adapter.respondJson(200, absensiBody('2026-11-10'));
    h.adapter.respondJson(200, absensiBody('2026-11-11'));

    await pumpMicrotasks();
    final subA = h.container.listen(waliAbsensiHarianProvider(201), (_, _) {});
    final subB = h.container.listen(waliAbsensiHarianProvider(202), (_, _) {});
    await pumpMicrotasks();

    final stateA = h.container.read(waliAbsensiHarianProvider(201));
    final stateB = h.container.read(waliAbsensiHarianProvider(202));

    expect(stateA.items.single.tanggal, '2026-11-10');
    expect(stateB.items.single.tanggal, '2026-11-11');

    subA.close();
    subB.close();
  });

  test('anakAktif default: anak verified pertama, pending diabaikan', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);
    h.adapter.respondJson(200, waliAnakListBody());

    h.container.listen(waliAnakListProvider, (_, _) {});
    await pumpMicrotasks();
    expect(h.container.read(waliAnakAktifProvider), 201);
  });

  test('anakAktif: pilihan eksplisit anak verified dihormati', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);
    h.adapter.respondJson(200, {
      'success': true,
      'message': 'Berhasil',
      'data': {
        'konteks': {
          'valid': true,
          'peringatan': <String>[],
          'tahun_ajaran': {'id': 10, 'nama': 'TA-2026/2027'},
          'semester': {'id': 11, 'nama': 'Ganjil'},
        },
        'anak': [
          {
            'relasi_id': 501,
            'hubungan': 'ayah',
            'status_hubungan': 'verified',
            'tanggal_mulai': '2026-07-01',
            'tanggal_berhenti': null,
            'tanggal_verifikasi': '2026-07-05T08:00:00+07:00',
            'bisa_akses_akademik': true,
            'kelas': 'X-IPA-1',
            'siswa': {
              'id': 201,
              'nisn': '001',
              'nis': 'NIS201',
              'nama': 'Andi Anak',
              'jenis_kelamin': 'L',
              'tahun_masuk': 2024,
              'status': 'aktif',
            },
          },
          {
            'relasi_id': 503,
            'hubungan': 'ayah',
            'status_hubungan': 'verified',
            'tanggal_mulai': '2026-07-01',
            'tanggal_berhenti': null,
            'tanggal_verifikasi': '2026-07-05T08:00:00+07:00',
            'bisa_akses_akademik': true,
            'kelas': 'VIII-A',
            'siswa': {
              'id': 203,
              'nisn': '003',
              'nis': 'NIS203',
              'nama': 'Citra Anak',
              'jenis_kelamin': 'P',
              'tahun_masuk': 2025,
              'status': 'aktif',
            },
          },
        ],
      },
    });

    h.container.listen(waliAnakListProvider, (_, _) {});
    await pumpMicrotasks();
    h.container.read(selectedAnakIdProvider.notifier).set(203);
    expect(h.container.read(waliAnakAktifProvider), 203);
  });

  test('anakAktif: pilihan eksplisit anak pending diabaikan', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);
    h.adapter.respondJson(200, waliAnakListBody());

    h.container.listen(waliAnakListProvider, (_, _) {});
    await pumpMicrotasks();
    // 202 = pending / bisa_akses_akademik false → harus jatuh ke 201.
    h.container.read(selectedAnakIdProvider.notifier).set(202);
    expect(h.container.read(waliAnakAktifProvider), 201);
  });

  test(
    'anakAktif: tanpa anak verified → null (UI menampilkan status)',
    () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(
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
      );

      h.container.listen(waliAnakListProvider, (_, _) {});
      await pumpMicrotasks();
      expect(h.container.read(waliAnakAktifProvider), isNull);
    },
  );

  test(
    'anak terminated: bisaAksesAkademik false → tidak jadi anakAktif',
    () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(
        200,
        waliAnakListBody(
          anak: [
            {
              'relasi_id': 504,
              'hubungan': 'ayah',
              'status_hubungan': 'terminated',
              'tanggal_mulai': '2025-07-01',
              'tanggal_berhenti': '2026-10-01',
              'tanggal_verifikasi': '2025-07-05T08:00:00+07:00',
              'bisa_akses_akademik': false,
              'kelas': 'X-IPA-1',
              'siswa': {
                'id': 204,
                'nisn': '004',
                'nis': 'NIS204',
                'nama': 'Dedi Anak',
                'jenis_kelamin': 'L',
                'tahun_masuk': 2024,
                'status': 'aktif',
              },
            },
          ],
        ),
      );

      final list = await h.container.read(waliAnakListProvider.future);
      expect(list.anak.single.statusHubungan, 'terminated');
      expect(list.anak.single.bisaAksesAkademik, isFalse);
      expect(h.container.read(waliAnakAktifProvider), isNull);
    },
  );

  test('model: AnakRelasi parsing toleran terhadap field hilang', () {
    final relasi = AnakRelasi.fromJson(const {
      'relasi_id': 501,
      'status_hubungan': 'verified',
    });

    expect(relasi.relasiId, 501);
    expect(relasi.statusHubungan, 'verified');
    expect(relasi.bisaAksesAkademik, isFalse);
    expect(relasi.siswa, isNull);
    expect(relasi.tanggalBerhenti, isNull);
  });

  test('model: AnakDetail parsing histori kosong', () {
    final detail = AnakDetail.fromJson(const {
      'relasi_id': 501,
      'status_hubungan': 'pending',
      'histori': <Map<String, dynamic>>[],
    });

    expect(detail.histori, isEmpty);
    expect(detail.bisaAksesAkademik, isFalse);
  });
}
