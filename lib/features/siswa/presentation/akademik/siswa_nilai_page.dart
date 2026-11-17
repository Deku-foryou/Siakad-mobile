import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/siswa_providers.dart';
import '../../data/models/nilai.dart';

/// Nilai akhir siswa — hanya snapshot rapor final (`/siswa/nilai`).
/// Filter semester/kelas opsional (didukung backend: semester_id, kelas_id).
class SiswaNilaiPage extends ConsumerStatefulWidget {
  const SiswaNilaiPage({super.key});

  @override
  ConsumerState<SiswaNilaiPage> createState() => _SiswaNilaiPageState();
}

class _SiswaNilaiPageState extends ConsumerState<SiswaNilaiPage> {
  int? _semesterId;
  int? _kelasId;

  @override
  Widget build(BuildContext context) {
    final nilai = ref.watch(nilaiProvider((_semesterId, _kelasId)));
    final rapor = ref.watch(raporProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nilai Akhir')),
      body: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------- Filter (opsional)
            SizedBox(
              height: 52,
              child: rapor.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (entries) => _FilterChips(
                  entries: entries,
                  semesterId: _semesterId,
                  kelasId: _kelasId,
                  onChanged: (semesterId, kelasId) => setState(() {
                    _semesterId = semesterId;
                    _kelasId = kelasId;
                  }),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(nilaiProvider((_semesterId, _kelasId)));
                  await ref.read(nilaiProvider((_semesterId, _kelasId)).future);
                },
                child: nilai.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ListView(
                    children: [
                      AsyncValueView<void>(
                        value: AsyncValue.error(error, StackTrace.current),
                        onRetry: () => ref.invalidate(
                          nilaiProvider((_semesterId, _kelasId)),
                        ),
                        data: (_) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  data: (groups) => groups.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 96),
                            AppEmptyView(
                              icon: Icons.grade_rounded,
                              title: 'Belum Ada Nilai',
                              message: 'Nilai akhir hanya tersedia untuk rapor yang sudah difinalisasi.',
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: groups
                              .map((g) => _NilaiKelompokCard(group: g))
                              .toList(),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.entries,
    required this.semesterId,
    required this.kelasId,
    required this.onChanged,
  });

  final List<RaporEntry> entries;
  final int? semesterId;
  final int? kelasId;
  final void Function(int? semesterId, int? kelasId) onChanged;

  @override
  Widget build(BuildContext context) {
    final semesters = <int, String>{
      for (final e in entries) e.semester.id: e.semester.nama,
    };
    final kelas = <int, String>{
      for (final e in entries) e.kelas.id: e.kelas.nama,
    };

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: ChoiceChip(
            label: const Text('Semua semester'),
            selected: semesterId == null,
            onSelected: (_) => onChanged(null, kelasId),
          ),
        ),
        for (final s in semesters.entries)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text('Semester ${s.value}'),
              selected: semesterId == s.key,
              onSelected: (_) => onChanged(s.key, kelasId),
            ),
          ),
        for (final k in kelas.entries)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: FilterChip(
              label: Text(k.value),
              selected: kelasId == k.key,
              onSelected: (selected) =>
                  onChanged(semesterId, selected ? k.key : null),
            ),
          ),
      ],
    );
  }
}

class _NilaiKelompokCard extends StatelessWidget {
  const _NilaiKelompokCard({required this.group});

  final NilaiKelompok group;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final semester = group.semester;
    final ta = semester.tahunAjaranNama;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            'Kelas ${group.kelas.nama} · Semester ${semester.nama}',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              if (ta != null) 'TA $ta',
              '${group.nilai.length} mata pelajaran',
            ].join(' · '),
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          children: [
            for (final nilai in group.nilai)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nilai.mapelNama,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (nilai.mapelKode != null)
                            Text(
                              nilai.mapelKode!,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      nilai.nilaiAkhir.toStringAsFixed(2),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            nilai.nilaiKktp != null &&
                                nilai.nilaiAkhir < nilai.nilaiKktp!
                            ? scheme.error
                            : scheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      width: 96,
                      child: Text(
                        nilai.keterangan ?? '-',
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
