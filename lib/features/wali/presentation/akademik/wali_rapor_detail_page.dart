import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../widgets/child_switcher.dart';
import '../../application/wali_providers.dart';

/// Detail rapor final anak — `GET /wali/anak/{siswaId}/rapor/{semesterId}/{kelasId}`.
/// Nilai dari snapshot finalisasi backend; TIDAK dihitung ulang di client.
class WaliRaporDetailPage extends ConsumerWidget {
  const WaliRaporDetailPage({
    super.key,
    required this.siswaId,
    required this.semesterId,
    required this.kelasId,
  });

  final int siswaId;
  final int semesterId;
  final int kelasId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(
      anakRaporDetailProvider((siswaId, semesterId, kelasId)),
    );
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: AnakAppBarTitle('Detail Rapor', siswaId: siswaId)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(
            anakRaporDetailProvider((siswaId, semesterId, kelasId)),
          ),
          child: detail.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncValueView<void>(
              value: AsyncValue.error(error, StackTrace.current),
              onRetry: () => ref.invalidate(
                anakRaporDetailProvider((siswaId, semesterId, kelasId)),
              ),
              data: (_) => const SizedBox.shrink(),
            ),
            data: (data) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (data.namaSekolah != null)
                  Text(
                    data.namaSekolah!,
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                Text(
                  '${data.semester.nama} · ${data.kelas.nama}',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (data.semester.tahunAjaranNama != null)
                  Text(
                    'Tahun Ajaran ${data.semester.tahunAjaranNama}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: AppSpacing.md),

                // ------------------------------ Nilai
                const SectionHeader(title: 'Nilai Akhir'),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < data.nilai.length; i++) ...[
                        ListTile(
                          dense: true,
                          title: Text(data.nilai[i].mapelNama),
                          subtitle: data.nilai[i].keterangan != null
                              ? Text(data.nilai[i].keterangan!)
                              : null,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                data.nilai[i].nilaiAkhir.toStringAsFixed(
                                  data.nilai[i].nilaiAkhir.truncateToDouble() ==
                                          data.nilai[i].nilaiAkhir
                                      ? 0
                                      : 1,
                                ),
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color:
                                      data.nilai[i].nilaiKktp == null ||
                                          data.nilai[i].nilaiAkhir >=
                                              data.nilai[i].nilaiKktp!
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                              if (data.nilai[i].nilaiKktp != null)
                                Text(
                                  'KKTP ${data.nilai[i].nilaiKktp!.toStringAsFixed(0)}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (i != data.nilai.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ------------------------------ Rekap kehadiran
                const SectionHeader(title: 'Rekap Kehadiran'),
                InfoCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final pair in [
                        ('Hadir', data.rekapKehadiran.hadir),
                        ('Sakit', data.rekapKehadiran.sakit),
                        ('Izin', data.rekapKehadiran.izin),
                        ('Alpha', data.rekapKehadiran.alpha),
                      ])
                        Column(
                          children: [
                            Text(
                              '${pair.$2}',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(pair.$1, style: textTheme.labelSmall),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ------------------------------ Catatan
                if (data.catatan != null && data.catatan!.isNotEmpty) ...[
                  const SectionHeader(title: 'Catatan Wali Kelas'),
                  InfoCard(child: Text(data.catatan!)),
                  const SizedBox(height: AppSpacing.lg),
                ] else
                  const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
