import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/guru_providers.dart';

/// Detail jadwal mengajar — `GET /guru/jadwal/{id}`.
class GuruJadwalDetailPage extends ConsumerWidget {
  const GuruJadwalDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jadwal = ref.watch(guruJadwalDetailProvider(id));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Jadwal')),
      body: SafeArea(
        child: jadwal.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () => ref.invalidate(guruJadwalDetailProvider(id)),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(item.mapel.nama, style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Kelas ${item.kelas.nama}',
                style: textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InfoCard(
                child: Column(
                  children: [
                    InfoRow(label: 'Hari', value: item.namaHari),
                    if (item.jamKe != null)
                      InfoRow(label: 'Jam ke', value: '${item.jamKe}'),
                    if (item.mulai != null)
                      InfoRow(
                        label: 'Waktu',
                        value: '${item.mulai} – ${item.selesai ?? 'Selesai'}',
                      ),
                    InfoRow(label: 'Kelas', value: item.kelas.nama),
                    if (item.kelas.tingkat != null)
                      InfoRow(label: 'Tingkat', value: item.kelas.tingkat!),
                    if (item.semesterNama != null)
                      InfoRow(label: 'Semester', value: item.semesterNama!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
