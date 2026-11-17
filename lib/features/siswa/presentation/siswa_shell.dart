import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/siswa_providers.dart';
import '../application/siswa_tab_index.dart';
import 'akademik/siswa_akademik_page.dart';
import 'beranda/siswa_dashboard_page.dart';
import 'keuangan/siswa_keuangan_page.dart';
import 'notifikasi/siswa_notifikasi_page.dart';
import 'profil/siswa_profil_page.dart';

/// Shell utama siswa: bottom navigation dengan 5 kelompok.
///
/// Tab dipertahankan hidup via IndexedStack agar state/scroll tidak hilang.
/// Sub-halaman dibuka via router (menutupi shell).
class SiswaShell extends ConsumerWidget {
  const SiswaShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(siswaTabIndexProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          SiswaDashboardPage(),
          SiswaAkademikPage(),
          SiswaKeuanganPage(),
          SiswaNotifikasiPage(),
          SiswaProfilPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(siswaTabIndexProvider.notifier).set(i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Akademik',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Keuangan',
          ),
          NavigationDestination(
            icon: _BadgeIcon(
              icon: Icons.notifications_none_rounded,
              count: unread,
            ),
            selectedIcon: _BadgeIcon(
              icon: Icons.notifications_rounded,
              count: unread,
            ),
            label: 'Notifikasi',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Icon(icon);
    return Badge(label: Text(count > 99 ? '99+' : '$count'), child: Icon(icon));
  }
}
