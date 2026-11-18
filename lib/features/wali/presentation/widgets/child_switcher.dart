import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../application/wali_providers.dart';

/// Pemilih anak aktif (dropdown) untuk konteks shell — HANYA anak dengan
/// akses akademik (verified + belum berakhir) yang bisa dipilih.
/// [value] = siswaId efektif; [onChanged] = id anak baru.
class ChildSwitcher extends ConsumerWidget {
  const ChildSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anakAsync = ref.watch(waliAnakListProvider);
    final scheme = Theme.of(context).colorScheme;

    return anakAsync.when(
      loading: () => const SizedBox(
        height: 36,
        width: 36,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, _) => Tooltip(
        message: 'Gagal memuat daftar anak',
        child: IconButton(
          tooltip: 'Gagal memuat daftar anak — coba lagi',
          icon: Icon(Icons.error_outline, color: scheme.error),
          onPressed: () => ref.invalidate(waliAnakListProvider),
        ),
      ),
      data: (data) {
        final eligible = data.anak.where((a) => a.bisaAksesAkademik).toList();
        if (eligible.isEmpty) return const SizedBox.shrink();
        final selectedId = eligible.any((a) => a.siswa?.id == value)
            ? value
            : eligible.first.siswa?.id;
        return DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedId,
            borderRadius: BorderRadius.circular(12),
            isDense: true,
            icon: const Icon(Icons.expand_more_rounded),
            items: [
              for (final e in eligible)
                DropdownMenuItem<int>(
                  value: e.siswa?.id,
                  child: Text(
                    [
                      e.siswa?.nama ?? 'Anak',
                      if (e.kelas != null) e.kelas!,
                    ].join(' · '),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) {
              if (id != null) onChanged(id);
            },
          ),
        );
      },
    );
  }
}

/// Judul AppBar dua baris: judul halaman + identitas anak terpilih
/// (nama · kelas) agar konteks anak selalu terlihat di halaman akademik
/// dan finansial wali. Menampilkan judul saja saat data belum siap.
class AnakAppBarTitle extends ConsumerWidget {
  const AnakAppBarTitle(this.title, {super.key, required this.siswaId});

  final String title;
  final int siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anakAsync = ref.watch(waliAnakListProvider);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return anakAsync.when(
      loading: () => Text(title),
      error: (_, _) => Text(title),
      data: (data) {
        final matches = data.anak.where((a) => a.siswa?.id == siswaId);
        if (matches.isEmpty) return Text(title);
        final anak = matches.first;
        final nama = anak.siswa?.nama;
        final kelas = anak.kelas;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            Text(
              [?nama, ?kelas].join(' · '),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}

/// Ajakan informatif saat wali belum punya anak verified (atau gagal memuat).
class PilihAnakKosong extends StatelessWidget {
  const PilihAnakKosong({
    super.key,
    required this.message,
    this.icon = Icons.family_restroom_rounded,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: scheme.outline),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Belum Ada Anak Terverifikasi',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}
