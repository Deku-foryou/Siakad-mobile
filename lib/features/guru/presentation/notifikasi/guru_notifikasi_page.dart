import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../shared/models/notifikasi.dart';
import '../../application/guru_providers.dart';

/// Tab Notifikasi guru: daftar, filter status, badge unread, tandai dibaca.
class GuruNotifikasiPage extends ConsumerWidget {
  const GuruNotifikasiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(guruNotifikasiProvider);
    final notifier = ref.read(guruNotifikasiProvider.notifier);
    final unread = ref.watch(guruUnreadCountProvider).value ?? 0;

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
                  _chip(ref, null, 'Semua'),
                  _chip(ref, 'unread', 'Belum Dibaca'),
                  _chip(ref, 'read', 'Dibaca'),
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
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(state.error!, textAlign: TextAlign.center),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton.icon(
                                onPressed: notifier.refresh,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
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

  Widget _chip(WidgetRef ref, String? value, String label) {
    final notifier = ref.read(guruNotifikasiProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: notifier.status == value,
        onSelected: (_) => notifier.applyFilter(status: value),
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
      final result = await ref.read(guruNotifikasiActionProvider).markAllRead();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.ditandai} notifikasi ditandai dibaca.'),
          ),
        );
      }
      await ref.read(guruNotifikasiProvider.notifier).refresh();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menandai. Coba lagi.')),
        );
      }
    }
  }
}

class _NotifikasiTile extends StatelessWidget {
  const _NotifikasiTile({required this.item});

  final NotifikasiItem item;

  @override
  Widget build(BuildContext context) {
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
          Icons.notifications_none_rounded,
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
      onTap: () => context.push('/guru/notifikasi/${item.id}'),
    );
  }
}
