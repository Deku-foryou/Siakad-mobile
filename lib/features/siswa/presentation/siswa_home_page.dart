import 'package:flutter/material.dart';

import '../../../shared/widgets/role_placeholder_page.dart';

class SiswaHomePage extends StatelessWidget {
  const SiswaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderPage(
      roleLabel: 'Siswa',
      roleIcon: Icons.school_rounded,
      description:
          'Beranda, jadwal, absensi, nilai, rapor, dan pengumuman siswa '
          'akan tersedia di tahap berikutnya.',
    );
  }
}
