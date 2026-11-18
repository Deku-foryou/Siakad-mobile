import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/siswa_providers.dart';
import '../../application/siswa_tab_index.dart';
import '../../data/models/beranda.dart';
import '../../data/models/keuangan.dart';

/// Beranda siswa — data dari `GET /siswa/beranda` (+ringkasan keuangan &
/// pengumuman terbaru dari endpoint masing-masing).
class SiswaDashboardPage extends ConsumerWidget {
  const SiswaDashboardPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(berandaProvider);
    ref.invalidate(unreadCountProvider);
    ref.invalidate(ringkasanProvider);
    // Tunggu futures yang dibatalkan/berubah; error dibiarkan ke UI per-kartu.
    try {
      await Future.wait([
        ref.read(berandaProvider.future),
        ref.read(unreadCountProvider.future),
        ref.read(ringkasanProvider.future),
      ]);
    } catch (_) {
      // Error per-section ditampilkan di masing-masing kartu.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beranda = ref.watch(berandaProvider);
    final ringkasan = ref.watch(ringkasanProvider);
    final unread = ref.watch(unreadCountProvider);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: Scaffold(
        body: SafeArea(
          child: beranda.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncValueView<void>(
              value: AsyncValue.error(error, StackTrace.current),
              onRetry: () => ref.invalidate(berandaProvider),
              data: (_) => const SizedBox.shrink(),
            ),
            data: (data) => _DashboardBody(
              data: data,
              ringkasanValue: ringkasan,
              unreadCount: unread.value ?? 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.data,
    required this.ringkasanValue,
    required this.unreadCount,
  });

  final BerandaSiswa data;
  final AsyncValue<RingkasanKeuangan> ringkasanValue;
  final int unreadCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final siswa = data;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ------------------------------------------------ Identitas
        InfoCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                child: Text(Formatters.initials(siswa.nama)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(siswa.nama ?? 'Siswa', style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (siswa.nis != null) 'NIS ${siswa.nis}',
                        if (siswa.status != null) siswa.status!,
                      ].join(' · '),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (siswa.kelas.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        children: siswa.kelas
                            .map(
                              (k) => Chip(
                                label: Text(
                                  k.tingkat != null
                                      ? '${k.nama} (Tingkat ${k.tingkat})'
                                      : k.nama,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Konteks TA/semester
        if (siswa.konteks.tahunAjaranNama != null ||
            siswa.konteks.semesterNama != null)
          InfoCard(
            child: Row(
              children: [
                Icon(Icons.event_note_rounded, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    [
                      if (siswa.konteks.tahunAjaranNama != null)
                        'Tahun Ajaran ${siswa.konteks.tahunAjaranNama}',
                      if (siswa.konteks.semesterNama != null)
                        'Semester ${siswa.konteks.semesterNama}',
                    ].join(' · '),
                    style: textTheme.bodyMedium,
                  ),
                ),
                if (siswa.konteks.valid)
                  StatusBadge(
                    label: 'Aktif',
                    color: StatusBadge.forStatus('hadir'),
                  ),
              ],
            ),
          ),
        // Peringatan konteks (jika ada dari backend)
        ...siswa.konteks.peringatan.map(
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
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Ringkasan keuangan
        _FinanceCard(
          ringkasanValue: ringkasanValue,
          onOpenFinance: () => ref.read(siswaTabIndexProvider.notifier).set(2),
        ),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Jadwal hari ini
        SectionHeader(
          title: 'Jadwal Hari Ini',
          subtitle: data.namaHari,
          action: TextButton(
            onPressed: () => context.push('/siswa/jadwal'),
            child: const Text('Lihat Semua'),
          ),
        ),
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
          ...data.jadwalHariIni.map((j) => _JadwalTile(item: j)),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Aksi cepat
        const SectionHeader(title: 'Akses Cepat'),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _QuickAction(
              icon: Icons.calendar_month_rounded,
              label: 'Jadwal',
              onTap: () => context.push('/siswa/jadwal'),
            ),
            _QuickAction(
              icon: Icons.fact_check_outlined,
              label: 'Absensi',
              onTap: () => context.push('/siswa/absensi'),
            ),
            _QuickAction(
              icon: Icons.grade_rounded,
              label: 'Nilai',
              onTap: () => context.push('/siswa/nilai'),
            ),
            _QuickAction(
              icon: Icons.description_rounded,
              label: 'Rapor',
              onTap: () => context.push('/siswa/rapor'),
            ),
            _QuickAction(
              icon: Icons.campaign_rounded,
              label: 'Pengumuman',
              onTap: () => context.push('/siswa/pengumuman'),
            ),
            _QuickAction(
              icon: Icons.notifications_rounded,
              label: 'Notifikasi${unreadCount > 0 ? ' ($unreadCount)' : ''}',
              onTap: () => ref.read(siswaTabIndexProvider.notifier).set(3),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _JadwalTile extends StatelessWidget {
  const _JadwalTile({required this.item});

  final JadwalItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.jamKe != null ? 'Ke-${item.jamKe}' : '—',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (item.mulai != null)
              Text(
                item.mulai!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
        title: Text(item.mapelNama),
        subtitle: Text(
          [
            if (item.selesai != null) '${item.mulai ?? ''}–${item.selesai}',
            if (item.guruNama != null) item.guruNama!,
          ].join(' · '),
        ),
        trailing: item.kelasId != null ? null : null,
      ),
    );
  }
}

class _FinanceCard extends ConsumerWidget {
  const _FinanceCard({
    required this.ringkasanValue,
    required this.onOpenFinance,
  });

  final AsyncValue<RingkasanKeuangan> ringkasanValue;
  final VoidCallback onOpenFinance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ringkasanValue.when(
          loading: () => const Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Memuat ringkasan keuangan…')),
            ],
          ),
          error: (error, _) => Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(child: Text('Ringkasan keuangan tidak tersedia.')),
              TextButton(
                onPressed: () => ref.invalidate(ringkasanProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
          data: (ringkasan) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text('Keuangan', style: textTheme.titleMedium),
                    ),
                    TextButton(
                      onPressed: onOpenFinance,
                      child: const Text('Detail'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Sisa kewajiban',
                        value: Formatters.rupiah(ringkasan.sisaKewajiban),
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Saldo',
                        value: Formatters.rupiah(ringkasan.saldo),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(value, style: textTheme.titleMedium),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
