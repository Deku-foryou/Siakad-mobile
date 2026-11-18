import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/wali_providers.dart';
import '../application/wali_tab_index.dart';
import 'anak/wali_anak_page.dart';
import 'beranda/wali_dashboard_page.dart';
import 'keuangan/wali_keuangan_page.dart';
import 'notifikasi/wali_notifikasi_page.dart';
import 'profil/wali_profil_page.dart';

/// Shell utama wali: bottom navigation 5 kelompok
/// (Beranda · Anak · Keuangan · Notifikasi · Profil).
///
/// Tab dipertahankan hidup via IndexedStack. Sub-halaman anak (jadwal,
/// absensi, nilai, rapor, detail) dibuka via router dengan `:siswaId`
/// eksplisit — konteks anak tidak pernah ambigu.
class WaliShell extends ConsumerWidget {
  const WaliShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(waliTabIndexProvider);
    final unread = ref.watch(waliUnreadCountProvider).value ?? 0;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          WaliDashboardPage(),
          WaliAnakPage(),
          WaliKeuanganPage(),
          WaliNotifikasiPage(),
          WaliProfilPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(waliTabIndexProvider.notifier).set(i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.family_restroom_outlined),
            selectedIcon: Icon(Icons.family_restroom_rounded),
            label: 'Anak',
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
