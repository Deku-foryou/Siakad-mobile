import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/siswa_providers.dart';

/// Detail rapor final — snapshot finalisasi backend; tidak diedit di client.
class SiswaRaporDetailPage extends ConsumerWidget {
  const SiswaRaporDetailPage({
    super.key,
    required this.semesterId,
    required this.kelasId,
  });

  final int semesterId;
  final int kelasId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(raporDetailProvider((semesterId, kelasId)));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Rapor')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () =>
                ref.invalidate(raporDetailProvider((semesterId, kelasId))),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (data) {
            final ta = data.semester.tahunAjaranNama;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // --------------------------------------- Identitas rapor
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.namaSekolah ?? 'Rapor',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      InfoRow(
                        label: 'Semester',
                        value:
                            '${data.semester.nama}${ta != null ? ' · TA $ta' : ''}',
                      ),
                      InfoRow(
                        label: 'Kelas',
                        value:
                            '${data.kelas.nama}${data.kelas.tingkat != null ? ' (Tingkat ${data.kelas.tingkat})' : ''}',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      StatusBadge(
                        label: data.isFinal ? 'FINAL' : 'DRAFT',
                        color: data.isFinal
                            ? StatusBadge.forStatus('hadir')
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // --------------------------------------- Rekap kehadiran
                const SectionHeader(title: 'Rekap Kehadiran'),
                InfoCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat(
                        context,
                        'Hadir',
                        data.rekapKehadiran.hadir,
                        const Color(0xFF15803D),
                      ),
                      _stat(
                        context,
                        'Sakit',
                        data.rekapKehadiran.sakit,
                        const Color(0xFFB45309),
                      ),
                      _stat(
                        context,
                        'Izin',
                        data.rekapKehadiran.izin,
                        const Color(0xFFB45309),
                      ),
                      _stat(
                        context,
                        'Alpha',
                        data.rekapKehadiran.alpha,
                        const Color(0xFFB91C1C),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // --------------------------------------- Nilai
                const SectionHeader(title: 'Nilai Mata Pelajaran'),
                if (data.nilai.isEmpty)
                  const InfoCard(child: Text('Belum ada nilai pada rapor ini.'))
                else
                  ...data.nilai.map(
                    (n) => Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.mapelNama,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (n.mapelKode != null)
                                    Text(
                                      n.mapelKode!,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  if (n.nilaiKktp != null)
                                    Text(
                                      'KKTP ${n.nilaiKktp!.toStringAsFixed(0)}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              n.nilaiAkhir.toStringAsFixed(2),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color:
                                    n.nilaiKktp != null &&
                                        n.nilaiAkhir < n.nilaiKktp!
                                    ? scheme.error
                                    : scheme.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            SizedBox(
                              width: 84,
                              child: Text(
                                n.keterangan ?? '-',
                                style: textTheme.bodySmall,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // --------------------------------------- Catatan
                if (data.catatan != null && data.catatan!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const SectionHeader(title: 'Catatan'),
                  InfoCard(child: Text(data.catatan!)),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            );
          },
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
