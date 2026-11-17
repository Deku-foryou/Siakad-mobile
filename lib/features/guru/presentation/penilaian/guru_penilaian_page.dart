import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/guru_providers.dart';
import '../../data/models/guru.dart';

/// Tab Penilaian: daftar penugasan mengajar semester aktif.
class GuruPenilaianPage extends ConsumerStatefulWidget {
  const GuruPenilaianPage({super.key});

  @override
  ConsumerState<GuruPenilaianPage> createState() => _GuruPenilaianPageState();
}

class _GuruPenilaianPageState extends ConsumerState<GuruPenilaianPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final penugasanAsync = ref.watch(guruPenugasanListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Penugasan Mengajar')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(guruPenugasanListProvider);
            await ref.read(guruPenugasanListProvider.future);
          },
          child: penugasanAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                AsyncValueView<void>(
                  value: AsyncValue.error(error, StackTrace.current),
                  onRetry: () => ref.invalidate(guruPenugasanListProvider),
                  data: (_) => const SizedBox.shrink(),
                ),
              ],
            ),
            data: (list) {
              final filtered = _query.isEmpty
                  ? list
                  : list.where((p) {
                      final q = _query.toLowerCase();
                      return p.mapel.nama.toLowerCase().contains(q) ||
                          p.kelas.nama.toLowerCase().contains(q);
                    }).toList();

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Cari mata pelajaran atau kelas…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (filtered.isEmpty)
                    SizedBox(
                      height: 280,
                      child: AppEmptyView(
                        icon: Icons.assignment_outlined,
                        title: 'Tidak Ada Penugasan',
                        message: list.isEmpty
                            ? 'Belum ada penugasan mengajar pada semester aktif.'
                            : 'Tidak ada penugasan cocok dengan pencarian "$_query".',
                      ),
                    )
                  else
                    for (final p in filtered) _PenugasanCard(penugasan: p),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PenugasanCard extends StatelessWidget {
  const _PenugasanCard({required this.penugasan});

  final Penugasan penugasan;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/guru/penilaian/${penugasan.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  penugasan.mapel.nama.isEmpty ? '?' : penugasan.mapel.nama[0],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      penugasan.mapel.nama,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Kelas ${penugasan.kelas.nama} · ${penugasan.semester.nama}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (penugasan.semester.tahunAjaran != null)
                      Text(
                        'TA ${penugasan.semester.tahunAjaran}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
