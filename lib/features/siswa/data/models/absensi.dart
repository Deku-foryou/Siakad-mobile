import '../../../../core/utils/json_cast.dart';
import '../../../../shared/models/page_meta.dart';

/// Item absensi harian — `AbsensiHarianResource` backend.
class AbsensiHarianItem {
  const AbsensiHarianItem({
    required this.tanggal,
    required this.status,
    this.catatan,
    required this.kelasId,
    required this.kelasNama,
  });

  final String? tanggal;
  final String status;
  final String? catatan;
  final int? kelasId;
  final String? kelasNama;

  factory AbsensiHarianItem.fromJson(Map<String, dynamic> json) {
    final kelas = json['kelas'];
    return AbsensiHarianItem(
      tanggal: json['tanggal']?.toString(),
      status: (json['status'] ?? '').toString(),
      catatan: json['catatan']?.toString(),
      kelasId: (kelas is Map ? JsonCast.intOrNull(kelas['id']) : null),
      kelasNama: kelas is Map ? kelas['nama']?.toString() : null,
    );
  }
}

/// Item absensi per jam — `AbsensiPerjamResource` backend.
class AbsensiPerjamItem {
  const AbsensiPerjamItem({
    required this.tanggal,
    this.hari,
    this.namaHari,
    this.jamKe,
    this.waktuMulai,
    this.waktuSelesai,
    required this.status,
    this.keterangan,
    this.pertemuanStatus,
    this.kelasNama,
    this.mapelNama,
    this.guruNama,
  });

  final String? tanggal;
  final int? hari;
  final String? namaHari;
  final int? jamKe;
  final String? waktuMulai;
  final String? waktuSelesai;
  final String status;
  final String? keterangan;
  final String? pertemuanStatus;
  final String? kelasNama;
  final String? mapelNama;
  final String? guruNama;

  factory AbsensiPerjamItem.fromJson(Map<String, dynamic> json) =>
      AbsensiPerjamItem(
        tanggal: json['tanggal']?.toString(),
        hari: JsonCast.intOrNull(json['hari']),
        namaHari: json['nama_hari']?.toString(),
        jamKe: JsonCast.intOrNull(json['jam_ke']),
        waktuMulai: json['waktu_mulai']?.toString(),
        waktuSelesai: json['waktu_selesai']?.toString(),
        status: (json['status'] ?? '').toString(),
        keterangan: json['keterangan']?.toString(),
        pertemuanStatus: json['pertemuan_status']?.toString(),
        kelasNama: json['kelas_nama']?.toString(),
        mapelNama: json['mapel_nama']?.toString(),
        guruNama: json['guru_nama']?.toString(),
      );
}

/// Rekap kehadiran — `{total,hadir,sakit,izin,alpha,persen_hadir}`.
/// `persen_hadir` adalah STRING FORMAT LOKAL dari backend (mis. "87,5%").
class RekapAbsensi {
  const RekapAbsensi({
    required this.total,
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alpha,
    this.persenHadir,
  });

  final int total;
  final int hadir;
  final int sakit;
  final int izin;
  final int alpha;
  final String? persenHadir;

  factory RekapAbsensi.fromJson(Map<String, dynamic> json) => RekapAbsensi(
    total: JsonCast.intOrNull(json['total']) ?? 0,
    hadir: JsonCast.intOrNull(json['hadir']) ?? 0,
    sakit: JsonCast.intOrNull(json['sakit']) ?? 0,
    izin: JsonCast.intOrNull(json['izin']) ?? 0,
    alpha: JsonCast.intOrNull(json['alpha']) ?? 0,
    persenHadir: json['persen_hadir']?.toString(),
  );

  static const RekapAbsensi kosong = RekapAbsensi(
    total: 0,
    hadir: 0,
    sakit: 0,
    izin: 0,
    alpha: 0,
  );
}

/// `GET /siswa/absensi/harian` response.
class AbsensiHarianResponse {
  const AbsensiHarianResponse({
    required this.rekapSemester,
    required this.ringkasan,
    this.dari,
    this.sampai,
    this.statusFilter,
    this.items = const [],
    this.meta,
  });

