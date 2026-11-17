import 'package:flutter/material.dart';

import '../../../shared/widgets/role_placeholder_page.dart';

class WaliHomePage extends StatelessWidget {
  const WaliHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderPage(
      roleLabel: 'Wali Murid',
      roleIcon: Icons.family_restroom_rounded,
      description:
          'Data anak, jadwal, absensi, nilai, rapor, dan pengajuan '
          'penghentian relasi akan tersedia di tahap berikutnya.',
    );
  }
}
