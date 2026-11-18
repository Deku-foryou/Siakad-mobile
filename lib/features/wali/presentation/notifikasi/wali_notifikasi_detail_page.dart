import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/wali_providers.dart';

/// Detail notifikasi wali. TIDAK otomatis menandai dibaca —
/// user menekan "Tandai Dibaca".
class WaliNotifikasiDetailPage extends ConsumerWidget {
  const WaliNotifikasiDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(waliNotifikasiDetailProvider(id));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Notifikasi')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () => ref.invalidate(waliNotifikasiDetailProvider(id)),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(item.judul, style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  if (item.jenis != null) 'Jenis: ${item.jenis}',
                  if (item.prioritas != null) 'Prioritas: ${item.prioritas}',
                  if (item.waktuDibuat != null)
                    Formatters.dateTimeLokal(item.waktuDibuat),
                ].join(' · '),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: AppSpacing.lg),
              SelectableText(item.isi ?? '-', style: textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.lg),
              if (item.dibaca)
                Row(
                  children: [
                    Icon(
                      Icons.done_all_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Sudah dibaca${item.dibacaPada != null ? ' · ${Formatters.dateTimeLokal(item.dibacaPada)}' : ''}',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: () => _markRead(context, ref),
                  icon: const Icon(Icons.done_rounded),
                  label: const Text('Tandai Dibaca'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(waliNotifikasiActionProvider).markRead(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifikasi ditandai dibaca.')),
        );
      }
      ref.invalidate(waliNotifikasiDetailProvider(id));
      await ref.read(waliNotifikasiProvider.notifier).refresh();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menandai. Coba lagi.')),
        );
      }
    }
  }
}
