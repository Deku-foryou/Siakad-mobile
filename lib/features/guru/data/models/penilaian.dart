import '../../../../core/utils/json_cast.dart';

/// Model penilaian guru — `penilaian/penugasan/*` backend.
class KomponenNilai {
  const KomponenNilai({
    required this.id,
    required this.nama,
    required this.bobot,
    required this.urutan,
  });

  final int id;
  final String nama;
  final double bobot;
  final int urutan;

  factory KomponenNilai.fromJson(Map<String, dynamic> json) => KomponenNilai(
    id: JsonCast.intOrNull(json['id']) ?? 0,
    nama: (json['nama'] ?? '').toString(),
    bobot: JsonCast.doubleOrNull(json['bobot']) ?? 0,
    urutan: JsonCast.intOrNull(json['urutan']) ?? 0,
  );
}

/// Detail penugasan penilaian — `GET /guru/penilaian/penugasan/{id}`.
class PenugasanDetail {
  const PenugasanDetail({
    required this.id,
    required this.semester,
    required this.kelas,
    required this.mapel,
    required this.jumlahSiswa,
    this.komponen = const [],
    this.totalBobotAktif = 0,
    this.konfigurasiValid = false,
    this.terkunci = false,
  });

  final int id;
  final SemesterPenilaian semester;
  final KelasPenilaian kelas;
  final MapelPenilaian mapel;
  final int jumlahSiswa;
  final List<KomponenNilai> komponen;
  final double totalBobotAktif;
  final bool konfigurasiValid;
  final bool terkunci;

  factory PenugasanDetail.fromJson(Map<String, dynamic> json) {
    final semester = json['semester'];
    final kelas = json['kelas'];
    final mapel = json['mapel'];
    final komponenRaw = json['komponen'];
    return PenugasanDetail(
      id: JsonCast.intOrNull(json['id']) ?? 0,
      semester: semester is Map
          ? SemesterPenilaian.fromJson(Map<String, dynamic>.from(semester))
          : const SemesterPenilaian(id: 0, nama: '-'),
      kelas: kelas is Map
          ? KelasPenilaian.fromJson(Map<String, dynamic>.from(kelas))
          : const KelasPenilaian(id: 0, nama: '-'),
      mapel: mapel is Map
          ? MapelPenilaian.fromJson(Map<String, dynamic>.from(mapel))
          : const MapelPenilaian(id: 0, nama: '-'),
      jumlahSiswa: JsonCast.intOrNull(json['jumlah_siswa']) ?? 0,
      komponen: komponenRaw is List
          ? komponenRaw
                .whereType<Map>()
                .map(
                  (e) => KomponenNilai.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      totalBobotAktif: JsonCast.doubleOrNull(json['total_bobot_aktif']) ?? 0,
      konfigurasiValid: JsonCast.boolOrNull(json['konfigurasi_valid']) ?? false,
      terkunci: JsonCast.boolOrNull(json['terkunci']) ?? false,
    );
  }
}

class SemesterPenilaian {
  const SemesterPenilaian({
    required this.id,
    required this.nama,
    this.tahunAjaran,
  });

  final int id;
  final String nama;
  final String? tahunAjaran;

  factory SemesterPenilaian.fromJson(Map<String, dynamic> json) =>
      SemesterPenilaian(
        id: JsonCast.intOrNull(json['id']) ?? 0,
        nama: (json['nama'] ?? '').toString(),
        tahunAjaran: json['tahun_ajaran']?.toString(),
      );
}

class KelasPenilaian {
  const KelasPenilaian({required this.id, required this.nama, this.tingkat});

  final int id;
  final String nama;
  final String? tingkat;

  factory KelasPenilaian.fromJson(Map<String, dynamic> json) => KelasPenilaian(
    id: JsonCast.intOrNull(json['id']) ?? 0,
    nama: (json['nama'] ?? '').toString(),
    tingkat: json['tingkat']?.toString(),
  );
}

class MapelPenilaian {
  const MapelPenilaian({required this.id, required this.nama, this.kode});

  final int id;
  final String? kode;
  final String nama;

  factory MapelPenilaian.fromJson(Map<String, dynamic> json) => MapelPenilaian(
    id: JsonCast.intOrNull(json['id']) ?? 0,
    kode: json['kode']?.toString(),
    nama: (json['nama'] ?? '-').toString(),
  );
}

/// Rekap siswa untuk penugasan — elemen `siswa` pada endpoint G23.
class SiswaPenilaian {
  const SiswaPenilaian({
    required this.id,
    this.nisn,
    this.nis,
    required this.nama,
    this.nilai = const {},
    this.nilaiDraft,
    this.lengkap = false,
    this.jumlahTerisi = 0,
    this.jumlahKomponen = 0,
    this.bobotTerisi = 0,
    this.bobotTotal = 0,
    this.konfigurasiValid = false,
  });

  final int id;
  final String? nisn;
  final String? nis;
  final String nama;

  /// Map komponenId → nilai (null bila belum diisi).
  final Map<int, double?> nilai;
  final double? nilaiDraft;
  final bool lengkap;
  final int jumlahTerisi;
  final int jumlahKomponen;
  final double bobotTerisi;
  final double bobotTotal;
  final bool konfigurasiValid;

  factory SiswaPenilaian.fromJson(Map<String, dynamic> json) {
    final rawNilai = json['nilai'];
    final nilai = <int, double?>{};
    if (rawNilai is Map) {
      rawNilai.forEach((key, value) {
        final komponenId = int.tryParse(key.toString());
        if (komponenId == null) return;
        nilai[komponenId] = value == null ? null : (value as num).toDouble();
      });
    }
    return SiswaPenilaian(
      id: JsonCast.intOrNull(json['id']) ?? 0,
      nisn: json['nisn']?.toString(),
      nis: json['nis']?.toString(),
      nama: (json['nama'] ?? '').toString(),
      nilai: nilai,
      nilaiDraft: JsonCast.doubleOrNull(json['nilai_draft']),
      lengkap: JsonCast.boolOrNull(json['lengkap']) ?? false,
      jumlahTerisi: JsonCast.intOrNull(json['jumlah_terisi']) ?? 0,
      jumlahKomponen: JsonCast.intOrNull(json['jumlah_komponen']) ?? 0,
      bobotTerisi: JsonCast.doubleOrNull(json['bobot_terisi']) ?? 0,
      bobotTotal: JsonCast.doubleOrNull(json['bobot_total']) ?? 0,
      konfigurasiValid: JsonCast.boolOrNull(json['konfigurasi_valid']) ?? false,
    );
  }
}

/// Respons `GET /guru/penilaian/penugasan/{id}/siswa`.
class PenugasanSiswaResponse {
  const PenugasanSiswaResponse({
    required this.penugasanId,
    required this.terkunci,
    required this.siswa,
  });

  final int penugasanId;
  final bool terkunci;
  final List<SiswaPenilaian> siswa;
}
