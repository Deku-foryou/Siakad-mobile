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

  (int, Map<String, dynamic>) _for(String path) {
    final normalized = path.replaceFirst(RegExp(r'^https?://[^/]+'), '');
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
    final (statusCode, body) = _for(options.path);
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
