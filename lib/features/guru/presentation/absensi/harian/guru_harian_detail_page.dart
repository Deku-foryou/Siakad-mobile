import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../application/guru_providers.dart';

/// Detail record absensi harian — `GET /guru/absensi/harian/{id}`.
class GuruAbsensiHarianDetailPage extends ConsumerWidget {
  const GuruAbsensiHarianDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(guruAbsensiHarianDetailProvider(id));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Absensi')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () => ref.invalidate(guruAbsensiHarianDetailProvider(id)),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(Formatters.initials(item.siswa.nama)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(item.siswa.nama, style: textTheme.titleMedium),
                  ),
                  StatusBadge(
                    label: StatusBadge.labelOf(item.status),
                    color: StatusBadge.forStatus(item.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              InfoCard(
                child: Column(
                  children: [
                    InfoRow(label: 'Tanggal', value: item.tanggal ?? '-'),
                    InfoRow(label: 'Kelas', value: item.kelas.nama),
                    InfoRow(
                      label: 'Status',
                      value: StatusBadge.labelOf(item.status),
                    ),
                    if (item.catatan != null && item.catatan!.isNotEmpty)
                      InfoRow(label: 'Catatan', value: item.catatan!),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () =>
                    context.push('/guru/absensi/harian/${item.id}/edit'),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Ubah Absensi'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Catatan: perubahan absensi hanya dapat dilakukan hari ini '
                'atau kemarin (H+1), sesuai kebijakan sekolah.',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
