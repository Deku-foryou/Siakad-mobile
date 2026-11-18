import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/wali_providers.dart';
import '../../../siswa/data/keuangan_repository.dart' show DokumenResult;
import '../../../siswa/data/private_document_service.dart';

/// Detail pembayaran anak + unduhan dokumen privat (bukti/kuitansi).
/// Dokumen diakses via endpoint backend (privat, ownership server-side).
class WaliPembayaranDetailPage extends ConsumerStatefulWidget {
  const WaliPembayaranDetailPage({
    super.key,
    required this.siswaId,
    required this.id,
  });

  final int siswaId;
  final int id;

  @override
  ConsumerState<WaliPembayaranDetailPage> createState() =>
      _WaliPembayaranDetailPageState();
}

class _WaliPembayaranDetailPageState
    extends ConsumerState<WaliPembayaranDetailPage> {
  bool _downloadingBukti = false;
  bool _downloadingKuitansi = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(
      anakPembayaranDetailProvider((widget.siswaId, widget.id)),
    );
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pembayaran')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () => ref.invalidate(
              anakPembayaranDetailProvider((widget.siswaId, widget.id)),
            ),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                Formatters.rupiah(item.nominal),
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              StatusBadge(
                label: StatusBadge.labelOf(item.status),
                color: StatusBadge.forStatus(item.status),
              ),
              const SizedBox(height: AppSpacing.md),
              InfoCard(
                child: Column(
                  children: [
                    InfoRow(label: 'Metode', value: item.metode ?? '-'),
                    if (item.dibayarPada != null)
                      InfoRow(
                        label: 'Dibayar pada',
                        value: Formatters.dateTimeLokal(item.dibayarPada),
                      ),
                    InfoRow(label: 'Referensi', value: '#${item.id}'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Dokumen'),
              OutlinedButton.icon(
                onPressed: _downloadingBukti ? null : _unduhBukti,
                icon: _downloadingBukti
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long_rounded),
                label: const Text('Bukti Pembayaran'),
              ),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: _downloadingKuitansi ? null : _unduhKuitansi,
                icon: _downloadingKuitansi
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.description_rounded),
                label: const Text('Kuitansi'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Dokumen diunduh melalui server (endpoint privat) dan disimpan '
                'secara lokal di perangkat. Tidak dibagikan ke pihak lain.',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unduhBukti() => _unduhDokumen(
    unduh: () => ref.read(waliKeuanganRepositoryProvider).unduhBukti(widget.id),
    setBusy: (v) => setState(() => _downloadingBukti = v),
  );

  Future<void> _unduhKuitansi() => _unduhDokumen(
    unduh: () =>
        ref.read(waliKeuanganRepositoryProvider).unduhKuitansi(widget.id),
    setBusy: (v) => setState(() => _downloadingKuitansi = v),
  );

  Future<void> _unduhDokumen({
    required Future<DokumenResult> Function() unduh,
    required void Function(bool) setBusy,
  }) async {
    setBusy(true);
    try {
      final dokumen = await unduh();
      const service = PrivateDocumentService();
      final path = await service.save(dokumen);
      final opened = await service.open(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Dokumen dibuka.'
                : 'Dokumen tersimpan di perangkat (${dokumen.filename}).',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengunduh dokumen. Coba lagi nanti.'),
        ),
      );
    } finally {
      if (mounted) setBusy(false);
    }
  }
}
