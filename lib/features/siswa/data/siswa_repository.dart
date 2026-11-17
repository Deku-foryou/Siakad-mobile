import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_envelope.dart';
import 'models/absensi.dart';
import 'models/beranda.dart';
import 'models/nilai.dart';
import '../../../shared/models/notifikasi.dart';
import '../../../shared/models/page_meta.dart';
import 'models/pengumuman.dart';

/// Repository akademik & komunikasi siswa — read-only (kecuali tandai dibaca).
///
/// Semua request memakai instance Dio terpusat dan error dinormalisasi
/// menjadi [ApiException]. Identitas siswa selalu dari token (backend);
/// repository ini TIDAK menerima parameter siswa_id.
class SiswaRepository {
  SiswaRepository(this._dio);

  final Dio _dio;

  Map<String, dynamic> _params(Map<String, Object?> raw) {
    final params = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value != null && value != '') params[key] = value;
    });
    return params;
  }

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  // ---------------- Profil & Beranda ----------------

  Future<ProfilSiswa> profil() => _guard(() async {
    final response = await _dio.get<dynamic>('/siswa/profil');
    return ProfilSiswa.fromJson(ApiEnvelope.dataObject(response));
  });

  Future<BerandaSiswa> beranda() => _guard(() async {
    final response = await _dio.get<dynamic>('/siswa/beranda');
    return BerandaSiswa.fromJson(ApiEnvelope.dataObject(response));
  });

  // ---------------- Jadwal ----------------

  /// `tanggal` menang atas `hari` bila keduanya diisi (perilaku backend).
  Future<JadwalResponse> jadwal({String? tanggal, int? hari}) =>
      _guard(() async {
        final response = await _dio.get<dynamic>(
          '/siswa/jadwal',
          queryParameters: _params({'tanggal': tanggal, 'hari': hari}),
        );
        return JadwalResponse.fromJson(ApiEnvelope.dataObject(response));
      });

  Future<JadwalResponse> jadwalHariIni() => _guard(() async {
    final response = await _dio.get<dynamic>('/siswa/jadwal/hari-ini');
    return JadwalResponse.fromJson(ApiEnvelope.dataObject(response));
  });

  // ---------------- Absensi ----------------

  Future<AbsensiHarianResponse> absensiHarian({
    String? dari,
    String? sampai,
    String? status,
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/siswa/absensi/harian',
      queryParameters: _params({
        'dari': dari,
        'sampai': sampai,
        'status': status,
        'page': page,
        'per_page': perPage,
      }),
    );
    return AbsensiHarianResponse.fromJson(
      ApiEnvelope.dataObject(response),
      _metaOf(response),
    );
  });

  Future<AbsensiPeriodeResponse> absensiPeriode({
    required String dari,
    required String sampai,
    String? status,
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/siswa/absensi/periode',
      queryParameters: _params({
        'dari': dari,
        'sampai': sampai,
        'status': status,
        'page': page,
        'per_page': perPage,
      }),
    );
    return AbsensiPeriodeResponse.fromJson(
      ApiEnvelope.dataObject(response),
      _metaOf(response),
    );
  });

  Future<AbsensiPerjamResponse> absensiPerjam({
    String? dari,
    String? sampai,
    String? status,
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/siswa/absensi/perjam',
      queryParameters: _params({
        'dari': dari,
        'sampai': sampai,
        'status': status,
        'page': page,
        'per_page': perPage,
      }),
    );
    return AbsensiPerjamResponse.fromJson(
      ApiEnvelope.dataObject(response),
      _metaOf(response),
    );
  });

  // ---------------- Nilai & Rapor ----------------

  /// Nilai akhir (hanya snapshot rapor final). Filter opsional `semesterId`/`kelasId`.
  /// Backend mengembalikan 404 NILAI_NOT_FOUND bila filter diisi tetapi kosong.
  Future<List<NilaiKelompok>> nilai({int? semesterId, int? kelasId}) =>
      _guard(() async {
        final response = await _dio.get<dynamic>(
          '/siswa/nilai',
          queryParameters: _params({
            'semester_id': semesterId,
            'kelas_id': kelasId,
          }),
        );
        final data = ApiEnvelope.dataObject(response);
        final rapor = data['rapor'];
        if (rapor is! List) return const [];
        return rapor
            .whereType<Map>()
            .map((e) => NilaiKelompok.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });

  Future<List<RaporEntry>> rapor() => _guard(() async {
    final response = await _dio.get<dynamic>('/siswa/rapor');
    final data = ApiEnvelope.dataObject(response);
    final rapor = data['rapor'];
    if (rapor is! List) return const [];
    return rapor
        .whereType<Map>()
        .map((e) => RaporEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  });

  Future<RaporDetail> raporDetail({
    required int semesterId,
    required int kelasId,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/siswa/rapor/$semesterId/$kelasId',
    );
    return RaporDetail.fromJson(ApiEnvelope.dataObject(response));
  });

  // ---------------- Pengumuman ----------------

  Future<PagedResult<PengumumanItem>> pengumuman({
    String tab = 'aktif',
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/siswa/pengumuman',
      queryParameters: _params({'tab': tab, 'page': page, 'per_page': perPage}),
    );
    final data = ApiEnvelope.dataObject(response);
    final items = data['items'];
    return PagedResult<PengumumanItem>(
      items: items is List
          ? items
                .whereType<Map>()
                .map(
                  (e) => PengumumanItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      meta: _metaOf(response),
    );
  });

  /// Detail pengumuman — backend otomatis menandai dibaca (idempoten).
  Future<PengumumanItem> pengumumanDetail(int id) => _guard(() async {
    final response = await _dio.get<dynamic>('/siswa/pengumuman/$id');
    return PengumumanItem.fromJson(ApiEnvelope.dataObject(response));
  });

  // ---------------- Notifikasi ----------------

  Future<NotifikasiListResponse> notifikasi({
    String? status, // 'read' | 'unread' | null
    String? jenis,
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/siswa/notifikasi',
      queryParameters: _params({
        'status': status,
        'jenis': jenis,
        'page': page,
        'per_page': perPage,
      }),
    );
    return NotifikasiListResponse.fromJson(
      ApiEnvelope.dataObject(response),
      _metaOf(response),
    );
  });

  Future<int> unreadCount() => _guard(() async {
    final response = await _dio.get<dynamic>('/siswa/notifikasi/unread-count');
    final data = ApiEnvelope.dataObject(response);
    return (data['belum_dibaca'] as num?)?.toInt() ?? 0;
  });

  Future<NotifikasiItem> notifikasiDetail(int id) => _guard(() async {
    final response = await _dio.get<dynamic>('/siswa/notifikasi/$id');
    return NotifikasiItem.fromJson(ApiEnvelope.dataObject(response));
  });

  /// Tandai satu notifikasi dibaca. Tidak optimistic — UI harus menunggu
  /// hasil backend.
  Future<void> markRead(int id) => _guard(() async {
    await _dio.patch<dynamic>('/siswa/notifikasi/$id/read');
  });

  /// Tandai seluruh notifikasi dibaca. Mengembalikan jumlah yang ditandai.
  Future<TandaiSemuaDibacaResult> markAllRead() => _guard(() async {
    final response = await _dio.patch<dynamic>('/siswa/notifikasi/read-all');
    final data = ApiEnvelope.dataObject(response);
    return TandaiSemuaDibacaResult(
      ditandai: (data['ditandai'] as num?)?.toInt() ?? 0,
      belumDibaca: (data['belum_dibaca'] as num?)?.toInt() ?? 0,
    );
  });

  static PageMeta? _metaOf(Response<dynamic> response) {
    final meta = ApiEnvelope.meta(response);
    return meta == null ? null : PageMeta.fromJson(meta);
  }
}
