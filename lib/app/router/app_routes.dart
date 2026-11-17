/// Konstanta path & nama route aplikasi.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String changePassword = '/change-password';
  static const String siswa = '/siswa';
  static const String guru = '/guru';
  static const String wali = '/wali';

  /// Prefix area per role — dipakai redirect untuk pengecekan keanggotaan.
  static const Map<String, String> roleByArea = {
    siswa: 'siswa',
    guru: 'guru',
    wali: 'wali',
  };

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
