import '../../../../core/utils/json_cast.dart';
import 'guru.dart';

/// Absensi harian guru â€” `GuruAbsensiHarianResource`.
class GuruAbsensiHarianItem {
  const GuruAbsensiHarianItem({
    this.id,
    required this.tanggal,
    required this.status,
    this.catatan,
    required this.kelasId,
    required this.kelasNama,
    required this.siswaId,
    required this.siswaNama,
  });

  final int? id;
  final String? tanggal;
  final String status;
  final String? catatan;
  final int? kelasId;
  final String? kelasNama;
  final int? siswaId;
  final String? siswaNama;

  factory GuruAbsensiHarianItem.fromJson(Map<String, dynamic> json) {
    final kelas = json['kelas'];
    final siswa = json['siswa'];
    return GuruAbsensiHarianItem(
      id: JsonCast.intOrNull(json['id']),
      tanggal: json['tanggal']?.toString(),
      status: (json['status'] ?? '').toString(),
      catatan: json['catatan']?.toString(),
      kelasId: (kelas is Map ? JsonCast.intOrNull(kelas['id']) : null),
      kelasNama: kelas is Map ? kelas['nama']?.toString() : null,
      siswaId: (siswa is Map ? JsonCast.intOrNull(siswa['id']) : null),
      siswaNama: siswa is Map ? siswa['nama']?.toString() : null,
    );
  }
}

/// Absensi per jam â€” `GuruAbsensiPerjamResource`.
class GuruAbsensiPerjamItem {
  const GuruAbsensiPerjamItem({
    required this.id,
    required this.jadwalPertemuanId,
    required this.tanggal,
    this.hari,
    this.namaHari,
    this.jamKe,
    this.waktuMulai,
    this.waktuSelesai,
    required this.status,
    this.keterangan,
    this.pertemuanStatus,
    this.kelasId,
    this.kelasNama,
    this.mapelNama,
    this.siswaId,
    this.siswaNama,
  });

  final int id;
  final int? jadwalPertemuanId;
  final String? tanggal;
  final int? hari;
  final String? namaHari;
  final int? jamKe;
  final String? waktuMulai;
  final String? waktuSelesai;
  final String status;
  final String? keterangan;
  final String? pertemuanStatus;
  final int? kelasId;
  final String? kelasNama;
  final String? mapelNama;
  final int? siswaId;
  final String? siswaNama;

  factory GuruAbsensiPerjamItem.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'];
    return GuruAbsensiPerjamItem(
      id: JsonCast.intOrNull(json['id']) ?? 0,
      jadwalPertemuanId: JsonCast.intOrNull(json['jadwal_pertemuan_id']),
      tanggal: json['tanggal']?.toString(),
      hari: JsonCast.intOrNull(json['hari']),
      namaHari: json['nama_hari']?.toString(),
      jamKe: JsonCast.intOrNull(json['jam_ke']),
      waktuMulai: json['waktu_mulai']?.toString(),
      waktuSelesai: json['waktu_selesai']?.toString(),
      status: (json['status'] ?? '').toString(),
      keterangan: json['keterangan']?.toString(),
      pertemuanStatus: json['pertemuan_status']?.toString(),
      kelasId: JsonCast.intOrNull(json['kelas_id']),
      kelasNama: json['kelas_nama']?.toString(),
      mapelNama: json['mapel_nama']?.toString(),
      siswaId: (siswa is Map ? JsonCast.intOrNull(siswa['id']) : null),
      siswaNama: siswa is Map ? siswa['nama']?.toString() : null,
    );
  }
}

/// Grid absensi harian â€” `GET /guru/kelas/{id}/absensi`.
class AbsensiHarianGrid {
  const AbsensiHarianGrid({
    required this.tanggal,
    required this.kelasId,
    required this.siswa,
    required this.konteks,
  });

  final String tanggal;
  final int kelasId;
  final List<GridSiswa> siswa;
  final KonteksAkademik konteks;

