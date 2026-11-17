import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../application/siswa_providers.dart';
import '../../data/models/pengumuman.dart';

/// Daftar pengumuman siswa â€” tab Aktif/Riwayat (`?tab=` backend).
class SiswaPengumumanPage extends ConsumerStatefulWidget {
  const SiswaPengumumanPage({super.key});

  @override
  ConsumerState<SiswaPengumumanPage> createState() =>
      _SiswaPengumumanPageState();
}

class _SiswaPengumumanPageState extends ConsumerState<SiswaPengumumanPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pengumumanProvider);
    final notifier = ref.read(pengumumanProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Aktif'),
                    selected: notifier.tab == 'aktif',
                    onSelected: (_) => notifier.setTab('aktif'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Riwayat'),
                    selected: notifier.tab == 'riwayat',
                    onSelected: (_) => notifier.setTab('riwayat'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: notifier.refresh,
          child: state.items.isEmpty && state.refreshing
              ? const Center(child: CircularProgressIndicator())
              : state.error != null && state.items.isEmpty
              ? _ListError(message: state.error!, onRetry: notifier.refresh)
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    if (state.items.isEmpty)
                      SizedBox(
                        height: 280,
                        child: AppEmptyView(
                          icon: Icons.campaign_rounded,
                          title: notifier.tab == 'aktif'
                              ? 'Tidak Ada Pengumuman Aktif'
                              : 'Belum Ada Riwayat',
                          message:
                              'Pengumuman dari sekolah akan tampil di sini.',
                        ),
                      )
                    else ...[
                      for (final item in state.items)
                        _PengumumanTile(item: item),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
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
}

class _PengumumanTile extends StatelessWidget {
  const _PengumumanTile({required this.item});

  final PengumumanItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool prioritas = (item.prioritas ?? '').toLowerCase() == 'tinggi';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: prioritas
              ? scheme.errorContainer
              : scheme.secondaryContainer,
          child: Icon(
            Icons.campaign_rounded,
            color: prioritas
                ? scheme.onErrorContainer
                : scheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          item.judul,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: item.dibaca ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Text(
          [
            if (item.kategori != null) item.kategori!,
            if (item.waktuTerbit != null)
              Formatters.dateTimeLokal(item.waktuTerbit),
          ].join(' Â· '),
        ),
        trailing: item.dibaca
            ? Icon(Icons.done_all_rounded, color: scheme.primary, size: 20)
            : const Icon(Icons.fiber_new_rounded, size: 20),
        onTap: () => context.push('/siswa/pengumuman/${item.id}'),
      ),
    );
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