  final RekapAbsensi rekapSemester;
  final RekapAbsensi ringkasan;
  final String? dari;
  final String? sampai;
  final String? statusFilter;
  final List<AbsensiHarianItem> items;
  final PageMeta? meta;

  factory AbsensiHarianResponse.fromJson(
    Map<String, dynamic> json,
    PageMeta? meta,
  ) {
    final filter = json['filter'];
    return AbsensiHarianResponse(
      rekapSemester: json['rekap_semester'] is Map
          ? RekapAbsensi.fromJson(
              Map<String, dynamic>.from(json['rekap_semester'] as Map),
            )
          : RekapAbsensi.kosong,
      ringkasan: json['ringkasan'] is Map
          ? RekapAbsensi.fromJson(
              Map<String, dynamic>.from(json['ringkasan'] as Map),
            )
          : RekapAbsensi.kosong,
      dari: filter is Map ? filter['dari']?.toString() : null,
      sampai: filter is Map ? filter['sampai']?.toString() : null,
      statusFilter: filter is Map ? filter['status']?.toString() : null,
      items: _itemsOf(json['items']),
      meta: meta,
    );
  }

  static List<AbsensiHarianItem> _itemsOf(Object? raw) => raw is List
      ? raw
            .whereType<Map>()
            .map(
              (e) => AbsensiHarianItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList()
      : const [];
}

/// `GET /siswa/absensi/periode` response (identik ringkasan, tanpa rekap_semester).
class AbsensiPeriodeResponse {
  const AbsensiPeriodeResponse({
    required this.dari,
    required this.sampai,
    required this.ringkasan,
    this.statusFilter,
    this.items = const [],
    this.meta,
  });

  final String dari;
  final String sampai;
  final RekapAbsensi ringkasan;
  final String? statusFilter;
  final List<AbsensiHarianItem> items;
  final PageMeta? meta;

  factory AbsensiPeriodeResponse.fromJson(
    Map<String, dynamic> json,
    PageMeta? meta,
  ) {
    final periode = json['periode'];
    final filter = json['filter'];
    return AbsensiPeriodeResponse(
      dari: periode is Map ? (periode['dari'] ?? '').toString() : '',
      sampai: periode is Map ? (periode['sampai'] ?? '').toString() : '',
      ringkasan: json['ringkasan'] is Map
          ? RekapAbsensi.fromJson(
              Map<String, dynamic>.from(json['ringkasan'] as Map),
            )
          : RekapAbsensi.kosong,
      statusFilter: filter is Map ? filter['status']?.toString() : null,
      items: AbsensiHarianResponse._itemsOf(json['items']),
      meta: meta,
    );
  }
}

/// `GET /siswa/absensi/perjam` response.
class AbsensiPerjamResponse {
  const AbsensiPerjamResponse({
    required this.rekap,
    required this.rekapTotal,
    this.dari,
    this.sampai,
    this.statusFilter,
    this.items = const [],
    this.meta,
  });

  final RekapAbsensi rekap;
  final RekapAbsensi rekapTotal;
  final String? dari;
  final String? sampai;
  final String? statusFilter;
  final List<AbsensiPerjamItem> items;
  final PageMeta? meta;

  factory AbsensiPerjamResponse.fromJson(
    Map<String, dynamic> json,
    PageMeta? meta,
  ) {
    final filter = json['filter'];
    return AbsensiPerjamResponse(
      rekap: json['rekap'] is Map
          ? RekapAbsensi.fromJson(
              Map<String, dynamic>.from(json['rekap'] as Map),
            )
          : RekapAbsensi.kosong,
      rekapTotal: json['rekap_total'] is Map
          ? RekapAbsensi.fromJson(
              Map<String, dynamic>.from(json['rekap_total'] as Map),
            )
          : RekapAbsensi.kosong,
      dari: filter is Map ? filter['dari']?.toString() : null,
      sampai: filter is Map ? filter['sampai']?.toString() : null,
      statusFilter: filter is Map ? filter['status']?.toString() : null,
      items: json['items'] is List
          ? (json['items'] as List)
                .whereType<Map>()
                .map(
                  (e) =>
                      AbsensiPerjamItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      meta: meta,
    );
  }
}
