import 'package:flutter/material.dart';

import '../../../shared/widgets/role_placeholder_page.dart';

class GuruHomePage extends StatelessWidget {
  const GuruHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderPage(
      roleLabel: 'Guru',
      roleIcon: Icons.co_present_rounded,
      description:
          'Kelas, jadwal mengajar, absensi siswa, dan penilaian akan '
          'tersedia di tahap berikutnya.',
    );
  }
}
