import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../application/siswa_providers.dart';
import '../../data/models/notifikasi.dart';

/// Tab Notifikasi siswa: daftar, filter status, badge unread, tandai dibaca.
class SiswaNotifikasiPage extends ConsumerWidget {
  const SiswaNotifikasiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notifikasiProvider);
    final notifier = ref.read(notifikasiProvider.notifier);
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => _markAll(context, ref),
              child: const Text('Tandai Semua Dibaca'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                children: [
                  _chip(
                    context,
                    ref,
                    label: 'Semua',
                    value: null,
                    current: notifier.status,
                  ),
                  _chip(
                    context,
                    ref,
                    label: 'Belum Dibaca',
                    value: 'unread',
                    current: notifier.status,
                  ),
                  _chip(
                    context,
                    ref,
                    label: 'Dibaca',
                    value: 'read',
                    current: notifier.status,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: notifier.refresh,
                child: state.items.isEmpty && state.refreshing
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null && state.items.isEmpty
                    ? _ListError(
                        message: state.error!,
                        onRetry: notifier.refresh,
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        children: [
                          if (state.items.isEmpty)
                            SizedBox(
                              height: 280,
                              child: AppEmptyView(
                                icon: Icons.notifications_none_rounded,
                                title: 'Tidak Ada Notifikasi',
                                message: 'Notifikasi dari sekolah akan tampil di sini.',
                              ),
                            )
                          else
                            for (final item in state.items)
                              _NotifikasiTile(item: item),
                          if (state.error != null)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Text(
                                state.error!,
                                style: TextStyle(color: scheme.error),
                              ),
                            ),
                          if (state.hasMore)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Center(
                                child: OutlinedButton(
                                  onPressed: state.busy
                                      ? null
                                      : notifier.loadMore,
                                  child: state.busy
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Muat Lebih Banyak'),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String? value,
    required String? current,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: current == value,
        onSelected: (_) =>
            ref.read(notifikasiProvider.notifier).applyFilter(status: value),
      ),
    );
  }

  Future<void> _markAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tandai Semua Dibaca'),
        content: const Text('Menandai seluruh notifikasi Anda sebagai dibaca?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Tandai Semua'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await ref.read(notifikasiActionProvider).markAllRead();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.ditandai} notifikasi ditandai dibaca.'),
          ),
        );
      }
      await ref.read(notifikasiProvider.notifier).refresh();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menandai notifikasi. Coba lagi.'),
          ),
        );
      }
    }
  }
}

class _NotifikasiTile extends ConsumerWidget {
  const _NotifikasiTile({required this.item});

  final NotifikasiItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final bool unread = !item.dibaca;
    return ListTile(
      tileColor: unread
          ? scheme.primaryContainer.withValues(alpha: 0.25)
          : null,
      leading: CircleAvatar(
        backgroundColor: unread
            ? scheme.primary
            : scheme.surfaceContainerHighest,
        child: Icon(
          _iconFor(item.jenis),
          color: unread ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        item.judul,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      subtitle: Text(
        [
          if (item.jenis != null) item.jenis!,
          if (item.waktuDibuat != null)
            Formatters.dateTimeLokal(item.waktuDibuat),
        ].join(' Â· '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: unread
          ? Icon(Icons.circle, size: 10, color: scheme.primary)
          : null,
      onTap: () => context.push('/siswa/notifikasi/${item.id}'),
    );
  }

  IconData _iconFor(String? jenis) {
    switch ((jenis ?? '').toLowerCase()) {
      case 'tagihan':
      case 'keuangan':
        return Icons.payments_outlined;
      case 'absensi':
        return Icons.fact_check_outlined;
      case 'nilai':
        return Icons.grade_outlined;
      case 'pengumuman':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}

class _ListError extends StatelessWidget {
  const _ListError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: scheme.error),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
