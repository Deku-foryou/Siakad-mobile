import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/errors/api_exception.dart';
import 'package:siakad_mobile/features/auth/application/auth_controller.dart';
import 'package:siakad_mobile/features/auth/application/auth_state.dart';
import 'package:siakad_mobile/features/wali/application/wali_providers.dart';

import '../../fakes/harness.dart';

/// 401 di TENGAH sesi (bukan di splash/restore): interceptor membersihkan
/// token + memberi sinyal; AuthController menutup sesi (state →
/// unauthenticated) tanpa menunggu restore.
void main() {
  test('401 mid-session menutup sesi & memunculkan notice', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    // Login sebagai wali (role diizinkan).
    h.adapter.respondJson(200, loginSuccessBody(role: 'wali'));
    await h.container
        .read(authStateProvider.notifier)
        .login(username: 'wali01', password: 'rahasia');
    expect(
      h.container.read(authStateProvider).status,
      AuthStatus.authenticated,
    );

    // Request berikutnya dijawab 401 (token dicabut di server).
    h.adapter.respondJson(401, {
      'success': false,
      'message': 'Unauthenticated.',
      'code': 'UNAUTHENTICATED',
    });

    await expectLater(
      () => h.container.read(waliRepositoryProvider).unreadCount(),
      throwsA(isA<ApiException>()),
    );
    await pumpMicrotasks();

    final state = h.container.read(authStateProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.notice, 'Sesi Anda telah berakhir. Silakan login kembali.');
    // Token lokal dibersihkan.
    expect(await h.store.read('siakad.auth_token'), isNull);
  });

  test(
    '401 bersamaan dari beberapa request: sesi ditutup sekali, tanpa duplikasi',
    () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);

      h.adapter.respondJson(200, loginSuccessBody(role: 'wali'));
      await h.container
          .read(authStateProvider.notifier)
          .login(username: 'wali01', password: 'rahasia');
      expect(
        h.container.read(authStateProvider).status,
        AuthStatus.authenticated,
      );

      // Dua request konkuren menjawab 401 dari server.
      h.adapter.respondJson(401, {
        'success': false,
        'message': 'Unauthenticated.',
        'code': 'UNAUTHENTICATED',
      });
      h.adapter.respondJson(401, {
        'success': false,
        'message': 'Unauthenticated.',
        'code': 'UNAUTHENTICATED',
      });

      final results = await Future.wait<void>([
        h.container
            .read(waliRepositoryProvider)
            .unreadCount()
            .then((_) {}, onError: (_) {}),
        h.container
            .read(waliRepositoryProvider)
            .unreadCount()
            .then((_) {}, onError: (_) {}),
      ]);
      expect(results, hasLength(2));
      await pumpMicrotasks();

      final state = h.container.read(authStateProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.notice, 'Sesi Anda telah berakhir. Silakan login kembali.');
      expect(await h.store.read('siakad.auth_token'), isNull);
    },
  );

  test(
    'logout membersihkan sesi (mock) & state menjadi unauthenticated',
    () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);

      h.adapter.respondJson(200, loginSuccessBody(role: 'wali'));
      await h.container
          .read(authStateProvider.notifier)
          .login(username: 'wali01', password: 'rahasia');
      expect(
        h.container.read(authStateProvider).status,
        AuthStatus.authenticated,
      );

      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil logout.',
        'data': null,
      });
      await h.container.read(authStateProvider.notifier).logout();

      expect(
        h.container.read(authStateProvider).status,
        AuthStatus.unauthenticated,
      );
      expect(await h.store.read('siakad.auth_token'), isNull);
    },
  );
}
