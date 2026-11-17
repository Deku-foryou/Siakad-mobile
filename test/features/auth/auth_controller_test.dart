import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/storage/secure_storage_service.dart';
import 'package:siakad_mobile/features/auth/application/auth_controller.dart';
import 'package:siakad_mobile/features/auth/application/auth_state.dart';

import '../../fakes/harness.dart';

void main() {
  test('tanpa token tersimpan -> unauthenticated setelah restore', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    // Akses provider memicu build() -> microtask restoreSession.
    h.container.read(authStateProvider);
    await pumpMicrotasks();

    expect(
      h.container.read(authStateProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(h.adapter.requests, isEmpty);
  });

  test(
    'token valid -> authenticated (session restoration via /auth/me)',
    () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);

      await SecureStorageService(h.store).saveToken('1|tokenvalid');
      h.adapter.respondJson(200, meSuccessBody());

      h.container.read(authStateProvider);
      await pumpMicrotasks();

      final state = h.container.read(authStateProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.username, 'siswa01');
      expect(state.user?.level, 'siswa');
      expect(h.adapter.requests.single.path, '/auth/me');
      // Header Authorization ada pada request /auth/me.
      expect(
        h.adapter.requests.single.headers['Authorization'],
        'Bearer 1|tokenvalid',
      );
      // wajib_ganti_password false diteruskan.
      expect(state.wajibGantiPassword, isFalse);
    },
  );

  test('wajib_ganti_password=true dipulihkan dari /auth/me', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    await SecureStorageService(h.store).saveToken('1|tokenvalid');
    h.adapter.respondJson(200, meSuccessBody(wajibGantiPassword: true));

    h.container.read(authStateProvider);
    await pumpMicrotasks();

    final state = h.container.read(authStateProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.wajibGantiPassword, isTrue);
  });

  test('401 saat restore -> sesi lokal dibersihkan, unauthenticated', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    final storage = SecureStorageService(h.store);
    await storage.saveToken('1|tokenmati');
    h.adapter.respondJson(401, {
      'success': false,
      'message': 'Belum terautentikasi atau token tidak valid.',
      'code': 'UNAUTHENTICATED',
    });

    h.container.read(authStateProvider);
    await pumpMicrotasks();

    final state = h.container.read(authStateProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(await storage.readToken(), isNull);
  });

  test(
    'error jaringan saat restore -> sessionCheckFailed, token dipertahankan',
    () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);

      final storage = SecureStorageService(h.store);
      await storage.saveToken('1|tokenvalid');
      h.adapter.error = Exception('network down');

      h.container.read(authStateProvider);
      await pumpMicrotasks();

      final state = h.container.read(authStateProvider);
      expect(state.status, AuthStatus.sessionCheckFailed);
      expect(await storage.readToken(), '1|tokenvalid');
    },
  );

  test('login sukses -> token tersimpan, authenticated', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    h.container.read(authStateProvider);
    await pumpMicrotasks();

    h.adapter.respondJson(200, loginSuccessBody());
    await h.container
        .read(authStateProvider.notifier)
        .login(username: 'Siswa01 ', password: 'rahasia');

    final state = h.container.read(authStateProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.level, 'siswa');
    expect(state.isSubmitting, isFalse);
    expect(await SecureStorageService(h.store).readToken(), '1|testtoken123');
    // Request login: username dinormalisasi (trim+lowercase), device_name terkirim.
    final request = h.adapter.requests.single;
    expect(request.path, '/auth/login');
    expect((request.data as Map)['username'], 'siswa01');
    expect((request.data as Map)['device_name'], isNotEmpty);
  });

  test(
    'login gagal 401 INVALID_CREDENTIALS -> error, tidak authenticated',
    () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);

      h.container.read(authStateProvider);
      await pumpMicrotasks();

      h.adapter.respondJson(401, {
        'success': false,
        'message': 'Username atau password salah.',
        'code': 'INVALID_CREDENTIALS',
      });
      await h.container
          .read(authStateProvider.notifier)
          .login(username: 'siswa01', password: 'salah');

      final state = h.container.read(authStateProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.errorMessage, 'Username atau password salah.');
      expect(await SecureStorageService(h.store).readToken(), isNull);
    },
  );

  test('login 422 validation -> fieldErrors terpetakan', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    h.container.read(authStateProvider);
    await pumpMicrotasks();

    h.adapter.respondJson(422, {
      'success': false,
      'message': 'Validasi gagal.',
      'errors': {
        'password': ['Password wajib diisi.'],
      },
    });
    await h.container
        .read(authStateProvider.notifier)
        .login(username: 'siswa01', password: '');

    final state = h.container.read(authStateProvider);
    expect(state.errorMessage, 'Validasi gagal.');
    expect(state.fieldErrors['password'], ['Password wajib diisi.']);
  });

  test('logout -> token lokal dihapus, unauthenticated', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    final storage = SecureStorageService(h.store);
    await storage.saveToken('1|tokenvalid');
    h.adapter.respondJson(200, meSuccessBody());
    h.container.read(authStateProvider);
    await pumpMicrotasks();
    expect(
      h.container.read(authStateProvider).status,
      AuthStatus.authenticated,
    );

    h.adapter.respondJson(200, {
      'success': true,
      'message': 'Logout berhasil',
      'data': null,
    });
    await h.container.read(authStateProvider.notifier).logout();

    expect(
      h.container.read(authStateProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(await storage.readToken(), isNull);
    expect(h.adapter.requests.last.path, '/auth/logout');
  });

  test('logout-all -> token lokal dihapus, notice tersimpan', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    final storage = SecureStorageService(h.store);
    await storage.saveToken('1|tokenvalid');
    h.adapter.respondJson(200, meSuccessBody());
    h.container.read(authStateProvider);
    await pumpMicrotasks();

    h.adapter.respondJson(200, {
      'success': true,
      'message': 'Seluruh perangkat telah logout. Silakan login kembali.',
      'data': null,
    });
    await h.container.read(authStateProvider.notifier).logoutAll();

    final state = h.container.read(authStateProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.notice, contains('Seluruh perangkat'));
    expect(await storage.readToken(), isNull);
    expect(h.adapter.requests.last.path, '/auth/logout-all');
  });

  test('logout tetap membersihkan sesi lokal walau server gagal', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    final storage = SecureStorageService(h.store);
    await storage.saveToken('1|tokenvalid');
    h.adapter.respondJson(200, meSuccessBody());
    h.container.read(authStateProvider);
    await pumpMicrotasks();

    h.adapter.error = Exception('network down');
    await h.container.read(authStateProvider.notifier).logout();

    expect(
      h.container.read(authStateProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(await storage.readToken(), isNull);
  });

  test(
    'changePassword sukses -> sesi dibersihkan, wajib login ulang',
    () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);

      final storage = SecureStorageService(h.store);
      await storage.saveToken('1|tokenvalid');
      h.adapter.respondJson(200, meSuccessBody(wajibGantiPassword: true));
      h.container.read(authStateProvider);
      await pumpMicrotasks();
      expect(h.container.read(authStateProvider).wajibGantiPassword, isTrue);

      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Password berhasil diubah. Silakan login kembali.',
        'data': null,
      });
      final ok = await h.container
          .read(authStateProvider.notifier)
          .changePassword(
            currentPassword: 'lama123',
            newPassword: 'baru12345',
            confirmation: 'baru12345',
          );

      expect(ok, isTrue);
      final state = h.container.read(authStateProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.notice, contains('Password berhasil diubah'));
      expect(await storage.readToken(), isNull);
      expect(h.adapter.requests.last.path, '/auth/password');
      expect(
        (h.adapter.requests.last.data as Map)['password_confirmation'],
        'baru12345',
      );
    },
  );

  test('changePassword 422 -> errorMessage & fieldErrors terisi', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    final storage = SecureStorageService(h.store);
    await storage.saveToken('1|tokenvalid');
    h.adapter.respondJson(200, meSuccessBody());
    h.container.read(authStateProvider);
    await pumpMicrotasks();

    h.adapter.respondJson(422, {
      'success': false,
      'message': 'Validasi gagal.',
      'errors': {
        'current_password': ['Password saat ini salah.'],
      },
    });
    final ok = await h.container
        .read(authStateProvider.notifier)
        .changePassword(
          currentPassword: 'salah',
          newPassword: 'baru12345',
          confirmation: 'baru12345',
        );

    expect(ok, isFalse);
    final state = h.container.read(authStateProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.fieldErrors['current_password'], ['Password saat ini salah.']);
    expect(await storage.readToken(), '1|tokenvalid');
  });

  test(
    'login dengan role tidak dikenal -> sesi ditolak & dibersihkan',
    () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);

      h.container.read(authStateProvider);
      await pumpMicrotasks();

      h.adapter.respondJson(200, loginSuccessBody(role: 'admin'));
      final storage = SecureStorageService(h.store);
      await h.container
          .read(authStateProvider.notifier)
          .login(username: 'admin01', password: 'rahasia');

      final state = h.container.read(authStateProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.errorCode, 'ROLE_NOT_ALLOWED');
      expect(state.errorMessage, contains('siswa, guru, dan wali'));
      expect(await storage.readToken(), isNull); // token tidak tersimpan
    },
  );

  test(
    'restore dengan role tidak dikenal -> sesi ditolak & dibersihkan',
    () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);

      final storage = SecureStorageService(h.store);
      await storage.saveToken('1|tokenvalid');
      h.adapter.respondJson(200, meSuccessBody(role: 'walikelas'));

      h.container.read(authStateProvider);
      await pumpMicrotasks();

      final state = h.container.read(authStateProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.errorCode, 'ROLE_NOT_ALLOWED');
      expect(await storage.readToken(), isNull);
    },
  );

  test(
    'restore error ACCOUNT_INACTIVE -> sesi dibersihkan dengan notice',
    () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);

      final storage = SecureStorageService(h.store);
      await storage.saveToken('1|tokenvalid');
      h.adapter.respondJson(403, {
        'success': false,
        'message': 'Akun tidak dapat digunakan. Hubungi admin sekolah.',
        'code': 'ACCOUNT_INACTIVE',
      });

      h.container.read(authStateProvider);
      await pumpMicrotasks();

      final state = h.container.read(authStateProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.notice, contains('Akun tidak dapat digunakan'));
      expect(await storage.readToken(), isNull);
    },
  );

  test('restore 401 -> notice sesi berakhir', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    final storage = SecureStorageService(h.store);
    await storage.saveToken('1|tokenvalid');
    h.adapter.respondJson(401, {
      'success': false,
      'message': 'Belum terautentikasi atau token tidak valid.',
      'code': 'UNAUTHENTICATED',
    });

    h.container.read(authStateProvider);
    await pumpMicrotasks();

    final state = h.container.read(authStateProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.notice, contains('Sesi Anda telah berakhir'));
    expect(await storage.readToken(), isNull);
  });

  test('login double-submit hanya mengirim satu request', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    h.container.read(authStateProvider);
    await pumpMicrotasks();

    h.adapter.respondJson(200, loginSuccessBody());
    final notifier = h.container.read(authStateProvider.notifier);
    final first = notifier.login(username: 'siswa01', password: 'rahasia');
    final second = notifier.login(username: 'siswa01', password: 'rahasia');
    await Future.wait([first, second]);

    expect(
      h.adapter.requests.where((r) => r.path == '/auth/login'),
      hasLength(1),
    );
    expect(
      h.container.read(authStateProvider).status,
      AuthStatus.authenticated,
    );
  });

  test('login 429 menampilkan pesan ramah rate limit', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    h.container.read(authStateProvider);
    await pumpMicrotasks();

    h.adapter.respondJson(429, {
      'success': false,
      'message': 'Terlalu banyak percobaan. Coba lagi nanti.',
      'code': 'TOO_MANY_REQUESTS',
    });
    await h.container
        .read(authStateProvider.notifier)
        .login(username: 'siswa01', password: 'rahasia');

    final state = h.container.read(authStateProvider);
    expect(state.errorCode, 'TOO_MANY_REQUESTS');
    expect(state.errorMessage, contains('Terlalu banyak'));
  });

  test('login 403 ROLE_NOT_ALLOWED menampilkan pesan akses mobile', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    h.container.read(authStateProvider);
    await pumpMicrotasks();

    h.adapter.respondJson(403, {
      'success': false,
      'message': 'Akses ditolak untuk role ini.',
      'code': 'ROLE_NOT_ALLOWED',
    });
    await h.container
        .read(authStateProvider.notifier)
        .login(username: 'admin01', password: 'rahasia');

    final state = h.container.read(authStateProvider);
    expect(state.errorCode, 'ROLE_NOT_ALLOWED');
    expect(state.errorMessage, contains('siswa, guru, dan wali'));
  });

  test('restoreSession paralel tidak menghasilkan dua /auth/me', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    final storage = SecureStorageService(h.store);
    await storage.saveToken('1|tokenvalid');
    h.adapter.respondJson(200, meSuccessBody());

    final notifier = h.container.read(authStateProvider.notifier);
    await Future.wait([notifier.restoreSession(), notifier.restoreSession()]);

    expect(
      h.adapter.requests.where((r) => r.path == '/auth/me').length,
      lessThanOrEqualTo(1),
    );
  });

  test(
    'login 401 TIDAK menghapus token yang sudah ada (guard interceptor)',
    () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);

      final storage = SecureStorageService(h.store);
      await storage.saveToken('1|tokenvalid');
      h.adapter.error = Exception('network down'); // paksa sessionCheckFailed
      h.container.read(authStateProvider);
      await pumpMicrotasks();
      expect(
        h.container.read(authStateProvider).status,
        AuthStatus.sessionCheckFailed,
      );

      // Login gagal (401 INVALID_CREDENTIALS): token tersimpan tidak boleh terhapus.
      h.adapter.error = null;
      h.adapter.respondJson(401, {
        'success': false,
        'message': 'Username atau password salah.',
        'code': 'INVALID_CREDENTIALS',
      });
      await h.container
          .read(authStateProvider.notifier)
          .login(username: 'siswa01', password: 'salah');

      expect(await storage.readToken(), '1|tokenvalid');
    },
  );

  test('logout 401 dari server tetap membersihkan sesi lokal', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    final storage = SecureStorageService(h.store);
    await storage.saveToken('1|tokenvalid');
    h.adapter.respondJson(200, meSuccessBody());
    h.container.read(authStateProvider);
    await pumpMicrotasks();

    h.adapter.respondJson(401, {
      'success': false,
      'message': 'Belum terautentikasi atau token tidak valid.',
      'code': 'UNAUTHENTICATED',
    });
    await h.container.read(authStateProvider.notifier).logout();

    expect(
      h.container.read(authStateProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(await storage.readToken(), isNull);
  });
  test('changePassword 401 (token dicabut dari perangkat lain) -> sesi dibersihkan', () async {
    final h = buildTestHarness();
    addTearDown(h.container.dispose);

    final storage = SecureStorageService(h.store);
    await storage.saveToken('1|tokenvalid');
    h.adapter.respondJson(200, meSuccessBody());
    h.container.read(authStateProvider);
    await pumpMicrotasks();

    h.adapter.respondJson(401, {
      'success': false,
      'message': 'Belum terautentikasi atau token tidak valid.',
      'code': 'UNAUTHENTICATED',
    });
    final ok = await h.container
        .read(authStateProvider.notifier)
        .changePassword(
          currentPassword: 'lama123',
          newPassword: 'baru12345',
          confirmation: 'baru12345',
        );

    expect(ok, isFalse);
    expect(
      h.container.read(authStateProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(await storage.readToken(), isNull);
  });
}
