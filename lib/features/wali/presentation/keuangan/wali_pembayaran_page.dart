import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../widgets/child_switcher.dart';
import '../../application/wali_providers.dart';
import '../../../siswa/data/models/keuangan.dart';

/// Riwayat pembayaran anak (paginated) — `GET /keuangan/pembayaran?siswa_id=`.
class WaliPembayaranPage extends ConsumerWidget {
  const WaliPembayaranPage({super.key, required this.siswaId});

  final int siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(waliPembayaranProvider(siswaId));
    final notifier = ref.read(waliPembayaranProvider(siswaId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: AnakAppBarTitle('Riwayat Pembayaran', siswaId: siswaId),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: notifier.refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
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
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum Ada Pembayaran',
                    message: 'Riwayat pembayaran anak ini akan tampil di sini.',
                  ),
                )
              else ...[
                for (final item in state.items)
                  _PembayaranTile(
                    item: item,
                    onTap: () => context.push(
                      '/wali/anak/$siswaId/keuangan/pembayaran/${item.id}',
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

class _PembayaranTile extends StatelessWidget {
  const _PembayaranTile({required this.item, required this.onTap});

  final Pembayaran item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.payments_rounded),
        title: Text(
          Formatters.rupiah(item.nominal),
          style: textTheme.titleSmall,
        ),
        subtitle: Text(
          [
            if (item.metode != null) 'Metode: ${item.metode}',
            if (item.dibayarPada != null)
              Formatters.dateTimeLokal(item.dibayarPada),
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: StatusBadge(
          label: StatusBadge.labelOf(item.status),
          color: StatusBadge.forStatus(item.status),
        ),
      ),
    );
  }
}
