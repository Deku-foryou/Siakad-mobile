import '../../../../core/utils/json_cast.dart';
import '../../../siswa/data/models/beranda.dart'; // KonteksAkademik

/// Model untuk API wali murid (`/api/v1/wali/*`).
///
/// Relasi wali↔anak bersifat many-to-many. Akses akademik/finansial hanya
/// diberikan backend bila `status_hubungan == 'verified'` dan
/// `tanggal_berhenti == null` (+ `tanggal_mulai <= hari ini`).
/// Field `bisaAksesAkademik` dikirim backend dan dipakai untuk UI
/// (backend tetap otoritas sesungguhnya).

/// Ringkasan relasi pada `GET /wali/profil` dan `GET /wali/beranda`.
class RelasiRingkasan {
  const RelasiRingkasan({
    this.verified = 0,
    this.pending = 0,
    this.rejected = 0,
    this.terminated = 0,
  });

  final int verified;
  final int pending;
  final int rejected;
  final int terminated;

  factory RelasiRingkasan.fromJson(Map<String, dynamic> json) =>
      RelasiRingkasan(
        verified: JsonCast.intOrNull(json['verified']) ?? 0,
        pending: JsonCast.intOrNull(json['pending']) ?? 0,
        rejected: JsonCast.intOrNull(json['rejected']) ?? 0,
        terminated: JsonCast.intOrNull(json['terminated']) ?? 0,
      );
}

/// `GET /wali/profil` — identitas wali (read-only).
class ProfilWali {
  const ProfilWali({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.statusAkun,
    this.wajibGantiPassword = false,
    this.relasi = const RelasiRingkasan(),
  });

  final int id;
  final String name;
  final String username;
  final String? email;
  final String? statusAkun;
  final bool wajibGantiPassword;
  final RelasiRingkasan relasi;

  factory ProfilWali.fromJson(Map<String, dynamic> json) {
    final relasi = json['relasi'];
    return ProfilWali(
      id: JsonCast.intOrNull(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: json['email']?.toString(),
      statusAkun: json['status_akun']?.toString(),
      wajibGantiPassword:
          JsonCast.boolOrNull(json['wajib_ganti_password']) ?? false,
      relasi: relasi is Map
          ? RelasiRingkasan.fromJson(Map<String, dynamic>.from(relasi))
          : const RelasiRingkasan(),
    );
  }
}

/// Anak terverifikasi pada `GET /wali/beranda` (tanpa data akademik).
class AnakRingkas {
  const AnakRingkas({
    required this.id,
    this.nisn,
    this.nis,
    this.nama,
    this.kelas,
  });

  final int id;
  final String? nisn;
  final String? nis;
  final String? nama;
  final String? kelas;

  factory AnakRingkas.fromJson(Map<String, dynamic> json) => AnakRingkas(
    id: JsonCast.intOrNull(json['id']) ?? 0,
    nisn: json['nisn']?.toString(),
    nis: json['nis']?.toString(),
    nama: json['nama']?.toString(),
    kelas: json['kelas']?.toString(),
  );
}

/// Ringkasan pada `GET /wali/beranda`.
class BerandaWaliRingkasan {
  const BerandaWaliRingkasan({
    this.jumlahAnak = 0,
    this.jumlahMenunggu = 0,
    this.jumlahDitolak = 0,
    this.jumlahBerakhir = 0,
    this.notifikasiBelumDibaca = 0,
  });

  final int jumlahAnak;
  final int jumlahMenunggu;
  final int jumlahDitolak;
  final int jumlahBerakhir;
  final int notifikasiBelumDibaca;

