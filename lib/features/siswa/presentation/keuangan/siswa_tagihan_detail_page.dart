import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/siswa_providers.dart';
import '../../data/models/keuangan.dart';

/// Detail tagihan + aksi "Bayar" (membuat payment attempt via backend).
///
/// - Nominal SELALU dari backend; client hanya mengirim tagihan_id.
/// - Attempt ≠ pembayaran; status hanya mengikuti server.
class SiswaTagihanDetailPage extends ConsumerStatefulWidget {
  const SiswaTagihanDetailPage({super.key, required this.id});

  final int id;

  @override
  ConsumerState<SiswaTagihanDetailPage> createState() =>
      _SiswaTagihanDetailPageState();
}

class _SiswaTagihanDetailPageState
    extends ConsumerState<SiswaTagihanDetailPage> {
  bool _creatingAttempt = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(tagihanDetailProvider(widget.id));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tagihan')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () => ref.invalidate(tagihanDetailProvider(widget.id)),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (tagihan) {
            final canPay =
                (tagihan.status == 'belum_dibayar' ||
                    tagihan.status == 'dibayar_sebagian') &&
                tagihan.sisa > 0;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(tagihan.nama, style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                StatusBadge(
                  label: StatusBadge.labelOf(tagihan.status),
                  color: StatusBadge.forStatus(tagihan.status),
                ),
                const SizedBox(height: AppSpacing.md),
                InfoCard(
                  child: Column(
                    children: [
                      InfoRow(
                        label: 'Total Tagihan',
                        value: Formatters.rupiah(tagihan.nominal),
                      ),
                      InfoRow(
                        label: 'Terbayar',
                        value: Formatters.rupiah(tagihan.terbayar),
                      ),
                      InfoRow(
                        label: 'Sisa',
                        value: Formatters.rupiah(tagihan.sisa),
                      ),
                      if (tagihan.jatuhTempo != null)
                        InfoRow(
                          label: 'Jatuh Tempo',
                          value: Formatters.tanggalPanjang(tagihan.jatuhTempo),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (canPay) ...[
                  FilledButton.icon(
                    onPressed: _creatingAttempt ? null : _bayar,
                    icon: _creatingAttempt
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payment_rounded),
                    label: Text(
                      _creatingAttempt
                          ? 'Memproses…'
                          : 'Bayar ${Formatters.rupiah(tagihan.sisa)}',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Nominal dan status transaksi ditentukan server (Midtrans). '
                    'Pembayaran baru dianggap berhasil setelah dikonfirmasi backend.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else
                  InfoCard(
                    child: Text(
                      tagihan.status == 'lunas' ? 'Tagihan ini sudah lunas.' : 'Tagihan ini tidak dapat dibayar pada status saat ini.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _bayar() async {
    final tagihan = ref.read(tagihanDetailProvider(widget.id)).value;
    if (tagihan == null) return;

    // Konfirmasi sebelum membuat attempt.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Pembayaran'),
        content: Text(
          'Buat instruksi pembayaran untuk "${tagihan.nama}" sebesar '
          '${Formatters.rupiah(tagihan.sisa)}?\n\n'
          'Nominal final dan status ditentukan server. Anda akan diarahkan '
          'ke halaman pembayaran Midtrans.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _creatingAttempt = true);
    try {
      final attempt = await ref
          .read(keuanganRepositoryProvider)
          .buatAttempt(tagihanId: tagihan.id);
      if (mounted) await _showAttemptDialog(attempt);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _creatingAttempt = false);
    }
  }

  Future<void> _showAttemptDialog(PaymentAttempt attempt) async {
    final scheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Instruksi Pembayaran Dibuat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoRow(label: 'Nomor Order', value: attempt.orderId),
            InfoRow(
              label: 'Nominal',
              value: Formatters.rupiah(attempt.nominal),
            ),
            InfoRow(
              label: 'Status',
              value: StatusBadge.labelOf(attempt.status),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Selesaikan pembayaran melalui halaman Midtrans. Status '
              'transaksi berubah hanya dari konfirmasi server.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Nanti'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              GoRouter.of(context)
                  .push('/siswa/pembayaran-attempt/${attempt.id}');
            },
            child: const Text('Periksa Status'),
          ),
          if (attempt.snapRedirectUrl != null &&
              attempt.snapRedirectUrl!.isNotEmpty)
            FilledButton.tonal(
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final url = Uri.tryParse(attempt.snapRedirectUrl!);
                final launched =
                    url != null &&
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                if (!launched && ctx.mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tidak bisa membuka halaman pembayaran. '
                        'Coba lagi nanti.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Buka Halaman Pembayaran'),
            ),
        ],
      ),
    );
    // Setelah dialog ditutup, segarkan detail tagihan (mungkin status berubah).
    if (mounted) ref.invalidate(tagihanDetailProvider(widget.id));
  }
}
