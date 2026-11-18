import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index tab aktif di shell wali:
/// 0 Beranda · 1 Anak · 2 Keuangan · 3 Notifikasi · 4 Profil.
class WaliTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

final waliTabIndexProvider = NotifierProvider<WaliTabIndex, int>(
  WaliTabIndex.new,
);
