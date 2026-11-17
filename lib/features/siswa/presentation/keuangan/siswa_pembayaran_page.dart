import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/siswa_providers.dart';

/// Riwayat pembayaran siswa (K5) — tap item → detail (K6).
class SiswaPembayaranPage extends ConsumerWidget {
  const SiswaPembayaranPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pembayaranProvider);
    final notifier = ref.read(pembayaranProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pembayaran')),
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
                          icon: Icons.payments_outlined,
                          title: 'Belum Ada Pembayaran',
                          message: 'Riwayat pembayaran akan tampil di sini.',
                        ),
                      )
                    else
                      for (final item in state.items)
                        Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: ListTile(
                            onTap: () =>
                                context.push('/siswa/pembayaran/${item.id}'),
                            title: Text(
                              Formatters.rupiah(item.nominal),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              [
                                if (item.metode != null) item.metode!,
                                if (item.dibayarPada != null)
                                  Formatters.dateTimeLokal(item.dibayarPada),
                              ].join(' · '),
                            ),
                            trailing: StatusBadge(
                              label: StatusBadge.labelOf(item.status),
                              color: StatusBadge.forStatus(item.status),
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
                ),
        ),
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
