import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../app/router/app_routes.dart';
import '../../application/auth_controller.dart';
import '../../application/auth_state.dart';

/// Splash: memulihkan sesi dari secure storage + memverifikasi ke server.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: switch (auth.status) {
                AuthStatus.sessionCheckFailed => _SessionCheckFailed(
                  message:
                      auth.errorMessage ?? 'Tidak dapat memverifikasi sesi.',
                ),
                _ => const _Brand(
                  child: AppLoading(message: 'Memeriksa sesi...'),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.school_rounded, size: 72, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          AppConstants.appTagline,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        child,
      ],
    );
  }
}

class _SessionCheckFailed extends ConsumerWidget {
  const _SessionCheckFailed({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Brand(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppErrorView(
            message: message,
            onRetry: () =>
                ref.read(authStateProvider.notifier).restoreSession(),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Ke Halaman Login'),
          ),
        ],
      ),
    );
  }
}
