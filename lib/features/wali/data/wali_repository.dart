import '../../../core/utils/json_cast.dart';

import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../../../shared/models/notifikasi.dart';
import '../../../shared/models/page_meta.dart';
import '../../siswa/data/models/absensi.dart';
import '../../siswa/data/models/beranda.dart';
import '../../siswa/data/models/nilai.dart';
import 'models/wali.dart';

/// Repository API wali murid — `/api/v1/wali/*`.
///
/// Kontrak (diaudit dari backend Laravel aktual):
/// - Identitas wali selalu dari token; `siswaId` HANYA path parameter
///   `{siswaId}` yang divalidasi backend terhadap relasi milik wali.
/// - Akses akademik: backend menegakkan relasi `verified` + tanpa
///   `tanggal_berhenti`. Pelanggaran → 403 `AKSES_DITOLAK`.
/// - Filter rapor bila `semester_id`/`kelas_id` diisi & kosong → 404
///   `NILAI_NOT_FOUND`.
/// - `per_page` maks 50; meta pagination hanya pada endpoint histori
///   absensi (`absensi.harian|periode|perjam`) dan notifikasi.
class WaliRepository {
  WaliRepository(this._dio);

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

  static PageMeta? _metaOf(Response<dynamic> response) {
    final meta = ApiEnvelope.meta(response);
    return meta == null ? null : PageMeta.fromJson(meta);
  }

  // ---------------- A. Akun & relasi ----------------

  Future<ProfilWali> profil() => _guard(() async {
    final response = await _dio.get<dynamic>('/wali/profil');
    return ProfilWali.fromJson(ApiEnvelope.dataObject(response));
  });

  Future<BerandaWali> beranda() => _guard(() async {
    final response = await _dio.get<dynamic>('/wali/beranda');
    return BerandaWali.fromJson(ApiEnvelope.dataObject(response));
  });

  /// Seluruh relasi milik wali (semua status: pending/verified/rejected/terminated).
  Future<AnakListResponse> anak() => _guard(() async {
    final response = await _dio.get<dynamic>('/wali/anak');
    return AnakListResponse.fromJson(ApiEnvelope.dataObject(response));
  });

  /// Detail relasi 1 anak (+histori). 404 `ANAK_NOT_FOUND` bila bukan milik wali.
  Future<AnakDetail> anakDetail(int siswaId) => _guard(() async {
    final response = await _dio.get<dynamic>('/wali/anak/$siswaId');
    return AnakDetail.fromJson(ApiEnvelope.dataObject(response));
  });

  // ---------------- B. Akademik anak ----------------

  /// Beranda anak (identik portal siswa). 403 bila relasi tidak verified.
  Future<BerandaSiswa> anakBeranda(int siswaId) => _guard(() async {
    final response = await _dio.get<dynamic>('/wali/anak/$siswaId/beranda');
    return BerandaSiswa.fromJson(ApiEnvelope.dataObject(response));
  });

  /// `tanggal` menang atas `hari` bila keduanya diisi (perilaku backend).
  Future<JadwalResponse> anakJadwal(
    int siswaId, {
    String? tanggal,
    int? hari,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/wali/anak/$siswaId/jadwal',
      queryParameters: _params({'tanggal': tanggal, 'hari': hari}),
    );
    return JadwalResponse.fromJson(ApiEnvelope.dataObject(response));
  });

  Future<JadwalResponse> anakJadwalHariIni(int siswaId) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/wali/anak/$siswaId/jadwal/hari-ini',
    );
    return JadwalResponse.fromJson(ApiEnvelope.dataObject(response));
  });

  Future<AbsensiHarianResponse> anakAbsensiHarian(
    int siswaId, {
    String? dari,
    String? sampai,
    String? status,
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/wali/anak/$siswaId/absensi/harian',
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

  Future<AbsensiPeriodeResponse> anakAbsensiPeriode(
    int siswaId, {
    required String dari,
    required String sampai,
    String? status,
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/wali/anak/$siswaId/absensi/periode',
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

  Future<AbsensiPerjamResponse> anakAbsensiPerjam(
    int siswaId, {
    String? dari,
    String? sampai,
    String? status,
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/wali/anak/$siswaId/absensi/perjam',
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

  /// Nilai akhir (snapshot rapor final). Filter opsional semesterId/kelasId;
  /// backend 404 `NILAI_NOT_FOUND` bila filter diisi tetapi kosong.
  Future<List<NilaiKelompok>> anakNilai(
    int siswaId, {
    int? semesterId,
    int? kelasId,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/wali/anak/$siswaId/nilai',
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

  Future<List<RaporEntry>> anakRapor(int siswaId) => _guard(() async {
    final response = await _dio.get<dynamic>('/wali/anak/$siswaId/rapor');
    final data = ApiEnvelope.dataObject(response);
    final rapor = data['rapor'];
    if (rapor is! List) return const [];
    return rapor
        .whereType<Map>()
        .map((e) => RaporEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  });

  /// Detail rapor final. 404 `RAPOR_NOT_FOUND` bila tidak tersedia.
  Future<RaporDetail> anakRaporDetail({
    required int siswaId,
    required int semesterId,
    required int kelasId,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/wali/anak/$siswaId/rapor/$semesterId/$kelasId',
    );
    return RaporDetail.fromJson(ApiEnvelope.dataObject(response));
  });

  // ---------------- C. Notifikasi ----------------

  Future<NotifikasiListResponse> notifikasi({
    String? status, // 'read' | 'unread' | null
    String? jenis,
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/wali/notifikasi',
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
    final response = await _dio.get<dynamic>('/wali/notifikasi/unread-count');
    final data = ApiEnvelope.dataObject(response);
    return JsonCast.intOrNull(data['belum_dibaca']) ?? 0;
  });

  Future<NotifikasiItem> notifikasiDetail(int id) => _guard(() async {
    final response = await _dio.get<dynamic>('/wali/notifikasi/$id');
    return NotifikasiItem.fromJson(ApiEnvelope.dataObject(response));
  });

  /// Tandai satu notifikasi dibaca. UI tidak optimistic.
  Future<void> markRead(int id) => _guard(() async {
    await _dio.patch<dynamic>('/wali/notifikasi/$id/read');
  });

  Future<TandaiSemuaDibacaResult> markAllRead() => _guard(() async {
    final response = await _dio.patch<dynamic>('/wali/notifikasi/read-all');
    final data = ApiEnvelope.dataObject(response);
    return TandaiSemuaDibacaResult(
      ditandai: JsonCast.intOrNull(data['ditandai']) ?? 0,
      belumDibaca: JsonCast.intOrNull(data['belum_dibaca']) ?? 0,
    );
  });
}
