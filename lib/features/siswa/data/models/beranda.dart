import '../../../../core/utils/json_cast.dart';

/// Model untuk profil & beranda siswa (`GET /siswa/profil`, `GET /siswa/beranda`).
class KelasAktif {
  const KelasAktif({
    required this.id,
    required this.nama,
    this.tingkat,
    this.jenis,
    this.rombel,
  });

  final int id;
  final String nama;
  final String? tingkat;
  final String? jenis;
  final String? rombel;

  factory KelasAktif.fromJson(Map<String, dynamic> json) => KelasAktif(
    id: JsonCast.intOrNull(json['id']) ?? 0,
    nama: (json['nama'] ?? '').toString(),
    tingkat: json['tingkat']?.toString(),
    jenis: json['jenis']?.toString(),
    rombel: json['rombel']?.toString(),
  );
}

class KonteksAkademik {
  const KonteksAkademik({
    required this.valid,
    this.peringatan = const [],
    this.tahunAjaranId,
    this.tahunAjaranNama,
    this.semesterId,
    this.semesterNama,
  });

  final bool valid;
  final List<String> peringatan;
  final int? tahunAjaranId;
  final String? tahunAjaranNama;
  final int? semesterId;
  final String? semesterNama;

  factory KonteksAkademik.fromJson(Map<String, dynamic> json) {
    final ta = json['tahun_ajaran'];
    final semester = json['semester'];
    final peringatanRaw = json['peringatan'];
    return KonteksAkademik(
      valid: JsonCast.boolOrNull(json['valid']) ?? false,
      peringatan: peringatanRaw is List
          ? peringatanRaw.map((e) => e.toString()).toList()
          : const [],
      tahunAjaranId: (ta is Map ? JsonCast.intOrNull(ta['id']) : null),
      tahunAjaranNama: ta is Map ? ta['nama']?.toString() : null,
      semesterId: (semester is Map ? JsonCast.intOrNull(semester['id']) : null),
      semesterNama: semester is Map ? semester['nama']?.toString() : null,
    );
  }
}

/// Profil siswa — `GET /siswa/profil`.
class ProfilSiswa {
  const ProfilSiswa({
    required this.id,
    required this.nis,
    required this.nama,
    this.nisn,
    this.jenisKelamin,
    this.tahunMasuk,
    this.status,
    this.kelas = const [],
    required this.akunUsername,
    this.akunWajibGantiPassword = false,
  });

  final int id;
  final String? nisn;
  final String nis;
  final String nama;
  final String? jenisKelamin;
  final int? tahunMasuk;
  final String? status;
  final List<KelasAktif> kelas;
  final String akunUsername;
  final bool akunWajibGantiPassword;

  factory ProfilSiswa.fromJson(Map<String, dynamic> json) {
    final kelasRaw = json['kelas'];
    final akun = json['akun'];
    return ProfilSiswa(
      id: JsonCast.intOrNull(json['id']) ?? 0,
      nisn: json['nisn']?.toString(),
      nis: (json['nis'] ?? '').toString(),
      nama: (json['nama'] ?? '').toString(),
      jenisKelamin: json['jenis_kelamin']?.toString(),
      tahunMasuk: JsonCast.intOrNull(json['tahun_masuk']),
      status: json['status']?.toString(),
      kelas: kelasRaw is List
          ? kelasRaw
                .whereType<Map>()
                .map((e) => KelasAktif.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      akunUsername: akun is Map ? (akun['username'] ?? '-').toString() : '-',
      akunWajibGantiPassword:
          akun is Map &&
          (JsonCast.boolOrNull(akun['wajib_ganti_password']) ?? false),
    );
  }
}

/// `GET /siswa/beranda` — identitas + konteks + kelas + jadwal hari ini.
class BerandaSiswa {
  const BerandaSiswa({
    this.siswaId,
    this.nisn,
    this.nis,
    this.nama,
    this.tahunMasuk,
    this.status,
    required this.akunUsername,
    this.akunWajibGantiPassword = false,
    required this.konteks,
    required this.kelas,
    this.namaHari,
    this.jadwalHariIni = const [],
  });

  final int? siswaId;
  final String? nisn;
  final String? nis;
  final String? nama;
  final int? tahunMasuk;
  final String? status;
  final String akunUsername;
  final bool akunWajibGantiPassword;
  final KonteksAkademik konteks;
  final List<KelasAktif> kelas;
  final String? namaHari;
  final List<JadwalItem> jadwalHariIni;

