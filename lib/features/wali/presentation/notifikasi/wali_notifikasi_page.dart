import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../application/wali_providers.dart';

/// Daftar notifikasi wali (user-scoped) — `GET /wali/notifikasi`.
/// Filter status dibaca + "Tandai Semua Dibaca". Pull-to-refresh + muat lagi.
class WaliNotifikasiPage extends ConsumerWidget {
  const WaliNotifikasiPage({super.key});

  static const _filters = <String?>[null, 'unread', 'read'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(waliNotifikasiProvider);
    final notifier = ref.read(waliNotifikasiProvider.notifier);
    final unread = ref.watch(waliUnreadCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            tooltip: 'Tandai semua dibaca',
            onPressed: unread == 0 ? null : () => _markAllRead(context, ref),
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await notifier.refresh();
            ref.invalidate(waliUnreadCountProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final f in _filters)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: FilterChip(
                          label: Text(switch (f) {
                            null => 'Semua',
                            'unread' => 'Belum Dibaca',
                            _ => 'Dibaca',
                          }),
                          selected: notifier.status == f,
                          onSelected: (_) => notifier.applyFilter(status: f),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (state.items.isEmpty && state.refreshing)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.error != null && state.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(state.error!, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: notifier.refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              else if (state.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AppEmptyView(
                    icon: Icons.notifications_none_rounded,
                    title: 'Belum Ada Notifikasi',
                    message: 'Notifikasi Anda akan tampil di sini.',
                  ),
                )
              else ...[
                for (final item in state.items)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ListTile(
                      onTap: () => context.push('/wali/notifikasi/${item.id}'),
                      leading: Icon(
                        item.dibaca
                            ? Icons.notifications_none_rounded
                            : Icons.notifications_active_rounded,
                        color: item.dibaca
                            ? null
                            : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        item.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: item.dibaca
                            ? null
                            : const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        item.waktuDibuat != null
                            ? Formatters.dateTimeLokal(item.waktuDibuat)
                            : '',
                      ),
                      trailing: item.dibaca
                          ? null
                          : const Icon(
                              Icons.circle,
                              size: 10,
                              color: Colors.blue,
                            ),
                    ),
                  ),
                if (state.hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: state.busy ? null : notifier.loadMore,
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(waliNotifikasiActionProvider).markAllRead();
      await ref.read(waliNotifikasiProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.ditandai} notifikasi ditandai dibaca.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menandai. Coba lagi.')),
        );
      }
    }
  }
}
