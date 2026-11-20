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
              _MenuGrid(
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

/// Grid 2 kolom tanpa fixed aspect ratio.
///
/// Setiap kartu diukur berdasarkan konten (`IntrinsicHeight`) sehingga
/// teks yang lebih panjang (mis. saat text scaling 1.5/2.0) tidak pernah
/// menghasilkan `RenderFlex overflow`; tinggi seluruh kartu dalam satu
/// baris tetap konsisten.
class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        children.sublist(i, i + 2 > children.length ? children.length : i + 2),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - AppSpacing.xs) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: halfWidth, child: rows[r][0]),
                    SizedBox(width: AppSpacing.xs),
                    if (rows[r].length > 1)
                      SizedBox(width: halfWidth, child: rows[r][1])
                    else
                      SizedBox(width: halfWidth),
                  ],
                ),
              ),
              if (r != rows.length - 1) const SizedBox(height: AppSpacing.xs),
            ],
          ],
        );
      },
    );
  }
}
