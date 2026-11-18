import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/wali_absensi_notifiers.dart';
import '../../../siswa/data/models/absensi.dart';

/// Absensi anak terpilih — 3 tab: Harian, Periode, Per Jam.
/// Seluruhnya read-only; data selalu dari `/wali/anak/{siswaId}/absensi/*`.
class WaliAbsensiPage extends ConsumerWidget {
  const WaliAbsensiPage({super.key, required this.siswaId});

  final int siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Absensi Anak'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Harian'),
              Tab(text: 'Periode'),
              Tab(text: 'Per Jam'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _HarianTab(siswaId: siswaId),
              _PeriodeTab(siswaId: siswaId),
              _PerjamTab(siswaId: siswaId),
            ],
          ),
        ),
      ),
    );
  }
}

const _statusFilters = <String?>[null, 'hadir', 'sakit', 'izin', 'alpha'];

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({required this.value, required this.onSelected});

  final String? value;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final status in _statusFilters)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: FilterChip(
                label: Text(
                  status == null ? 'Semua' : StatusBadge.labelOf(status),
                ),
                selected: value == status,
                onSelected: (_) => onSelected(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _RekapCard extends StatelessWidget {
  const _RekapCard({required this.title, required this.rekap});

  final String title;
  final RekapAbsensi rekap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final pair in [
                  ('Hadir', rekap.hadir, const Color(0xFF15803D)),
                  ('Sakit', rekap.sakit, const Color(0xFFB45309)),
                  ('Izin', rekap.izin, const Color(0xFFB45309)),
                  ('Alpha', rekap.alpha, const Color(0xFFB91C1C)),
                ])
                  Column(
                    children: [
                      Text(
                        '${pair.$2}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: pair.$3,
                        ),
                      ),
                      Text(pair.$1, style: textTheme.labelSmall),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Total ${rekap.total} · Kehadiran ${Formatters.persenHadir(rekap.persenHadir)}',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HarianTab extends ConsumerWidget {
  const _HarianTab({required this.siswaId});

  final int siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(waliAbsensiHarianProvider(siswaId));
    final notifier = ref.read(waliAbsensiHarianProvider(siswaId).notifier);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _StatusFilterChips(
            value: state.status,
            onSelected: (s) => notifier.applyFilter(status: s),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.rekapTotal != null)
            _RekapCard(
              title: 'Rekap Semester/TA Aktif',
              rekap: state.rekapTotal!,
            ),
          if (state.rekap != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _RekapCard(title: 'Ringkasan (sesuai filter)', rekap: state.rekap!),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (state.items.isEmpty && state.refreshing)
            const Center(child: CircularProgressIndicator())
          else if (state.error != null && state.items.isEmpty)
            _ErrorBlock(message: state.error!, onRetry: notifier.refresh)
          else if (state.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppEmptyView(
                icon: Icons.fact_check_outlined,
                title: 'Belum Ada Absensi',
                message: 'Tidak ada catatan absensi harian pada filter ini.',
              ),
            )
          else ...[
            for (final item in state.items) _AbsensiHarianTile(item: item),
            if (state.hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(
                  child: OutlinedButton(
                    onPressed: state.busy ? null : notifier.loadMore,
                    child: state.busy
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Muat Lebih Banyak'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PeriodeTab extends ConsumerWidget {
  const _PeriodeTab({required this.siswaId});

  final int siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(waliAbsensiPeriodeProvider(siswaId));
    final notifier = ref.read(waliAbsensiPeriodeProvider(siswaId).notifier);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rentang tanggal wajib diisi.',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                        ),
                        label: Text(
                          state.dari ?? 'Dari',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => _pickDate(context, ref, isDari: true),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('–'),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                        ),
                        label: Text(
                          state.sampai ?? 'Sampai',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => _pickDate(context, ref, isDari: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _StatusFilterChips(
            value: state.status,
            onSelected: (s) {
              if (state.dari == null || state.sampai == null) return;
              notifier.applyFilter(
                dari: state.dari!,
                sampai: state.sampai!,
                status: s,
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.dari == null || state.sampai == null)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppEmptyView(
                icon: Icons.date_range_rounded,
                title: 'Pilih Rentang Tanggal',
                message: 'Pilih tanggal awal dan akhir untuk melihat absensi pada periode tersebut.',
              ),
            )
          else ...[
            if (state.rekap != null) ...[
              _RekapCard(title: 'Ringkasan Periode', rekap: state.rekap!),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (state.items.isEmpty && state.refreshing)
              const Center(child: CircularProgressIndicator())
            else if (state.error != null && state.items.isEmpty)
              _ErrorBlock(message: state.error!, onRetry: notifier.refresh)
            else if (state.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AppEmptyView(
                  icon: Icons.fact_check_outlined,
                  title: 'Tidak Ada Data',
                  message: 'Tidak ada absensi pada periode yang dipilih.',
                ),
              )
            else ...[
              for (final item in state.items) _AbsensiHarianTile(item: item),
              if (state.hasMore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Center(
                    child: OutlinedButton(
                      onPressed: state.busy ? null : notifier.loadMore,
                      child: state.busy
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Muat Lebih Banyak'),
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref, {
    required bool isDari,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    final notifier = ref.read(waliAbsensiPeriodeProvider(siswaId).notifier);
    final state = ref.read(waliAbsensiPeriodeProvider(siswaId));
    final dari = isDari ? iso : (state.dari ?? iso);
    final sampai = isDari ? (state.sampai ?? iso) : iso;
    if (dari.compareTo(sampai) > 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal awal tidak boleh melebihi tanggal akhir.'),
          ),
        );
      }
      return;
    }
    notifier.applyFilter(dari: dari, sampai: sampai, status: state.status);
  }
}

class _PerjamTab extends ConsumerWidget {
  const _PerjamTab({required this.siswaId});

  final int siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(waliAbsensiPerjamProvider(siswaId));
    final notifier = ref.read(waliAbsensiPerjamProvider(siswaId).notifier);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _StatusFilterChips(
            value: state.status,
            onSelected: (s) => notifier.applyFilter(status: s),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.rekapTotal != null)
            _RekapCard(
              title: 'Total Per Jam (seluruh riwayat)',
              rekap: state.rekapTotal!,
            ),
          if (state.rekap != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _RekapCard(title: 'Ringkasan (sesuai filter)', rekap: state.rekap!),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (state.items.isEmpty && state.refreshing)
            const Center(child: CircularProgressIndicator())
          else if (state.error != null && state.items.isEmpty)
            _ErrorBlock(message: state.error!, onRetry: notifier.refresh)
          else if (state.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppEmptyView(
                icon: Icons.schedule_rounded,
                title: 'Belum Ada Absensi Per Jam',
                message: 'Tidak ada catatan absensi per jam pada filter ini.',
              ),
            )
          else ...[
            for (final item in state.items) _AbsensiPerjamTile(item: item),
            if (state.hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(
                  child: OutlinedButton(
                    onPressed: state.busy ? null : notifier.loadMore,
                    child: state.busy
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Muat Lebih Banyak'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AbsensiHarianTile extends StatelessWidget {
  const _AbsensiHarianTile({required this.item});

  final AbsensiHarianItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: StatusBadge(
          label: StatusBadge.labelOf(item.status),
          color: StatusBadge.forStatus(item.status),
        ),
        title: Text(Formatters.tanggalPanjang(item.tanggal)),
        subtitle: Text(
          [
            if (item.kelasNama != null) item.kelasNama!,
            if (item.catatan != null && item.catatan!.isNotEmpty)
              'Catatan: ${item.catatan}',
          ].join('\n'),
        ),
        isThreeLine: item.catatan != null && item.catatan!.isNotEmpty,
      ),
    );
  }
}

class _AbsensiPerjamTile extends StatelessWidget {
  const _AbsensiPerjamTile({required this.item});

  final AbsensiPerjamItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: StatusBadge(
          label: StatusBadge.labelOf(item.status),
          color: StatusBadge.forStatus(item.status),
        ),
        title: Text(item.mapelNama ?? 'Pertemuan'),
        subtitle: Text(
          [
            if (item.tanggal != null) Formatters.tanggalPendek(item.tanggal),
            'Jam ke-${item.jamKe ?? '-'}${item.waktuMulai != null ? ' (${item.waktuMulai}–${item.waktuSelesai ?? ''})' : ''}',
            if (item.guruNama != null) 'Guru: ${item.guruNama}',
            if (item.kelasNama != null) 'Kelas: ${item.kelasNama}',
            if (item.keterangan != null && item.keterangan!.isNotEmpty)
              'Keterangan: ${item.keterangan}',
          ].join('\n'),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
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
    );
  }
}
