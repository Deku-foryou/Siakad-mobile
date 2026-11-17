import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/errors/api_exception.dart';
import 'package:siakad_mobile/features/guru/application/guru_providers.dart';
import 'package:siakad_mobile/features/guru/data/guru_repository.dart';

import '../../fakes/harness.dart';

Map<String, dynamic> guruProfilBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'id': 7,
    'nip': '198801012010011001',
    'kode_guru': 'GR001',
    'nama': 'Guru Uji',
    'jenis_kelamin': 'L',
    'tempat_lahir': 'Jakarta',
    'tanggal_lahir': '1988-01-01',
    'telepon': '08123456789',
    'alamat': 'Jl. Guru No. 1',
    'status': 'aktif',
    'mapel': [
      {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
    ],
    'akun': {'username': 'guru01', 'wajib_ganti_password': false},
  },
};

Map<String, dynamic> guruBerandaBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'guru': {
      'id': 7,
      'nip': '198801012010011001',
      'kode_guru': 'GR001',
      'nama': 'Guru Uji',
      'status': 'aktif',
    },
    'akun': {'username': 'guru01', 'wajib_ganti_password': false},
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
        'sumber': ['mengajar'],
        'jumlah_siswa': 25,
        'mapel': [
          {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
        ],
      },
    ],
    'ringkasan': {
      'jumlah_kelas': 1,
      'jumlah_penugasan': 1,
      'pertemuan_hari_ini': 1,
      'absensi_perjam_hari_ini': 5,
      'absensi_harian_hari_ini': 25,
    },
    'nama_hari': 'Selasa',
    'jadwal_hari_ini': [
      {
        'id': 55,
        'hari': 2,
        'nama_hari': 'Selasa',
        'jam_ke': 1,
        'mulai': '07:00',
        'selesai': '07:45',
        'mapel': {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
        'kelas': {'id': 99, 'nama': 'X-IPA-1', 'tingkat': 'X'},
        'semester': {'id': 11, 'nama': 'Ganjil'},
      },
    ],
  },
};

Map<String, dynamic> kelasListBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'konteks': {
      'valid': true,
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
        'tahunajaran': {'id': 10, 'nama': 'TA-2026/2027'},
        'jurusan': {'id': 1, 'nama': 'IPA'},
        'sumber': ['mengajar', 'wali'],
        'jumlah_siswa': 25,
        'mapel': [
          {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
        ],
      },
    ],
  },
};

Map<String, dynamic> kelasSiswaBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'kelas': {'id': 99, 'nama': 'X-IPA-1'},
    'jumlah': 2,
    'siswa': [
      {
        'id': 1001,
        'nisn': '001',
        'nis': 'S001',
        'nama': 'Siswa A',
        'jenis_kelamin': 'L',
      },
      {
        'id': 1002,
        'nisn': '002',
        'nis': 'S002',
        'nama': 'Siswa B',
        'jenis_kelamin': 'P',
      },
    ],
  },
};

Map<String, dynamic> penugasanBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'penugasan': [
      {
        'id': 501,
        'semester': {
          'id': 11,
          'nama': 'Ganjil',
          'tahun_ajaran': 'TA-2026/2027',
        },
        'kelas': {'id': 99, 'nama': 'X-IPA-1', 'tingkat': 'X'},
        'mapel': {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
      },
    ],
  },
};

Map<String, dynamic> jadwalBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'konteks': {
      'valid': true,
      'tahun_ajaran': {'id': 10, 'nama': 'TA-2026/2027'},
      'semester': {'id': 11, 'nama': 'Ganjil'},
    },
    'filter': {'tanggal': '2026-11-17', 'hari': 2, 'nama_hari': 'Selasa'},
    'jadwal': [
      {
        'id': 55,
        'hari': 2,
        'nama_hari': 'Selasa',
        'jam_ke': 1,
        'mulai': '07:00',
        'selesai': '07:45',
        'mapel': {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
        'kelas': {'id': 99, 'nama': 'X-IPA-1', 'tingkat': 'X'},
        'semester': {'id': 11, 'nama': 'Ganjil'},
      },
    ],
  },
};

