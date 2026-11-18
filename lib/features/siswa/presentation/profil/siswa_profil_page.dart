import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/application/auth_state.dart';
import '../../application/siswa_providers.dart';

/// Profil siswa — read-only dari `GET /siswa/profil` + informasi sesi lokal.
class SiswaProfilPage extends ConsumerWidget {
  const SiswaProfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilProvider);
    final auth = ref.watch(authStateProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(profilProvider),
          child: profil.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                AsyncValueView<void>(
                  value: AsyncValue.error(error, StackTrace.current),
                  onRetry: () => ref.invalidate(profilProvider),
                  data: (_) => const SizedBox.shrink(),
                ),
              ],
            ),
            data: (data) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // ------------------------------------------- Identitas
                InfoCard(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        child: Text(
                          Formatters.initials(data.nama),
                          style: textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(data.nama, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '@${data.akunUsername}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      StatusBadge(
                        label: (data.status ?? 'tidak diketahui').toUpperCase(),
                        color: data.status == 'aktif'
                            ? StatusBadge.forStatus('hadir')
                            : StatusBadge.forStatus('failed'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const SectionHeader(title: 'Data Siswa'),
                InfoCard(
                  child: Column(
                    children: [
                      InfoRow(label: 'NIS', value: data.nis),
                      if (data.nisn != null)
                        InfoRow(label: 'NISN', value: data.nisn!),
                      if (data.jenisKelamin != null)
                        InfoRow(
                          label: 'Jenis Kelamin',
                          value: _jenisKelaminLabel(data.jenisKelamin!),
                        ),
                      if (data.tahunMasuk != null)
                        InfoRow(
                          label: 'Tahun Masuk',
                          value: '${data.tahunMasuk}',
                        ),
                      if (data.kelas.isNotEmpty)
                        InfoRow(
                          label: 'Kelas',
                          value: data.kelas
                              .map(
                                (k) => k.tingkat != null
                                    ? '${k.nama} (T${k.tingkat})'
                                    : k.nama,
                              )
                              .join(', '),
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

  String _jenisKelaminLabel(String value) {
    switch (value.toUpperCase()) {
      case 'L':
        return 'Laki-laki';
      case 'P':
        return 'Perempuan';
      default:
        return value;
    }
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