  factory AbsensiHarianGrid.fromJson(Map<String, dynamic> json) {
    final konteks = json['konteks'];
    final raw = json['siswa'];
    return AbsensiHarianGrid(
      tanggal: (json['tanggal'] ?? '').toString(),
      kelasId: JsonCast.intOrNull(json['kelas_id']) ?? 0,
      konteks: konteks is Map
          ? KonteksAkademik.fromJson(Map<String, dynamic>.from(konteks))
          : const KonteksAkademik(valid: false),
      siswa: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => GridSiswa.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}

/// Grid absensi pertemuan per jam â€” `GET /guru/absensi/perjam/pertemuan/{id}`.
class AbsensiPerjamGrid {
  const AbsensiPerjamGrid({
    required this.id,
    required this.tanggal,
    this.hari,
    this.jamKe,
    this.waktuMulai,
    this.waktuSelesai,
    required this.status,
    required this.bisaDiabsen,
    required this.kelas,
    required this.mapel,
    this.siswa = const [],
  });

  final int id;
  final String tanggal;
  final int? hari;
  final int? jamKe;
  final String? waktuMulai;
  final String? waktuSelesai;
  final String status;
  final bool bisaDiabsen;
  final KelasRingkas kelas;
  final MapelInfo mapel;
  final List<GridSiswa> siswa;

  factory AbsensiPerjamGrid.fromJson(Map<String, dynamic> json) {
    final raw = json['siswa'];
    final kelas = json['kelas'];
    final mapel = json['mapel'];
    return AbsensiPerjamGrid(
      id: JsonCast.intOrNull(json['id']) ?? 0,
      tanggal: (json['tanggal'] ?? '').toString(),
      hari: JsonCast.intOrNull(json['hari']),
      jamKe: JsonCast.intOrNull(json['jam_ke']),
      waktuMulai: json['waktu_mulai']?.toString(),
      waktuSelesai: json['waktu_selesai']?.toString(),
      status: (json['status'] ?? '').toString(),
      bisaDiabsen: JsonCast.boolOrNull(json['bisa_diabsen']) ?? false,
      kelas: kelas is Map
          ? KelasRingkas.fromJson(Map<String, dynamic>.from(kelas))
          : const KelasRingkas(id: 0, nama: '-'),
      mapel: mapel is Map
          ? MapelInfo.fromJson(Map<String, dynamic>.from(mapel))
          : const MapelInfo(nama: '-'),
      siswa: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => GridSiswa.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}

/// Siswa pada grid pengisian absensi. `absensi` null bila belum tercatat.
class GridSiswa {
  const GridSiswa({
    required this.id,
    this.nisn,
    this.nama = '',
    this.absensiId,
    this.absensiStatus,
    this.absensiCatatan,
  });

  final int id;
  final String? nisn;
  final String nama;
  final int? absensiId;
  final String? absensiStatus;
  final String? absensiCatatan;

  factory GridSiswa.fromJson(Map<String, dynamic> json) {
    final absensi = json['absensi'];
    return GridSiswa(
      id: JsonCast.intOrNull(json['id']) ?? 0,
      nisn: json['nisn']?.toString(),
      nama: (json['nama'] ?? '').toString(),
      absensiId: (absensi is Map ? JsonCast.intOrNull(absensi['id']) : null),
      absensiStatus: absensi is Map ? absensi['status']?.toString() : null,
      absensiCatatan: absensi is Map
          ? (absensi['catatan'] ?? absensi['keterangan'])?.toString()
          : null,
    );
  }

  GridSiswa copyWith({String? absensiStatus, String? absensiCatatan}) =>
      GridSiswa(
        id: id,
        nisn: nisn,
        nama: nama,
        absensiId: absensiId,
        absensiStatus: absensiStatus ?? this.absensiStatus,
        absensiCatatan: absensiCatatan ?? this.absensiCatatan,
      );
}

/// Snapshot pertemuan â€” `pertemuan[]` dari `GET /guru/absensi/perjam/pertemuan`.
class PertemuanItem {
  const PertemuanItem({
    required this.id,
    required this.jadwalKelasId,
    required this.tanggal,
    required this.hari,
    this.jamKe,
    this.waktuMulai,
    this.waktuSelesai,
    required this.status,
    required this.kelas,
    required this.mapel,
    this.jumlahSiswa = 0,
    this.jumlahAbsensi = 0,
    this.bisaDiabsen = false,
  });

  final int id;
  final int? jadwalKelasId;
  final String tanggal;
  final int hari;
  final int? jamKe;
  final String? waktuMulai;
  final String? waktuSelesai;
  final String status;
  final KelasRingkas kelas;
  final MapelInfo mapel;
  final int jumlahSiswa;
  final int jumlahAbsensi;
  final bool bisaDiabsen;

  factory PertemuanItem.fromJson(Map<String, dynamic> json) {
    final kelas = json['kelas'];
    final mapel = json['mapel'];
    return PertemuanItem(
      id: JsonCast.intOrNull(json['id']) ?? 0,
      jadwalKelasId: JsonCast.intOrNull(json['jadwal_kelas_id']),
      tanggal: (json['tanggal'] ?? '').toString(),
      hari: JsonCast.intOrNull(json['hari']) ?? 0,
      jamKe: JsonCast.intOrNull(json['jam_ke']),
      waktuMulai: json['waktu_mulai']?.toString(),
      waktuSelesai: json['waktu_selesai']?.toString(),
      status: (json['status'] ?? '').toString(),
      kelas: kelas is Map
          ? KelasRingkas.fromJson(Map<String, dynamic>.from(kelas))
          : const KelasRingkas(id: 0, nama: '-'),
      mapel: mapel is Map
          ? MapelInfo.fromJson(Map<String, dynamic>.from(mapel))
          : const MapelInfo(nama: '-'),
      jumlahSiswa: JsonCast.intOrNull(json['jumlah_siswa']) ?? 0,
      jumlahAbsensi: JsonCast.intOrNull(json['jumlah_absensi']) ?? 0,
      bisaDiabsen: JsonCast.boolOrNull(json['bisa_diabsen']) ?? false,
    );
  }
}

/// Detail record absensi per jam (G20).
class GuruAbsensiPerjamDetail {
  const GuruAbsensiPerjamDetail({
    required this.id,
    required this.status,
    this.keterangan,
    required this.jadwalPertemuanId,
    required this.tanggal,
    required this.hari,
    this.jamKe,
    this.waktuMulai,
    this.waktuSelesai,
    this.pertemuanStatus,
    required this.kelas,
    required this.mapel,
    required this.siswa,
  });

  final int id;
  final String status;
  final String? keterangan;
  final int? jadwalPertemuanId;
  final String? tanggal;
  final int hari;
  final int? jamKe;
  final String? waktuMulai;
  final String? waktuSelesai;
  final String? pertemuanStatus;
  final KelasRingkas kelas;
  final MapelInfo mapel;
  final SiswaRingkas siswa;

  factory GuruAbsensiPerjamDetail.fromJson(Map<String, dynamic> json) {
    final kelas = json['kelas'];
    final mapel = json['mapel'];
    final siswa = json['siswa'];
    return GuruAbsensiPerjamDetail(
      id: JsonCast.intOrNull(json['id']) ?? 0,
      status: (json['status'] ?? '').toString(),
      keterangan: json['keterangan']?.toString(),
      jadwalPertemuanId: JsonCast.intOrNull(json['jadwal_pertemuan_id']),
      tanggal: json['tanggal']?.toString(),
      hari: JsonCast.intOrNull(json['hari']) ?? 0,
      jamKe: JsonCast.intOrNull(json['jam_ke']),
      waktuMulai: json['waktu_mulai']?.toString(),
      waktuSelesai: json['waktu_selesai']?.toString(),
      pertemuanStatus: json['pertemuan_status']?.toString(),
      kelas: kelas is Map
          ? KelasRingkas.fromJson(Map<String, dynamic>.from(kelas))
          : const KelasRingkas(id: 0, nama: '-'),
      mapel: mapel is Map
          ? MapelInfo.fromJson(Map<String, dynamic>.from(mapel))
          : const MapelInfo(nama: '-'),
      siswa: siswa is Map
          ? SiswaRingkas.fromJson(Map<String, dynamic>.from(siswa))
          : const SiswaRingkas(nama: '-'),
    );
  }
}

/// Detail record absensi harian guru (G12).
class GuruAbsensiHarianDetail {
  const GuruAbsensiHarianDetail({
    required this.id,
    required this.tanggal,
    required this.status,
    this.catatan,
    required this.kelas,
    required this.siswa,
  });

  final int id;
  final String? tanggal;
  final String status;
  final String? catatan;
  final KelasRingkas kelas;
  final SiswaRingkas siswa;

  factory GuruAbsensiHarianDetail.fromJson(Map<String, dynamic> json) {
    final kelas = json['kelas'];
    final siswa = json['siswa'];
    return GuruAbsensiHarianDetail(
      id: JsonCast.intOrNull(json['id']) ?? 0,
      tanggal: json['tanggal']?.toString(),
      status: (json['status'] ?? '').toString(),
      catatan: json['catatan']?.toString(),
      kelas: kelas is Map
          ? KelasRingkas.fromJson(Map<String, dynamic>.from(kelas))
          : const KelasRingkas(id: 0, nama: '-'),
      siswa: siswa is Map
          ? SiswaRingkas.fromJson(Map<String, dynamic>.from(siswa))
          : const SiswaRingkas(nama: '-'),
    );
  }
}
