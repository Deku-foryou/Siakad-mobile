import '../../../../core/utils/json_cast.dart';

/// Model nilai akhir & rapor (`GET /siswa/nilai`, `/siswa/rapor`,
/// `/rapor/{semesterId}/{kelasId}`). Semua read-only; `nilai_akhir` adalah
/// snapshot finalisasi backend — tidak dihitung ulang di client.
class NilaiAkhirItem {
  const NilaiAkhirItem({
    this.mapelId,
    this.mapelKode,
    required this.mapelNama,
    required this.nilaiAkhir,
    this.nilaiKktp,
    this.keterangan,
  });

  final int? mapelId;
  final String? mapelKode;
  final String mapelNama;
  final double nilaiAkhir;
  final double? nilaiKktp;
  final String? keterangan;

  factory NilaiAkhirItem.fromJson(Map<String, dynamic> json) => NilaiAkhirItem(
    mapelId: JsonCast.intOrNull(json['mapel_id']),
    mapelKode: json['mapel_kode']?.toString(),
    mapelNama: (json['mapel_nama'] ?? '-').toString(),
    nilaiAkhir: JsonCast.doubleOrNull(json['nilai_akhir']) ?? 0,
    nilaiKktp: JsonCast.doubleOrNull(json['nilai_kktp']),
    keterangan: json['keterangan']?.toString(),
  );
}

class SemesterInfo {
  const SemesterInfo({
    required this.id,
    required this.nama,
    this.tahunAjaranId,
    this.tahunAjaranNama,
  });

  final int id;
  final String nama;
  final int? tahunAjaranId;
  final String? tahunAjaranNama;

  factory SemesterInfo.fromJson(Map<String, dynamic> json) {
    final ta = json['tahunajaran'];
    return SemesterInfo(
      id: JsonCast.intOrNull(json['id']) ?? 0,
      nama: (json['nama'] ?? '').toString(),
      tahunAjaranId: (ta is Map ? JsonCast.intOrNull(ta['id']) : null),
      tahunAjaranNama: ta is Map ? ta['nama']?.toString() : null,
    );
  }
}

class KelasRaporInfo {
  const KelasRaporInfo({required this.id, required this.nama, this.tingkat});

  final int id;
  final String nama;
  final String? tingkat;

  factory KelasRaporInfo.fromJson(Map<String, dynamic> json) => KelasRaporInfo(
    id: JsonCast.intOrNull(json['id']) ?? 0,
    nama: (json['nama'] ?? '').toString(),
    tingkat: json['tingkat']?.toString(),
  );
}

/// Kelompok nilai akhir per rapor final — elemen `rapor` pada `/siswa/nilai`.
class NilaiKelompok {
  const NilaiKelompok({
    required this.semester,
    required this.kelas,
    this.nilai = const [],
  });

  final SemesterInfo semester;
  final KelasRaporInfo kelas;
  final List<NilaiAkhirItem> nilai;

  factory NilaiKelompok.fromJson(Map<String, dynamic> json) => NilaiKelompok(
    semester: SemesterInfo.fromJson(
      Map<String, dynamic>.from(json['semester'] as Map? ?? const {}),
    ),
    kelas: KelasRaporInfo.fromJson(
      Map<String, dynamic>.from(json['kelas'] as Map? ?? const {}),
    ),
    nilai: json['nilai'] is List
        ? (json['nilai'] as List)
              .whereType<Map>()
              .map((e) => NilaiAkhirItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [],
  );
}

/// Entri daftar rapor final — elemen `rapor` pada `GET /siswa/rapor`.
class RaporEntry {
  const RaporEntry({
    required this.semester,
    required this.kelas,
    this.waliKelas,
    this.difinalisasiPada,
  });

  final SemesterInfo semester;
  final KelasRaporInfo kelas;
  final String? waliKelas;
  final String? difinalisasiPada;

  factory RaporEntry.fromJson(Map<String, dynamic> json) => RaporEntry(
    semester: SemesterInfo.fromJson(
      Map<String, dynamic>.from(json['semester'] as Map? ?? const {}),
    ),
    kelas: KelasRaporInfo.fromJson(
      Map<String, dynamic>.from(json['kelas'] as Map? ?? const {}),
    ),
    waliKelas: json['wali_kelas']?.toString(),
    difinalisasiPada: json['difinalisasi_pada']?.toString(),
  );
}

/// Detail rapor final — `GET /siswa/rapor/{semesterId}/{kelasId}`.
class RaporDetail {
  const RaporDetail({
    required this.kelas,
    required this.semester,
    this.isFinal = true,
    this.nilai = const [],
    required this.rekapKehadiran,
    this.catatan,
    this.namaSekolah,
  });

  final KelasRaporInfo kelas;
  final SemesterInfo semester;
  final bool isFinal;
  final List<NilaiAkhirItem> nilai;
  final RekapKehadiranRapor rekapKehadiran;
  final String? catatan;
  final String? namaSekolah;

  factory RaporDetail.fromJson(Map<String, dynamic> json) => RaporDetail(
    kelas: KelasRaporInfo.fromJson(
      Map<String, dynamic>.from(json['kelas'] as Map? ?? const {}),
    ),
    semester: SemesterInfo.fromJson(
      Map<String, dynamic>.from(json['semester'] as Map? ?? const {}),
    ),
    isFinal: JsonCast.boolOrNull(json['is_final']) ?? true,
    nilai: json['nilai'] is List
        ? (json['nilai'] as List)
              .whereType<Map>()
              .map((e) => NilaiAkhirItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [],
    rekapKehadiran: RekapKehadiranRapor.fromJson(
      Map<String, dynamic>.from(json['rekap_kehadiran'] as Map? ?? const {}),
    ),
    catatan: json['catatan']?.toString(),
    namaSekolah: json['nama_sekolah']?.toString(),
  );
}

class RekapKehadiranRapor {
  const RekapKehadiranRapor({
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alpha,
    required this.total,
  });

  final int hadir;
  final int sakit;
  final int izin;
  final int alpha;
  final int total;

  factory RekapKehadiranRapor.fromJson(Map<String, dynamic> json) =>
      RekapKehadiranRapor(
        hadir: JsonCast.intOrNull(json['hadir']) ?? 0,
        sakit: JsonCast.intOrNull(json['sakit']) ?? 0,
        izin: JsonCast.intOrNull(json['izin']) ?? 0,
        alpha: JsonCast.intOrNull(json['alpha']) ?? 0,
        total: JsonCast.intOrNull(json['total']) ?? 0,
      );
}
