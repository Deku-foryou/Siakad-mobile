import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/guru_providers.dart';

/// Daftar siswa aktif kelas — `GET /guru/kelas/{id}/siswa`.
class GuruSiswaPage extends ConsumerWidget {
  const GuruSiswaPage({super.key, required this.kelasId});

  final int kelasId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siswa = ref.watch(guruKelasSiswaProvider(kelasId));

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Siswa')),
      body: SafeArea(
        child: siswa.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () => ref.invalidate(guruKelasSiswaProvider(kelasId)),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Kelas ${data.kelasNama} · ${data.jumlah} siswa',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              if (data.siswa.isEmpty)
                const SizedBox(
                  height: 280,
                  child: AppEmptyView(
                    icon: Icons.groups_rounded,
                    title: 'Belum Ada Siswa',
                    message: 'Belum ada siswa aktif di kelas ini.',
                  ),
                )
              else
                for (final s in data.siswa)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(_initials(s.nama))),
                      title: Text(s.nama),
                      subtitle: Text(
                        [
                          if (s.nis != null) 'NIS ${s.nis}',
                          if (s.nisn != null) 'NISN ${s.nisn}',
                        ].join(' · '),
                      ),
                      trailing: s.jenisKelamin != null
                          ? Text(
                              s.jenisKelamin == 'L' ? 'L' : 'P',
                              style: Theme.of(context).textTheme.labelLarge,
                            )
                          : null,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }
}
