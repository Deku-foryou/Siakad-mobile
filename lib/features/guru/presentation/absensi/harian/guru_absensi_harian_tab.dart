import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_empty_view.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../../application/guru_providers.dart';
import '../../../data/models/guru.dart';

/// Tab Harian: riwayat (G11) + aksi "Isi Absensi Hari Ini" (grid G15).
class GuruAbsensiHarianTab extends ConsumerWidget {
  const GuruAbsensiHarianTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(guruAbsensiHarianProvider);
    final notifier = ref.read(guruAbsensiHarianProvider.notifier);
    final kelasAsync = ref.watch(guruKelasListProvider);
    final diajar =
        kelasAsync.value?.kelas.where((k) => k.diajar).toList() ?? const [];

    return Column(
      children: [
        // ------------------------------------------- Isi absensi hari ini
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: diajar.isEmpty
                  ? null
                  : () => _pickKelasUntukIsi(context, ref, diajar),
              icon: const Icon(Icons.fact_check_rounded),
              label: const Text('Isi Absensi Hari Ini'),
            ),
          ),
        ),
        // ------------------------------------------- Filter
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              _statusChip(ref, 'Semua', null, notifier),
              _statusChip(ref, 'Hadir', 'hadir', notifier),
              _statusChip(ref, 'Sakit', 'sakit', notifier),
              _statusChip(ref, 'Izin', 'izin', notifier),
              _statusChip(ref, 'Alpha', 'alpha', notifier),
            ],
          ),
        ),
        const Divider(height: 1),
        // ------------------------------------------- Riwayat
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refresh,
            child: state.items.isEmpty && state.refreshing
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.items.isEmpty
                ? _ErrorBlock(message: state.error!, onRetry: notifier.refresh)
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      if (state.items.isEmpty)
                        const SizedBox(
                          height: 240,
                          child: AppEmptyView(
                            icon: Icons.fact_check_outlined,
                            title: 'Belum Ada Riwayat',
                            message:
                                'Riwayat absensi harian akan tampil di sini.',
                          ),
                        )
                      else
                        for (final item in state.items)
                          Card(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: ListTile(
                              onTap: item.id == null
                                  ? null
                                  : () => context.push(
                                      '/guru/absensi/harian/${item.id}',
                                    ),
                              leading: CircleAvatar(
                                child: Text(
                                  item.tanggal != null &&
                                          item.tanggal!.length >= 10
                                      ? item.tanggal!.substring(8, 10)
                                      : '?',
                                ),
                              ),
                              title: Text(item.siswaNama ?? '-'),
                              subtitle: Text(
                                [
                                  Formatters.tanggalPendek(item.tanggal),
                                  'Kelas ${item.kelasNama ?? '-'}',
                                  if (item.catatan != null &&
                                      item.catatan!.isNotEmpty)
                                    'Catatan: ${item.catatan}',
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
      ],
    );
  }

  Widget _statusChip(
    WidgetRef ref,
    String label,
    String? value,
    GuruAbsensiHarianNotifier notifier,
  ) {
    final current = notifier.status;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: current == value,
        onSelected: (_) => notifier.applyFilter(status: value),
      ),
    );
  }

  Future<void> _pickKelasUntukIsi(
    BuildContext context,
    WidgetRef ref,
    List<KelasRingkas> diajar,
  ) async {
    final today = DateTime.now();
    String iso(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('Pilih Kelas'),
            ),
            ...diajar.map(
              (k) => ListTile(
                title: Text(k.nama),
                subtitle: Text('${k.jumlahSiswa ?? 0} siswa'),
                onTap: () => Navigator.of(ctx).pop(k.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) {
      context.push('/guru/absensi/harian/grid/$selected?tanggal=${iso(today)}');
    }
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

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
