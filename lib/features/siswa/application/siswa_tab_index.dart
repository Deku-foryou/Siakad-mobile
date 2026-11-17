import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index tab aktif di shell siswa:
/// 0 Beranda · 1 Akademik · 2 Keuangan · 3 Notifikasi · 4 Profil.
class SiswaTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

final siswaTabIndexProvider = NotifierProvider<SiswaTabIndex, int>(
  SiswaTabIndex.new,
);
