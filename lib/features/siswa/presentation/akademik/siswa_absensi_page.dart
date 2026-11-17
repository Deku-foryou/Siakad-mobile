import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/absensi_notifiers.dart';
import '../../data/models/absensi.dart';

/// Absensi siswa (read-only): Harian · Periode · Per Jam.
class SiswaAbsensiPage extends StatelessWidget {
  const SiswaAbsensiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Absensi Saya'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Harian'),
              Tab(text: 'Periode'),
              Tab(text: 'Per Jam'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              _AbsensiHarianTab(),
              _AbsensiPeriodeTab(),
              _AbsensiPerjamTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- Widgets kecil

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({required this.value, required this.onChanged});

  final String? value;
  final void Function(String?) onChanged;

  static const _options = <String?>[null, 'hadir', 'sakit', 'izin', 'alpha'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          for (final option in _options)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: FilterChip(
                label: Text(
                  option == null ? 'Semua' : StatusBadge.labelOf(option),
                ),
                selected: value == option,
                onSelected: (_) => onChanged(option),
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleSmall),
            const Divider(height: AppSpacing.md * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(context, 'Hadir', rekap.hadir, const Color(0xFF15803D)),
                _stat(context, 'Sakit', rekap.sakit, const Color(0xFFB45309)),
                _stat(context, 'Izin', rekap.izin, const Color(0xFFB45309)),
                _stat(context, 'Alpha', rekap.alpha, const Color(0xFFB91C1C)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Total ${rekap.total} pertemuan · Kehadiran ${Formatters.persenHadir(rekap.persenHadir)}',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, int value, Color color) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('$value', style: textTheme.titleLarge?.copyWith(color: color)),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}

class _AbsensiTile extends StatelessWidget {
  const _AbsensiTile({
    required this.tanggal,
    required this.status,
    required this.detail,
    this.keterangan,
  });

  final String? tanggal;
  final String status;
  final String detail;
  final String? keterangan;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: StatusBadge.forStatus(status)
              ?.withValues(alpha: 0.15),
          child: Text(
            tanggal != null && tanggal!.length >= 10
                ? tanggal!.substring(8, 10)
                : '?',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(detail),
        subtitle: Text(
          [
            Formatters.tanggalPendek(tanggal),
            if (keterangan != null && keterangan!.isNotEmpty)
              'Catatan: $keterangan',
          ].join(' · '),
        ),
        trailing: StatusBadge(
          label: StatusBadge.labelOf(status),
          color: StatusBadge.forStatus(status),
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: scheme.error),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Gagal memuat data.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
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

/// Kerangka list: loading/error/empty/refresh/load-more.
class _ListScaffold<Item> extends StatelessWidget {
  const _ListScaffold({
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
    this.header,
    this.emptyHint = 'Data absensi belum tersedia.',
  });

  final AbsensiListState<Item> state;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final List<Widget> Function(List<Item> items) itemBuilder;
  final Widget? header;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    if (state.refreshing && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return _ErrorBlock(message: state.error!, onRetry: onRefresh);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ?header,
          if (state.items.isEmpty)
            SizedBox(
              height: 240,
              child: AppEmptyView(
                icon: Icons.fact_check_outlined,
                title: 'Belum Ada Data',
                message: emptyHint,
              ),
            )
          else ...[
            ...itemBuilder(state.items),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (state.hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(
                  child: OutlinedButton(
                    onPressed: state.busy ? null : onLoadMore,
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

// ---------------------------------------------------------------- Harian
class _AbsensiHarianTab extends ConsumerWidget {
  const _AbsensiHarianTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(absensiHarianProvider);
    final notifier = ref.read(absensiHarianProvider.notifier);

    return Column(
      children: [
        _StatusFilterChips(
          value: state.status,
          onChanged: (v) => notifier.applyFilter(status: v),
        ),
        Expanded(
          child: _ListScaffold<AbsensiHarianItem>(
            state: state,
            onRefresh: notifier.refresh,
            onLoadMore: notifier.loadMore,
            header: state.rekapTotal != null
                ? _RekapCard(
                    title: 'Rekap Semester Ini',
                    rekap: state.rekapTotal!,
                  )
                : null,
            itemBuilder: (items) => items
                .map(
                  (item) => _AbsensiTile(
                    tanggal: item.tanggal,
                    status: item.status,
                    detail: 'Kelas ${item.kelasNama ?? '-'}',
                    keterangan: item.catatan,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Periode
class _AbsensiPeriodeTab extends ConsumerStatefulWidget {
  const _AbsensiPeriodeTab();

  @override
  ConsumerState<_AbsensiPeriodeTab> createState() => _AbsensiPeriodeTabState();
}

class _AbsensiPeriodeTabState extends ConsumerState<_AbsensiPeriodeTab> {
  DateTime? _dari;
  DateTime? _sampai;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(absensiPeriodeProvider);
    final notifier = ref.read(absensiPeriodeProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(isDari: true),
                      icon: const Icon(Icons.event_rounded, size: 18),
                      label: Text(
                        _dari == null
                            ? 'Dari…'
                            : Formatters.tanggalPendek(_iso(_dari!)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(isDari: false),
                      icon: const Icon(Icons.event_rounded, size: 18),
                      label: Text(
                        _sampai == null
                            ? 'Sampai…'
                            : Formatters.tanggalPendek(_iso(_sampai!)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              FilledButton(
                onPressed:
                    _dari != null &&
                        _sampai != null &&
                        _dari!.isBefore(_sampai!.add(const Duration(days: 1)))
                    ? () => notifier.applyFilter(
                        dari: _iso(_dari!),
                        sampai: _iso(_sampai!),
                        status: state.status,
                      )
                    : null,
                child: const Text('Tampilkan Rekap'),
              ),
            ],
          ),
        ),
        _StatusFilterChips(
          value: state.status,
          onChanged: (v) {
            if (_dari != null && _sampai != null) {
              notifier.applyFilter(
                dari: _iso(_dari!),
                sampai: _iso(_sampai!),
                status: v,
              );
            }
          },
        ),
        Expanded(
          child: _ListScaffold<AbsensiHarianItem>(
            state: state,
            onRefresh: notifier.refresh,
            onLoadMore: notifier.loadMore,
            emptyHint: 'Pilih rentang tanggal lalu tekan "Tampilkan Rekap".',
            header: state.rekap != null
                ? _RekapCard(
                    title:
                        'Rekap Periode ${Formatters.tanggalPendek(state.dari)}–${Formatters.tanggalPendek(state.sampai)}',
                    rekap: state.rekap!,
                  )
                : null,
            itemBuilder: (items) => items
                .map(
                  (item) => _AbsensiTile(
                    tanggal: item.tanggal,
                    status: item.status,
                    detail: 'Kelas ${item.kelasNama ?? '-'}',
                    keterangan: item.catatan,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _pick({required bool isDari}) async {
    final now = DateTime.now();
    final initial = isDari ? (_dari ?? now) : (_sampai ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => isDari ? _dari = picked : _sampai = picked);
    }
  }

  String _iso(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------- Per jam
class _AbsensiPerjamTab extends ConsumerWidget {
  const _AbsensiPerjamTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(absensiPerjamProvider);
    final notifier = ref.read(absensiPerjamProvider.notifier);

    return Column(
      children: [
        _StatusFilterChips(
          value: state.status,
          onChanged: (v) => notifier.applyFilter(status: v),
        ),
        Expanded(
          child: _ListScaffold<AbsensiPerjamItem>(
            state: state,
            onRefresh: notifier.refresh,
            onLoadMore: notifier.loadMore,
            header: state.rekapTotal != null
                ? _RekapCard(
                    title: 'Total Per Jam (Seluruh Riwayat)',
                    rekap: state.rekapTotal!,
                  )
                : null,
            itemBuilder: (items) => items
                .map(
                  (item) => _AbsensiTile(
                    tanggal: item.tanggal,
                    status: item.status,
                    detail: item.mapelNama ?? 'Mata Pelajaran',
                    keterangan: [
                      if (item.jamKe != null) 'Jam ${item.jamKe}',
                      if (item.waktuMulai != null)
                        '${item.waktuMulai}–${item.waktuSelesai ?? ''}',
                      if (item.guruNama != null) item.guruNama!,
                      if (item.keterangan != null &&
                          item.keterangan!.isNotEmpty)
                        'Ktr: ${item.keterangan}',
                    ].join(' · '),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
