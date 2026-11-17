import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../../application/guru_providers.dart';

/// Detail record absensi per jam — `GET /guru/absensi/perjam/{id}`.
class GuruPerjamDetailPage extends ConsumerWidget {
  const GuruPerjamDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(guruAbsensiPerjamDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Absensi Per Jam')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () => ref.invalidate(guruAbsensiPerjamDetailProvider(id)),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  CircleAvatar(child: Text(_initials(item.siswa.nama))),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item.siswa.nama)),
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
                    InfoRow(label: 'Mapel', value: item.mapel.nama),
                    InfoRow(label: 'Kelas', value: item.kelas.nama),
                    InfoRow(label: 'Tanggal', value: item.tanggal ?? '-'),
                    if (item.jamKe != null)
                      InfoRow(label: 'Jam ke', value: '${item.jamKe}'),
                    if (item.waktuMulai != null)
                      InfoRow(
                        label: 'Waktu',
                        value: '${item.waktuMulai}–${item.waktuSelesai ?? ''}',
                      ),
                    if (item.pertemuanStatus != null)
                      InfoRow(
                        label: 'Status Pertemuan',
                        value: item.pertemuanStatus!,
                      ),
                    if (item.keterangan != null && item.keterangan!.isNotEmpty)
                      InfoRow(label: 'Keterangan', value: item.keterangan!),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () =>
                    context.push('/guru/absensi/perjam/${item.id}/edit'),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Ubah Absensi'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Catatan: perubahan absensi hanya dapat dilakukan hari ini '
                'atau kemarin (H+1), sesuai kebijakan sekolah.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }
}
