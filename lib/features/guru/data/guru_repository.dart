import '../../../core/utils/json_cast.dart';

import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_envelope.dart';
import '../../../../shared/models/notifikasi.dart';
import '../../../../shared/models/page_meta.dart';
import 'models/absensi.dart';
import 'models/guru.dart';
import 'models/penilaian.dart';

/// Repository API guru — read-only akademik + input absensi/nilai.
///
/// Identitas guru SELALU dari token (backend); Flutter tidak pernah mengirim
/// `guru_id`/`user_id`. Otorisasi per kelas/pertemuan ditegakkan backend.
class GuruRepository {
  GuruRepository(this._dio);

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

  static List<T> _listOf<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  // ---------------- Profil & Beranda ----------------

  Future<GuruProfil> profil() => _guard(() async {
    final response = await _dio.get<dynamic>('/guru/profil');
    return GuruProfil.fromJson(ApiEnvelope.dataObject(response));
  });

  Future<GuruBeranda> beranda() => _guard(() async {
    final response = await _dio.get<dynamic>('/guru/beranda');
    return GuruBeranda.fromJson(ApiEnvelope.dataObject(response));
  });

  // ---------------- Kelas & Siswa ----------------

  Future<KelasListResponse> kelas() => _guard(() async {
    final response = await _dio.get<dynamic>('/guru/kelas');
    final data = ApiEnvelope.dataObject(response);
    final konteks = data['konteks'] is Map
        ? KonteksAkademik.fromJson(
            Map<String, dynamic>.from(data['konteks'] as Map),
          )
        : const KonteksAkademik(valid: false);
    return KelasListResponse(
      konteks: konteks,
      kelas: _listOf(data['kelas'], KelasRingkas.fromJson),
    );
  });

  Future<KelasRingkas> kelasDetail(int id) => _guard(() async {
    final response = await _dio.get<dynamic>('/guru/kelas/$id');
    return KelasRingkas.fromJson(ApiEnvelope.dataObject(response));
  });

  Future<KelasSiswaResponse> kelasSiswa(int id) => _guard(() async {
    final response = await _dio.get<dynamic>('/guru/kelas/$id/siswa');
    return KelasSiswaResponse.fromJson(ApiEnvelope.dataObject(response));
  });

  Future<List<Penugasan>> penugasan() => _guard(() async {
    final response = await _dio.get<dynamic>('/guru/penugasan');
    final data = ApiEnvelope.dataObject(response);
    return _listOf(data['penugasan'], Penugasan.fromJson);
  });

  // ---------------- Jadwal ----------------

  /// `tanggal` menang atas `hari` bila keduanya diisi (perilaku backend).
  Future<JadwalGuruResponse> jadwal({String? tanggal, int? hari}) =>
      _guard(() async {
        final response = await _dio.get<dynamic>(
          '/guru/jadwal',
          queryParameters: _params({'tanggal': tanggal, 'hari': hari}),
        );
        return JadwalGuruResponse.fromJson(ApiEnvelope.dataObject(response));
      });

  Future<JadwalGuruResponse> jadwalHariIni() => _guard(() async {
    final response = await _dio.get<dynamic>('/guru/jadwal/hari-ini');
    return JadwalGuruResponse.fromJson(ApiEnvelope.dataObject(response));
  });

  Future<JadwalGuruItem> jadwalDetail(int id) => _guard(() async {
    final response = await _dio.get<dynamic>('/guru/jadwal/$id');
    return JadwalGuruItem.fromJson(ApiEnvelope.dataObject(response));
  });

  // ---------------- Absensi harian ----------------

