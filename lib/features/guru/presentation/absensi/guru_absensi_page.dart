import 'package:flutter/material.dart';

import 'harian/guru_absensi_harian_tab.dart';
import 'perjam/guru_absensi_perjam_tab.dart';

/// Tab Absensi guru: Harian (riwayat + isi) dan Per Jam (pertemuan + riwayat).
class GuruAbsensiPage extends StatelessWidget {
  const GuruAbsensiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Absensi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Harian'),
              Tab(text: 'Per Jam'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [GuruAbsensiHarianTab(), GuruAbsensiPerjamTab()],
          ),
        ),
      ),
    );
  }
}
