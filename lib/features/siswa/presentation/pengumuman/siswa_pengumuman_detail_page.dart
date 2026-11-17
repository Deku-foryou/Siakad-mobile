import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/siswa_providers.dart';

/// Detail pengumuman. Backend otomatis menandai dibaca saat detail dibuka
/// (idempoten) — halaman ini hanya menampilkan, tidak menandai manual.
class SiswaPengumumanDetailPage extends ConsumerWidget {
  const SiswaPengumumanDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(pengumumanDetailProvider(id));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengumuman')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () => ref.invalidate(pengumumanDetailProvider(id)),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  if (item.kategori != null) Chip(label: Text(item.kategori!)),
                  if (item.prioritas != null)
                    Chip(
                      avatar: Icon(
                        Icons.flag_rounded,
                        size: 16,
                        color: item.prioritas!.toLowerCase() == 'tinggi'
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                      label: Text('Prioritas ${item.prioritas}'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(item.judul, style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  if (item.waktuTerbit != null)
                    'Diterbitkan ${Formatters.dateTimeLokal(item.waktuTerbit)}',
                  if (item.berlakuDari != null)
                    'Berlaku ${Formatters.tanggalPanjang(item.berlakuDari)}'
                        '${item.berlakuSampai != null ? ' – ${Formatters.tanggalPanjang(item.berlakuSampai)}' : ''}',
                ].join('\n'),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: AppSpacing.lg),
              SelectableText(item.isi ?? '-', style: textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.lg),
              if (item.dibacaPada != null)
                Row(
                  children: [
                    Icon(
                      Icons.done_all_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Dibuka ${Formatters.dateTimeLokal(item.dibacaPada)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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