  Future<PagedResult<GuruAbsensiHarianItem>> absensiHarian({
    String? dari,
    String? sampai,
    String? status,
    int? kelasId,
    int? siswaId,
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/guru/absensi/harian',
      queryParameters: _params({
        'dari': dari,
        'sampai': sampai,
        'status': status,
        'kelas_id': kelasId,
        'siswa_id': siswaId,
        'page': page,
        'per_page': perPage,
      }),
    );
    final data = ApiEnvelope.dataObject(response);
    return PagedResult(
      items: _listOf(data['items'], GuruAbsensiHarianItem.fromJson),
      meta: _metaOf(response),
    );
  });

  Future<GuruAbsensiHarianDetail> absensiHarianDetail(int id) => _guard(
    () async {
      final response = await _dio.get<dynamic>('/guru/absensi/harian/$id');
      return GuruAbsensiHarianDetail.fromJson(ApiEnvelope.dataObject(response));
    },
  );

  /// Grid pengisian absensi harian (siswa + absensi tercatat).
  Future<AbsensiHarianGrid> absensiHarianGrid({
    required int kelasId,
    String? tanggal,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/guru/kelas/$kelasId/absensi',
      queryParameters: _params({'tanggal': tanggal}),
    );
    return AbsensiHarianGrid.fromJson(ApiEnvelope.dataObject(response));
  });

  /// Simpan massal (upsert per siswa). records minimal 1, maks 200.
  Future<SimpanAbsensiResult> simpanAbsensiHarian({
    required String tanggal,
    required int kelasId,
    required List<AbsensiRecordInput> records,
  }) => _guard(() async {
    final response = await _dio.post<dynamic>(
      '/guru/absensi/harian',
      data: {
        'tanggal': tanggal,
        'kelas_id': kelasId,
        'records': records.map((r) => r.toJson()).toList(),
      },
    );
    return SimpanAbsensiResult.fromJson(ApiEnvelope.dataObject(response));
  });

  /// Ubah satu record absensi harian (backend membatasi H+1).
  Future<GuruAbsensiHarianDetail> ubahAbsensiHarian({
    required int id,
    required String status,
    String? catatan,
  }) => _guard(() async {
    final response = await _dio.patch<dynamic>(
      '/guru/absensi/harian/$id',
      data: {'status': status, 'catatan': catatan},
    );
    return GuruAbsensiHarianDetail.fromJson(ApiEnvelope.dataObject(response));
  });

  // ---------------- Absensi per jam ----------------

  Future<PagedResult<GuruAbsensiPerjamItem>> absensiPerjam({
    String? dari,
    String? sampai,
    String? status,
    int? kelasId,
    int? siswaId,
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/guru/absensi/perjam',
      queryParameters: _params({
        'dari': dari,
        'sampai': sampai,
        'status': status,
        'kelas_id': kelasId,
        'siswa_id': siswaId,
        'page': page,
        'per_page': perPage,
      }),
    );
    final data = ApiEnvelope.dataObject(response);
    return PagedResult(
      items: _listOf(data['items'], GuruAbsensiPerjamItem.fromJson),
      meta: _metaOf(response),
    );
  });

  Future<GuruAbsensiPerjamDetail> absensiPerjamDetail(int id) => _guard(
    () async {
      final response = await _dio.get<dynamic>('/guru/absensi/perjam/$id');
      return GuruAbsensiPerjamDetail.fromJson(ApiEnvelope.dataObject(response));
    },
  );

  /// Daftar pertemuan pada tanggal (default hari ini).
  ///
  /// PERHATIAN — backend memicu `generateUntukTanggal(tanggal)` (idempoten)
  /// sehingga memanggil ini dapat menulis snapshot pertemuan baru.
  /// Panggil hanya saat pengguna memang membuka tab/tanggal pertemuan —
  /// BUKAN di dashboard atau prefetch agresif lain.
  Future<PertemuanResponse> pertemuan({String? tanggal}) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/guru/absensi/perjam/pertemuan',
      queryParameters: _params({'tanggal': tanggal}),
    );
    return PertemuanResponse.fromJson(ApiEnvelope.dataObject(response));
  });

  /// Grid pengisian absensi pertemuan.
  Future<AbsensiPerjamGrid> pertemuanDetail(int id) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/guru/absensi/perjam/pertemuan/$id',
    );
    return AbsensiPerjamGrid.fromJson(ApiEnvelope.dataObject(response));
  });

  /// Simpan massal per pertemuan (upsert). Payload tanpa guru_id.
  Future<SimpanAbsensiResult> simpanAbsensiPerjam({
    required int jadwalPertemuanId,
    required List<AbsensiPerjamRecordInput> records,
  }) => _guard(() async {
    final response = await _dio.post<dynamic>(
      '/guru/absensi/perjam',
      data: {
        'jadwal_pertemuan_id': jadwalPertemuanId,
        'records': records.map((r) => r.toJson()).toList(),
      },
    );
    return SimpanAbsensiResult.fromJson(ApiEnvelope.dataObject(response));
  });

  /// Ubah satu record absensi per jam (backend membatasi H+1).
  Future<AbsensiPerjamRecordEdit> ubahAbsensiPerjam({
    required int id,
    required String status,
    String? keterangan,
  }) => _guard(() async {
    final response = await _dio.patch<dynamic>(
      '/guru/absensi/perjam/$id',
      data: {'status': status, 'keterangan': keterangan},
    );
    return AbsensiPerjamRecordEdit.fromJson(ApiEnvelope.dataObject(response));
  });

  // ---------------- Penilaian ----------------

  Future<PenugasanDetail> penugasanDetail(int id) => _guard(() async {
    final response = await _dio.get<dynamic>('/guru/penilaian/penugasan/$id');
    return PenugasanDetail.fromJson(ApiEnvelope.dataObject(response));
  });

  Future<PenugasanSiswaResponse> penugasanSiswa(int id) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/guru/penilaian/penugasan/$id/siswa',
    );
    final data = ApiEnvelope.dataObject(response);
    final siswaRaw = data['siswa'];
    return PenugasanSiswaResponse(
      penugasanId: JsonCast.intOrNull(data['penugasan_id']) ?? id,
      terkunci: JsonCast.boolOrNull(data['terkunci']) ?? false,
      siswa: _listOf(siswaRaw, SiswaPenilaian.fromJson),
    );
  });

  /// Batch upsert nilai. Payload: `{nilai: {siswaId: {komponenId: 0..100|null}}}`.
  /// Nilai kosong dilewati backend (bukan menghapus nilai tersimpan).
  Future<SimpanNilaiResult> simpanNilaiBatch({
    required int penugasanId,
    required Map<int, Map<int, num?>> matriks,
  }) => _guard(() async {
    final nilai = <String, Map<String, num?>>{};
    matriks.forEach((siswaId, komponens) {
      final comps = <String, num?>{};
      komponens.forEach((k, v) => comps[k.toString()] = v);
      nilai[siswaId.toString()] = comps;
    });
    final response = await _dio.put<dynamic>(
      '/guru/penilaian/penugasan/$penugasanId/nilai',
      data: {'nilai': nilai},
    );
    return SimpanNilaiResult.fromJson(ApiEnvelope.dataObject(response));
  });

  /// Simpan satu nilai.
  Future<NilaiTunggalResult> simpanNilaiSatu({
    required int penugasanId,
    required int siswaId,
    required int komponenId,
    required num nilai,
  }) => _guard(() async {
    final response = await _dio.patch<dynamic>(
      '/guru/penilaian/penugasan/$penugasanId/nilai',
      data: {'siswa_id': siswaId, 'komponen_id': komponenId, 'nilai': nilai},
    );
    return NilaiTunggalResult.fromJson(ApiEnvelope.dataObject(response));
  });

  // ---------------- Notifikasi (bentuk response sama dengan siswa) ----------------

  Future<NotifikasiListResponse> notifikasi({
    String? status,
    String? jenis,
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/guru/notifikasi',
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
    final response = await _dio.get<dynamic>('/guru/notifikasi/unread-count');
    final data = ApiEnvelope.dataObject(response);
    return JsonCast.intOrNull(data['belum_dibaca']) ?? 0;
  });

  Future<NotifikasiItem> notifikasiDetail(int id) => _guard(() async {
    final response = await _dio.get<dynamic>('/guru/notifikasi/$id');
    return NotifikasiItem.fromJson(ApiEnvelope.dataObject(response));
  });

  Future<void> markRead(int id) => _guard(() async {
    await _dio.patch<dynamic>('/guru/notifikasi/$id/read');
  });

  Future<TandaiSemuaDibacaResult> markAllRead() => _guard(() async {
    final response = await _dio.patch<dynamic>('/guru/notifikasi/read-all');
    final data = ApiEnvelope.dataObject(response);
    return TandaiSemuaDibacaResult(
      ditandai: JsonCast.intOrNull(data['ditandai']) ?? 0,
      belumDibaca: JsonCast.intOrNull(data['belum_dibaca']) ?? 0,
    );
  });

  static PageMeta? _metaOf(Response<dynamic> response) {
    final meta = ApiEnvelope.meta(response);
    return meta == null ? null : PageMeta.fromJson(meta);
  }
}

