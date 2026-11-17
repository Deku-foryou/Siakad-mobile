/// Model profil & beranda guru (`GET /guru/profil`, `GET /guru/beranda`).
class KelasRingkas {
  const KelasRingkas({
    required this.id,
    required this.nama,
    this.tingkat,
    this.jenis,
    this.rombel,
    this.sumber = const [],
    this.jumlahSiswa,
    this.taId,
    this.taNama,
    this.jurusanId,
    this.jurusanNama,
    this.waliId,
    this.waliNama,
    this.mapel = const [],
  });

  final int id;
  final String nama;
  final String? tingkat;
  final String? jenis;
  final String? rombel;
  final List<String> sumber;
  final int? jumlahSiswa;
  final int? taId;
  final String? taNama;
  final int? jurusanId;
  final String? jurusanNama;
  final int? waliId;
  final String? waliNama;
  final List<MapelInfo> mapel;

  bool get diajar => sumber.contains('mengajar');
  bool get diwali => sumber.contains('wali');

  factory KelasRingkas.fromJson(Map<String, dynamic> json) {
    final mapelRaw = json['mapel'];
    final ta = json['tahunajaran'];
    final jurusan = json['jurusan'];
    final wali = json['wali_kelas'];
    final sumberRaw = json['sumber'];
    return KelasRingkas(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nama: (json['nama'] ?? '').toString(),
      tingkat: json['tingkat']?.toString(),
      jenis: json['jenis']?.toString(),
      rombel: json['rombel']?.toString(),
      sumber: sumberRaw is List
          ? sumberRaw.map((e) => e.toString()).toList()
          : const [],
      jumlahSiswa: (json['jumlah_siswa'] as num?)?.toInt(),
      taId: (ta is Map ? ta['id'] as num? : null)?.toInt(),
      taNama: ta is Map ? ta['nama']?.toString() : null,
      jurusanId: (jurusan is Map ? jurusan['id'] as num? : null)?.toInt(),
      jurusanNama: jurusan is Map ? jurusan['nama']?.toString() : null,
      waliId: (wali is Map ? wali['id'] as num? : null)?.toInt(),
      waliNama: wali is Map ? wali['nama']?.toString() : null,
      mapel: mapelRaw is List
          ? mapelRaw
                .whereType<Map>()
                .map((e) => MapelInfo.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}

class MapelInfo {
  const MapelInfo({this.id, this.kode, required this.nama});

  final int? id;
  final String? kode;
  final String nama;

  factory MapelInfo.fromJson(Map<String, dynamic> json) => MapelInfo(
    id: (json['id'] as num?)?.toInt(),
    kode: json['kode']?.toString(),
    nama: (json['nama'] ?? '-').toString(),
  );
}

class MapelRef {
  const MapelRef({
    required this.id,
    required this.nama,
    this.kode,
    this.tahunAjaran,
  });

  final int id;
  final String? kode;
  final String nama;
  final String? tahunAjaran;

  factory MapelRef.fromJson(Map<String, dynamic> json) => MapelRef(
    id: (json['id'] as num?)?.toInt() ?? 0,
    kode: json['kode']?.toString(),
    nama: (json['nama'] ?? '').toString(),
    tahunAjaran: json['tahun_ajaran']?.toString(),
  );
}

class GuruProfil {
  const GuruProfil({
    required this.id,
    this.nip,
    this.kodeGuru,
    required this.nama,
    this.jenisKelamin,
    this.tempatLahir,
    this.tanggalLahir,
    this.telepon,
    this.alamat,
    this.status,
    this.mapel = const [],
    required this.akunUsername,
    this.akunWajibGantiPassword = false,
  });

  final int id;
  final String? nip;
  final String? kodeGuru;
  final String nama;
  final String? jenisKelamin;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? telepon;
  final String? alamat;
  final String? status;
  final List<MapelInfo> mapel;
  final String akunUsername;
  final bool akunWajibGantiPassword;

  factory GuruProfil.fromJson(Map<String, dynamic> json) {
    final mapelRaw = json['mapel'];
    final akun = json['akun'];
    return GuruProfil(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nip: json['nip']?.toString(),
      kodeGuru: json['kode_guru']?.toString(),
      nama: (json['nama'] ?? '').toString(),
      jenisKelamin: json['jenis_kelamin']?.toString(),
      tempatLahir: json['tempat_lahir']?.toString(),
      tanggalLahir: json['tanggal_lahir']?.toString(),
      telepon: json['telepon']?.toString(),
      alamat: json['alamat']?.toString(),
      status: json['status']?.toString(),
      mapel: mapelRaw is List
          ? mapelRaw
                .whereType<Map>()
                .map((e) => MapelInfo.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      akunUsername: akun is Map ? (akun['username'] ?? '-').toString() : '-',
      akunWajibGantiPassword:
          akun is Map && (akun['wajib_ganti_password'] as bool? ?? false),
    );
  }
}

/// `GET /guru/beranda` â€” identitas + konteks + kelas + ringkasan + jadwal hari ini.
class GuruBeranda {
  const GuruBeranda({
    required this.id,
    this.nip,
    this.kodeGuru,
    required this.nama,
    this.status,
    required this.akunUsername,
    this.akunWajibGantiPassword = false,
    required this.konteks,
    this.kelas = const [],
    required this.ringkasan,
    this.namaHari,
    this.jadwalHariIni = const [],
  });

  final int id;
  final String? nip;
  final String? kodeGuru;
  final String nama;
  final String? status;
  final String akunUsername;
  final bool akunWajibGantiPassword;
  final KonteksAkademik konteks;
  final List<KelasRingkas> kelas;
  final GuruRingkasan ringkasan;
  final String? namaHari;
  final List<JadwalGuruItem> jadwalHariIni;

  factory GuruBeranda.fromJson(Map<String, dynamic> json) {
    final guru = json['guru'];
    final akun = json['akun'];
    final konteks = json['konteks'];
    final kelasRaw = json['kelas'];
    final jadwalRaw = json['jadwal_hari_ini'];
    return GuruBeranda(
      id: (guru is Map ? guru['id'] as num? : null)?.toInt() ?? 0,
      nip: guru is Map ? guru['nip']?.toString() : null,
      kodeGuru: guru is Map ? guru['kode_guru']?.toString() : null,
      nama: (guru is Map ? guru['nama'] : null)?.toString() ?? '',
      status: guru is Map ? guru['status']?.toString() : null,
      akunUsername: akun is Map ? (akun['username'] ?? '-').toString() : '-',
      akunWajibGantiPassword:
          akun is Map && (akun['wajib_ganti_password'] as bool? ?? false),
      konteks: konteks is Map
          ? KonteksAkademik.fromJson(Map<String, dynamic>.from(konteks))
          : const KonteksAkademik(valid: false),
      kelas: kelasRaw is List
          ? kelasRaw
                .whereType<Map>()
                .map((e) => KelasRingkas.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      ringkasan: GuruRingkasan.fromJson(
        Map<String, dynamic>.from(json['ringkasan'] as Map? ?? const {}),
      ),
      namaHari: json['nama_hari']?.toString(),
      jadwalHariIni: jadwalRaw is List
          ? jadwalRaw
                .whereType<Map>()
                .map(
                  (e) => JadwalGuruItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

class GuruRingkasan {
  const GuruRingkasan({
    this.jumlahKelas = 0,
    this.jumlahPenugasan = 0,
    this.pertemuanHariIni = 0,
    this.absensiPerjamHariIni = 0,
    this.absensiHarianHariIni = 0,
  });

  final int jumlahKelas;
  final int jumlahPenugasan;
  final int pertemuanHariIni;
  final int absensiPerjamHariIni;
  final int absensiHarianHariIni;

  factory GuruRingkasan.fromJson(Map<String, dynamic> json) => GuruRingkasan(
    jumlahKelas: (json['jumlah_kelas'] as num?)?.toInt() ?? 0,
    jumlahPenugasan: (json['jumlah_penugasan'] as num?)?.toInt() ?? 0,
    pertemuanHariIni: (json['pertemuan_hari_ini'] as num?)?.toInt() ?? 0,
    absensiPerjamHariIni:
        (json['absensi_perjam_hari_ini'] as num?)?.toInt() ?? 0,
    absensiHarianHariIni:
        (json['absensi_harian_hari_ini'] as num?)?.toInt() ?? 0,
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
      valid: json['valid'] as bool? ?? false,
      peringatan: peringatanRaw is List
          ? peringatanRaw.map((e) => e.toString()).toList()
          : const [],
      tahunAjaranId: (ta is Map ? ta['id'] as num? : null)?.toInt(),
      tahunAjaranNama: ta is Map ? ta['nama']?.toString() : null,
      semesterId: (semester is Map ? semester['id'] as num? : null)?.toInt(),
      semesterNama: semester is Map ? semester['nama']?.toString() : null,
    );
  }
}

/// `GuruJadwalResource` â€” item jadwal mengajar.
class JadwalGuruItem {
  const JadwalGuruItem({
    required this.id,
    required this.hari,
    required this.namaHari,
    this.jamKe,
    this.mulai,
    this.selesai,
    required this.mapel,
    required this.kelas,
    this.semesterId,
    this.semesterNama,
  });

  final int id;
  final int hari;
  final String namaHari;
  final int? jamKe;
  final String? mulai;
  final String? selesai;
  final MapelInfo mapel;
  final KelasRingkas kelas;
  final int? semesterId;
  final String? semesterNama;

  factory JadwalGuruItem.fromJson(Map<String, dynamic> json) {
    final mapel = json['mapel'];
    final kelas = json['kelas'];
    final semester = json['semester'];
    return JadwalGuruItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      hari: (json['hari'] as num?)?.toInt() ?? 0,
      namaHari: (json['nama_hari'] ?? '').toString(),
      jamKe: (json['jam_ke'] as num?)?.toInt(),
      mulai: json['mulai']?.toString(),
      selesai: json['selesai']?.toString(),
      mapel: mapel is Map
          ? MapelInfo.fromJson(Map<String, dynamic>.from(mapel))
          : const MapelInfo(nama: '-'),
      kelas: kelas is Map
          ? KelasRingkas.fromJson(Map<String, dynamic>.from(kelas))
          : const KelasRingkas(id: 0, nama: '-'),
      semesterId: (semester is Map ? semester['id'] as num? : null)?.toInt(),
      semesterNama: semester is Map ? semester['nama']?.toString() : null,
    );
  }
}

/// Respons `GET /guru/jadwal` (juga `/jadwal/hari-ini`).
class JadwalGuruResponse {
  const JadwalGuruResponse({
    required this.konteks,
    this.tanggal,
    this.hari,
    this.namaHari,
    this.jadwal = const [],
  });

  final KonteksAkademik konteks;
  final String? tanggal;
  final int? hari;
  final String? namaHari;
  final List<JadwalGuruItem> jadwal;

  factory JadwalGuruResponse.fromJson(Map<String, dynamic> json) {
    final filter = json['filter'];
    final jadwalRaw = json['jadwal'];
    return JadwalGuruResponse(
      konteks: json['konteks'] is Map
          ? KonteksAkademik.fromJson(
              Map<String, dynamic>.from(json['konteks'] as Map),
            )
          : const KonteksAkademik(valid: false),
      tanggal: (filter is Map ? filter['tanggal'] : json['tanggal'])
          ?.toString(),
      hari: (filter is Map ? filter['hari'] : json['hari']) is num
          ? ((filter is Map ? filter['hari'] : json['hari']) as num).toInt()
          : null,
      namaHari: (filter is Map ? filter['nama_hari'] : json['nama_hari'])
          ?.toString(),
      jadwal: jadwalRaw is List
          ? jadwalRaw
                .whereType<Map>()
                .map(
                  (e) => JadwalGuruItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

/// `PenugasanResource` â€” penugasan mengajar semester aktif.
class Penugasan {
  const Penugasan({
    required this.id,
    required this.semester,
    required this.kelas,
    required this.mapel,
  });

  final int id;
  final SemesterRingkas semester;
  final KelasRingkas kelas;
  final MapelRef mapel;

  factory Penugasan.fromJson(Map<String, dynamic> json) {
    final semester = json['semester'];
    final kelas = json['kelas'];
    final mapel = json['mapel'];
    return Penugasan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      semester: semester is Map
          ? SemesterRingkas.fromJson(Map<String, dynamic>.from(semester))
          : const SemesterRingkas(id: 0, nama: '-'),
      kelas: kelas is Map
          ? KelasRingkas.fromJson(Map<String, dynamic>.from(kelas))
          : const KelasRingkas(id: 0, nama: '-'),
      mapel: mapel is Map
          ? MapelRef(
              id: (mapel['id'] as num?)?.toInt() ?? 0,
              kode: mapel['kode']?.toString(),
              nama: (mapel['nama'] ?? '-').toString(),
              tahunAjaran: semester is Map
                  ? semester['tahun_ajaran']?.toString()
                  : null,
            )
          : const MapelRef(id: 0, nama: '-'),
    );
  }
}

class SemesterRingkas {
  const SemesterRingkas({
    required this.id,
    required this.nama,
    this.tahunAjaran,
  });

  final int id;
  final String nama;
  final String? tahunAjaran;

  factory SemesterRingkas.fromJson(Map<String, dynamic> json) =>
      SemesterRingkas(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nama: (json['nama'] ?? '').toString(),
        tahunAjaran: json['tahun_ajaran']?.toString(),
      );
}

/// Respons `GET /guru/kelas` (dibungkus {konteks, kelas[]}).
class KelasListResponse {
  const KelasListResponse({required this.konteks, this.kelas = const []});

  final KonteksAkademik konteks;
  final List<KelasRingkas> kelas;
}

/// Respons `GET /guru/kelas/{id}/siswa`.
class KelasSiswaResponse {
  const KelasSiswaResponse({
    required this.kelasId,
    required this.kelasNama,
    this.jumlah = 0,
    this.siswa = const [],
  });

  final int kelasId;
  final String kelasNama;
  final int jumlah;
  final List<SiswaRingkas> siswa;

  factory KelasSiswaResponse.fromJson(Map<String, dynamic> json) {
    final kelas = json['kelas'];
    final siswaRaw = json['siswa'];
    return KelasSiswaResponse(
      kelasId: (kelas is Map ? kelas['id'] as num? : null)?.toInt() ?? 0,
      kelasNama: (kelas is Map ? kelas['nama'] : null)?.toString() ?? '-',
      jumlah: (json['jumlah'] as num?)?.toInt() ?? 0,
      siswa: siswaRaw is List
          ? siswaRaw
                .whereType<Map>()
                .map((e) => SiswaRingkas.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}

class SiswaRingkas {
  const SiswaRingkas({
    this.id,
    this.nisn,
    this.nis,
    required this.nama,
    this.jenisKelamin,
  });

  final int? id;
  final String? nisn;
  final String? nis;
  final String nama;
  final String? jenisKelamin;

  factory SiswaRingkas.fromJson(Map<String, dynamic> json) => SiswaRingkas(
    id: (json['id'] as num?)?.toInt(),
    nisn: json['nisn']?.toString(),
    nis: json['nis']?.toString(),
    nama: (json['nama'] ?? '').toString(),
    jenisKelamin: json['jenis_kelamin']?.toString(),
  );
}
