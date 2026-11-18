import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/features/auth/application/auth_controller.dart';
import 'package:siakad_mobile/features/auth/application/auth_state.dart';
import 'package:siakad_mobile/features/guru/application/guru_tab_index.dart';
import 'package:siakad_mobile/features/siswa/application/siswa_tab_index.dart';
import 'package:siakad_mobile/features/wali/application/wali_providers.dart';
import 'package:siakad_mobile/features/wali/application/wali_tab_index.dart';
import 'package:siakad_mobile/shared/application/account_session_reset.dart';

import '../fakes/harness.dart';

/// Pergantian akun setelah logout: state lintas fitur (pilihan anak,
/// indeks tab) di-reset — tidak bocor ke pengguna berikutnya.
void main() {
  test('login wali → logout → state non-autoDispose di-reset', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    // Aktifkan listener reset (di app di-watch oleh SiakadApp).
    h.container.read(accountSessionResetProvider);

    h.adapter.respondJson(200, loginSuccessBody(role: 'wali'));
    await h.container
        .read(authStateProvider.notifier)
        .login(username: 'wali01', password: 'rahasia');
    expect(
      h.container.read(authStateProvider).status,
      AuthStatus.authenticated,
    );

    // Simulasikan kondisi "tertinggal" pengguna sebelumnya.
    h.container.read(waliTabIndexProvider.notifier).set(3);
    h.container.read(selectedAnakIdProvider.notifier).set(201);
    h.container.read(siswaTabIndexProvider.notifier).set(3);
    h.container.read(guruTabIndexProvider.notifier).set(4);
    expect(h.container.read(waliTabIndexProvider), 3);
    expect(h.container.read(selectedAnakIdProvider), 201);

    // Logout (mock jaringan sukses).
    h.adapter.respondJson(200, {
      'success': true,
      'message': 'Berhasil logout.',
      'data': null,
    });
    await h.container.read(authStateProvider.notifier).logout();

    expect(h.container.read(waliTabIndexProvider), 0);
    expect(h.container.read(siswaTabIndexProvider), 0);
    expect(h.container.read(guruTabIndexProvider), 0);
    expect(h.container.read(selectedAnakIdProvider), isNull);
  });
}
