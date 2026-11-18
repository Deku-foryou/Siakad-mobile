import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../../core/widgets/app_widgets.dart';

/// Label & warna status relasi wali↔anak (dari backend).
class RelasiStatus {
  const RelasiStatus._();

  static String label(String status) {
    switch (status) {
      case 'verified':
        return 'Terverifikasi';
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'rejected':
        return 'Ditolak';
      case 'terminated':
        return 'Berakhir';
      default:
        return status.isEmpty ? 'Tidak Diketahui' : status;
    }
  }

  static Color? color(String status) {
    switch (status) {
      case 'verified':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
      case 'terminated':
        return AppColors.error;
      default:
        return null;
    }
  }

  static Widget badge(String status) =>
      StatusBadge(label: label(status), color: color(status));
}

/// Banner penjelasan untuk relasi yang belum/tidak memberi akses akademik.
class RelasiTerkunciBanner extends StatelessWidget {
  const RelasiTerkunciBanner({super.key, required this.statusHubungan});

  final String statusHubungan;

  String get _message {
    switch (statusHubungan) {
      case 'pending':
        return 'Hubungan Anda dengan anak ini sedang menunggu verifikasi '
            'admin sekolah. Data akademik dan keuangan belum dapat diakses.';
      case 'rejected':
        return 'Pengajuan hubungan dengan anak ini ditolak admin sekolah. '
            'Data akademik dan keuangan tidak dapat diakses.';
      case 'terminated':
        return 'Hubungan dengan anak ini telah berakhir. Data akademik dan '
            'keuangan tidak dapat diakses.';
      default:
        return 'Akses akademik dan keuangan tidak tersedia untuk hubungan '
            'ini (belum memenuhi syarat periode akses).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
