import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/wali_providers.dart';
import '../../application/wali_tab_index.dart';
import '../../data/models/wali.dart';

/// Beranda wali — `GET /api/v1/wali/beranda`.
/// Identitas + konteks akademik + daftar anak verified + notifikasi
/// belum dibaca + ringkasan keuangan anak yang dipilih (bila ada).
class WaliDashboardPage extends ConsumerWidget {
  const WaliDashboardPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(waliBerandaProvider);
    ref.invalidate(waliUnreadCountProvider);
    ref.invalidate(waliAnakListProvider);
    try {
      await Future.wait([
        ref.read(waliBerandaProvider.future),
        ref.read(waliUnreadCountProvider.future),
        ref.read(waliAnakListProvider.future),
      ]);
    } catch (_) {
      // Error per-section ditampilkan di masing-masing kartu.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beranda = ref.watch(waliBerandaProvider);
    final unread = ref.watch(waliUnreadCountProvider);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: Scaffold(
        appBar: AppBar(title: const Text('Beranda Wali')),
        body: SafeArea(
          child: beranda.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncValueView<void>(
              value: AsyncValue.error(error, StackTrace.current),
              onRetry: () => ref.invalidate(waliBerandaProvider),
              data: (_) => const SizedBox.shrink(),
            ),
            data: (data) => _DashboardBody(
              data: data,
              unreadCount: unread.value ?? data.ringkasan.notifikasiBelumDibaca,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.data, required this.unreadCount});

  final BerandaWali data;
  final int unreadCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selectedId = ref.watch(waliAnakAktifProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ------------------------------------------------ Identitas
        InfoCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                child: Text(Formatters.initials(data.name)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name.isEmpty ? 'Wali Murid' : data.name,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${data.akunUsername}',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(
                      label: 'Wali Murid',
                      color: scheme.secondaryContainer,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Konteks TA/semester
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
                        'Tahun Ajaran ${data.konteks.tahunAjaranNama}',
                      if (data.konteks.semesterNama != null)
                        'Semester ${data.konteks.semesterNama}',
                    ].join(' · '),
                    style: textTheme.bodyMedium,
                  ),
                ),
                if (data.konteks.valid)
                  StatusBadge(
                    label: 'Aktif',
                    color: StatusBadge.forStatus('hadir'),
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
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Ringkasan relasi
        const SectionHeader(title: 'Ringkasan Relasi'),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Terverifikasi',
                value: '${data.ringkasan.jumlahAnak}',
                color: AppColors.success,
              ),
            ),
            Expanded(
              child: _MiniStat(
                label: 'Menunggu',
                value: '${data.ringkasan.jumlahMenunggu}',
                color: AppColors.warning,
              ),
            ),
            Expanded(
              child: _MiniStat(
                label: 'Ditolak',
                value: '${data.ringkasan.jumlahDitolak}',
                color: AppColors.error,
              ),
            ),
            Expanded(
              child: _MiniStat(
                label: 'Berakhir',
                value: '${data.ringkasan.jumlahBerakhir}',
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Notifikasi
        _NotifikasiRow(unreadCount: unreadCount),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Keuangan anak dipilih
        if (selectedId != null)
          _KeuanganCard(siswaId: selectedId)
        else
          const InfoCard(
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Ringkasan keuangan tersedia setelah ada anak '
                    'terverifikasi dan dipilih.',
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Anak terhubung
        SectionHeader(
          title: 'Anak Terhubung',
          subtitle: '${data.anak.length} anak dengan relasi terverifikasi',
          action: TextButton(
            onPressed: () => ref.read(waliTabIndexProvider.notifier).set(1),
            child: const Text('Lihat Semua'),
          ),
        ),
        if (data.anak.isEmpty)
          InfoCard(
            child: Column(
              children: [
                Icon(
                  Icons.family_restroom_rounded,
                  size: 40,
                  color: scheme.outline,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Belum ada anak dengan relasi terverifikasi.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Gunakan tab "Anak" untuk melihat status seluruh relasi '
                  '(termasuk yang menunggu verifikasi / ditolak / berakhir).',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ...data.anak.map(
            (anak) => _AnakTile(
              anak: anak,
              onTap: () {
                ref.read(selectedAnakIdProvider.notifier).set(anak.id);
                context.push('/wali/anak/${anak.id}');
              },
            ),
          ),
        const SizedBox(height: AppSpacing.md),

        // ------------------------------------------------ Akses cepat
        const SectionHeader(title: 'Akses Cepat'),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _QuickAction(
              icon: Icons.calendar_month_rounded,
              label: 'Jadwal',
              enabled: selectedId != null,
              onTap: () => context.push('/wali/anak/$selectedId/jadwal'),
            ),
            _QuickAction(
              icon: Icons.fact_check_outlined,
              label: 'Absensi',
              enabled: selectedId != null,
              onTap: () => context.push('/wali/anak/$selectedId/absensi'),
            ),
            _QuickAction(
              icon: Icons.grade_rounded,
              label: 'Nilai',
              enabled: selectedId != null,
              onTap: () => context.push('/wali/anak/$selectedId/nilai'),
            ),
            _QuickAction(
              icon: Icons.description_rounded,
              label: 'Rapor',
              enabled: selectedId != null,
              onTap: () => context.push('/wali/anak/$selectedId/rapor'),
            ),
            _QuickAction(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Keuangan',
              enabled: selectedId != null,
              onTap: () => ref.read(waliTabIndexProvider.notifier).set(2),
            ),
            _QuickAction(
              icon: Icons.notifications_rounded,
              label: 'Notifikasi${unreadCount > 0 ? ' ($unreadCount)' : ''}',
              enabled: true,
              onTap: () => ref.read(waliTabIndexProvider.notifier).set(3),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _AnakTile extends StatelessWidget {
  const _AnakTile({required this.anak, required this.onTap});

  final AnakRingkas anak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(
            (anak.nama ?? '?').trim().isEmpty
                ? '?'
                : (anak.nama ?? '?').trim()[0].toUpperCase(),
          ),
        ),
        title: Text(anak.nama ?? '-', style: textTheme.titleSmall),
        subtitle: Text(
          [
            if (anak.nis != null) 'NIS ${anak.nis}',
            if (anak.kelas != null) anak.kelas!,
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _NotifikasiRow extends ConsumerWidget {
  const _NotifikasiRow({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
          child: const Icon(Icons.notifications_rounded),
        ),
        title: const Text('Notifikasi'),
        subtitle: Text(
          unreadCount > 0
              ? '$unreadCount belum dibaca'
              : 'Semua notifikasi sudah dibaca',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => ref.read(waliTabIndexProvider.notifier).set(3),
      ),
    );
  }
}

class _KeuanganCard extends ConsumerWidget {
  const _KeuanganCard({required this.siswaId});

  final int siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringkasan = ref.watch(anakRingkasanKeuanganProvider(siswaId));
    final anakList = ref.watch(waliAnakListProvider).value;
    final matches = anakList?.anak.where((a) => a.siswa?.id == siswaId);
    final anak = (matches != null && matches.isNotEmpty)
        ? matches.first.siswa?.nama
        : null;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ringkasan.when(
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
                onPressed: () =>
                    ref.invalidate(anakRingkasanKeuanganProvider(siswaId)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
          data: (data) => Column(
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
                    child: Text(
                      'Keuangan${anak != null ? ' — $anak' : ''}',
                      style: textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(waliTabIndexProvider.notifier).set(2),
                    child: const Text('Detail'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatInline(
                      label: 'Sisa kewajiban',
                      value: Formatters.rupiah(data.sisaKewajiban),
                    ),
                  ),
                  Expanded(
                    child: _MiniStatInline(
                      label: 'Saldo',
                      value: Formatters.rupiah(data.saldo),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatInline extends StatelessWidget {
  const _MiniStatInline({required this.label, required this.value});

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
        Text(value, style: textTheme.titleSmall),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(
        icon,
        size: 18,
        color: enabled ? scheme.primary : scheme.outline,
      ),
      label: Text(label),
      onPressed: enabled ? onTap : null,
    );
  }
}