  factory BerandaWaliRingkasan.fromJson(Map<String, dynamic> json) =>
      BerandaWaliRingkasan(
        jumlahAnak: JsonCast.intOrNull(json['jumlah_anak']) ?? 0,
        jumlahMenunggu: JsonCast.intOrNull(json['jumlah_menunggu']) ?? 0,
        jumlahDitolak: JsonCast.intOrNull(json['jumlah_ditolak']) ?? 0,
        jumlahBerakhir: JsonCast.intOrNull(json['jumlah_berakhir']) ?? 0,
        notifikasiBelumDibaca:
            JsonCast.intOrNull(json['notifikasi_belum_dibaca']) ?? 0,
      );
}

/// `GET /wali/beranda` — identitas wali + konteks + daftar anak verified.
class BerandaWali {
  const BerandaWali({
    required this.userId,
    required this.name,
    required this.username,
    required this.akunUsername,
    this.wajibGantiPassword = false,
    required this.konteks,
    this.anak = const [],
    this.ringkasan = const BerandaWaliRingkasan(),
    this.namaHari,
  });

  final int userId;
  final String name;
  final String username;
  final String akunUsername;
  final bool wajibGantiPassword;
  final KonteksAkademik konteks;
  final List<AnakRingkas> anak;
  final BerandaWaliRingkasan ringkasan;
  final String? namaHari;

  factory BerandaWali.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final akun = json['akun'];
    final anakRaw = json['anak'];
    final ringkasan = json['ringkasan'];
    return BerandaWali(
      userId: (user is Map ? JsonCast.intOrNull(user['id']) : null) ?? 0,
      name: user is Map ? (user['name'] ?? '').toString() : '',
      username: user is Map ? (user['username'] ?? '').toString() : '',
      akunUsername: akun is Map ? (akun['username'] ?? '-').toString() : '-',
      wajibGantiPassword:
          akun is Map &&
          (JsonCast.boolOrNull(akun['wajib_ganti_password']) ?? false),
      konteks: json['konteks'] is Map
          ? KonteksAkademik.fromJson(
              Map<String, dynamic>.from(json['konteks'] as Map),
            )
          : const KonteksAkademik(valid: false),
      anak: anakRaw is List
          ? anakRaw
                .whereType<Map>()
                .map((e) => AnakRingkas.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      ringkasan: ringkasan is Map
          ? BerandaWaliRingkasan.fromJson(Map<String, dynamic>.from(ringkasan))
          : const BerandaWaliRingkasan(),
      namaHari: json['nama_hari']?.toString(),
    );
  }
}

/// Identitas siswa pada payload relasi wali.
class AnakSiswa {
  const AnakSiswa({
    required this.id,
    this.nisn,
    this.nis,
    this.nama,
    this.jenisKelamin,
    this.tahunMasuk,
    this.status,
  });

  final int id;
  final String? nisn;
  final String? nis;
  final String? nama;
  final String? jenisKelamin;
  final int? tahunMasuk;
  final String? status;

  factory AnakSiswa.fromJson(Map<String, dynamic> json) => AnakSiswa(
    id: JsonCast.intOrNull(json['id']) ?? 0,
    nisn: json['nisn']?.toString(),
    nis: json['nis']?.toString(),
    nama: json['nama']?.toString(),
    jenisKelamin: json['jenis_kelamin']?.toString(),
    tahunMasuk: JsonCast.intOrNull(json['tahun_masuk']),
    status: json['status']?.toString(),
  );
}

/// Satu relasi wali↔anak — elemen `anak` pada `GET /wali/anak` dan
/// payload `GET /wali/anak/{siswaId}`.
class AnakRelasi {
  const AnakRelasi({
    required this.relasiId,
    this.hubungan,
    required this.statusHubungan,
    this.tanggalMulai,
    this.tanggalBerhenti,
    this.tanggalVerifikasi,
    this.bisaAksesAkademik = false,
    this.kelas,
    this.siswa,
  });

  final int relasiId;
  final String? hubungan;
  final String statusHubungan;
  final String? tanggalMulai;
  final String? tanggalBerhenti;
  final String? tanggalVerifikasi;

  /// Dihitung backend (verified + tanggal_berhenti null + tanggal_mulai
  /// sudah berlaku). Dipakai HANYA untuk render; otorisasi tetap di backend.
  final bool bisaAksesAkademik;
  final String? kelas;
  final AnakSiswa? siswa;

