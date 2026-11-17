import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index tab aktif di shell guru:
/// 0 Beranda · 1 Kelas · 2 Absensi · 3 Penilaian · 4 Profil.
class GuruTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

final guruTabIndexProvider = NotifierProvider<GuruTabIndex, int>(
  GuruTabIndex.new,
);
