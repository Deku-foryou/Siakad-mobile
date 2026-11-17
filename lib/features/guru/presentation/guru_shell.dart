import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/guru_tab_index.dart';
import 'absensi/guru_absensi_page.dart';
import 'penilaian/guru_penilaian_page.dart';
import 'beranda/guru_dashboard_page.dart';
import 'kelas/guru_kelas_page.dart';
import 'profil/guru_profil_page.dart';

/// Shell utama guru: bottom navigation dengan 5 kelompok.
///
/// Tab dipertahankan hidup via IndexedStack agar state/scroll tidak hilang.
class GuruShell extends ConsumerWidget {
  const GuruShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(guruTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          GuruDashboardPage(),
          GuruKelasPage(),
          GuruAbsensiPage(),
          GuruPenilaianPage(),
          GuruProfilPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(guruTabIndexProvider.notifier).set(i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_rounded),
            label: 'Kelas',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Absensi',
          ),
          NavigationDestination(
            icon: Icon(Icons.grade_outlined),
            selectedIcon: Icon(Icons.grade_rounded),
            label: 'Penilaian',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
