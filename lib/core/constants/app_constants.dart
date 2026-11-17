/// Konstanta aplikasi lintas fitur.
library;

class AppConstants {
  const AppConstants._();

  static const String appName = 'SIAKAD Mobile';
  static const String appTagline = 'Sistem Informasi Akademik';

  /// Versi API backend yang dipakai (prefix `/api/v1`).
  static const String apiVersion = 'v1';

  /// Masa berlaku Sanctum Personal Access Token di backend (30 hari).
  /// Informasi saja; token refresh TIDAK didukung backend.
  static const Duration tokenLifetime = Duration(days: 30);

  /// Role mobile yang diizinkan masuk aplikasi. Role lain (admin/superadmin/
  /// walikelas/dsb.) tetap di website Laravel — ditegakkan backend (403)
  /// dan sebagai defense-in-depth juga di client.
  static const List<String> mobileRoles = ['siswa', 'guru', 'wali'];

  static bool isMobileRole(String? role) =>
      role != null && mobileRoles.contains(role);
}
