import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../widgets/child_switcher.dart';
import '../../application/wali_providers.dart';

/// Daftar rapor final anak — `GET /wali/anak/{siswaId}/rapor`.
class WaliRaporPage extends ConsumerWidget {
  const WaliRaporPage({super.key, required this.siswaId});

  final int siswaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rapor = ref.watch(anakRaporProvider(siswaId));

    return Scaffold(
      appBar: AppBar(title: AnakAppBarTitle('Rapor Anak', siswaId: siswaId)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(anakRaporProvider(siswaId)),
          child: AsyncValueView(
            value: rapor,
            onRetry: () => ref.invalidate(anakRaporProvider(siswaId)),
            isEmpty: (items) => items.isEmpty,
            empty: const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Icon(Icons.description_outlined, size: 48),
                  SizedBox(height: AppSpacing.sm),
                  Text('Belum Ada Rapor Final', textAlign: TextAlign.center),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Rapor hanya tersedia setelah difinalisasi oleh sekolah.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            data: (items) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final item in items)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ListTile(
                      leading: const Icon(Icons.description_rounded),
                      title: Text('${item.semester.nama} · ${item.kelas.nama}'),
                      subtitle: Text(
                        [
                          if (item.semester.tahunAjaranNama != null)
                            'TA ${item.semester.tahunAjaranNama}',
                          if (item.waliKelas != null)
                            'Wali Kelas: ${item.waliKelas}',
                          if (item.difinalisasiPada != null)
                            'Finalisasi: ${Formatters.dateTimeLokal(item.difinalisasiPada)}',
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(
                        '/wali/anak/$siswaId/rapor/${item.semester.id}/${item.kelas.id}',
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
