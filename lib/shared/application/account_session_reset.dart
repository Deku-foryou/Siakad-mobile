import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/guru/application/guru_tab_index.dart';
import '../../features/siswa/application/siswa_tab_index.dart';
import '../../features/wali/application/wali_providers.dart';
import '../../features/wali/application/wali_tab_index.dart';

/// Reset state lintas fitur saat sesi berakhir (logout / 401 / gagal ganti
/// password) sehingga state pengguna lama tidak bocor ke pengguna berikutnya
/// pada perangkat yang sama ("pergantian akun setelah logout").
///
/// Yang di-reset adalah state NON-autoDispose yang bisa bertahan melewati
/// navigasi: pilihan anak terpilih (wali) dan indeks tab aktif (3 role).
/// Provider data (autoDispose) dibuang otomatis saat layar lama dilepas.
final accountSessionResetProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (previous, next) {
    final becameUnauthenticated =
        next.status == AuthStatus.unauthenticated &&
        previous?.status != AuthStatus.unauthenticated;
    if (!becameUnauthenticated) return;
    ref.invalidate(selectedAnakIdProvider);
    ref.invalidate(siswaTabIndexProvider);
    ref.invalidate(guruTabIndexProvider);
    ref.invalidate(waliTabIndexProvider);
  });
});
