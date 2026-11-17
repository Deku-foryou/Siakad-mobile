import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_empty_view.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../../application/guru_providers.dart';
import '../../../data/models/absensi.dart';

/// Tab Per Jam: Pertemuan (input absensi) + Riwayat (G16).
class GuruAbsensiPerjamTab extends ConsumerStatefulWidget {
  const GuruAbsensiPerjamTab({super.key});

  @override
  ConsumerState<GuruAbsensiPerjamTab> createState() =>
      _GuruAbsensiPerjamTabState();
}

class _GuruAbsensiPerjamTabState extends ConsumerState<GuruAbsensiPerjamTab> {
  int _segment = 0; // 0 = Pertemuan, 1 = Riwayat

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Segmentasi Pertemuan / Riwayat
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Pertemuan')),
              ButtonSegment(value: 1, label: Text('Riwayat')),
            ],
            selected: {_segment},
            onSelectionChanged: (s) => setState(() => _segment = s.first),
          ),
        ),
        Expanded(child: _segment == 0 ? _PertemuanView() : _RiwayatView()),
      ],
    );
  }
}

/// Pertemuan pada tanggal (default: hari ini).
///
/// CATATAN: backend men-generate snapshot pertemuan yang belum ada
/// (idempoten) saat endpoint ini dipanggil. Panggilan hanya dilakukan
/// pada tab ini — bukan di dashboard.
class _PertemuanView extends ConsumerStatefulWidget {
  const _PertemuanView();

  @override
  ConsumerState<_PertemuanView> createState() => _PertemuanViewState();
}

class _PertemuanViewState extends ConsumerState<_PertemuanView> {
  String? _tanggal; // null = hari ini (server default)

  @override
  Widget build(BuildContext context) {
    final pertemuan = ref.watch(guruPertemuanProvider(_tanggal));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickTanggal,
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(
                  _tanggal == null
                      ? 'Hari Ini'
                      : Formatters.tanggalPendek(_tanggal),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (_tanggal != null)
                TextButton(
                  onPressed: () => setState(() => _tanggal = null),
                  child: const Text('Hari Ini'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(guruPertemuanProvider(_tanggal));
              await ref.read(guruPertemuanProvider(_tanggal).future);
            },
            child: pertemuan.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AsyncValueView<void>(
                value: AsyncValue.error(error, StackTrace.current),
                onRetry: () => ref.invalidate(guruPertemuanProvider(_tanggal)),
                data: (_) => const SizedBox.shrink(),
              ),
              data: (data) => data.pertemuan.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 64),
                        AppEmptyView(
                          icon: Icons.event_available_rounded,
                          title: 'Tidak Ada Pertemuan',
                          message:
                              'Tidak ada jadwal pertemuan pada tanggal ini.',
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        if (data.tanggal.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: Text(
                              'Tanggal ${Formatters.tanggalPendek(data.tanggal)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                        for (final p in data.pertemuan) _PertemuanTile(item: p),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickTanggal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal != null ? DateTime.parse(_tanggal!) : now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _tanggal =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }
}

class _PertemuanTile extends StatelessWidget {
  const _PertemuanTile({required this.item});

  final PertemuanItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canAbsen = item.bisaDiabsen;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canAbsen
            ? () => context.push('/guru/absensi/perjam/grid/${item.id}')
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.secondaryContainer,
                child: Text(item.jamKe != null ? '${item.jamKe}' : '—'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.mapel.nama} — Kelas ${item.kelas.nama}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      [
                        if (item.waktuMulai != null)
                          '${item.waktuMulai}–${item.waktuSelesai ?? ''}',
                        'Status: ${item.status}',
                        '${item.jumlahAbsensi}/${item.jumlahSiswa} absen',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(
                canAbsen
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
                color: canAbsen ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Riwayat absensi per jam (paginated, filter status).
class _RiwayatView extends ConsumerWidget {
  const _RiwayatView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(guruAbsensiPerjamProvider);
    final notifier = ref.read(guruAbsensiPerjamProvider.notifier);

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              _chip(notifier, null, 'Semua'),
              _chip(notifier, 'hadir', 'Hadir'),
              _chip(notifier, 'sakit', 'Sakit'),
              _chip(notifier, 'izin', 'Izin'),
              _chip(notifier, 'alpha', 'Alpha'),
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
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      if (state.items.isEmpty)
                        const SizedBox(
                          height: 240,
                          child: AppEmptyView(
                            icon: Icons.fact_check_outlined,
                            title: 'Belum Ada Riwayat',
                            message:
                                'Riwayat absensi per jam akan tampil di sini.',
                          ),
                        )
                      else
                        for (final item in state.items)
                          Card(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: ListTile(
                              onTap: () => context.push(
                                '/guru/absensi/perjam/${item.id}',
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
                                  if (item.mapelNama != null) item.mapelNama!,
                                  if (item.kelasNama != null)
                                    'Kelas ${item.kelasNama}',
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

  Widget _chip(
    GuruAbsensiPerjamNotifier notifier,
    String? value,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: notifier.status == value,
        onSelected: (_) => notifier.applyFilter(status: value),
      ),
    );
  }
}