Map<String, dynamic> harianGridBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'tanggal': '2026-11-17',
    'kelas_id': 99,
    'konteks': {'valid': true},
    'siswa': [
      {
        'id': 1001,
        'nisn': '001',
        'nama': 'Siswa A',
        'absensi': {'id': 71, 'status': 'sakit', 'catatan': 'Demam'},
      },
      {'id': 1002, 'nisn': '002', 'nama': 'Siswa B', 'absensi': null},
    ],
  },
};

Map<String, dynamic> penugasanDetailBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'id': 501,
    'semester': {'id': 11, 'nama': 'Ganjil', 'tahun_ajaran': 'TA-2026/2027'},
    'kelas': {'id': 99, 'nama': 'X-IPA-1', 'tingkat': 'X'},
    'mapel': {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
    'jumlah_siswa': 25,
    'komponen': [
      {'id': 601, 'nama': 'Tugas', 'bobot': 50.0, 'urutan': 1},
      {'id': 602, 'nama': 'UTS', 'bobot': 50.0, 'urutan': 2},
    ],
    'total_bobot_aktif': 100.0,
    'konfigurasi_valid': true,
    'terkunci': false,
  },
};

Map<String, dynamic> penugasanSiswaBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'penugasan_id': 501,
    'terkunci': false,
    'siswa': [
      {
        'id': 1001,
        'nisn': '001',
        'nis': 'S001',
        'nama': 'Siswa A',
        'nilai': {'601': 80.0, '602': 90.0},
        'nilai_draft': 85.0,
        'lengkap': true,
        'jumlah_terisi': 2,
        'jumlah_komponen': 2,
        'bobot_terisi': 100.0,
        'bobot_total': 100.0,
        'konfigurasi_valid': true,
      },
      {
        'id': 1002,
        'nisn': '002',
        'nis': 'S002',
        'nama': 'Siswa B',
        'nilai': {'601': null, '602': 70.0},
        'nilai_draft': null,
        'lengkap': false,
        'jumlah_terisi': 1,
        'jumlah_komponen': 2,
        'bobot_terisi': 50.0,
        'bobot_total': 100.0,
        'konfigurasi_valid': true,
      },
    ],
  },
};

Map<String, dynamic> pertemuanBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'tanggal': '2026-11-17',
    'pertemuan': [
      {
        'id': 301,
        'jadwal_kelas_id': 55,
        'tanggal': '2026-11-17',
        'hari': 2,
        'jam_ke': 1,
        'waktu_mulai': '07:00',
        'waktu_selesai': '07:45',
        'status': 'terjadwal',
        'kelas': {'id': 99, 'nama': 'X-IPA-1'},
        'mapel': {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
        'jumlah_siswa': 25,
        'jumlah_absensi': 10,
        'bisa_diabsen': true,
      },
    ],
  },
};

Map<String, dynamic> perjamGridBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'id': 301,
    'tanggal': '2026-11-17',
    'hari': 2,
    'jam_ke': 1,
    'waktu_mulai': '07:00',
    'waktu_selesai': '07:45',
    'status': 'terjadwal',
    'bisa_diabsen': true,
    'kelas': {'id': 99, 'nama': 'X-IPA-1'},
    'mapel': {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
    'siswa': [
      {'id': 1001, 'nisn': '001', 'nama': 'Siswa A', 'absensi': null},
    ],
  },
};