  factory AnakRelasi.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'];
    return AnakRelasi(
      relasiId: JsonCast.intOrNull(json['relasi_id']) ?? 0,
      hubungan: json['hubungan']?.toString(),
      statusHubungan: (json['status_hubungan'] ?? '').toString(),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      tanggalBerhenti: json['tanggal_berhenti']?.toString(),
      tanggalVerifikasi: json['tanggal_verifikasi']?.toString(),
      bisaAksesAkademik:
          JsonCast.boolOrNull(json['bisa_akses_akademik']) ?? false,
      kelas: json['kelas']?.toString(),
      siswa: siswa is Map
          ? AnakSiswa.fromJson(Map<String, dynamic>.from(siswa))
          : null,
    );
  }
}

/// `GET /wali/anak` — daftar seluruh relasi + konteks akademik.
class AnakListResponse {
  const AnakListResponse({required this.konteks, this.anak = const []});

  final KonteksAkademik konteks;
  final List<AnakRelasi> anak;

  factory AnakListResponse.fromJson(Map<String, dynamic> json) {
    final anakRaw = json['anak'];
    return AnakListResponse(
      konteks: json['konteks'] is Map
          ? KonteksAkademik.fromJson(
              Map<String, dynamic>.from(json['konteks'] as Map),
            )
          : const KonteksAkademik(valid: false),
      anak: anakRaw is List
          ? anakRaw
                .whereType<Map>()
                .map((e) => AnakRelasi.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}

/// Satu baris histori relasi (append-only) — `histori` pada detail anak.
class HistoriRelasi {
  const HistoriRelasi({
    this.event,
    this.statusSebelum,
    this.statusSesudah,
    this.aktorPeran,
    this.alasan,
    this.tanggalMulaiSesudah,
    this.tanggalBerhentiSesudah,
    this.createdAt,
  });

  final String? event;
  final String? statusSebelum;
  final String? statusSesudah;
  final String? aktorPeran;
  final String? alasan;
  final String? tanggalMulaiSesudah;
  final String? tanggalBerhentiSesudah;
  final String? createdAt;

  factory HistoriRelasi.fromJson(Map<String, dynamic> json) => HistoriRelasi(
    event: json['event']?.toString(),
    statusSebelum: json['status_sebelum']?.toString(),
    statusSesudah: json['status_sesudah']?.toString(),
    aktorPeran: json['aktor_peran']?.toString(),
    alasan: json['alasan']?.toString(),
    tanggalMulaiSesudah: json['tanggal_mulai_sesudah']?.toString(),
    tanggalBerhentiSesudah: json['tanggal_berhenti_sesudah']?.toString(),
    createdAt: json['created_at']?.toString(),
  );
}

/// `GET /wali/anak/{siswaId}` — detail relasi + histori.
class AnakDetail extends AnakRelasi {
  const AnakDetail({
    required super.relasiId,
    super.hubungan,
    required super.statusHubungan,
    super.tanggalMulai,
    super.tanggalBerhenti,
    super.tanggalVerifikasi,
    super.bisaAksesAkademik,
    super.kelas,
    super.siswa,
    this.histori = const [],
  });

  final List<HistoriRelasi> histori;

  factory AnakDetail.fromJson(Map<String, dynamic> json) {
    final base = AnakRelasi.fromJson(json);
    final historiRaw = json['histori'];
    return AnakDetail(
      relasiId: base.relasiId,
      hubungan: base.hubungan,
      statusHubungan: base.statusHubungan,
      tanggalMulai: base.tanggalMulai,
      tanggalBerhenti: base.tanggalBerhenti,
      tanggalVerifikasi: base.tanggalVerifikasi,
      bisaAksesAkademik: base.bisaAksesAkademik,
      kelas: base.kelas,
      siswa: base.siswa,
      histori: historiRaw is List
          ? historiRaw
                .whereType<Map>()
                .map(
                  (e) => HistoriRelasi.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}
