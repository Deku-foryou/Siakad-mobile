import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/guru/presentation/guru_home_page.dart';
import '../../features/siswa/presentation/siswa_home_page.dart';
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
      GoRoute(
        path: AppRoutes.siswa,
        name: 'siswa',
        builder: (context, state) => const SiswaHomePage(),
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
