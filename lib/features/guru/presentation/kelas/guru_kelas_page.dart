import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/guru_providers.dart';
import '../../data/models/guru.dart';

/// Daftar kelas guru — `GET /guru/kelas` (mengajar ∪ wali).
class GuruKelasPage extends ConsumerStatefulWidget {
  const GuruKelasPage({super.key});

  @override
  ConsumerState<GuruKelasPage> createState() => _GuruKelasPageState();
}

class _GuruKelasPageState extends ConsumerState<GuruKelasPage> {
  /// 'semua' | 'mengajar' | 'wali'
  String _filter = 'semua';

  @override
  Widget build(BuildContext context) {
    final kelasAsync = ref.watch(guruKelasListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelas Saya')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(guruKelasListProvider);
            await ref.read(guruKelasListProvider.future);
          },
          child: kelasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                AsyncValueView<void>(
                  value: AsyncValue.error(error, StackTrace.current),
                  onRetry: () => ref.invalidate(guruKelasListProvider),
                  data: (_) => const SizedBox.shrink(),
                ),
              ],
            ),
            data: (data) {
              final filtered = data.kelas.where((k) {
                switch (_filter) {
                  case 'mengajar':
                    return k.diajar;
                  case 'wali':
                    return k.diwali;
                  default:
                    return true;
                }
              }).toList();

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (data.konteks.semesterNama != null ||
                      data.konteks.tahunAjaranNama != null) ...[
                    Text(
                      [
                        if (data.konteks.tahunAjaranNama != null)
                          'TA ${data.konteks.tahunAjaranNama}',
                        if (data.konteks.semesterNama != null)
                          'Semester ${data.konteks.semesterNama}',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  SizedBox(
                    height: 46,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final entry in const [
                          ('semua', 'Semua'),
                          ('mengajar', 'Mengajar'),
                          ('wali', 'Wali Kelas'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: ChoiceChip(
                              label: Text(entry.$2),
                              selected: _filter == entry.$1,
                              onSelected: (_) =>
                                  setState(() => _filter = entry.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (filtered.isEmpty)
                    const SizedBox(
                      height: 280,
                      child: AppEmptyView(
                        icon: Icons.class_outlined,
                        title: 'Tidak Ada Kelas',
                        message: 'Tidak ada kelas pada filter ini.',
                      ),
                    )
                  else
                    ...filtered.map((k) => _KelasCard(kelas: k)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _KelasCard extends StatelessWidget {
  const _KelasCard({required this.kelas});

  final KelasRingkas kelas;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/guru/kelas/${kelas.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  kelas.nama.isEmpty ? '?' : kelas.nama[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kelas.nama,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      [
                        if (kelas.tingkat != null) 'Tingkat ${kelas.tingkat}',
                        if (kelas.jumlahSiswa != null)
                          '${kelas.jumlahSiswa} siswa',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (kelas.mapel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: kelas.mapel
                              .map(
                                (m) => Chip(
                                  label: Text(m.nama),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (kelas.diajar) const StatusBadge(label: 'Mengajar'),
                  if (kelas.diwali) ...[
                    const SizedBox(height: 4),
                    const StatusBadge(label: 'Wali'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
