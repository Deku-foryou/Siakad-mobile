import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../widgets/child_switcher.dart';
import '../../application/wali_providers.dart';

/// Status payment attempt (K8) — hanya menampilkan status dari server.
class WaliAttemptStatusPage extends ConsumerWidget {
  const WaliAttemptStatusPage({
    super.key,
    required this.siswaId,
    required this.id,
  });

  final int siswaId;
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempt = ref.watch(anakAttemptStatusProvider((siswaId, id)));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: AnakAppBarTitle('Status Pembayaran', siswaId: siswaId),
      ),
      body: SafeArea(
        child: attempt.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () =>
                ref.invalidate(anakAttemptStatusProvider((siswaId, id))),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (data) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(
                        _iconFor(data.status),
                        size: 72,
                        color:
                            StatusBadge.forStatus(data.status) ??
                            scheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        StatusBadge.labelOf(data.status),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Status ini bersumber dari server (Midtrans).',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                InfoCard(
                  child: Column(
                    children: [
                      InfoRow(label: 'Nomor Order', value: data.orderId),
                      InfoRow(
                        label: 'Nominal',
                        value: Formatters.rupiah(data.nominal),
                      ),
                      InfoRow(
                        label: 'Status',
                        value: StatusBadge.labelOf(data.status),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _StatusNote(status: data.status),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.invalidate(anakAttemptStatusProvider((siswaId, id))),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Periksa Lagi'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(String status) {
    switch (status) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'pending':
      case 'created':
        return Icons.hourglass_bottom_rounded;
      case 'expired':
        return Icons.timer_off_rounded;
      case 'failed':
        return Icons.error_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final String message;
    switch (status) {
      case 'success':
        message =
            'Pembayaran berhasil dikonfirmasi server dan sudah tercatat '
            'di sistem. Kuitansi tersedia pada menu Riwayat Pembayaran.';
        break;
      case 'pending':
      case 'created':
        message =
            'Menunggu pembayaran diselesaikan melalui Midtrans. '
            'Selesaikan pembayaran lalu periksa kembali status ini.';
        break;
      case 'expired':
        message =
            'Instruksi pembayaran kedaluwarsa. Buat pembayaran baru '
            'dari halaman tagihan.';
        break;
      case 'failed':
        message =
            'Pembayaran gagal. Periksa kembali metode pembayaran Anda '
            'atau buat pembayaran baru.';
        break;
      default:
        message =
            'Status transaksi tidak dikenal. Hubungi admin sekolah '
            'bila berlanjut.';
    }
    return InfoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
