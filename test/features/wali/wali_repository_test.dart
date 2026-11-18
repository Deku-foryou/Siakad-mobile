import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/errors/api_exception.dart';
import 'package:siakad_mobile/features/wali/application/wali_providers.dart';

import '../../fakes/harness.dart';

/// Repository wali — parsing response aktual backend, error HTTP, 422,
/// dan pagination. Semua test memakai FakeHttpClientAdapter (mock),
/// BUKAN live backend.
void main() {
  group('profil & beranda', () {
    test('profil sukses: identitas + relasi ringkasan terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, waliProfilBody());

      final repo = h.container.read(waliRepositoryProvider);
      final profil = await repo.profil();

      expect(profil.name, 'Wali Uji');
      expect(profil.username, 'wali01');
      expect(profil.email, 'wali@example.test');
      expect(profil.statusAkun, 'aktif');
      expect(profil.relasi.verified, 2);
      expect(profil.relasi.pending, 1);
      expect(h.adapter.requests.single.path, '/wali/profil');
    });

    test('beranda 403 WALI_NOT_ACTIVE dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(403, {
        'success': false,
        'message': 'Akun wali tidak aktif. Hubungi admin sekolah.',
        'code': 'WALI_NOT_ACTIVE',
      });

      final repo = h.container.read(waliRepositoryProvider);
      try {
        await repo.beranda();
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 403);
        expect(e.code, 'WALI_NOT_ACTIVE');
      }
    });

    test('beranda sukses: konteks + anak + ringkasan terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, waliBerandaBody());

      final repo = h.container.read(waliRepositoryProvider);
      final beranda = await repo.beranda();

      expect(beranda.name, 'Wali Uji');
      expect(beranda.konteks.tahunAjaranNama, 'TA-2026/2027');
      expect(beranda.anak.length, 2);
      expect(beranda.anak.first.nama, 'Andi Anak');
      expect(beranda.anak.first.kelas, 'X-IPA-1');
      expect(beranda.ringkasan.jumlahAnak, 2);
      expect(beranda.ringkasan.notifikasiBelumDibaca, 3);
      expect(beranda.namaHari, 'Selasa');
      expect(h.adapter.requests.single.path, '/wali/beranda');
    });
  });

  group('daftar & detail anak', () {
    test('daftar anak sukses: semua status relasi terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, waliAnakListBody());

      final repo = h.container.read(waliRepositoryProvider);
      final list = await repo.anak();

      expect(list.anak.length, 2);
      final andi = list.anak.firstWhere((a) => a.siswa?.id == 201);
      final budi = list.anak.firstWhere((a) => a.siswa?.id == 202);
      expect(andi.statusHubungan, 'verified');
      expect(andi.bisaAksesAkademik, isTrue);
      expect(andi.kelas, 'X-IPA-1');
      expect(budi.statusHubungan, 'pending');
      expect(budi.bisaAksesAkademik, isFalse);
      expect(list.konteks.valid, isTrue);
      expect(h.adapter.requests.single.path, '/wali/anak');
    });

    test('daftar anak kosong: [] terpetakan tanpa error', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, waliAnakListBody(anak: const []));

      final repo = h.container.read(waliRepositoryProvider);
      final list = await repo.anak();

      expect(list.anak, isEmpty);
    });

    test('detail anak sukses: histori terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, waliAnakDetailBody());

      final repo = h.container.read(waliRepositoryProvider);
      final detail = await repo.anakDetail(201);

      expect(detail.siswa?.nama, 'Andi Anak');
      expect(detail.statusHubungan, 'verified');
      expect(detail.histori, hasLength(1));
      expect(detail.histori.first.event, 'verifikasi');
      expect(detail.histori.first.aktorPeran, 'admin');
      expect(h.adapter.requests.single.path, '/wali/anak/201');
    });

    test('detail anak 404 ANAK_NOT_FOUND dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(404, {
        'success': false,
        'message': 'Data anak tidak ditemukan.',
        'code': 'ANAK_NOT_FOUND',
      });

      final repo = h.container.read(waliRepositoryProvider);
      try {
        await repo.anakDetail(999);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 404);
        expect(e.code, 'ANAK_NOT_FOUND');
      }
    });

    test('akses akademik ditolak 403 AKSES_DITOLAK (relasi pending)', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(403, {
        'success': false,
        'message': 'Akses akademik tidak tersedia untuk siswa ini.',
        'code': 'AKSES_DITOLAK',
      });

      final repo = h.container.read(waliRepositoryProvider);
      try {
        await repo.anakAbsensiHarian(202);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 403);
        expect(e.code, 'AKSES_DITOLAK');
      }
    });

    test(
      'akses akademik ditolak 403 AKSES_DITOLAK (relasi terminated)',
      () async {
        final h = buildTestHarness();
        addTearDown(h.container.dispose);
        h.adapter.respondJson(403, {
          'success': false,
          'message': 'Akses akademik telah berakhir.',
          'code': 'AKSES_DITOLAK',
        });

        final repo = h.container.read(waliRepositoryProvider);
        try {
          await repo.anakNilai(202);
          fail('harus melempar ApiException');
        } on ApiException catch (e) {
          expect(e.statusCode, 403);
          expect(e.code, 'AKSES_DITOLAK');
        }
      },
    );
  });

  group('jadwal', () {
    test('jadwal sukses: parameter filter diteruskan & terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'tanggal': '2026-11-17',
          'hari': 2,
          'nama_hari': 'Selasa',
          'konteks': {
            'valid': true,
            'tahun_ajaran': {'id': 10, 'nama': 'TA-2026/2027'},
            'semester': {'id': 11, 'nama': 'Ganjil'},
          },
          'jadwal': [
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
      });

      final repo = h.container.read(waliRepositoryProvider);
      final jadwal = await repo.anakJadwal(201, tanggal: '2026-11-17');

      expect(jadwal.jadwal.single.mapelNama, 'Matematika');
      expect(jadwal.jadwal.single.guruNama, 'Guru Uji');
      expect(jadwal.hari, 2);

      final request = h.adapter.requests.single;
      expect(request.path, '/wali/anak/201/jadwal');
      expect(request.queryParameters['tanggal'], '2026-11-17');
    });

    test('jadwal tanpa filter: queryParameters kosong', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'tanggal': null,
          'hari': null,
          'nama_hari': null,
          'konteks': {
            'valid': false,
            'peringatan': ['Tidak ada TA aktif'],
          },
          'jadwal': <Map<String, dynamic>>[],
        },
      });

      final repo = h.container.read(waliRepositoryProvider);
      final jadwal = await repo.anakJadwal(201);

      expect(jadwal.jadwal, isEmpty);
      expect(jadwal.konteks.valid, isFalse);
      expect(h.adapter.requests.single.queryParameters, isEmpty);
    });
  });

  group('absensi', () {
    Map<String, dynamic> harianBody() => {
      'success': true,
      'message': 'Berhasil',
      'data': {
        'konteks': {'valid': true},
        'rekap_semester': {
          'total': 40,
          'hadir': 38,
          'sakit': 1,
          'izin': 1,
          'alpha': 0,
          'persen_hadir': '95,0%',
        },
        'ringkasan': {
          'total': 5,
          'hadir': 4,
          'sakit': 0,
          'izin': 1,
          'alpha': 0,
          'persen_hadir': '80,0%',
        },
        'filter': {'dari': null, 'sampai': null, 'status': 'hadir'},
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
        'current_page': 2,
        'per_page': 15,
        'last_page': 3,
        'total': 40,
        'from': 16,
        'to': 30,
      },
    };

    test(
      'harian sukses: rekap + meta + items terpetakan, parameter benar',
      () async {
        final h = buildTestHarness();
        addTearDown(h.container.dispose);
        h.adapter.respondJson(200, harianBody());

        final repo = h.container.read(waliRepositoryProvider);
        final response = await repo.anakAbsensiHarian(
          201,
          status: 'hadir',
          page: 2,
        );

        expect(response.rekapSemester.total, 40);
        expect(response.rekapSemester.persenHadir, '95,0%');
        expect(response.ringkasan.hadir, 4);
        expect(response.items.single.status, 'hadir');
        expect(response.items.single.kelasNama, 'X-IPA-1');
        expect(response.meta?.currentPage, 2);
        expect(response.meta?.total, 40);

        final request = h.adapter.requests.single;
        expect(request.path, '/wali/anak/201/absensi/harian');
        expect(request.queryParameters['status'], 'hadir');
        expect(request.queryParameters['page'], 2);
        expect(request.queryParameters['per_page'], 15);
      },
    );

    test('harian 422 (validasi): fieldErrors terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(422, {
        'success': false,
        'message': 'The per_page must be at most 50.',
        'errors': {
          'per_page': ['The per_page must be at most 50.'],
        },
      });

      final repo = h.container.read(waliRepositoryProvider);
      try {
        await repo.anakAbsensiHarian(201, perPage: 500);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 422);
        expect(e.fieldErrors['per_page'], isNotEmpty);
      }
    });

    test('periode 422: dari > sampai dipetakan sebagai 422', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(422, {
        'success': false,
        'message': 'Tanggal awal tidak boleh melebihi tanggal akhir.',
        'errors': {
          'dari': ['Tanggal awal tidak boleh melebihi tanggal akhir.'],
        },
      });

      final repo = h.container.read(waliRepositoryProvider);
      try {
        await repo.anakAbsensiPeriode(
          201,
          dari: '2026-11-20',
          sampai: '2026-11-10',
        );
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 422);
        expect(e.fieldErrors['dari'], isNotEmpty);
      }
    });

    test('periode sukses: ringkasan terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'periode': {'dari': '2026-11-01', 'sampai': '2026-11-30'},
          'ringkasan': {
            'total': 3,
            'hadir': 2,
            'sakit': 1,
            'izin': 0,
            'alpha': 0,
            'persen_hadir': '66,7%',
          },
          'filter': {
            'dari': '2026-11-01',
            'sampai': '2026-11-30',
            'status': null,
          },
          'items': <Map<String, dynamic>>[],
        },
        'meta': {'current_page': 1, 'per_page': 15, 'last_page': 1, 'total': 3},
      });

      final repo = h.container.read(waliRepositoryProvider);
      final response = await repo.anakAbsensiPeriode(
        201,
        dari: '2026-11-01',
        sampai: '2026-11-30',
      );

      expect(response.dari, '2026-11-01');
      expect(response.sampai, '2026-11-30');
      expect(response.ringkasan.sakit, 1);
      expect(response.meta?.total, 3);
    });

    test('perjam sukses: rekap_total + items terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'rekap': {
            'total': 2,
            'hadir': 2,
            'sakit': 0,
            'izin': 0,
            'alpha': 0,
            'persen_hadir': '100,0%',
          },
          'rekap_total': {
            'total': 100,
            'hadir': 97,
            'sakit': 1,
            'izin': 1,
            'alpha': 1,
            'persen_hadir': '97,0%',
          },
          'filter': {'dari': null, 'sampai': null, 'status': null},
          'items': [
            {
              'tanggal': '2026-11-16',
              'hari': 1,
              'nama_hari': 'Senin',
              'jam_ke': 3,
              'waktu_mulai': '09:00',
              'waktu_selesai': '09:45',
              'status': 'hadir',
              'keterangan': null,
              'pertemuan_status': 'terlaksana',
              'kelas_nama': 'X-IPA-1',
              'mapel_nama': 'Fisika',
              'guru_nama': 'Guru Fisika',
            },
          ],
        },
        'meta': {'current_page': 1, 'per_page': 15, 'last_page': 1, 'total': 2},
      });

      final repo = h.container.read(waliRepositoryProvider);
      final response = await repo.anakAbsensiPerjam(201);

      expect(response.rekapTotal.total, 100);
      expect(response.items.single.mapelNama, 'Fisika');
      expect(response.items.single.guruNama, 'Guru Fisika');
      expect(response.items.single.pertemuanStatus, 'terlaksana');
      expect(h.adapter.requests.single.path, '/wali/anak/201/absensi/perjam');
    });
  });

  group('nilai & rapor', () {
    test('nilai sukses: kelompok per rapor terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
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
              'nilai': [
                {
                  'mapel_id': 5,
                  'mapel_kode': 'MAT',
                  'mapel_nama': 'Matematika',
                  'nilai_akhir': 87.5,
                  'nilai_kktp': 75.0,
                  'keterangan': 'Tuntas',
                },
              ],
            },
          ],
        },
      });

      final repo = h.container.read(waliRepositoryProvider);
      final kelompok = await repo.anakNilai(201);

      expect(kelompok, hasLength(1));
      expect(kelompok.single.semester.nama, 'Ganjil');
      expect(kelompok.single.nilai.single.nilaiAkhir, 87.5);
      expect(kelompok.single.nilai.single.nilaiKktp, 75.0);
      expect(h.adapter.requests.single.path, '/wali/anak/201/nilai');
    });

    test(
      'nilai 404 NILAI_NOT_FOUND saat filter mengisi nilai kosong',
      () async {
        final h = buildTestHarness();
        addTearDown(h.container.dispose);
        h.adapter.respondJson(404, {
          'success': false,
          'message': 'Nilai untuk filter tersebut tidak tersedia.',
          'code': 'NILAI_NOT_FOUND',
        });

        final repo = h.container.read(waliRepositoryProvider);
        try {
          await repo.anakNilai(201, semesterId: 99);
          fail('harus melempar ApiException');
        } on ApiException catch (e) {
          expect(e.statusCode, 404);
          expect(e.code, 'NILAI_NOT_FOUND');
        }

        final request = h.adapter.requests.single;
        expect(request.queryParameters['semester_id'], 99);
      },
    );

    test('rapor sukses: daftar terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
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
              'wali_kelas': 'Guru Kelas',
              'difinalisasi_pada': '2026-12-01T10:00:00+07:00',
            },
          ],
        },
      });

      final repo = h.container.read(waliRepositoryProvider);
      final rapor = await repo.anakRapor(201);

      expect(rapor.single.kelas.nama, 'X-IPA-1');
      expect(rapor.single.waliKelas, 'Guru Kelas');
    });

    test('rapor kosong: list kosong terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {'rapor': <Map<String, dynamic>>[]},
      });

      final repo = h.container.read(waliRepositoryProvider);
      expect(await repo.anakRapor(201), isEmpty);
    });

    test('rapor detail sukses: nilai + rekap kehadiran terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
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
              'nilai_akhir': 87.5,
              'nilai_kktp': 75.0,
              'keterangan': 'Tuntas',
            },
          ],
          'rekap_kehadiran': {
            'hadir': 90,
            'sakit': 2,
            'izin': 1,
            'alpha': 0,
            'total': 93,
          },
          'catatan': 'Tingkatkan terus belajarnya.',
          'nama_sekolah': 'SMA Uji',
        },
      });

      final repo = h.container.read(waliRepositoryProvider);
      final detail = await repo.anakRaporDetail(
        siswaId: 201,
        semesterId: 11,
        kelasId: 99,
      );

      expect(detail.isFinal, isTrue);
      expect(detail.nilai.single.mapelNama, 'Matematika');
      expect(detail.rekapKehadiran.hadir, 90);
      expect(detail.catatan, 'Tingkatkan terus belajarnya.');
      expect(h.adapter.requests.single.path, '/wali/anak/201/rapor/11/99');
    });

    test('rapor detail 404 RAPOR_NOT_FOUND dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(404, {
        'success': false,
        'message': 'Rapor ini tidak tersedia.',
        'code': 'RAPOR_NOT_FOUND',
      });

      final repo = h.container.read(waliRepositoryProvider);
      try {
        await repo.anakRaporDetail(siswaId: 201, semesterId: 99, kelasId: 99);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 404);
        expect(e.code, 'RAPOR_NOT_FOUND');
      }
    });
  });

  group('notifikasi', () {
    test('list sukses: items + belum_dibaca + meta terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, notifikasiListBody());

      final repo = h.container.read(waliRepositoryProvider);
      final list = await repo.notifikasi(status: 'unread');

      expect(list.items, hasLength(1));
      expect(list.belumDibaca, 2);
      expect(list.meta?.total, 1);

      final request = h.adapter.requests.single;
      expect(request.path, '/wali/notifikasi');
      expect(request.queryParameters['status'], 'unread');
    });

    test('unread-count sukses', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, unreadCountBody(count: 7));

      final repo = h.container.read(waliRepositoryProvider);
      expect(await repo.unreadCount(), 7);
      expect(h.adapter.requests.single.path, '/wali/notifikasi/unread-count');
    });

    test('mark read dipanggil ke PATCH /wali/notifikasi/{id}/read', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Notifikasi ditandai sudah dibaca.',
        'data': {
          'id': 9,
          'dibaca': true,
          'dibaca_pada': '2026-11-17T10:00:00+07:00',
        },
      });

      final repo = h.container.read(waliRepositoryProvider);
      await repo.markRead(9);

      final request = h.adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/wali/notifikasi/9/read');
    });

    test('read-all sukses mengembalikan ditandai & belum_dibaca', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': '3 notifikasi ditandai sudah dibaca.',
        'data': {'ditandai': 3, 'belum_dibaca': 0},
      });

      final repo = h.container.read(waliRepositoryProvider);
      final result = await repo.markAllRead();

      expect(result.ditandai, 3);
      expect(result.belumDibaca, 0);
      expect(h.adapter.requests.single.method, 'PATCH');
      expect(h.adapter.requests.single.path, '/wali/notifikasi/read-all');
    });

    test('detail 404 dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(404, {
        'success': false,
        'message': 'Notifikasi tidak ditemukan.',
        'code': 'NOTIFIKASI_NOT_FOUND',
      });

      final repo = h.container.read(waliRepositoryProvider);
      try {
        await repo.notifikasiDetail(123);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 404);
        expect(e.code, 'NOTIFIKASI_NOT_FOUND');
      }
    });
  });
}
