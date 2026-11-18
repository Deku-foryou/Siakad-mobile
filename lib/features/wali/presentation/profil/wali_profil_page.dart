import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/wali_providers.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/application/auth_state.dart';

/// Profil wali (read-only) — `GET /wali/profil` + informasi sesi lokal.
class WaliProfilPage extends ConsumerWidget {
  const WaliProfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(waliProfilProvider);
    final auth = ref.watch(authStateProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(waliProfilProvider),
          child: profil.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                AsyncValueView<void>(
                  value: AsyncValue.error(error, StackTrace.current),
                  onRetry: () => ref.invalidate(waliProfilProvider),
                  data: (_) => const SizedBox.shrink(),
                ),
              ],
            ),
            data: (data) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // --------------------------------------- Identitas
                InfoCard(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        child: Text(
                          _initials(data.name),
                          style: textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        data.name.isEmpty ? 'Wali Murid' : data.name,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${data.username}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      StatusBadge(
                        label: (data.statusAkun ?? 'tidak diketahui')
                            .toUpperCase(),
                        color: data.statusAkun == 'aktif'
                            ? StatusBadge.forStatus('hadir')
                            : StatusBadge.forStatus('failed'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const SectionHeader(title: 'Akun'),
                InfoCard(
                  child: Column(
                    children: [
                      InfoRow(label: 'Nama', value: data.name),
                      InfoRow(label: 'Username', value: '@${data.username}'),
                      if (data.email != null)
                        InfoRow(label: 'Email', value: data.email!),
                      InfoRow(
                        label: 'Wajib Ganti Password',
                        value: data.wajibGantiPassword ? 'Ya' : 'Tidak',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const SectionHeader(title: 'Relasi Anak'),
                InfoCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final pair in [
                        ('Terverifikasi', data.relasi.verified),
                        ('Menunggu', data.relasi.pending),
                        ('Ditolak', data.relasi.rejected),
                        ('Berakhir', data.relasi.terminated),
                      ])
                        Column(
                          children: [
                            Text(
                              '${pair.$2}',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(pair.$1, style: textTheme.labelSmall),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const SectionHeader(title: 'Sesi Perangkat'),
                _SesiCard(auth: auth),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: auth.isSubmitting
                      ? null
                      : () => _confirmLogout(context, ref, allDevices: false),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout Perangkat Ini'),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  onPressed: auth.isSubmitting
                      ? null
                      : () => _confirmLogout(context, ref, allDevices: true),
                  icon: const Icon(Icons.devices_other_rounded),
                  label: const Text('Logout Semua Perangkat'),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }

  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref, {
    required bool allDevices,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(allDevices ? 'Logout Semua Perangkat' : 'Logout'),
        content: Text(
          allDevices
              ? 'Keluar dari SEMUA perangkat yang memakai akun ini? '
                    'Anda perlu login kembali di semua perangkat.'
              : 'Keluar dari akun pada perangkat ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final controller = ref.read(authStateProvider.notifier);
    if (allDevices) {
      await controller.logoutAll();
    } else {
      await controller.logout();
    }
  }
}

class _SesiCard extends StatelessWidget {
  const _SesiCard({required this.auth});

  final AuthState auth;

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        children: [
          InfoRow(
            label: 'Status',
            value: auth.isAuthenticated ? 'Sesi aktif' : 'Tidak aktif',
          ),
          if (auth.deviceName != null && auth.deviceName!.isNotEmpty)
            InfoRow(label: 'Perangkat', value: auth.deviceName!),
          if (auth.tokenExpiresAt != null)
            InfoRow(
              label: 'Token berlaku hingga',
              value: _formatDate(auth.tokenExpiresAt!),
            ),
        ],
      ),
    );
  }
}