/// Input satu record absensi harian (field backend: `catatan`).
class AbsensiRecordInput {
  const AbsensiRecordInput({
    required this.siswaId,
    required this.status,
    this.catatan,
  });

  final int siswaId;
  final String status;
  final String? catatan;

  Map<String, dynamic> toJson() => {
    'siswa_id': siswaId,
    'status': status,
    'catatan': catatan,
  };
}

/// Input untuk pertemuan per jam (field backend: `keterangan`).
class AbsensiPerjamRecordInput {
  const AbsensiPerjamRecordInput({
    required this.siswaId,
    required this.status,
    this.keterangan,
  });

  final int siswaId;
  final String status;
  final String? keterangan;

  Map<String, dynamic> toJson() => {
    'siswa_id': siswaId,
    'status': status,
    'keterangan': keterangan,
  };
}

/// Hasil penyimpanan batch absensi — `{dibuat, diubah}` dari backend.
class SimpanAbsensiResult {
  const SimpanAbsensiResult({
    required this.created,
    required this.updated,
    this.tanggal,
    this.kelasId,
  });

  final int created;
  final int updated;
  final String? tanggal;
  final int? kelasId;

  factory SimpanAbsensiResult.fromJson(Map<String, dynamic> json) =>
      SimpanAbsensiResult(
        created: JsonCast.intOrNull(json['dibuat']) ?? 0,
        updated: JsonCast.intOrNull(json['diubah']) ?? 0,
        tanggal: json['tanggal']?.toString(),
        kelasId: JsonCast.intOrNull(json['kelas_id']),
      );
}

