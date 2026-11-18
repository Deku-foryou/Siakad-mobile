import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/wali_providers.dart';
import '../../../siswa/data/models/nilai.dart';

/// Nilai anak (read-only, snapshot rapor final) — `GET /wali/anak/{siswaId}/nilai`.
/// Filter semester/kelas tersedia bila data dari backend mendukung.
class WaliNilaiPage extends ConsumerWidget {
  const WaliNilaiPage({super.key, required this.siswaId});

  final int siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_nilaiFilterProvider(siswaId));
    final nilai = ref.watch(
      anakNilaiProvider((siswaId, filter?.semester.id, filter?.kelas.id)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Nilai Anak')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(
            anakNilaiProvider((siswaId, filter?.semester.id, filter?.kelas.id)),
          ),
          child: nilai.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) {
              final is404 = error is ApiException && error.statusCode == 404;
              return _ErrorBody(
                message: is404
                    ? 'Nilai untuk filter tersebut tidak tersedia.'
                    : 'Gagal memuat nilai.\n${AsyncValueView.errorMessage(error)}',
                onRetry: () => ref.invalidate(
                  anakNilaiProvider((
                    siswaId,
                    filter?.semester.id,
                    filter?.kelas.id,
                  )),
                ),
              );
            },
            data: (kelompok) => _NilaiBody(
              siswaId: siswaId,
              data: kelompok,
              activeFilter: filter,
            ),
          ),
        ),
      ),
    );
  }
}

class _NilaiBody extends ConsumerWidget {
  const _NilaiBody({
    required this.siswaId,
    required this.data,
    required this.activeFilter,
  });

  final int siswaId;
  final List<NilaiKelompok> data;
  final NilaiFilterOption? activeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    // Opsi filter: dari data tampil bila tanpa filter; bila filter aktif,
    // baca juga daftar penuh (cache provider family terpisah).
    final fullList = activeFilter == null
        ? null
        : ref.watch(anakNilaiProvider((siswaId, null, null))).value;
    final allOptions = _collectOptions(activeFilter == null ? data : fullList);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const InfoCard(
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Nilai yang tampil adalah nilai akhir (snapshot rapor '
                  'final). Nilai draft tidak ditampilkan.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (activeFilter != null || allOptions.isNotEmpty)
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: FilterChip(
                    label: const Text('Semua'),
                    selected: activeFilter == null,
                    onSelected: (_) => ref
                        .read(_nilaiFilterProvider(siswaId).notifier)
                        .set(null),
                  ),
                ),
                for (final option in allOptions)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      label: Text(option.label),
                      selected: activeFilter == option,
                      onSelected: (_) => ref
                          .read(_nilaiFilterProvider(siswaId).notifier)
                          .set(option),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        if (data.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(Icons.grade_outlined, size: 48, color: scheme.outline),
                const SizedBox(height: AppSpacing.sm),
                Text('Belum Ada Nilai Akhir', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Nilai akhir hanya tersedia setelah rapor difinalisasi.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          for (final group in data) ...[
            SectionHeader(
              title: '${group.semester.nama} · ${group.kelas.nama}',
              subtitle: group.semester.tahunAjaranNama != null
                  ? 'TA ${group.semester.tahunAjaranNama}'
                  : null,
            ),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < group.nilai.length; i++) ...[
                    _NilaiTile(item: group.nilai[i]),
                    if (i != group.nilai.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  List<NilaiFilterOption> _collectOptions(List<NilaiKelompok>? source) {
    if (source == null) return const [];
    return [
      for (final group in source)
        NilaiFilterOption(semester: group.semester, kelas: group.kelas),
    ];
  }
}

/// Opsi filter (semester+kelas) — record sederhana dengan equality.
class NilaiFilterOption {
  const NilaiFilterOption({required this.semester, required this.kelas});

  final SemesterInfo semester;
  final KelasRaporInfo kelas;

  String get label => '${semester.nama} · ${kelas.nama}';

  @override
  bool operator ==(Object other) =>
      other is NilaiFilterOption &&
      other.semester.id == semester.id &&
      other.kelas.id == kelas.id;

  @override
  int get hashCode => Object.hash(semester.id, kelas.id);
}

class _NilaiFilter extends Notifier<NilaiFilterOption?> {
  _NilaiFilter(this._siswaId);

  // Scope family: satu instance per anak.
  // ignore: unused_field
  final int _siswaId;

  @override
  NilaiFilterOption? build() => null;

  void set(NilaiFilterOption? value) => state = value;
}

final _nilaiFilterProvider = NotifierProvider.autoDispose
    .family<_NilaiFilter, NilaiFilterOption?, int>(_NilaiFilter.new);

class _NilaiTile extends StatelessWidget {
  const _NilaiTile({required this.item});

  final NilaiAkhirItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tuntas = item.nilaiKktp == null || item.nilaiAkhir >= item.nilaiKktp!;
    return ListTile(
      dense: true,
      title: Text(item.mapelNama),
      subtitle: item.keterangan != null ? Text(item.keterangan!) : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            item.nilaiAkhir.toStringAsFixed(
              item.nilaiAkhir.truncateToDouble() == item.nilaiAkhir ? 0 : 1,
            ),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: tuntas ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
            ),
          ),
          if (item.nilaiKktp != null)
            Text(
              'KKTP ${item.nilaiKktp!.toStringAsFixed(0)}',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

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
            Icon(Icons.cloud_off_rounded, color: scheme.error, size: 48),
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
