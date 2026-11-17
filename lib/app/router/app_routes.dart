/// Konstanta path & nama route aplikasi.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String changePassword = '/change-password';

  // Area siswa (shell + sub-route).
  static const String siswa = '/siswa';
  static const String siswaJadwal = '/siswa/jadwal';
  static const String siswaAbsensi = '/siswa/absensi';
  static const String siswaNilai = '/siswa/nilai';
  static const String siswaRapor = '/siswa/rapor';
  static const String siswaRaporDetailPath =
      '/siswa/rapor/:semesterId/:kelasId';
  static const String siswaRaporDetail =
      '/siswa/rapor/:semesterId/:kelasId'; // kompatibilitas lama
  static const String siswaPengumuman = '/siswa/pengumuman';
  static const String siswaPengumumanDetail = '/siswa/pengumuman/:id';
  static const String siswaNotifikasiDetail = '/siswa/notifikasi/:id';
  static const String siswaTagihanDetail = '/siswa/tagihan/:id';
  static const String siswaPembayaranDetail = '/siswa/pembayaran/:id';
  static const String siswaAttemptDetail = '/siswa/pembayaran-attempt/:id';

  // Area guru (shell + sub-route).
  static const String guru = '/guru';
  static const String guruJadwal = '/guru/jadwal';
  static const String guruJadwalDetail = '/guru/jadwal/:id';
  static const String guruKelasDetail = '/guru/kelas/:id';
  static const String guruKelasSiswa = '/guru/kelas/:id/siswa';
  static const String guruPenugasanDetail = '/guru/penilaian/:id';
  static const String guruNilaiInput = '/guru/penilaian/:penugasanId/nilai';
  static const String guruAbsensiHarianGrid =
      '/guru/absensi/harian/grid/:kelasId';
  static const String guruAbsensiHarianDetail = '/guru/absensi/harian/:id';
  static const String guruAbsensiHarianEdit = '/guru/absensi/harian/:id/edit';
  static const String guruPerjamGrid = '/guru/absensi/perjam/grid/:pertemuanId';
  static const String guruPerjamDetail = '/guru/absensi/perjam/:id';
  static const String guruPerjamEdit = '/guru/absensi/perjam/:id/edit';
  static const String guruNotifikasi = '/guru/notifikasi';
  static const String guruNotifikasiDetail = '/guru/notifikasi/:id';

  static const String wali = '/wali';

  static const Map<String, String> _roleByArea = {
    siswa: 'siswa',
    guru: 'guru',
    wali: 'wali',
  };

  /// Role area bila [location] berada di dalam area tersebut (prefix match,
  /// termasuk sub-route), atau null bila bukan area role mana pun.
  static String? roleByAreaPrefix(String location) {
    for (final entry in _roleByArea.entries) {
      if (location == entry.key || location.startsWith('${entry.key}/')) {
        return entry.value;
      }
    }
    return null;
  }

  /// Kompatibilitas mundur untuk test lama.
  static String? roleByArea(String location) => _roleByArea[location];

  /// Path home untuk role mobile tertentu; null bila role tidak dikenal.
  static String? homeForRole(String? role) {
    switch (role) {
      case 'siswa':
        return siswa;
      case 'guru':
        return guru;
      case 'wali':
        return wali;
      default:
        return null;
    }
  }
}
