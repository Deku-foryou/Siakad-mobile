import '../../features/auth/application/auth_state.dart';
import 'app_routes.dart';

/// Fungsi redirect MURNI (mudah dites) untuk GoRouter.
///
/// Aturan:
/// - status `unknown`            → tetap di splash (menunggu restore sesi).
/// - status `sessionCheckFailed` → tetap di splash (UI retry) atau login.
/// - status `unauthenticated`    → wajib di /login (kecuali sudah di sana).
/// - authenticated + wajib ganti password → wajib di /change-password.
/// - authenticated tanpa kewajiban pw → splash/login/change-password diarahkan
///   ke home role; area role lain (termasuk sub-route-nya) dialihkan ke home.
///
/// Area role cocok secara PREFIX: `/siswa`, `/siswa/jadwal`, dan seterusnya
/// hanya untuk role siswa — dan begitu juga guru/wali.
///
/// Catatan: route guard di Flutter HANYA untuk navigasi & UX. Otorisasi
/// sesungguhnya selalu ditegakkan backend (middleware auth:sanctum +
/// api.role + api.akun + api.password).
String? resolveRedirect(AuthState auth, String location) {
  final atSplash = location == AppRoutes.splash;
  final atLogin = location == AppRoutes.login;
  final atChangePassword = location == AppRoutes.changePassword;

  switch (auth.status) {
    case AuthStatus.unknown:
      return atSplash ? null : AppRoutes.splash;

    case AuthStatus.sessionCheckFailed:
      return (atSplash || atLogin) ? null : AppRoutes.splash;

    case AuthStatus.unauthenticated:
      return atLogin ? null : AppRoutes.login;

    case AuthStatus.authenticated:
      final home = AppRoutes.homeForRole(auth.role);
      // Role tidak dikenal (seharusnya tidak mungkin: backend menolak
      // role non-mobile saat login) → paksa login ulang dengan bersih.
      if (home == null) return AppRoutes.login;

      if (auth.wajibGantiPassword) {
        return atChangePassword ? null : AppRoutes.changePassword;
      }

      // Tidak wajib ganti password: area terlarang diarahkan ke home.
      if (atSplash || atLogin || atChangePassword) return home;

      final areaRole = AppRoutes.roleByAreaPrefix(location);
      if (areaRole != null && areaRole != auth.role) return home;

      return null;
  }
}