  factory BerandaSiswa.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'];
    final akun = json['akun'];
    final kelasRaw = json['kelas'];
    final jadwalRaw = json['jadwal_hari_ini'];
    return BerandaSiswa(
      siswaId: (siswa is Map ? JsonCast.intOrNull(siswa['id']) : null),
      nisn: siswa is Map ? siswa['nisn']?.toString() : null,
      nis: siswa is Map ? siswa['nis']?.toString() : null,
      nama: siswa is Map ? siswa['nama']?.toString() : null,
      tahunMasuk: (siswa is Map
          ? JsonCast.intOrNull(siswa['tahun_masuk'])
          : null),
      status: siswa is Map ? siswa['status']?.toString() : null,
      akunUsername: akun is Map ? (akun['username'] ?? '-').toString() : '-',
      akunWajibGantiPassword:
          akun is Map &&
          (JsonCast.boolOrNull(akun['wajib_ganti_password']) ?? false),
      konteks: json['konteks'] is Map
          ? KonteksAkademik.fromJson(
              Map<String, dynamic>.from(json['konteks'] as Map),
            )
          : const KonteksAkademik(valid: false),
      kelas: kelasRaw is List
          ? kelasRaw
                .whereType<Map>()
                .map((e) => KelasAktif.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      namaHari: json['nama_hari']?.toString(),
      jadwalHariIni: jadwalRaw is List
          ? jadwalRaw
                .whereType<Map>()
                .map((e) => JadwalItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}

/// Item jadwal kanonis (`JadwalResource` backend).
class JadwalItem {
  const JadwalItem({
    required this.hari,
    required this.namaHari,
    this.jamKe,
    this.mulai,
    this.selesai,
    required this.mapelId,
    this.mapelKode,
    required this.mapelNama,
    this.guruId,
    this.guruNama,
    this.kelasId,
  });

  final int hari;
  final String namaHari;
  final int? jamKe;
  final String? mulai; // "07:00"
  final String? selesai;
  final int? mapelId;
  final String? mapelKode;
  final String mapelNama;
  final int? guruId;
  final String? guruNama;
  final int? kelasId;

  factory JadwalItem.fromJson(Map<String, dynamic> json) {
    final mapel = json['mapel'];
    final guru = json['guru'];
    return JadwalItem(
      hari: JsonCast.intOrNull(json['hari']) ?? 0,
      namaHari: (json['nama_hari'] ?? '').toString(),
      jamKe: JsonCast.intOrNull(json['jam_ke']),
      mulai: json['mulai']?.toString(),
      selesai: json['selesai']?.toString(),
      mapelId: (mapel is Map ? JsonCast.intOrNull(mapel['id']) : null),
      mapelKode: mapel is Map ? mapel['kode']?.toString() : null,
      mapelNama: mapel is Map ? (mapel['nama'] ?? '-').toString() : '-',
      guruId: (guru is Map ? JsonCast.intOrNull(guru['id']) : null),
      guruNama: guru is Map ? guru['nama']?.toString() : null,
      kelasId: JsonCast.intOrNull(json['kelas_id']),
    );
  }
}

/// Respons `GET /siswa/jadwal` dan `/siswa/jadwal/hari-ini`.
class JadwalResponse {
  const JadwalResponse({
    this.tanggal,
    this.hari,
    this.namaHari,
    required this.konteks,
    this.jadwal = const [],
  });

  final String? tanggal;
  final int? hari;
  final String? namaHari;
  final KonteksAkademik konteks;
  final List<JadwalItem> jadwal;

  factory JadwalResponse.fromJson(Map<String, dynamic> json) {
    final jadwalRaw = json['jadwal'];
    return JadwalResponse(
      tanggal: json['tanggal']?.toString(),
      hari: JsonCast.intOrNull(json['hari']),
      namaHari: json['nama_hari']?.toString(),
      konteks: json['konteks'] is Map
          ? KonteksAkademik.fromJson(
              Map<String, dynamic>.from(json['konteks'] as Map),
            )
          : const KonteksAkademik(valid: false),
      jadwal: jadwalRaw is List
          ? jadwalRaw
                .whereType<Map>()
                .map((e) => JadwalItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}
