import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/guru/presentation/guru_home_page.dart';
import '../../features/siswa/presentation/akademik/siswa_absensi_page.dart';
import '../../features/siswa/presentation/akademik/siswa_jadwal_page.dart';
import '../../features/siswa/presentation/akademik/siswa_nilai_page.dart';
import '../../features/siswa/presentation/akademik/siswa_rapor_detail_page.dart';
import '../../features/siswa/presentation/akademik/siswa_rapor_page.dart';
import '../../features/siswa/presentation/keuangan/siswa_attempt_status_page.dart';
import '../../features/siswa/presentation/keuangan/siswa_pembayaran_detail_page.dart';
import '../../features/siswa/presentation/keuangan/siswa_pembayaran_page.dart';
import '../../features/siswa/presentation/keuangan/siswa_tagihan_detail_page.dart';
import '../../features/siswa/presentation/pengumuman/siswa_pengumuman_detail_page.dart';
import '../../features/siswa/presentation/pengumuman/siswa_pengumuman_page.dart';
import '../../features/siswa/presentation/notifikasi/siswa_notifikasi_detail_page.dart';
import '../../features/siswa/presentation/siswa_shell.dart';
import '../../features/wali/presentation/wali_home_page.dart';
import 'app_routes.dart';
import 'redirect.dart';

/// Menjembatani perubahan AuthState ke GoRouter (refreshListenable).
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    _subscription = ref.listen<AuthState>(
      authStateProvider,
      (previous, next) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) =>
        resolveRedirect(ref.read(authStateProvider), state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: 'change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      // Area siswa: shell + sub-route (sub-route memakai root navigator).
      GoRoute(
        path: AppRoutes.siswa,
        name: 'siswa',
        builder: (context, state) => const SiswaShell(),
      ),
      GoRoute(
        path: AppRoutes.siswaJadwal,
        name: 'siswa-jadwal',
        builder: (context, state) => const SiswaJadwalPage(),
      ),
      GoRoute(
        path: AppRoutes.siswaAbsensi,
        name: 'siswa-absensi',
        builder: (context, state) => const SiswaAbsensiPage(),
      ),
      GoRoute(
        path: AppRoutes.siswaNilai,
        name: 'siswa-nilai',
        builder: (context, state) => const SiswaNilaiPage(),
      ),
      GoRoute(
        path: AppRoutes.siswaRapor,
        name: 'siswa-rapor',
        builder: (context, state) => const SiswaRaporPage(),
      ),
      GoRoute(
        path: AppRoutes.siswaRaporDetailPath,
        name: 'siswa-rapor-detail',
        builder: (context, state) {
          final semesterId = int.tryParse(
            state.pathParameters['semesterId'] ?? '',
          );
          final kelasId = int.tryParse(state.pathParameters['kelasId'] ?? '');
          if (semesterId == null || kelasId == null) {
            return const _InvalidParameterPage();
          }
          return SiswaRaporDetailPage(semesterId: semesterId, kelasId: kelasId);
        },
      ),
      GoRoute(
        path: AppRoutes.siswaPengumuman,
        name: 'siswa-pengumuman',
        builder: (context, state) => const SiswaPengumumanPage(),
      ),
      GoRoute(
        path: AppRoutes.siswaPengumumanDetail,
        name: 'siswa-pengumuman-detail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _InvalidParameterPage();
          return SiswaPengumumanDetailPage(id: id);
        },
      ),
      GoRoute(
        path: AppRoutes.siswaNotifikasiDetail,
        name: 'siswa-notifikasi-detail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _InvalidParameterPage();
          return SiswaNotifikasiDetailPage(id: id);
        },
      ),
      GoRoute(
        path: '/siswa/pembayaran',
        name: 'siswa-pembayaran',
        builder: (context, state) => const SiswaPembayaranPage(),
      ),
      GoRoute(
        path: AppRoutes.siswaTagihanDetail,
        name: 'siswa-tagihan-detail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _InvalidParameterPage();
          return SiswaTagihanDetailPage(id: id);
        },
      ),
      GoRoute(
        path: AppRoutes.siswaPembayaranDetail,
        name: 'siswa-pembayaran-detail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _InvalidParameterPage();
          return SiswaPembayaranDetailPage(id: id);
        },
      ),
      GoRoute(
        path: AppRoutes.siswaAttemptDetail,
        name: 'siswa-attempt-detail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _InvalidParameterPage();
          return SiswaAttemptStatusPage(id: id);
        },
      ),
      GoRoute(
        path: AppRoutes.guru,
        name: 'guru',
        builder: (context, state) => const GuruHomePage(),
      ),
      GoRoute(
        path: AppRoutes.wali,
        name: 'wali',
        builder: (context, state) => const WaliHomePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan: ${state.uri}')),
    ),
  );
});

class _InvalidParameterPage extends StatelessWidget {
  const _InvalidParameterPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parameter tidak valid')),
      body: const Center(child: Text('Alamat halaman tidak valid.')),
    );
  }
}
