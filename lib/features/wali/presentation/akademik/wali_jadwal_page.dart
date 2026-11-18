import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../widgets/child_switcher.dart';
import '../../application/wali_providers.dart';
import '../../../siswa/data/models/beranda.dart';

/// Jadwal anak terpilih — `GET /wali/anak/{siswaId}/jadwal`.
/// Filter hari (1..7) atau tanggal (tanggal menang di backend).
class WaliJadwalPage extends ConsumerWidget {
  const WaliJadwalPage({super.key, required this.siswaId});

  final int siswaId;

  static const _hariFilters = <int?>[null, 1, 2, 3, 4, 5, 6, 7];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_jadwalFilterProvider(siswaId));
    final jadwal = ref.watch(
      anakJadwalProvider((siswaId, filter.tanggal, filter.hari)),
    );
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: AnakAppBarTitle('Jadwal Anak', siswaId: siswaId)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(
            anakJadwalProvider((siswaId, filter.tanggal, filter.hari)),
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // ------------------------------ Filter
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final hari in _hariFilters)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: FilterChip(
                          label: Text(
                            hari == null ? 'Semua' : Formatters.namaHari(hari),
                          ),
                          selected:
                              filter.tanggal == null && filter.hari == hari,
                          onSelected: (_) => ref
                              .read(_jadwalFilterProvider(siswaId).notifier)
                              .setHari(hari),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ActionChip(
                        avatar: const Icon(Icons.event_rounded, size: 18),
                        label: Text(filter.tanggal ?? 'Pilih Tanggal'),
                        onPressed: () => _pickTanggal(context, ref),
                      ),
                    ),
                    if (filter.tanggal != null)
                      ActionChip(
                        avatar: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Hapus Tanggal'),
                        onPressed: () => ref
                            .read(_jadwalFilterProvider(siswaId).notifier)
                            .clearTanggal(),
                      ),
                  ],
                ),
              ),
              if (filter.tanggal != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Tanggal ${Formatters.tanggalPanjang(filter.tanggal)} dipilih — '
                    'filter tanggal menang atas filter hari.',
                    style: textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),

              // ------------------------------ Daftar
              AsyncValueView<JadwalResponse>(
                value: jadwal,
                onRetry: () => ref.invalidate(
                  anakJadwalProvider((siswaId, filter.tanggal, filter.hari)),
                ),
                isEmpty: (d) => d.jadwal.isEmpty,
                empty: const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, size: 48),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Tidak ada jadwal pada filter ini.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                data: (data) => Column(
                  children: [
                    ..._konteksInfo(context, data),
                    if (data.jadwal.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text('Tidak ada jadwal pada filter ini.'),
                      )
                    else
                      ...() {
                        // Kelompokkan per hari agar mudah dibaca.
                        final grouped = <int, List<JadwalItem>>{};
                        for (final item in data.jadwal) {
                          grouped.putIfAbsent(item.hari, () => []).add(item);
                        }
                        final keys = grouped.keys.toList()..sort();
                        return keys.expand(
                          (hari) => [
                            SectionHeader(title: Formatters.namaHari(hari)),
                            ...grouped[hari]!.map(
                              (item) => _JadwalTile(item: item),
                            ),
                          ],
                        );
                      }(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _konteksInfo(BuildContext context, JadwalResponse data) {
    final scheme = Theme.of(context).colorScheme;
    return [
      if (!data.konteks.valid)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: InfoCard(
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: scheme.tertiary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    data.konteks.peringatan.isNotEmpty
                        ? data.konteks.peringatan.join('\n')
                        : 'Konteks akademik tidak valid.',
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Future<void> _pickTanggal(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    ref.read(_jadwalFilterProvider(siswaId).notifier).setTanggal(iso);
  }
}

class _JadwalFilterState {
  const _JadwalFilterState({this.hari, this.tanggal});

  final int? hari;
  final String? tanggal;
}

class _JadwalFilter extends Notifier<_JadwalFilterState> {
  _JadwalFilter(this._siswaId);

  // ignore: unused_field
  final int _siswaId;

  @override
  _JadwalFilterState build() => const _JadwalFilterState();

  void setHari(int? hari) => state = _JadwalFilterState(hari: hari);

  void setTanggal(String tanggal) =>
      state = _JadwalFilterState(tanggal: tanggal);

  void clearTanggal() => state = _JadwalFilterState(hari: state.hari);
}

final _jadwalFilterProvider = NotifierProvider.autoDispose
    .family<_JadwalFilter, _JadwalFilterState, int>(_JadwalFilter.new);

class _JadwalTile extends StatelessWidget {
  const _JadwalTile({required this.item});

  final JadwalItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.jamKe != null ? 'Ke-${item.jamKe}' : '—',
              style: textTheme.labelLarge,
            ),
            if (item.mulai != null)
              Text(
                item.mulai!,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        title: Text(item.mapelNama),
        subtitle: Text(
          [
            if (item.mulai != null && item.selesai != null)
              '${item.mulai}–${item.selesai}',
            if (item.guruNama != null) 'Guru: ${item.guruNama}',
          ].join('\n'),
        ),
        isThreeLine: true,
      ),
    );
  }
}
