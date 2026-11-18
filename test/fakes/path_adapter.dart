import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'harness.dart';

/// Fake adapter yang menjawab berdasarkan path request tanpa urutan antrean.
/// Dipakai widget test yang memicu banyak request paralel di shell siswa.
class PathAdapter implements HttpClientAdapter {
  PathAdapter({this.overrides = const {}});

  /// path → (statusCode, JSON body). Bila tidak ada, fallback default aman.
  final Map<String, (int, Map<String, dynamic>)> overrides;

  final List<RequestOptions> requests = [];

  (int, Map<String, dynamic>) _for(String path, String method) {
    final normalized = path.replaceFirst(RegExp(r'^https?://[^/]+'), '');
    // Kunci dengan prefix method (opsional): 'POST /guru/absensi/harian'
    final methodKey = '$method $normalized';
    if (overrides.containsKey(methodKey)) return overrides[methodKey]!;
    if (overrides.containsKey(normalized)) return overrides[normalized]!;
    // Fallback per prefix
    if (normalized.contains('/auth/me')) {
      return (200, meSuccessBody());
    }
    if (normalized.contains('/siswa/beranda')) {
      return (200, berandaSuccessBody());
    }
    if (normalized.contains('/siswa/profil')) {
      return (200, profilSuccessBody());
    }
    if (normalized.contains('/siswa/notifikasi/unread-count')) {
      return (200, unreadCountBody());
    }
    if (normalized.contains('/siswa/notifikasi')) {
      return (200, notifikasiListBody());
    }
    if (normalized.contains('/keuangan/tagihan')) {
      return (200, tagihanListBody());
    }
    if (normalized.contains('/keuangan/ringkasan')) {
      return (200, ringkasanKeuanganBody());
    }
    if (normalized.contains('/keuangan/saldo')) {
      return (
        200,
        {
          'success': true,
          'message': 'Berhasil',
          'data': {'saldo': 250000},
        },
      );
    }
    if (normalized.contains('/keuangan/pembayaran')) {
      return (
        200,
        {
          'success': true,
          'message': 'Berhasil',
          'data': <Map<String, dynamic>>[],
          'meta': {
            'current_page': 1,
            'per_page': 15,
            'last_page': 1,
            'total': 0,
          },
        },
      );
    }
    if (normalized.contains('/siswa/pengumuman')) {
      return (
        200,
        {
          'success': true,
          'message': 'Berhasil',
          'data': {'tab': 'aktif', 'items': <Map<String, dynamic>>[]},
          'meta': {
            'current_page': 1,
            'per_page': 15,
            'last_page': 1,
            'total': 0,
          },
        },
      );
    }
    // ---------------- Wali ----------------
    if (normalized.contains('/wali/beranda')) {
      return (200, waliBerandaBody());
    }
    if (normalized.contains('/wali/profil')) {
      return (200, waliProfilBody());
    }
    if (normalized.contains('/wali/notifikasi/unread-count')) {
      return (200, unreadCountBody(count: 3));
    }
    if (normalized.contains('/wali/notifikasi')) {
      return (200, notifikasiListBody());
    }
    if (normalized.contains('/wali/anak/201/beranda')) {
      return (200, waliAnakBerandaBody(siswaId: 201));
    }
    if (normalized.contains('/wali/anak/202/beranda')) {
      return (200, waliAnakBerandaBody(siswaId: 202));
    }
    final anakDetailMatch = RegExp(r'/wali/anak/(\d+)$').firstMatch(normalized);
    if (anakDetailMatch != null) {
      final id = int.parse(anakDetailMatch.group(1)!);
      final verified = id == 201;
      return (
        200,
        waliAnakDetailBody(
          siswaId: id,
          statusHubungan: verified ? 'verified' : 'pending',
          bisaAksesAkademik: verified,
        ),
      );
    }
    if (normalized.contains('/wali/anak')) {
      return (200, waliAnakListBody());
    }
    if (normalized.contains('/guru/beranda')) {
      return (200, guruBerandaBody());
    }
    if (normalized.contains('/guru/profil')) {
      return (200, guruProfilBody());
    }
    if (normalized.contains('/guru/notifikasi/unread-count')) {
      return (200, unreadCountBody(count: 2));
    }
    if (normalized.contains('/guru/notifikasi')) {
      return (200, notifikasiListBody());
    }
    if (normalized.contains('/guru/kelas') &&
        !normalized.contains('/guru/kelas/')) {
      return (200, guruKelasListBody());
    }
    if (normalized.contains('/guru/penugasan')) {
      return (200, guruPenugasanBody());
    }
    if (normalized.contains('/guru/jadwal')) {
      return (200, guruJadwalBody());
    }
    if (normalized.contains('/guru/penilaian/penugasan/')) {
      return (200, guruPenugasanDetailBody());
    }
    if (normalized.contains('/guru/absensi/harian') &&
        !normalized.contains('/guru/kelas/')) {
      return (200, guruHarianListBody());
    }
    if (normalized.contains('/guru/absensi/perjam/pertemuan') &&
        !normalized.contains('/guru/absensi/perjam/pertemuan/')) {
      return (200, guruPertemuanBody());
    }
    return (
      404,
      {'success': false, 'message': 'Tidak ditemukan.', 'code': 'NOT_FOUND'},
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (statusCode, body) = _for(options.path, options.method);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: const {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
