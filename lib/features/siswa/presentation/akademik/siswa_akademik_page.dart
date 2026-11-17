import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_widgets.dart';

/// Tab Akademik — menu fitur akademik siswa.
class SiswaAkademikPage extends StatelessWidget {
  const SiswaAkademikPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akademik')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Menu Akademik',
                subtitle: 'Data akademik Anda bersumber dari sistem sekolah.',
              ),
              const SizedBox(height: AppSpacing.xs),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.15,
                children: [
                  MenuCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Jadwal',
                    subtitle: 'Jadwal pelajaran per hari',
                    onTap: () => context.push('/siswa/jadwal'),
                  ),
                  MenuCard(
                    icon: Icons.fact_check_outlined,
                    title: 'Absensi',
                    subtitle: 'Harian, periode, dan per jam',
                    onTap: () => context.push('/siswa/absensi'),
                  ),
                  MenuCard(
                    icon: Icons.grade_rounded,
                    title: 'Nilai',
                    subtitle: 'Nilai akhir rapor final',
                    onTap: () => context.push('/siswa/nilai'),
                  ),
                  MenuCard(
                    icon: Icons.description_rounded,
                    title: 'Rapor',
                    subtitle: 'Daftar dan detail rapor final',
                    onTap: () => context.push('/siswa/rapor'),
                  ),
                  MenuCard(
                    icon: Icons.campaign_rounded,
                    title: 'Pengumuman',
                    subtitle: 'Pengumuman dari sekolah',
                    onTap: () => context.push('/siswa/pengumuman'),
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
