import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/errors/api_exception.dart';
import 'package:siakad_mobile/features/siswa/application/siswa_providers.dart';

import '../../fakes/harness.dart';

void main() {
  group('profil & beranda', () {
    test('profil sukses: field terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, profilSuccessBody());

      final repo = h.container.read(siswaRepositoryProvider);
      final profil = await repo.profil();

      expect(profil.nama, 'Siswa Uji');
      expect(profil.nis, 'NIS001');
      expect(profil.nisn, '0012345678');
      expect(profil.kelas.single.nama, 'X-IPA-1');
      expect(profil.akunUsername, 'siswa01');
      expect(h.adapter.requests.single.path, '/siswa/profil');
    });

    test('profil error SISWA_NOT_LINKED dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(403, {
        'success': false,
        'message':
            'Akun ini belum terhubung ke data siswa. Hubungi administrator.',
        'code': 'SISWA_NOT_LINKED',
      });

      final repo = h.container.read(siswaRepositoryProvider);
      try {
        await repo.profil();
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 403);
        expect(e.code, 'SISWA_NOT_LINKED');
      }
    });

    test('beranda sukses: identitas + konteks + kelas terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, berandaSuccessBody());

      final repo = h.container.read(siswaRepositoryProvider);
      final beranda = await repo.beranda();

      expect(beranda.nama, 'Siswa Uji');
      expect(beranda.konteks.tahunAjaranNama, 'TA-2026/2027');
      expect(beranda.konteks.semesterNama, 'Ganjil');
      expect(beranda.kelas.single.nama, 'X-IPA-1');
      expect(beranda.namaHari, 'Selasa');
      expect(beranda.jadwalHariIni, isEmpty);
    });

    test('beranda error tetap ApiException', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(500, {
        'success': false,
        'message': 'Kesalahan server. Silakan coba lagi.',
        'code': 'SERVER_ERROR',
      });

      final repo = h.container.read(siswaRepositoryProvider);
      try {
        await repo.beranda();
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.isServerError, isTrue);
        expect(e.message, 'Kesalahan server. Silakan coba lagi.');
      }
    });
  });

  group('jadwal', () {
    test('jadwal sukses: hari & nama_hari terpetakan', () async {
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

      final repo = h.container.read(siswaRepositoryProvider);
      final jadwal = await repo.jadwal(tanggal: '2026-11-17');

      expect(jadwal.hari, 2);
      expect(jadwal.namaHari, 'Selasa');
      expect(jadwal.jadwal.single.mapelNama, 'Matematika');
      expect(jadwal.jadwal.single.guruNama, 'Guru Uji');
      expect(jadwal.jadwal.single.mulai, '07:00');

      final request = h.adapter.requests.single;
      expect(request.path, '/siswa/jadwal');
      expect(request.queryParameters['tanggal'], '2026-11-17');
    });

    test('jadwal dengan hari (tanpa tanggal): param hari terkirim', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'tanggal': null,
          'hari': 3,
          'nama_hari': 'Rabu',
          'konteks': {'valid': true},
          'jadwal': <Map<String, dynamic>>[],
        },
      });

      final repo = h.container.read(siswaRepositoryProvider);
      final jadwal = await repo.jadwal(hari: 3);

      expect(jadwal.jadwal, isEmpty);
      expect(h.adapter.requests.single.queryParameters['hari'], 3);
      expect(
        h.adapter.requests.single.queryParameters.containsKey('tanggal'),
        isFalse,
      );
    });

    test('jadwal hari-ini memakai endpoint hari-ini', () async {
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

      final repo = h.container.read(siswaRepositoryProvider);
      await repo.jadwalHariIni();

      expect(h.adapter.requests.single.path, '/siswa/jadwal/hari-ini');
    });
  });

  group('absensi', () {
    Map<String, dynamic> harianBody() => {
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

    test('harian sukses: ringkasan, rekap, items, meta', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, harianBody());

      final repo = h.container.read(siswaRepositoryProvider);
      final result = await repo.absensiHarian();

      expect(result.ringkasan.hadir, 9);
      expect(result.rekapSemester.total, 20);
      expect(result.rekapSemester.persenHadir, '90,0%');
      expect(result.items.single.status, 'hadir');
      expect(result.items.single.kelasNama, 'X-IPA-1');
      expect(result.meta?.total, 1);
      expect(result.meta?.hasMore, isFalse);
    });

    test('harian dengan filter: param status/page terkirim', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, harianBody());

      final repo = h.container.read(siswaRepositoryProvider);
      await repo.absensiHarian(status: 'hadir', page: 2, perPage: 10);

      final q = h.adapter.requests.single.queryParameters;
      expect(q['status'], 'hadir');
      expect(q['page'], 2);
      expect(q['per_page'], 10);
    });

    test('periode wajib dari/sampai: param terkirim', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'periode': {'dari': '2026-11-01', 'sampai': '2026-11-17'},
          'ringkasan': {
            'total': 5,
            'hadir': 5,
            'sakit': 0,
            'izin': 0,
            'alpha': 0,
            'persen_hadir': '100,0%',
          },
          'filter': {
            'dari': '2026-11-01',
            'sampai': '2026-11-17',
            'status': null,
          },
          'items': <Map<String, dynamic>>[],
        },
        'meta': {'current_page': 1, 'per_page': 15, 'last_page': 1, 'total': 0},
      });

      final repo = h.container.read(siswaRepositoryProvider);
      final result = await repo.absensiPeriode(
        dari: '2026-11-01',
        sampai: '2026-11-17',
      );

      expect(result.dari, '2026-11-01');
      expect(result.ringkasan.persenHadir, '100,0%');
      final q = h.adapter.requests.single.queryParameters;
      expect(q['dari'], '2026-11-01');
      expect(q['sampai'], '2026-11-17');
    });

    test('per jam sukses: snapshot pertemuan terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'rekap': {
            'total': 2,
            'hadir': 1,
            'sakit': 0,
            'izin': 0,
            'alpha': 1,
            'persen_hadir': '50,0%',
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
              'status': 'alpha',
              'keterangan': null,
              'pertemuan_status': 'berlangsung',
              'kelas_nama': 'X-IPA-1',
              'mapel_nama': 'Matematika',
              'guru_nama': 'Guru Uji',
            },
          ],
        },
        'meta': {'current_page': 1, 'per_page': 15, 'last_page': 1, 'total': 1},
      });

      final repo = h.container.read(siswaRepositoryProvider);
      final result = await repo.absensiPerjam();

      expect(result.items.single.mapelNama, 'Matematika');
      expect(result.items.single.status, 'alpha');
      expect(result.rekap.alpha, 1);
      expect(result.rekapTotal.hadir, 28);
    });

    test('422 periode dengan dari > sampai dipetakan validation', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(422, {
        'success': false,
        'message': 'Validasi gagal.',
        'errors': {
          'sampai': ['Tanggal akhir tidak boleh sebelum tanggal awal.'],
        },
      });

      final repo = h.container.read(siswaRepositoryProvider);
      try {
        await repo.absensiPeriode(dari: '2026-11-17', sampai: '2026-11-01');
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.isValidation, isTrue);
        expect(e.fieldErrors['sampai'], isNotEmpty);
      }
    });
  });

  group('nilai & rapor', () {
    test('nilai sukses: kelompok semester+kelas terpetakan', () async {
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
                  'nilai_akhir': 85.5,
                  'nilai_kktp': 75,
                  'keterangan': 'Tuntas',
                },
              ],
            },
          ],
        },
      });

      final repo = h.container.read(siswaRepositoryProvider);
      final groups = await repo.nilai();

      expect(groups.single.nilai.single.mapelNama, 'Matematika');
      expect(groups.single.nilai.single.nilaiAkhir, 85.5);
      expect(groups.single.nilai.single.nilaiKktp, 75);
      expect(groups.single.semester.tahunAjaranNama, 'TA-2026/2027');
    });

    test('nilai 404 NILAI_NOT_FOUND dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(404, {
        'success': false,
        'message': 'Nilai untuk filter tersebut tidak tersedia.',
        'code': 'NILAI_NOT_FOUND',
      });

      final repo = h.container.read(siswaRepositoryProvider);
      try {
        await repo.nilai(semesterId: 11, kelasId: 99);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.isNotFound, isTrue);
        expect(e.code, 'NILAI_NOT_FOUND');
      }
    });

    test('daftar rapor sukses', () async {
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
              'wali_kelas': 'Wali Uji',
              'difinalisasi_pada': '2026-11-15T10:00:00+07:00',
            },
          ],
        },
      });

      final repo = h.container.read(siswaRepositoryProvider);
      final rapor = await repo.rapor();

      expect(rapor.single.waliKelas, 'Wali Uji');
      expect(rapor.single.semester.nama, 'Ganjil');
    });

    test('detail rapor sukses: nilai + rekap kehadiran terpetakan', () async {
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
      });

      final repo = h.container.read(siswaRepositoryProvider);
      final detail = await repo.raporDetail(semesterId: 11, kelasId: 99);

      expect(h.adapter.requests.single.path, '/siswa/rapor/11/99');
      expect(detail.isFinal, isTrue);
      expect(detail.nilai.single.nilaiAkhir, 88);
      expect(detail.rekapKehadiran.hadir, 40);
      expect(detail.catatan, 'Tingkatkan terus.');
      expect(detail.namaSekolah, 'SMA Uji');
    });

    test('detail rapor 404 RAPOR_NOT_FOUND dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(404, {
        'success': false,
        'message': 'Rapor ini tidak tersedia.',
        'code': 'RAPOR_NOT_FOUND',
      });

      final repo = h.container.read(siswaRepositoryProvider);
      try {
        await repo.raporDetail(semesterId: 99, kelasId: 99);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.code, 'RAPOR_NOT_FOUND');
      }
    });
  });

  group('pengumuman', () {
    test('daftar pengumuman sukses: tab & items terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'tab': 'aktif',
          'items': [
            {
              'id': 3,
              'judul': 'Pengumuman UAT',
              'isi': 'Isi pengumuman.',
              'kategori': 'Akademik',
              'prioritas': 'tinggi',
              'waktu_terbit': '2026-11-17T08:00:00+07:00',
              'berlaku_dari': '2026-11-17',
              'berlaku_sampai': '2026-11-30',
              'dibaca': false,
              'dibaca_pada': null,
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

      final repo = h.container.read(siswaRepositoryProvider);
      final result = await repo.pengumuman(tab: 'aktif');

      expect(result.items.single.judul, 'Pengumuman UAT');
      expect(result.items.single.dibaca, isFalse);
      expect(h.adapter.requests.single.queryParameters['tab'], 'aktif');
    });

    test('detail pengumuman sukses (backend auto-tandai dibaca)', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'id': 3,
          'judul': 'Pengumuman UAT',
          'isi': 'Isi.',
          'kategori': 'Umum',
          'prioritas': 'normal',
          'waktu_terbit': '2026-11-17T08:00:00+07:00',
          'berlaku_dari': null,
          'berlaku_sampai': null,
          'dibaca': true,
          'dibaca_pada': '2026-11-17T09:00:00+07:00',
        },
      });

      final repo = h.container.read(siswaRepositoryProvider);
      final item = await repo.pengumumanDetail(3);

      expect(item.dibaca, isTrue);
      expect(h.adapter.requests.single.path, '/siswa/pengumuman/3');
    });
  });

  group('notifikasi', () {
    Map<String, dynamic> listBody({int belumDibaca = 1}) => {
      'success': true,
      'message': 'Berhasil',
      'data': {
        'items': [
          {
            'id': 9,
            'judul': 'Pemberitahuan',
            'isi': 'Isi notifikasi.',
            'jenis': 'pengumuman',
            'prioritas': 'normal',
            'waktu_dibuat': '2026-11-17T08:00:00+07:00',
            'sumber_tabel': 'pengumuman',
            'sumber_id': 3,
            'link': null,
            'dibaca': false,
            'dibaca_pada': null,
          },
        ],
        'belum_dibaca': belumDibaca,
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

    test('daftar notifikasi + belum_dibaca terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, listBody());

      final repo = h.container.read(siswaRepositoryProvider);
      final result = await repo.notifikasi(status: 'unread');

      expect(result.items.single.judul, 'Pemberitahuan');
      expect(result.belumDibaca, 1);
      expect(h.adapter.requests.single.queryParameters['status'], 'unread');
    });

    test('unread count sukses', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, unreadCountBody(count: 4));

      final repo = h.container.read(siswaRepositoryProvider);
      expect(await repo.unreadCount(), 4);
      expect(h.adapter.requests.single.path, '/siswa/notifikasi/unread-count');
    });

    test('detail notifikasi sukses', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'id': 9,
          'judul': 'Pemberitahuan',
          'isi': 'Detail.',
          'jenis': 'pengumuman',
          'prioritas': 'normal',
          'waktu_dibuat': '2026-11-17T08:00:00+07:00',
          'sumber_tabel': null,
          'sumber_id': null,
          'link': null,
          'dibaca': false,
          'dibaca_pada': null,
        },
      });

      final repo = h.container.read(siswaRepositoryProvider);
      final item = await repo.notifikasiDetail(9);

      expect(item.id, 9);
      expect(item.dibaca, isFalse);
    });

    test(
      'markRead memanggil PATCH /read dan melempar error bila gagal',
      () async {
        final h = buildTestHarness();
        addTearDown(h.container.dispose);
        h.adapter.respondJson(200, {
          'success': true,
          'message': 'Notifikasi ditandai sudah dibaca.',
          'data': {
            'id': 9,
            'dibaca': true,
            'dibaca_pada': '2026-11-17T09:00:00+07:00',
          },
        });

        final repo = h.container.read(siswaRepositoryProvider);
        await repo.markRead(9);

        expect(h.adapter.requests.single.method, 'PATCH');
        expect(h.adapter.requests.single.path, '/siswa/notifikasi/9/read');
      },
    );

    test(
      'markAllRead memanggil PATCH read-all dan mengembalikan hasil',
      () async {
        final h = buildTestHarness();
        addTearDown(h.container.dispose);
        h.adapter.respondJson(200, {
          'success': true,
          'message': '5 notifikasi ditandai sudah dibaca.',
          'data': {'ditandai': 5, 'belum_dibaca': 0},
        });

        final repo = h.container.read(siswaRepositoryProvider);
        final result = await repo.markAllRead();

        expect(result.ditandai, 5);
        expect(result.belumDibaca, 0);
        expect(h.adapter.requests.single.path, '/siswa/notifikasi/read-all');
      },
    );
  });
}
