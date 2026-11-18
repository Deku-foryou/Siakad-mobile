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
        'jumlah_siswa': 2,
        'mapel': [
          {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
        ],
      },
    ],
    'ringkasan': {
      'jumlah_kelas': 1,
      'jumlah_penugasan': 1,
      'pertemuan_hari_ini': 1,
      'absensi_perjam_hari_ini': 2,
      'absensi_harian_hari_ini': 2,
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

Map<String, dynamic> guruKelasListBody() => {
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
        'sumber': ['mengajar'],
        'jumlah_siswa': 2,
        'mapel': [
          {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
        ],
      },
    ],
  },
};

Map<String, dynamic> guruPenugasanBody() => {
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

Map<String, dynamic> guruJadwalBody() => {
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

Map<String, dynamic> guruPenugasanDetailBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'id': 501,
    'semester': {'id': 11, 'nama': 'Ganjil', 'tahun_ajaran': 'TA-2026/2027'},
    'kelas': {'id': 99, 'nama': 'X-IPA-1', 'tingkat': 'X'},
    'mapel': {'id': 1, 'kode': 'MAT', 'nama': 'Matematika'},
    'jumlah_siswa': 2,
    'komponen': [
      {'id': 601, 'nama': 'Tugas', 'bobot': 50.0, 'urutan': 1},
      {'id': 602, 'nama': 'UTS', 'bobot': 50.0, 'urutan': 2},
    ],
    'total_bobot_aktif': 100.0,
    'konfigurasi_valid': true,
    'terkunci': false,
  },
};

Map<String, dynamic> guruPenugasanSiswaBody() => {
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
        'nilai': {'601': null, '602': null},
        'nilai_draft': null,
        'lengkap': false,
        'jumlah_terisi': 0,
        'jumlah_komponen': 2,
        'bobot_terisi': 0.0,
        'bobot_total': 100.0,
        'konfigurasi_valid': true,
      },
    ],
  },
};

Map<String, dynamic> guruHarianGridBody() => {
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

Map<String, dynamic> guruAbsensiHarianBody() => {
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
};

Map<String, dynamic> guruHarianListBody() => guruAbsensiHarianBody();

Map<String, dynamic> guruPertemuanBody() => {
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
        'jumlah_siswa': 2,
        'jumlah_absensi': 1,
        'bisa_diabsen': true,
      },
    ],
  },
};

Map<String, dynamic> guruPerjamGridBody() => {
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
      {'id': 1002, 'nisn': '002', 'nama': 'Siswa B', 'absensi': null},
    ],
  },
};

Map<String, dynamic> guruNotifikasiBody() => {
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

Map<String, dynamic> waliProfilBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'id': 881,
    'name': 'Wali Uji',
    'username': 'wali01',
    'email': 'wali@example.test',
    'status_akun': 'aktif',
    'wajib_ganti_password': false,
    'relasi': {'verified': 2, 'pending': 1, 'rejected': 0, 'terminated': 0},
  },
};

Map<String, dynamic> waliBerandaBody() => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'user': {'id': 881, 'name': 'Wali Uji', 'username': 'wali01'},
    'akun': {'username': 'wali01', 'wajib_ganti_password': false},
    'konteks': {
      'valid': true,
      'peringatan': <String>[],
      'tahun_ajaran': {'id': 10, 'nama': 'TA-2026/2027'},
      'semester': {'id': 11, 'nama': 'Ganjil'},
    },
    'anak': [
      {
        'id': 201,
        'nisn': '0011111111',
        'nis': 'NIS201',
        'nama': 'Andi Anak',
        'kelas': 'X-IPA-1',
      },
      {
        'id': 202,
        'nisn': '0022222222',
        'nis': 'NIS202',
        'nama': 'Budi Anak',
        'kelas': 'VIII-A',
      },
    ],
    'ringkasan': {
      'jumlah_anak': 2,
      'jumlah_menunggu': 1,
      'jumlah_ditolak': 0,
      'jumlah_berakhir': 0,
      'notifikasi_belum_dibaca': 3,
    },
    'nama_hari': 'Selasa',
  },
};

Map<String, dynamic> waliAnakListBody({
  List<Map<String, dynamic>>? anak,
  bool konteksValid = true,
}) => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'konteks': {
      'valid': konteksValid,
      'peringatan': <String>[],
      'tahun_ajaran': {'id': 10, 'nama': 'TA-2026/2027'},
      'semester': {'id': 11, 'nama': 'Ganjil'},
    },
    'anak':
        anak ??
        [
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
              'nisn': '0011111111',
              'nis': 'NIS201',
              'nama': 'Andi Anak',
              'jenis_kelamin': 'L',
              'tahun_masuk': 2024,
              'status': 'aktif',
            },
          },
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
              'nisn': '0022222222',
              'nis': 'NIS202',
              'nama': 'Budi Anak',
              'jenis_kelamin': 'L',
              'tahun_masuk': 2025,
              'status': 'aktif',
            },
          },
        ],
  },
};

Map<String, dynamic> waliAnakDetailBody({
  int siswaId = 201,
  String statusHubungan = 'verified',
  bool bisaAksesAkademik = true,
}) => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'relasi_id': 501,
    'hubungan': 'ayah',
    'status_hubungan': statusHubungan,
    'tanggal_mulai': '2026-07-01',
    'tanggal_berhenti': statusHubungan == 'terminated' ? '2026-10-01' : null,
    'tanggal_verifikasi': '2026-07-05T08:00:00+07:00',
    'bisa_akses_akademik': bisaAksesAkademik,
    'kelas': 'X-IPA-1',
    'siswa': {
      'id': siswaId,
      'nisn': '0011111111',
      'nis': 'NIS201',
      'nama': 'Andi Anak',
      'jenis_kelamin': 'L',
      'tahun_masuk': 2024,
      'status': 'aktif',
    },
    'histori': [
      {
        'event': 'verifikasi',
        'status_sebelum': 'pending',
        'status_sesudah': 'verified',
        'aktor_peran': 'admin',
        'alasan': null,
        'tanggal_mulai_sesudah': '2026-07-01',
        'tanggal_berhenti_sesudah': null,
        'created_at': '2026-07-05 08:00:00',
      },
    ],
  },
};

Map<String, dynamic> waliAnakBerandaBody({int siswaId = 201}) => {
  'success': true,
  'message': 'Berhasil',
  'data': {
    'siswa': {
      'id': siswaId,
      'nisn': '0011111111',
      'nis': 'NIS201',
      'nama': 'Andi Anak',
      'tahun_masuk': 2024,
      'status': 'aktif',
    },
    'akun': {'username': 'andi01', 'wajib_ganti_password': false},
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
