import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/wali_providers.dart';
import '../../data/models/wali.dart';
import '../widgets/relasi_widgets.dart';

/// Daftar seluruh relasi wali↔anak (semua status). Sumber: `GET /wali/anak`.
/// Mengetuk anak → set konteks terpilih + buka detail anak.
class WaliAnakPage extends ConsumerWidget {
  const WaliAnakPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anakAsync = ref.watch(waliAnakListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Anak Saya')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(waliAnakListProvider),
          child: anakAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AsyncValueView<void>(
              value: AsyncValue.error(error, StackTrace.current),
              onRetry: () => ref.invalidate(waliAnakListProvider),
              data: (_) => const SizedBox.shrink(),
            ),
            data: (data) => _AnakListBody(data: data),
          ),
        ),
      ),
    );
  }
}

class _AnakListBody extends ConsumerWidget {
  const _AnakListBody({required this.data});

  final AnakListResponse data;

  static const _filters = <String?>[
    null,
    'verified',
    'pending',
    'rejected',
    'terminated',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filter = ref.watch(_anakFilterProvider);

    final items = data.anak
        .where((a) => filter == null || a.statusHubungan == filter)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (!data.konteks.valid && data.konteks.peringatan.isNotEmpty)
          ...data.konteks.peringatan.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
        if (data.anak.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Column(
              children: [
                Icon(
                  Icons.family_restroom_rounded,
                  size: 56,
                  color: scheme.outline,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Belum Ada Relasi Anak',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Anda belum memiliki relasi dengan siswa mana pun. '
                  'Relasi baru hanya dapat dibuat admin sekolah; halaman '
                  'ini akan menampilkan statusnya setelah ada data.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else ...[
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      label: Text(f == null ? 'Semua' : RelasiStatus.label(f)),
                      selected: filter == f,
                      onSelected: (_) =>
                          ref.read(_anakFilterProvider.notifier).set(f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Tidak ada relasi pada filter ini.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final anak in items)
            _AnakRelasiTile(
              anak: anak,
              onTap: () {
                final siswaId = anak.siswa?.id;
                if (siswaId == null) return;
                // Namun relasi yang verified (bisa diakses) jadi konteks shell.
                if (anak.bisaAksesAkademik) {
                  ref.read(selectedAnakIdProvider.notifier).set(siswaId);
                }
                context.push('/wali/anak/$siswaId');
              },
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Status relasi ditentukan admin sekolah. Akses akademik dan '
            'keuangan hanya tersedia untuk relasi "Terverifikasi".',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _AnakFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final _anakFilterProvider = NotifierProvider<_AnakFilter, String?>(
  _AnakFilter.new,
);

class _AnakRelasiTile extends StatelessWidget {
  const _AnakRelasiTile({required this.anak, required this.onTap});

  final AnakRelasi anak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final siswa = anak.siswa;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(
            (siswa?.nama ?? '?').trim().isEmpty
                ? '?'
                : (siswa?.nama ?? '?').trim()[0].toUpperCase(),
          ),
        ),
        title: Text(siswa?.nama ?? '-', style: textTheme.titleSmall),
        subtitle: Text(
          [
            if (siswa?.nis != null) 'NIS ${siswa?.nis}',
            if (anak.kelas != null) anak.kelas!,
            if (anak.hubungan != null) anak.hubungan!,
          ].join(' · '),
        ),
        trailing: RelasiStatus.badge(anak.statusHubungan),
      ),
    );
  }
}
