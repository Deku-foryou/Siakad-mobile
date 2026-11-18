import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/siswa_providers.dart';
import '../../data/models/keuangan.dart';

/// Tab Keuangan siswa: ringkasan (K1) + saldo (K4) + tagihan (K2, K3).
/// Riwayat pembayaran & detail tagihan dibuka via router.
class SiswaKeuanganPage extends ConsumerWidget {
  const SiswaKeuanganPage({super.key});

  static const _statusFilters = <String?>[
    null,
    'belum_dibayar',
    'dibayar_sebagian',
    'lunas',
    'dibebaskan',
    'dibatalkan',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringkasan = ref.watch(ringkasanProvider);
    final saldo = ref.watch(saldoProvider);
    final tagihan = ref.watch(tagihanProvider);
    final tagNotifier = ref.read(tagihanProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> refreshAll() async {
      ref.invalidate(ringkasanProvider);
      ref.invalidate(saldoProvider);
      await tagNotifier.refresh();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Keuangan')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshAll,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // ---------------------------------- Ringkasan (K1)
              _RingkasanCard(
                ringkasan: ringkasan,
                onRetry: () => ref.invalidate(ringkasanProvider),
              ),
              const SizedBox(height: AppSpacing.md),

              // ---------------------------------- Saldo (K4)
              InfoCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo Tersedia',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          saldo.when(
                            loading: () => const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: (_, _) => TextButton(
                              onPressed: () => ref.invalidate(saldoProvider),
                              child: const Text('Gagal memuat — Coba lagi'),
                            ),
                            data: (value) => Text(
                              Formatters.rupiah(value),
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ---------------------------------- Tagihan (K2)
              SectionHeader(
                title: 'Tagihan Saya',
                action: TextButton(
                  onPressed: () => context.push('/siswa/pembayaran'),
                  child: const Text('Riwayat Pembayaran'),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final status in _statusFilters)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: FilterChip(
                          label: Text(
                            status == null
                                ? 'Semua'
                                : StatusBadge.labelOf(status),
                          ),
                          selected: tagNotifier.status == status,
                          onSelected: (_) =>
                              tagNotifier.applyFilter(status: status),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (tagihan.items.isEmpty && tagihan.refreshing)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (tagihan.error != null && tagihan.items.isEmpty)
                AppErrorRetry(
                  message: tagihan.error!,
                  onRetry: () => tagNotifier.refresh(),
                )
              else if (tagihan.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AppEmptyView(
                    icon: Icons.receipt_long_outlined,
                    title: 'Tidak Ada Tagihan',
                    message: 'Belum ada tagihan pada filter ini.',
                  ),
                )
              else ...[
                for (final item in tagihan.items)
                  _TagihanTile(
                    item: item,
                    onTap: () => context.push('/siswa/tagihan/${item.id}'),
                  ),
                if (tagihan.hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: tagihan.busy ? null : tagNotifier.loadMore,
                        child: tagihan.busy
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

class _RingkasanCard extends StatelessWidget {
  const _RingkasanCard({required this.ringkasan, required this.onRetry});

  final AsyncValue<RingkasanKeuangan> ringkasan;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ringkasan.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ringkasan keuangan tidak tersedia.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
            ],
          ),
          data: (data) {
            final total = data.totalKewajiban;
            final sisa = data.sisaKewajiban;
            final progress = total > 0 ? (total - sisa) / total : 0.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Kewajiban',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  Formatters.rupiah(data.sisaKewajiban),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'sisa dari ${Formatters.rupiah(total)} · dibayar ${Formatters.rupiah(data.totalDibayar)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TagihanTile extends StatelessWidget {
  const _TagihanTile({required this.item, required this.onTap});

  final Tagihan item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        onTap: onTap,
        title: Text(item.nama, style: textTheme.titleSmall),
        subtitle: Text(
          [
            if (item.jatuhTempo != null)
              'Jatuh tempo ${Formatters.tanggalPanjang(item.jatuhTempo)}',
            'Sisa ${Formatters.rupiah(item.sisa)}',
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
