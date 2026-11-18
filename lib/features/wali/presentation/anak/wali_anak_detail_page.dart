import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../siswa/data/models/beranda.dart'; // JadwalItem
import '../../application/wali_providers.dart';
import '../../application/wali_tab_index.dart';
import '../../data/models/wali.dart';
import '../widgets/relasi_widgets.dart';

/// Detail relasi 1 anak (read-only): identitas + konteks akademik +
/// jadwal hari ini + histori relasi. Seluruh data selalu milik anak
/// pada `siswaId` (route param) — tidak ada pencampuran konteks.
class WaliAnakDetailPage extends ConsumerWidget {
  const WaliAnakDetailPage({super.key, required this.siswaId});

  final int siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(anakDetailProvider(siswaId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Anak')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(anakDetailProvider(siswaId));
            ref.invalidate(anakBerandaProvider(siswaId));
          },
          child: detail.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncValueView<void>(
              value: AsyncValue.error(error, StackTrace.current),
              onRetry: () => ref.invalidate(anakDetailProvider(siswaId)),
              data: (_) => const SizedBox.shrink(),
            ),
            data: (data) => _DetailBody(data: data, siswaId: siswaId),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.data, required this.siswaId});

  final AnakDetail data;
  final int siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final siswa = data.siswa;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ------------------------------------------------ Identitas
        InfoCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                child: Text(
                  (siswa?.nama ?? '?').trim().isEmpty
                      ? '?'
                      : (siswa?.nama ?? '?').trim()[0].toUpperCase(),
                  style: textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(siswa?.nama ?? '-', style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (siswa?.nis != null) 'NIS ${siswa?.nis}',
                        if (siswa?.nisn != null) 'NISN ${siswa?.nisn}',
                      ].join(' · '),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    RelasiStatus.badge(data.statusHubungan),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Relasi
        const SectionHeader(title: 'Hubungan Anda'),
        InfoCard(
          child: Column(
            children: [
              InfoRow(label: 'Hubungan', value: data.hubungan ?? '-'),
              InfoRow(
                label: 'Status',
                value: RelasiStatus.label(data.statusHubungan),
              ),
              if (data.tanggalMulai != null)
                InfoRow(
                  label: 'Mulai',
                  value: Formatters.tanggalPanjang(data.tanggalMulai),
                ),
              if (data.tanggalVerifikasi != null)
                InfoRow(
                  label: 'Diverifikasi',
                  value: Formatters.dateTimeLokal(data.tanggalVerifikasi),
                ),
              if (data.tanggalBerhenti != null)
                InfoRow(
                  label: 'Berhenti',
                  value: Formatters.tanggalPanjang(data.tanggalBerhenti),
                ),
              if (data.kelas != null)
                InfoRow(label: 'Kelas (TA aktif)', value: data.kelas!),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (!data.bisaAksesAkademik) ...[
          RelasiTerkunciBanner(statusHubungan: data.statusHubungan),
        ] else ...[
          // ------------------------------------------------ Akademik
          const SectionHeader(title: 'Akademik'),
          _AkademikSection(siswaId: siswaId),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _MenuChip(
                icon: Icons.calendar_month_rounded,
                label: 'Jadwal',
                onTap: () => context.push('/wali/anak/$siswaId/jadwal'),
              ),
              _MenuChip(
                icon: Icons.fact_check_outlined,
                label: 'Absensi',
                onTap: () => context.push('/wali/anak/$siswaId/absensi'),
              ),
              _MenuChip(
                icon: Icons.grade_rounded,
                label: 'Nilai',
                onTap: () => context.push('/wali/anak/$siswaId/nilai'),
              ),
              _MenuChip(
                icon: Icons.description_rounded,
                label: 'Rapor',
                onTap: () => context.push('/wali/anak/$siswaId/rapor'),
              ),
              _MenuChip(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Keuangan',
                onTap: () {
                  ref.read(selectedAnakIdProvider.notifier).set(siswaId);
                  ref.read(waliTabIndexProvider.notifier).set(2);
                  // Kembali ke shell agar tab Keuangan terlihat.
                  context.pop();
                },
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Identitas siswa
        const SectionHeader(title: 'Data Siswa'),
        InfoCard(
          child: Column(
            children: [
              if (siswa?.jenisKelamin != null)
                InfoRow(
                  label: 'Jenis Kelamin',
                  value: _jenisKelaminLabel(siswa!.jenisKelamin!),
                ),
              if (siswa?.tahunMasuk != null)
                InfoRow(label: 'Tahun Masuk', value: '${siswa!.tahunMasuk}'),
              if (siswa?.status != null)
                InfoRow(label: 'Status Siswa', value: siswa!.status!),
              if (siswa?.nisn != null)
                InfoRow(label: 'NISN', value: siswa!.nisn!),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Histori
        if (data.histori.isNotEmpty) ...[
          const SectionHeader(title: 'Histori Relasi'),
          InfoCard(
            padding: 8,
            child: Column(
              children: [
                for (var i = 0; i < data.histori.length; i++) ...[
                  _HistoriTile(histori: data.histori[i]),
                  if (i != data.histori.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  String _jenisKelaminLabel(String value) {
    switch (value.toUpperCase()) {
      case 'L':
        return 'Laki-laki';
      case 'P':
        return 'Perempuan';
      default:
        return value;
    }
  }
}

/// Konteks akademik + jadwal hari ini anak — hanya dirender saat akses
/// akademik tersedia (provider baru dipanggil ketika widget ini dibuat).
class _AkademikSection extends ConsumerWidget {
  const _AkademikSection({required this.siswaId});

  final int siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beranda = ref.watch(anakBerandaProvider(siswaId));
    final scheme = Theme.of(context).colorScheme;

    return beranda.when(
      loading: () => const InfoCard(
        child: Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Memuat konteks akademik…')),
          ],
        ),
      ),
      error: (error, _) => InfoCard(
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Text('Konteks akademik tidak tersedia.')),
            TextButton(
              onPressed: () => ref.invalidate(anakBerandaProvider(siswaId)),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (data) => Column(
        children: [
          if (data.konteks.tahunAjaranNama != null ||
              data.konteks.semesterNama != null)
            InfoCard(
              child: Row(
                children: [
                  Icon(Icons.event_note_rounded, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      [
                        if (data.konteks.tahunAjaranNama != null)
                          'TA ${data.konteks.tahunAjaranNama}',
                        if (data.konteks.semesterNama != null)
                          'Semester ${data.konteks.semesterNama}',
                      ].join(' · '),
                    ),
                  ),
                ],
              ),
            ),
          ...data.konteks.peringatan.map(
            (p) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: InfoCard(
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: scheme.tertiary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(p)),
                  ],
                ),
              ),
            ),
          ),
          if (data.kelas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                spacing: 6,
                children: data.kelas
                    .map(
                      (k) => Chip(
                        label: Text(k.nama),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          SectionHeader(title: 'Jadwal Hari Ini', subtitle: data.namaHari),
          if (data.jadwalHariIni.isEmpty)
            const InfoCard(
              child: Row(
                children: [
                  Icon(Icons.event_available_rounded),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('Tidak ada jadwal hari ini.')),
                ],
              ),
            )
          else
            ...data.jadwalHariIni.map((j) => _JadwalMini(item: j)),
        ],
      ),
    );
  }
}

class _JadwalMini extends StatelessWidget {
  const _JadwalMini({required this.item});

  final JadwalItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        dense: true,
        leading: Text(
          item.jamKe != null ? 'Ke-${item.jamKe}' : '—',
          style: textTheme.labelLarge,
        ),
        title: Text(item.mapelNama),
        subtitle: Text(
          [
            if (item.mulai != null && item.selesai != null)
              '${item.mulai}–${item.selesai}',
            if (item.guruNama != null) item.guruNama!,
          ].join(' · '),
        ),
      ),
    );
  }
}

class _MenuChip extends StatelessWidget {
  const _MenuChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(icon, size: 18, color: scheme.primary),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _HistoriTile extends StatelessWidget {
  const _HistoriTile({required this.histori});

  final HistoriRelasi histori;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: const Icon(Icons.history_rounded),
      title: Text(
        histori.event ?? 'Perubahan relasi',
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          if (histori.statusSesudah != null)
            'Status: ${RelasiStatus.label(histori.statusSesudah!)}',
          if (histori.aktorPeran != null) 'Oleh: ${histori.aktorPeran}',
          if (histori.alasan != null && histori.alasan!.isNotEmpty)
            'Alasan: ${histori.alasan}',
        ].join('\n'),
      ),
      trailing: histori.createdAt != null
          ? Text(
              Formatters.dateTimeLokal(histori.createdAt),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          : null,
    );
  }
}
