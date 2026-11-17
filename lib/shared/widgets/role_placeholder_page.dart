import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/widgets/app_empty_view.dart';
import '../../features/auth/application/auth_controller.dart';

/// Halaman placeholder untuk role mobile (siswa / guru / wali).
///
/// Fondasi: menampilkan identitas user + aksi logout. Fitur bisnis
/// dikembangkan pada tahap berikutnya sesuai ROADMAP.
class RolePlaceholderPage extends ConsumerWidget {
  const RolePlaceholderPage({
    super.key,
    required this.roleLabel,
    required this.roleIcon,
    required this.description,
  });

  final String roleLabel;
  final IconData roleIcon;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    final isSubmitting = auth.isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: Text('Area $roleLabel'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: isSubmitting
                ? null
                : () => _confirmLogout(
                    context,
                    ref,
                    title: 'Logout',
                    message: 'Keluar dari akun pada perangkat ini?',
                    allDevices: false,
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _SessionCard(
                      name: user?.name ?? 'Pengguna',
                      username: user?.username ?? '-',
                      roleLabel: roleLabel,
                      roleIcon: roleIcon,
                      initials: _initials(user?.name),
                      deviceName: auth.deviceName,
                      tokenExpiresAt: auth.tokenExpiresAt,
                      isSessionActive: auth.isAuthenticated,
                    ),
                  ),
                  AppEmptyView(
                    icon: roleIcon,
                    title: 'Modul $roleLabel Segera Hadir',
                    message: description,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: OutlinedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () => _confirmLogout(
                              context,
                              ref,
                              title: 'Logout Semua Perangkat',
                              message:
                                  'Keluar dari SEMUA perangkat yang memakai akun '
                                  'ini? Anda perlu login kembali di semua perangkat.',
                              allDevices: true,
                            ),
                      icon: const Icon(Icons.devices_other_rounded),
                      label: const Text('Logout Semua Perangkat'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
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
    required String title,
    required String message,
    required bool allDevices,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
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

/// Card identitas & informasi sesi (non-sensitif; token tidak pernah
/// ditampilkan).
class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.name,
    required this.username,
    required this.roleLabel,
    required this.roleIcon,
    required this.initials,
    required this.deviceName,
    required this.tokenExpiresAt,
    required this.isSessionActive,
  });

  final String name;
  final String username;
  final String roleLabel;
  final IconData roleIcon;
  final String initials;
  final String? deviceName;
  final DateTime? tokenExpiresAt;
  final bool isSessionActive;

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 28, child: Text(initials)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(roleIcon, color: scheme.primary),
              ],
            ),
            const Divider(height: AppSpacing.lg * 2),
            _InfoRow(
              icon: Icons.shield_outlined,
              label: 'Status',
              value: isSessionActive ? 'Sesi aktif' : 'Tidak aktif',
            ),
            if (deviceName != null && deviceName!.isNotEmpty)
              _InfoRow(
                icon: Icons.phone_android_rounded,
                label: 'Perangkat',
                value: deviceName!,
              ),
            if (tokenExpiresAt != null)
              _InfoRow(
                icon: Icons.event_available_rounded,
                label: 'Token berlaku hingga',
                value: _formatDate(tokenExpiresAt!),
              ),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Role',
              value: roleLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
