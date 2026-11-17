import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/errors/api_exception.dart';
import 'package:siakad_mobile/shared/providers/core_providers.dart';

import '../../fakes/harness.dart';

void main() {
  group('login', () {
    test('sukses: token, role, dan wajib_ganti_password terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, loginSuccessBody());

      final repo = h.container.read(authRepositoryProvider);
      final session = await repo.login(
        username: 'Siswa01 ',
        password: 'rahasia',
        deviceName: 'Flutter Android',
      );

      expect(session.token, '1|testtoken123');
      expect(session.tokenType, 'Bearer');
      expect(session.user.level, 'siswa');
      expect(session.wajibGantiPassword, isFalse);
      expect(session.expiresAt, isNotNull);
    });

    test('username dikirim lowercase + trim', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, loginSuccessBody());

      final repo = h.container.read(authRepositoryProvider);
      await repo.login(
        username: '  Siswa01  ',
        password: 'rahasia',
        deviceName: 'Flutter Android',
      );

      final request = h.adapter.requests.single;
      expect((request.data as Map)['username'], 'siswa01');
    });

    test('device_name dikirim apa adanya', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, loginSuccessBody());

      final repo = h.container.read(authRepositoryProvider);
      await repo.login(
        username: 'siswa01',
        password: 'rahasia',
        deviceName: 'Deku Android',
      );

      final request = h.adapter.requests.single;
      expect((request.data as Map)['device_name'], 'Deku Android');
    });

    test('kredensial salah: 401 INVALID_CREDENTIALS, pesan generik', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(401, {
        'success': false,
        'message': 'Username atau password salah.',
        'code': 'INVALID_CREDENTIALS',
      });

      final repo = h.container.read(authRepositoryProvider);
      try {
        await repo.login(
          username: 'siswa01',
          password: 'salah',
          deviceName: 'Flutter Android',
        );
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.isUnauthorized, isTrue);
        expect(e.code, 'INVALID_CREDENTIALS');
        expect(e.message, 'Username atau password salah.');
      }
    });

    test('akun nonaktif: 403 ACCOUNT_INACTIVE', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(403, {
        'success': false,
        'message': 'Akun tidak dapat digunakan. Hubungi admin sekolah.',
        'code': 'ACCOUNT_INACTIVE',
      });

      final repo = h.container.read(authRepositoryProvider);
      try {
        await repo.login(
          username: 'siswa01',
          password: 'rahasia',
          deviceName: 'Flutter Android',
        );
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.isAccountInactive, isTrue);
        expect(e.statusCode, 403);
      }
    });

    test('role tidak diizinkan: 403 ROLE_NOT_ALLOWED', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(403, {
        'success': false,
        'message': 'Akses ditolak untuk role ini.',
        'code': 'ROLE_NOT_ALLOWED',
      });

      final repo = h.container.read(authRepositoryProvider);
      try {
        await repo.login(
          username: 'admin01',
          password: 'rahasia',
          deviceName: 'Flutter Android',
        );
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.isRoleNotAllowed, isTrue);
      }
    });

    test('rate limit: 429 TOO_MANY_REQUESTS', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(429, {
        'success': false,
        'message': 'Terlalu banyak percobaan. Coba lagi nanti.',
        'code': 'TOO_MANY_REQUESTS',
      });

      final repo = h.container.read(authRepositoryProvider);
      try {
        await repo.login(
          username: 'siswa01',
          password: 'rahasia',
          deviceName: 'Flutter Android',
        );
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.isRateLimited, isTrue);
        expect(e.code, 'TOO_MANY_REQUESTS');
      }
    });

    test('422 tanpa code: errors map dipakai, code null', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(422, {
        'success': false,
        'message': 'Validasi gagal.',
        'errors': {
          'password': ['Password wajib diisi.'],
        },
      });

      final repo = h.container.read(authRepositoryProvider);
      try {
        await repo.login(
          username: 'siswa01',
          password: '',
          deviceName: 'Flutter Android',
        );
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.isValidation, isTrue);
        expect(e.code, isNull);
        expect(e.fieldErrors['password'], ['Password wajib diisi.']);
      }
    });
  });

  group('me', () {
    test('sukses: user dan metadata token terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, meSuccessBody());

      final repo = h.container.read(authRepositoryProvider);
      final me = await repo.me();

      expect(me.user.username, 'siswa01');
      expect(me.user.level, 'siswa');
      expect(me.tokenName, 'Flutter Android');
      expect(me.tokenExpiresAt, isNotNull);
    });

    test('401: ApiException unauthorized', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(401, {
        'success': false,
        'message': 'Belum terautentikasi atau token tidak valid.',
        'code': 'UNAUTHENTICATED',
      });

      final repo = h.container.read(authRepositoryProvider);
      try {
        await repo.me();
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.isUnauthorized, isTrue);
      }
    });
  });

  group('logout & password', () {
    test('logout perangkat ini', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Logout berhasil',
        'data': null,
      });

      final repo = h.container.read(authRepositoryProvider);
      await expectLater(repo.logout(), completes);
      expect(h.adapter.requests.single.path, '/auth/logout');
    });

    test('logout semua perangkat', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Seluruh perangkat telah logout.',
        'data': null,
      });

      final repo = h.container.read(authRepositoryProvider);
      await expectLater(repo.logoutAll(), completes);
      expect(h.adapter.requests.single.path, '/auth/logout-all');
    });

    test('ganti password sukses', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Password berhasil diubah. Silakan login kembali.',
        'data': null,
      });

      final repo = h.container.read(authRepositoryProvider);
      await expectLater(
        repo.changePassword(
          currentPassword: 'lama123',
          newPassword: 'baru12345',
          confirmation: 'baru12345',
        ),
        completes,
      );
      final request = h.adapter.requests.single;
      expect(request.path, '/auth/password');
      expect((request.data as Map)['current_password'], 'lama123');
      expect((request.data as Map)['password_confirmation'], 'baru12345');
    });

    test('ganti password gagal (password lama salah)', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(422, {
        'success': false,
        'message': 'Validasi gagal.',
        'errors': {
          'current_password': ['Password saat ini salah.'],
        },
      });

      final repo = h.container.read(authRepositoryProvider);
      try {
        await repo.changePassword(
          currentPassword: 'salah',
          newPassword: 'baru12345',
          confirmation: 'baru12345',
        );
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.isValidation, isTrue);
        expect(e.fieldErrors['current_password'], ['Password saat ini salah.']);
      }
    });
  });
}
