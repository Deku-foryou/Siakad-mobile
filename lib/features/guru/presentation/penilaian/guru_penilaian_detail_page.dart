import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/guru_providers.dart';

/// Detail penugasan penilaian — komponen, bobot, status, dan rekap siswa.
class GuruPenilaianDetailPage extends ConsumerWidget {
  const GuruPenilaianDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(guruPenugasanDetailProvider(id));
    final siswaAsync = ref.watch(guruPenugasanSiswaProvider(id));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Penugasan')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () => ref.invalidate(guruPenugasanDetailProvider(id)),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (d) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(guruPenugasanDetailProvider(id));
                ref.invalidate(guruPenugasanSiswaProvider(id));
                await Future.wait([
                  ref.read(guruPenugasanDetailProvider(id).future),
                  ref.read(guruPenugasanSiswaProvider(id).future),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // ---------------------------------- Info penugasan
                  Text(d.mapel.nama, style: textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Kelas ${d.kelas.nama} · ${d.semester.nama}'
                    '${d.semester.tahunAjaran != null ? ' · TA ${d.semester.tahunAjaran}' : ''}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      if (d.terkunci)
                        const StatusBadge(
                          label: 'TERKUNCI',
                          color: AppColors.warning,
                        ),
                      if (!d.konfigurasiValid)
                        StatusBadge(
                          label: 'Konfigurasi bobot tidak valid',
                          color: scheme.error,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ---------------------------------- Komponen & bobot
                  const SectionHeader(title: 'Komponen Penilaian'),
                  InfoCard(
                    child: Column(
                      children: [
                        for (final k in d.komponen)
                          InfoRow(
                            label: k.nama,
                            value: '${k.bobot.toStringAsFixed(2)}%',
                          ),
                        const Divider(height: AppSpacing.md),
                        InfoRow(
                          label: 'Total Bobot Aktif',
                          value: '${d.totalBobotAktif.toStringAsFixed(2)}%',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ---------------------------------- Rekap siswa
                  SectionHeader(
                    title: 'Siswa (${d.jumlahSiswa})',
                    subtitle:
                        '${siswaAsync.value?.siswa.where((s) => s.lengkap).length ?? 0} lengkap',
                  ),
                  siswaAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => AsyncValueView<void>(
                      value: AsyncValue.error(error, StackTrace.current),
                      onRetry: () =>
                          ref.invalidate(guruPenugasanSiswaProvider(id)),
                      data: (_) => const SizedBox.shrink(),
                    ),
                    data: (siswaData) => Column(
                      children: [
                        for (final s in siswaData.siswa)
                          Card(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(s.nama),
                              subtitle: Text(
                                'Terisi ${s.jumlahTerisi}/${s.jumlahKomponen} · '
                                'Draft ${s.nilaiDraft?.toStringAsFixed(2) ?? '-'}',
                              ),
                              trailing: s.lengkap
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: scheme.primary,
                                    )
                                  : Icon(
                                      Icons.pending_outlined,
                                      color: scheme.outline,
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ---------------------------------- Aksi
                  if (d.terkunci)
                    const InfoCard(
                      child: Text(
                        'Nilai sudah terkunci (rapor difinalisasi). '
                        'Anda tidak dapat mengubah nilai.',
                      ),
                    )
                  else if (!d.konfigurasiValid)
                    InfoCard(
                      child: Text(
                        'Konfigurasi bobot komponen belum valid '
                        '(total harus 100%). Hubungi admin/superadmin untuk '
                        'memperbaiki konfigurasi.',
                        style: TextStyle(color: scheme.error),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () =>
                          context.push('/guru/penilaian/${d.id}/nilai'),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Input / Ubah Nilai'),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
