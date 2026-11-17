import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AsyncValueView — merender loading / error / data dari AsyncValue
/// secara konsisten, dengan aksi retry.
///
/// [onRetry] dipanggil saat user menekan "Coba Lagi"; [isEmpty] mendeteksi
/// data kosong; [empty] adalah widget empty state bila kosong.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.isEmpty,
    this.empty,
    this.loadingMessage,
    this.errorPrefix = 'Gagal memuat data',
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final String? loadingMessage;
  final String errorPrefix;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (loadingMessage != null) ...[
                const SizedBox(height: 16),
                Text(loadingMessage!, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
      error: (error, _) => _ErrorBlock(
        message: '$errorPrefix.\n${errorMessage(error)}',
        onRetry: onRetry,
      ),
      data: (dataValue) {
        if (isEmpty != null && isEmpty!(dataValue)) {
          return empty ?? const SizedBox.shrink();
        }
        return data(dataValue);
      },
    );
  }

  static String errorMessage(Object error) {
    final text = error.toString();
    // ApiException sudah membawa pesan yang aman ditampilkan; buang prefix "ApiException(...)".
    final match = RegExp(r'message: (.*?)\)$').firstMatch(text);
    if (match != null) return match.group(1) ?? text;
    return text;
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Header section dengan judul, subtitle opsional, dan aksi opsional.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (action != null) ?action,
        ],
      ),
    );
  }
}

/// Badge status berwarna dengan label, mis. absensi / status tagihan.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badgeColor = color ?? scheme.secondaryContainer;
    final onColor =
        ThemeData.estimateBrightnessForColor(badgeColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onColor,
        ),
      ),
    );
  }

  /// Label Indonesia untuk status backend yang dikenal; lainnya tampil apa adanya.
  static String labelOf(String status) {
    switch (status) {
      case 'hadir':
        return 'Hadir';
      case 'sakit':
        return 'Sakit';
      case 'izin':
        return 'Izin';
      case 'alpha':
        return 'Alpha';
      case 'belum_dibayar':
        return 'Belum Dibayar';
      case 'dibayar_sebagian':
        return 'Dibayar Sebagian';
      case 'lunas':
        return 'Lunas';
      case 'dibebaskan':
        return 'Dibebaskan';
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'created':
        return 'Dibuat';
      case 'pending':
        return 'Menunggu';
      case 'success':
        return 'Berhasil';
      case 'failed':
        return 'Gagal';
      case 'expired':
        return 'Kedaluwarsa';
      default:
        return status;
    }
  }

  /// Warna konsisten untuk status absensi/tagihan/pembayaran yang umum.
  static Color? forStatus(String status) {
    switch (status) {
      case 'hadir':
      case 'lunas':
      case 'success':
      case 'dibebaskan':
        return const Color(0xFF15803D);
      case 'sakit':
      case 'izin':
      case 'pending':
      case 'belum_dibayar':
        return const Color(0xFFB45309);
      case 'alpha':
      case 'failed':
      case 'dibatalkan':
        return const Color(0xFFB91C1C);
      case 'created':
      case 'dibayar_sebagian':
        return const Color(0xFF1D4ED8);
      case 'expired':
        return const Color(0xFF6B7280);
      default:
        return null;
    }
  }
}

/// Baris info label→nilai yang nyaman dibaca.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu container sederhana (elevation 0, border tipis).
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}

/// Kartu menu aksi dengan ikon + judul + subtitle (untuk akademik/keuangan).
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.onSecondaryContainer),
              ),
              const SizedBox(height: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton sederhana (placeholder loading) berupa container abu-abu.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.height = 16, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
