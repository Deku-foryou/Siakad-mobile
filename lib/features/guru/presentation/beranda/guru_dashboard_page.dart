import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/guru_providers.dart';
import '../../application/guru_tab_index.dart';
import '../../data/models/guru.dart';

/// Beranda guru â€” data dari `GET /guru/beranda`.
class GuruDashboardPage extends ConsumerWidget {
  const GuruDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beranda = ref.watch(guruBerandaProvider);
    final unread = ref.watch(guruUnreadCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Guru'),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () => context.push('/guru/notifikasi'),
            icon: Badge(
              label: Text('$unread'),
              isLabelVisible: unread > 0,
              child: const Icon(Icons.notifications_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(guruBerandaProvider);
            ref.invalidate(guruUnreadCountProvider);
            try {
              await Future.wait([
                ref.read(guruBerandaProvider.future),
                ref.read(guruUnreadCountProvider.future),
              ]);
            } catch (_) {
              // Error per-section tampil di masing-masing kartu.
            }
          },
          child: beranda.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                AsyncValueView<void>(
                  value: AsyncValue.error(error, StackTrace.current),
                  onRetry: () => ref.invalidate(guruBerandaProvider),
                  data: (_) => const SizedBox.shrink(),
                ),
              ],
            ),
            data: (data) => _DashboardBody(data: data, unreadCount: unread),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.data, required this.unreadCount});

  final GuruBeranda data;
  final int unreadCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final r = data.ringkasan;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ------------------------------------------- Identitas
        InfoCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                child: Text(Formatters.initials(data.nama)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.nama, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (data.nip != null) 'NIP ${data.nip}',
                        if (data.kodeGuru != null) 'Kode ${data.kodeGuru}',
                      ].join(' · '),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      data.akunUsername,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.status != null)
                StatusBadge(
                  label: data.status!.toUpperCase(),
                  color: data.status == 'aktif'
                      ? StatusBadge.forStatus('hadir')
                      : StatusBadge.forStatus('failed'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // ------------------------------------------- Konteks
        if (data.konteks.semesterNama != null ||
            data.konteks.tahunAjaranNama != null)
          InfoCard(
            child: Row(
              children: [
                Icon(Icons.event_note_rounded, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    [
                      if (data.konteks.tahunAjaranNama != null)
                        'Tahun Ajaran ${data.konteks.tahunAjaranNama}',
                      if (data.konteks.semesterNama != null)
                        'Semester ${data.konteks.semesterNama}',
                    ].join(' · '),
                  ),
                ),
              ],
            ),
          ),

        // ------------------------------------------- Ringkasan
        const SizedBox(height: AppSpacing.md),
        const SectionHeader(title: 'Ringkasan'),
        Row(
          children: [
            Expanded(
              child: _statCard(
                context,
                '${r.jumlahKelas}',
                'Kelas',
                Icons.class_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _statCard(
                context,
                '${r.jumlahPenugasan}',
                'Penugasan',
                Icons.assignment_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _statCard(
                context,
                '${r.pertemuanHariIni}',
                'Pertemuan Hari Ini',
                Icons.event_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _statCard(
                context,
                '${r.absensiHarianHariIni}',
                'Absensi Harian Hari Ini',
                Icons.fact_check_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _statCard(
                context,
                '${r.absensiPerjamHariIni}',
                'Absensi Per Jam Hari Ini',
                Icons.schedule_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _statCard(
                context,
                '$unreadCount',
                'Notifikasi Belum Dibaca',
                Icons.notifications_none_rounded,
                onTap: () => context.push('/guru/notifikasi'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------- Kelas
        SectionHeader(
          title: 'Kelas Anda',
          subtitle: '${data.kelas.length} kelas',
          action: TextButton(
            onPressed: () => ref.read(guruTabIndexProvider.notifier).set(1),
            child: const Text('Lihat Semua'),
          ),
        ),
        if (data.kelas.isEmpty)
          const InfoCard(
            child: Row(
              children: [
                Icon(Icons.class_outlined),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Belum ada kelas yang terhubung dengan Anda.'),
                ),
              ],
            ),
          )
        else
          ...data.kelas.map((k) => _KelasChip(kelas: k)),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------- Jadwal hari ini
        SectionHeader(
          title: 'Jadwal Hari Ini',
          subtitle: data.namaHari,
          action: TextButton(
            onPressed: () => context.push('/guru/jadwal'),
            child: const Text('Lihat Semua'),
          ),
        ),
        if (data.jadwalHariIni.isEmpty)
          const InfoCard(child: Text('Tidak ada jadwal mengajar hari ini.'))
        else
          ...data.jadwalHariIni.map((j) => _JadwalTile(item: j)),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------- Akses cepat
        const SectionHeader(title: 'Akses Cepat'),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ActionChip(
              avatar: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('Jadwal'),
              onPressed: () => context.push('/guru/jadwal'),
            ),
            ActionChip(
              avatar: const Icon(Icons.class_rounded, size: 18),
              label: const Text('Kelas'),
              onPressed: () => ref.read(guruTabIndexProvider.notifier).set(1),
            ),
            ActionChip(
              avatar: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('Absensi'),
              onPressed: () => ref.read(guruTabIndexProvider.notifier).set(2),
            ),
            ActionChip(
              avatar: const Icon(Icons.grade_rounded, size: 18),
              label: const Text('Penilaian'),
              onPressed: () => ref.read(guruTabIndexProvider.notifier).set(3),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String value,
    String label,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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

class _KelasChip extends StatelessWidget {
  const _KelasChip({required this.kelas});

  final KelasRingkas kelas;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.class_rounded),
        title: Text(
          '${kelas.nama}${kelas.tingkat != null ? ' (Tingkat ${kelas.tingkat})' : ''}',
        ),
        subtitle: Text(
          [
            if (kelas.jumlahSiswa != null) '${kelas.jumlahSiswa} siswa',
            if (kelas.mapel.isNotEmpty)
              kelas.mapel.map((m) => m.nama).join(', '),
          ].join(' Â· '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kelas.diajar) const StatusBadge(label: 'Mengajar'),
            if (kelas.diwali) ...[
              const SizedBox(width: 4),
              const StatusBadge(label: 'Wali'),
            ],
          ],
        ),
      ),
    );
  }
}

class _JadwalTile extends StatelessWidget {
  const _JadwalTile({required this.item});

  final JadwalGuruItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            item.jamKe != null ? '${item.jamKe}' : '-',
            style: textTheme.labelLarge?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(item.mapel.nama),
        subtitle: Text(
          [
            if (item.mulai != null)
              '${item.mulai}${item.selesai != null ? '–${item.selesai}' : ''}',
            'Jam ${item.jamKe ?? '-'}',
            'Kelas ${item.kelas.nama}',
          ].join(' · '),
        ),
      ),
    );
  }
}