/// Hasil edit record per jam.
class AbsensiPerjamRecordEdit {
  const AbsensiPerjamRecordEdit({
    required this.id,
    required this.status,
    this.keterangan,
  });

  final int id;
  final String status;
  final String? keterangan;

  factory AbsensiPerjamRecordEdit.fromJson(Map<String, dynamic> json) =>
      AbsensiPerjamRecordEdit(
        id: JsonCast.intOrNull(json['id']) ?? 0,
        status: (json['status'] ?? '').toString(),
        keterangan: json['keterangan']?.toString(),
      );
}

/// Respons `GET /guru/absensi/perjam/pertemuan`.
class PertemuanResponse {
  const PertemuanResponse({required this.tanggal, this.pertemuan = const []});

  final String tanggal;
  final List<PertemuanItem> pertemuan;

  factory PertemuanResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['pertemuan'];
    return PertemuanResponse(
      tanggal: (json['tanggal'] ?? '').toString(),
      pertemuan: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) => PertemuanItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

/// Respons `PUT /guru/penilaian/penugasan/{id}/nilai` — `{tersimpan: int}`.
class SimpanNilaiResult {
  const SimpanNilaiResult({required this.tersimpan});

  final int tersimpan;

  factory SimpanNilaiResult.fromJson(Map<String, dynamic> json) =>
      SimpanNilaiResult(tersimpan: JsonCast.intOrNull(json['tersimpan']) ?? 0);
}

/// Respons `PATCH .../nilai` — `{id, siswa_id, komponen_id, nilai}`.
class NilaiTunggalResult {
  const NilaiTunggalResult({
    required this.id,
    required this.siswaId,
    required this.komponenId,
    required this.nilai,
  });

  final int id;
  final int siswaId;
  final int komponenId;
  final double nilai;

  factory NilaiTunggalResult.fromJson(Map<String, dynamic> json) =>
      NilaiTunggalResult(
        id: JsonCast.intOrNull(json['id']) ?? 0,
        siswaId: JsonCast.intOrNull(json['siswa_id']) ?? 0,
        komponenId: JsonCast.intOrNull(json['komponen_id']) ?? 0,
        nilai: JsonCast.doubleOrNull(json['nilai']) ?? 0,
      );
}
