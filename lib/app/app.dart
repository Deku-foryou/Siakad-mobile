import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../shared/application/account_session_reset.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget aplikasi SIAKAD Mobile.
///
/// Menggunakan MaterialApp.router + GoRouter; seluruh route guard
/// ditangani oleh redirect pada router (lihat `app/router/app_router.dart`).
class SiakadApp extends ConsumerWidget {
  const SiakadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Aktifkan listener reset lintas fitur saat sesi berakhir (see file).
    ref.watch(accountSessionResetProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