void main() {
  group('profil & beranda', () {
    test('profil sukses: field terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, guruProfilBody());

      final repo = h.container.read(guruRepositoryProvider);
      final p = await repo.profil();

      expect(p.nama, 'Guru Uji');
      expect(p.nip, '198801012010011001');
      expect(p.mapel.single.nama, 'Matematika');
      expect(p.akunUsername, 'guru01');
      expect(h.adapter.requests.single.path, '/guru/profil');
    });

    test('profil GURU_NOT_LINKED: 403 dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(403, {
        'success': false,
        'message': 'Akun guru ini belum terhubung ke data guru atau nonaktif. Hubungi administrator.',
        'code': 'GURU_NOT_LINKED',
      });

      final repo = h.container.read(guruRepositoryProvider);
      try {
        await repo.profil();
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 403);
        expect(e.code, 'GURU_NOT_LINKED');
      }
    });

    test('beranda sukses: kelas + ringkasan + jadwal terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, guruBerandaBody());

      final repo = h.container.read(guruRepositoryProvider);
      final b = await repo.beranda();

      expect(b.nama, 'Guru Uji');
      expect(b.kelas.single.nama, 'X-IPA-1');
      expect(b.kelas.single.jumlahSiswa, 25);
      expect(b.kelas.single.diajar, isTrue);
      expect(b.ringkasan.jumlahKelas, 1);
      expect(b.ringkasan.pertemuanHariIni, 1);
      expect(b.jadwalHariIni.single.mapel.nama, 'Matematika');
    });
  });

  group('kelas, siswa & penugasan', () {
    test('kelas list sukses: sumber + mapel terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, kelasListBody());

      final repo = h.container.read(guruRepositoryProvider);
      final result = await repo.kelas();

      expect(result.kelas.single.diajar, isTrue);
      expect(result.kelas.single.diwali, isTrue);
      expect(result.kelas.single.mapel.single.nama, 'Matematika');
      expect(result.konteks.tahunAjaranNama, 'TA-2026/2027');
    });

    test('kelas detail sukses', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'id': 99,
          'nama': 'X-IPA-1',
          'tingkat': 'X',
          'jenis': 'Reguler',
          'rombel': 'A',
          'tahunajaran': {'id': 10, 'nama': 'TA-2026/2027'},
          'jurusan': {'id': 1, 'nama': 'IPA'},
          'wali_kelas': {'id': 7, 'nama': 'Guru Uji'},
          'sumber': ['mengajar', 'wali'],
          'jumlah_siswa': 25,
          'mapel': [
            {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
          ],
          'penugasan': [
            {
              'id': 501,
              'mapel': {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
            },
          ],
        },
      });

      final repo = h.container.read(guruRepositoryProvider);
      final detail = await repo.kelasDetail(99);

      expect(detail.nama, 'X-IPA-1');
      expect(detail.waliNama, 'Guru Uji');
      expect(detail.mapel.single.nama, 'Matematika');
    });

    test('kelas siswa sukses: jumlah & daftar', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, kelasSiswaBody());

      final repo = h.container.read(guruRepositoryProvider);
      final result = await repo.kelasSiswa(99);

      expect(result.jumlah, 2);
      expect(result.siswa.first.nama, 'Siswa A');
      expect(h.adapter.requests.single.path, '/guru/kelas/99/siswa');
    });

    test('penugasan list sukses', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, penugasanBody());

      final repo = h.container.read(guruRepositoryProvider);
      final list = await repo.penugasan();

      expect(list.single.id, 501);
      expect(list.single.mapel.nama, 'Matematika');
      expect(list.single.semester.tahunAjaran, 'TA-2026/2027');
    });
  });

  group('jadwal', () {
    test('jadwal dengan tanggal: konteks & item terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, jadwalBody());

      final repo = h.container.read(guruRepositoryProvider);
      final j = await repo.jadwal(tanggal: '2026-11-17');

      expect(j.namaHari, 'Selasa');
      expect(j.jadwal.single.mapel.nama, 'Matematika');
      expect(
        h.adapter.requests.single.queryParameters['tanggal'],
        '2026-11-17',
      );
    });

    test('jadwal hari ini memakai endpoint hari-ini', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'tanggal': '2026-11-17',
          'hari': 2,
          'nama_hari': 'Selasa',
          'konteks': {'valid': true},
          'jadwal': <Map<String, dynamic>>[],
        },
      });

      final repo = h.container.read(guruRepositoryProvider);
      await repo.jadwalHariIni();

      expect(h.adapter.requests.single.path, '/guru/jadwal/hari-ini');
    });

    test('jadwal detail sukses', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'id': 55,
          'hari': 2,
          'nama_hari': 'Selasa',
          'jam_ke': 1,
          'mulai': '07:00',
          'selesai': '07:45',
          'mapel': {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
          'kelas': {'id': 99, 'nama': 'X-IPA-1', 'tingkat': 'X'},
          'semester': {'id': 11, 'nama': 'Ganjil'},
        },
      });

      final repo = h.container.read(guruRepositoryProvider);
      final item = await repo.jadwalDetail(55);

      expect(item.mapel.nama, 'Matematika');
      expect(item.semesterNama, 'Ganjil');
    });
  });

  group('absensi harian', () {
    test('list + filter param terkirim & meta terbaca', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'items': [
            {
              'id': 71,
              'tanggal': '2026-11-17',
              'status': 'sakit',
              'catatan': 'Demam',
              'kelas': {'id': 99, 'nama': 'X-IPA-1'},
              'siswa': {'id': 1001, 'nama': 'Siswa A'},
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
      });

      final repo = h.container.read(guruRepositoryProvider);
      final result = await repo.absensiHarian(
        status: 'sakit',
        kelasId: 99,
        page: 2,
      );

      expect(result.items.single.status, 'sakit');
      expect(result.meta?.total, 1);
      final q = h.adapter.requests.single.queryParameters;
      expect(q['status'], 'sakit');
      expect(q['kelas_id'], 99);
      expect(q['page'], 2);
    });

    test('grid harian: siswa + absensi tercatat terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, harianGridBody());

      final repo = h.container.read(guruRepositoryProvider);
      final grid = await repo.absensiHarianGrid(
        kelasId: 99,
        tanggal: '2026-11-17',
      );

      expect(grid.siswa.length, 2);
      expect(grid.siswa[0].absensiStatus, 'sakit');
      expect(grid.siswa[1].absensiStatus, isNull);
      expect(h.adapter.requests.single.path, '/guru/kelas/99/absensi');
    });

    test('POST harian: payload persis (tanpa guru_id/TA/semester)', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Absensi berhasil disimpan.',
        'data': {
          'tanggal': '2026-11-17',
          'kelas_id': 99,
          'dibuat': 1,
          'diubah': 1,
        },
      });

      final repo = h.container.read(guruRepositoryProvider);
      final result = await repo.simpanAbsensiHarian(
        tanggal: '2026-11-17',
        kelasId: 99,
        records: const [
          AbsensiRecordInput(siswaId: 1001, status: 'sakit', catatan: 'Demam'),
          AbsensiRecordInput(siswaId: 1002, status: 'hadir'),
        ],
      );

      expect(result.created, 1);
      expect(result.updated, 1);

      final data = h.adapter.requests.single.data as Map;
      expect(data.keys.toList()..sort(), ['kelas_id', 'records', 'tanggal']);
      expect(data['kelas_id'], 99);
      final records = (data['records'] as List).cast<Map>();
      expect(records[0]['siswa_id'], 1001);
      expect(records[0]['status'], 'sakit');
      expect(records[0]['catatan'], 'Demam');
      // Tidak boleh ada identitas otorisasi dari client:
      expect(data.containsKey('guru_id'), isFalse);
      expect(data.containsKey('user_id'), isFalse);
      expect(data.containsKey('semester_id'), isFalse);
      expect(data.containsKey('tahunajaran_id'), isFalse);
    });

    test('PATCH harian: payload status+catatan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Absensi berhasil diperbarui.',
        'data': {
          'id': 71,
          'tanggal': '2026-11-17',
          'status': 'izin',
          'catatan': 'Acara keluarga',
          'kelas': {'id': 99, 'nama': 'X-IPA-1'},
          'siswa': {'id': 1001, 'nama': 'Siswa A'},
        },
      });

      final repo = h.container.read(guruRepositoryProvider);
      final result = await repo.ubahAbsensiHarian(
        id: 71,
        status: 'izin',
        catatan: 'Acara keluarga',
      );

      expect(result.status, 'izin');
      expect(h.adapter.requests.single.method, 'PATCH');
    });

    test('POST harian 422 DUPLIKAT_SISWA dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(422, {
        'success': false,
        'message':
            'Terdapat siswa yang sama lebih dari satu kali pada records.',
        'code': 'DUPLIKAT_SISWA',
      });

      final repo = h.container.read(guruRepositoryProvider);
      try {
        await repo.simpanAbsensiHarian(
          tanggal: '2026-11-17',
          kelasId: 99,
          records: const [AbsensiRecordInput(siswaId: 1001, status: 'hadir')],
        );
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 422);
        expect(e.code, 'DUPLIKAT_SISWA');
      }
    });
  });

  group('absensi per jam', () {
    test('list perjam + filter param & meta terbaca', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'items': [
            {
              'id': 81,
              'jadwal_pertemuan_id': 301,
              'tanggal': '2026-11-17',
              'hari': 2,
              'nama_hari': 'Selasa',
              'jam_ke': 1,
              'waktu_mulai': '07:00',
              'waktu_selesai': '07:45',
              'status': 'hadir',
              'keterangan': null,
              'pertemuan_status': 'terjadwal',
              'kelas_id': 99,
              'kelas_nama': 'X-IPA-1',
              'mapel_nama': 'Matematika',
              'siswa': {'id': 1001, 'nama': 'Siswa A'},
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
      });

      final repo = h.container.read(guruRepositoryProvider);
      final result = await repo.absensiPerjam(status: 'hadir', kelasId: 99);

      expect(result.items.single.id, 81);
      final q = h.adapter.requests.single.queryParameters;
      expect(q['status'], 'hadir');
      expect(q['kelas_id'], 99);
    });

    test('pertemuan list: bisa_diabsen terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, pertemuanBody());

      final repo = h.container.read(guruRepositoryProvider);
      final result = await repo.pertemuan(tanggal: '2026-11-17');

      expect(result.pertemuan.single.bisaDiabsen, isTrue);
      expect(result.pertemuan.single.jumlahAbsensi, 10);
      expect(
        h.adapter.requests.single.queryParameters['tanggal'],
        '2026-11-17',
      );
    });

    test('pertemuan detail (grid): bisa_diabsen + siswa', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, perjamGridBody());

      final repo = h.container.read(guruRepositoryProvider);
      final grid = await repo.pertemuanDetail(301);

      expect(grid.bisaDiabsen, isTrue);
      expect(grid.siswa.length, 1);
      expect(
        h.adapter.requests.single.path,
        '/guru/absensi/perjam/pertemuan/301',
      );
    });

    test('POST perjam: payload pertemuan id + records (keterangan)', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Absensi per jam berhasil disimpan.',
        'data': {'jadwal_pertemuan_id': 301, 'dibuat': 1, 'diubah': 0},
      });

      final repo = h.container.read(guruRepositoryProvider);
      final result = await repo.simpanAbsensiPerjam(
        jadwalPertemuanId: 301,
        records: const [
          AbsensiPerjamRecordInput(
            siswaId: 1001,
            status: 'hadir',
            keterangan: 'Masuk tepat waktu',
          ),
        ],
      );

      expect(result.created, 1);
      final data = h.adapter.requests.single.data as Map;
      expect(data['jadwal_pertemuan_id'], 301);
      final rec = (data['records'] as List).single as Map;
      expect(rec['keterangan'], 'Masuk tepat waktu');
      expect(data.containsKey('guru_id'), isFalse);
    });

    test('PATCH perjam: payload status+keterangan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Absensi per jam berhasil diperbarui.',
        'data': {'id': 81, 'status': 'izin', 'keterangan': 'Acara lomba'},
      });

      final repo = h.container.read(guruRepositoryProvider);
      final result = await repo.ubahAbsensiPerjam(
        id: 81,
        status: 'izin',
        keterangan: 'Acara lomba',
      );

      expect(result.status, 'izin');
      expect(h.adapter.requests.single.method, 'PATCH');
    });
  });

  group('penilaian', () {
    test('penugasan detail: komponen, bobot, status terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, penugasanDetailBody());

      final repo = h.container.read(guruRepositoryProvider);
      final d = await repo.penugasanDetail(501);

      expect(d.komponen.length, 2);
      expect(d.komponen[0].bobot, 50.0);
      expect(d.konfigurasiValid, isTrue);
      expect(d.terkunci, isFalse);
      expect(d.jumlahSiswa, 25);
    });

    test('penugasan siswa: nilai map keys & draft terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, penugasanSiswaBody());

      final repo = h.container.read(guruRepositoryProvider);
      final r = await repo.penugasanSiswa(501);

      expect(r.terkunci, isFalse);
      expect(r.siswa[0].nilai[601], 80.0);
      expect(r.siswa[0].lengkap, isTrue);
      expect(r.siswa[1].nilai[601], isNull);
      expect(r.siswa[1].nilaiDraft, isNull);
    });

    test('PUT nilai batch: payload {siswa: {komponen: nilai}}', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': '2 nilai berhasil disimpan.',
        'data': {'tersimpan': 2},
      });

      final repo = h.container.read(guruRepositoryProvider);
      final result = await repo.simpanNilaiBatch(
        penugasanId: 501,
        matriks: const {
          1001: {601: 80, 602: 90},
          1002: {602: 70, 601: null},
        },
      );

      expect(result.tersimpan, 2);
      final data = h.adapter.requests.single.data as Map;
      final nilai = (data['nilai'] as Map).cast<String, Map>();
      expect(nilai.length, 2);
      expect(nilai['1001']!['601'], 80);
      expect(nilai['1002']!['601'], isNull); // null = skip
      expect(h.adapter.requests.single.method, 'PUT');
      expect(data.containsKey('guru_id'), isFalse);
    });

    test('PATCH nilai satuan: payload & respons', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Nilai berhasil disimpan.',
        'data': {'id': 91, 'siswa_id': 1001, 'komponen_id': 601, 'nilai': 85.5},
      });

      final repo = h.container.read(guruRepositoryProvider);
      final r = await repo.simpanNilaiSatu(
        penugasanId: 501,
        siswaId: 1001,
        komponenId: 601,
        nilai: 85.5,
      );

      expect(r.nilai, 85.5);
      final data = h.adapter.requests.single.data as Map;
      expect(data['siswa_id'], 1001);
      expect(data['komponen_id'], 601);
      expect(data['nilai'], 85.5);
    });
  });

  group('notifikasi', () {
    Map<String, dynamic> listBody() => {
      'success': true,
      'message': 'Berhasil',
      'data': {
        'items': [
          {
            'id': 9,
            'judul': 'Pemberitahuan',
            'isi': 'Isi.',
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

    test('notifikasi list + PATCH read + read-all', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, listBody());
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Notifikasi ditandai sudah dibaca.',
        'data': {
          'id': 9,
          'dibaca': true,
          'dibaca_pada': '2026-11-17T09:00:00+07:00',
        },
      });
      h.adapter.respondJson(200, {
        'success': true,
        'message': '5 notifikasi ditandai sudah dibaca.',
        'data': {'ditandai': 5, 'belum_dibaca': 0},
      });

      final repo = h.container.read(guruRepositoryProvider);
      final list = await repo.notifikasi(status: 'unread');
      expect(list.belumDibaca, 2);
      await repo.markRead(9);
      final all = await repo.markAllRead();
      expect(all.ditandai, 5);

      expect(h.adapter.requests[0].queryParameters['status'], 'unread');
      expect(h.adapter.requests[1].path, '/guru/notifikasi/9/read');
      expect(h.adapter.requests[2].path, '/guru/notifikasi/read-all');
    });

    test('unread-count sukses', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, unreadCountBody(count: 4));

      final repo = h.container.read(guruRepositoryProvider);
      expect(await repo.unreadCount(), 4);
      expect(h.adapter.requests.single.path, '/guru/notifikasi/unread-count');
    });
  });
}
