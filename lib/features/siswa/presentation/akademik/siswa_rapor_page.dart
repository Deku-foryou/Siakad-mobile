import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/siswa_providers.dart';

/// Daftar rapor final siswa — `GET /siswa/rapor`. Read-only.
class SiswaRaporPage extends ConsumerWidget {
  const SiswaRaporPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rapor = ref.watch(raporProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rapor Saya')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(raporProvider);
            await ref.read(raporProvider.future);
          },
          child: rapor.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                AsyncValueView<void>(
                  value: AsyncValue.error(error, StackTrace.current),
                  onRetry: () => ref.invalidate(raporProvider),
                  data: (_) => const SizedBox.shrink(),
                ),
              ],
            ),
            data: (entries) => entries.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 96),
                      AppEmptyView(
                        icon: Icons.description_rounded,
                        title: 'Belum Ada Rapor',
                        message: 'Rapor akan tersedia setelah difinalisasi oleh sekolah.',
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final ta = entry.semester.tahunAjaranNama;
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.description_rounded),
                          ),
                          title: Text(
                            'Semester ${entry.semester.nama} · Kelas ${entry.kelas.nama}',
                          ),
                          subtitle: Text(
                            [
                              if (ta != null) 'TA $ta',
                              if (entry.waliKelas != null)
                                'Wali kelas: ${entry.waliKelas}',
                              if (entry.difinalisasiPada != null)
                                'Difinalisasi ${Formatters.dateTimeLokal(entry.difinalisasiPada)}',
                            ].join('\n'),
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(
                            '/siswa/rapor/${entry.semester.id}/${entry.kelas.id}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
