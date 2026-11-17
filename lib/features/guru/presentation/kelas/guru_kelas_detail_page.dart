import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/guru_providers.dart';

/// Detail kelas — `GET /guru/kelas/{id}`.
class GuruKelasDetailPage extends ConsumerWidget {
  const GuruKelasDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(guruKelasDetailProvider(id));
    final penugasan = ref.watch(guruPenugasanListProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kelas')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () => ref.invalidate(guruKelasDetailProvider(id)),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (kelas) {
            final penugasanKelas =
                penugasan.value?.where((p) => p.kelas.id == id).toList() ??
                const [];
            final bisaAbsen = kelas.diajar;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // ---------------------------------- Identitas kelas
                Text(kelas.nama, style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    if (kelas.tingkat != null)
                      Chip(label: Text('Tingkat ${kelas.tingkat}')),
                    if (kelas.diajar) const StatusBadge(label: 'Mengajar'),
                    if (kelas.diwali) const StatusBadge(label: 'Wali Kelas'),
                    if (kelas.jenis != null) Chip(label: Text(kelas.jenis!)),
                    if (kelas.rombel != null) Chip(label: Text(kelas.rombel!)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                InfoCard(
                  child: Column(
                    children: [
                      InfoRow(
                        label: 'Jumlah Siswa',
                        value: '${kelas.jumlahSiswa ?? '-'} siswa',
                      ),
                      if (kelas.taNama != null)
                        InfoRow(label: 'Tahun Ajaran', value: kelas.taNama!),
                      if (kelas.jurusanNama != null)
                        InfoRow(label: 'Jurusan', value: kelas.jurusanNama!),
                      if (kelas.waliNama != null)
                        InfoRow(label: 'Wali Kelas', value: kelas.waliNama!),
                      if (kelas.mapel.isNotEmpty)
                        InfoRow(
                          label: 'Mata Pelajaran',
                          value: kelas.mapel.map((m) => m.nama).join(', '),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ---------------------------------- Penugasan di kelas ini
                const SectionHeader(title: 'Penugasan Mengajar Anda'),
                if (penugasanKelas.isEmpty)
                  const InfoCard(
                    child: Text(
                      'Tidak ada penugasan mengajar di kelas ini (untuk Anda).',
                    ),
                  )
                else
                  ...penugasanKelas.map(
                    (p) => Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: ListTile(
                        leading: const Icon(Icons.assignment_rounded),
                        title: Text(p.mapel.nama),
                        subtitle: Text(
                          '${p.semester.nama} · TA ${p.semester.tahunAjaran ?? '-'}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/guru/penilaian/${p.id}'),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // ---------------------------------- Aksi
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/guru/kelas/${kelas.id}/siswa'),
                  icon: const Icon(Icons.groups_rounded),
                  label: const Text('Lihat Daftar Siswa'),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (bisaAbsen)
                  FilledButton.icon(
                    onPressed: () =>
                        context.push('/guru/absensi/harian/grid/${kelas.id}'),
                    icon: const Icon(Icons.fact_check_rounded),
                    label: const Text('Isi Absensi Harian'),
                  )
                else
                  const InfoCard(
                    child: Text(
                      'Anda tercatat sebagai wali kelas, bukan pengajar. '
                      'Pengisian absensi harian hanya untuk guru pengajar.',
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
            );
          },
        ),
      ),
    );
  }
}
