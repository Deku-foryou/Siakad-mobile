import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/app/router/app_routes.dart';
import 'package:siakad_mobile/app/router/redirect.dart';
import 'package:siakad_mobile/features/auth/application/auth_state.dart';
import 'package:siakad_mobile/features/auth/data/models/auth_user.dart';

const _siswa = AuthUser(
  id: 1,
  name: 'Siswa Uji',
  username: 'siswa01',
  email: 's@example.test',
  level: 'siswa',
  statusAkun: 'aktif',
  wajibGantiPassword: false,
);

const _guru = AuthUser(
  id: 2,
  name: 'Guru Uji',
  username: 'guru01',
  email: 'g@example.test',
  level: 'guru',
  statusAkun: 'aktif',
  wajibGantiPassword: false,
);

const _wali = AuthUser(
  id: 3,
  name: 'Wali Uji',
  username: 'wali01',
  email: 'w@example.test',
  level: 'wali',
  statusAkun: 'aktif',
  wajibGantiPassword: false,
);

AuthState authenticated(AuthUser user, {bool wajib = false}) => AuthState(
  status: AuthStatus.authenticated,
  user: user,
  wajibGantiPassword: wajib,
);

void main() {
  group('status unknown', () {
    test('tetap di splash', () {
      expect(
        resolveRedirect(const AuthState.unknown(), AppRoutes.splash),
        isNull,
      );
    });
    test('dari /login dialihkan ke splash', () {
      expect(
        resolveRedirect(const AuthState.unknown(), AppRoutes.login),
        AppRoutes.splash,
      );
    });
    test('dari /siswa dialihkan ke splash', () {
      expect(
        resolveRedirect(const AuthState.unknown(), AppRoutes.siswa),
        AppRoutes.splash,
      );
    });
  });

  group('sessionCheckFailed', () {
    const state = AuthState.sessionCheckFailed('tidak bisa memverifikasi');
    test('splash diizinkan (UI retry)', () {
      expect(resolveRedirect(state, AppRoutes.splash), isNull);
    });
    test('login diizinkan (user bisa login ulang)', () {
      expect(resolveRedirect(state, AppRoutes.login), isNull);
    });
    test('halaman internal dialihkan ke splash', () {
      expect(resolveRedirect(state, AppRoutes.siswa), AppRoutes.splash);
    });
  });

  group('unauthenticated', () {
    test('login diizinkan', () {
      expect(
        resolveRedirect(const AuthState.unauthenticated(), AppRoutes.login),
        isNull,
      );
    });
    test('halaman internal dialihkan ke login', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.siswa,
        AppRoutes.guru,
        AppRoutes.wali,
        AppRoutes.changePassword,
      ]) {
        expect(
          resolveRedirect(const AuthState.unauthenticated(), location),
          AppRoutes.login,
          reason: location,
        );
      }
    });
  });

  group('authenticated tanpa wajib ganti password', () {
    test('siswa: /siswa -> null, /guru -> /siswa, /wali -> /siswa', () {
      final s = authenticated(_siswa);
      expect(resolveRedirect(s, AppRoutes.siswa), isNull);
      expect(resolveRedirect(s, AppRoutes.guru), AppRoutes.siswa);
      expect(resolveRedirect(s, AppRoutes.wali), AppRoutes.siswa);
    });

    test('guru: /guru -> null, /siswa -> /guru, /wali -> /guru', () {
      final s = authenticated(_guru);
      expect(resolveRedirect(s, AppRoutes.guru), isNull);
      expect(resolveRedirect(s, AppRoutes.siswa), AppRoutes.guru);
      expect(resolveRedirect(s, AppRoutes.wali), AppRoutes.guru);
    });

    test('wali: /wali -> null, /siswa -> /wali, /guru -> /wali', () {
      final s = authenticated(_wali);
      expect(resolveRedirect(s, AppRoutes.wali), isNull);
      expect(resolveRedirect(s, AppRoutes.siswa), AppRoutes.wali);
      expect(resolveRedirect(s, AppRoutes.guru), AppRoutes.wali);
    });

    test('splash/login/change-password dialihkan ke home role', () {
      expect(
        resolveRedirect(authenticated(_siswa), AppRoutes.splash),
        AppRoutes.siswa,
      );
      expect(
        resolveRedirect(authenticated(_siswa), AppRoutes.login),
        AppRoutes.siswa,
      );
      expect(
        resolveRedirect(authenticated(_siswa), AppRoutes.changePassword),
        AppRoutes.siswa,
      );
      expect(
        resolveRedirect(authenticated(_guru), AppRoutes.splash),
        AppRoutes.guru,
      );
      expect(
        resolveRedirect(authenticated(_wali), AppRoutes.login),
        AppRoutes.wali,
      );
    });
  });

  group('authenticated dengan wajib ganti password', () {
    test('wajib di /change-password dari semua lokasi', () {
      final s = authenticated(_siswa, wajib: true);
      for (final location in [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.siswa,
        AppRoutes.guru,
        AppRoutes.wali,
      ]) {
        expect(
          resolveRedirect(s, location),
          AppRoutes.changePassword,
          reason: location,
        );
      }
    });

    test('/change-password diizinkan (tidak redirect loop)', () {
      expect(
        resolveRedirect(
          authenticated(_guru, wajib: true),
          AppRoutes.changePassword,
        ),
        isNull,
      );
    });

    test('guru wajib ganti password tetap terkunci di change-password', () {
      final s = authenticated(_guru, wajib: true);
      expect(resolveRedirect(s, AppRoutes.guru), AppRoutes.changePassword);
    });
  });

  group('tidak ada redirect loop', () {
    test('semua kombinasi status+lokasi tidak memantul balik', () {
      const locations = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.changePassword,
        AppRoutes.siswa,
        AppRoutes.guru,
        AppRoutes.wali,
      ];
      final states = [
        const AuthState.unknown(),
        const AuthState.unauthenticated(),
        const AuthState.sessionCheckFailed('err'),
        authenticated(_siswa),
        authenticated(_guru),
        authenticated(_wali),
        authenticated(_siswa, wajib: true),
        authenticated(_guru, wajib: true),
        authenticated(_wali, wajib: true),
      ];
      // Titik tetap: hasil redirect, bila diterapkan lagi, stabil (== null
      // atau menunjuk ke lokasi yang juga stabil).
      for (final state in states) {
        for (final location in locations) {
          final first = resolveRedirect(state, location);
          if (first == null) continue;
          final second = resolveRedirect(state, first);
          expect(
            second,
            isNull,
            reason: 'lokasi $location -> $first -> $second tidak stabil',
          );
        }
      }
    });
  });

  group('role tidak dikenal (defense-in-depth)', () {
    const unknown = AuthUser(
      id: 9,
      name: 'Admin Uji',
      username: 'admin01',
      email: 'a@example.test',
      level: 'admin',
      statusAkun: 'aktif',
      wajibGantiPassword: false,
    );

    test('authenticated dengan role tak dikenal dipaksa ke /login', () {
      expect(
        resolveRedirect(authenticated(unknown), AppRoutes.siswa),
        AppRoutes.login,
      );
      expect(
        resolveRedirect(authenticated(unknown), AppRoutes.splash),
        AppRoutes.login,
      );
      expect(
        resolveRedirect(authenticated(unknown), AppRoutes.wali),
        AppRoutes.login,
      );
    });
  });

  group('sub-route area role lain (prefix match)', () {
    test('siswa tidak bisa membuka /guru/*', () {
      expect(
        resolveRedirect(authenticated(_siswa), '/guru/jadwal'),
        AppRoutes.siswa,
      );
      expect(
        resolveRedirect(authenticated(_siswa), '/guru/kelas/1/siswa'),
        AppRoutes.siswa,
      );
      expect(
        resolveRedirect(authenticated(_siswa), '/guru/notifikasi/3'),
        AppRoutes.siswa,
      );
    });

    test('guru tidak bisa membuka /siswa/* maupun /wali/*', () {
      expect(
        resolveRedirect(authenticated(_guru), '/siswa/jadwal'),
        AppRoutes.guru,
      );
      expect(
        resolveRedirect(authenticated(_guru), '/siswa/absensi'),
        AppRoutes.guru,
      );
      expect(
        resolveRedirect(authenticated(_guru), '/wali/beranda'),
        AppRoutes.guru,
      );
    });

    test('wali tidak bisa membuka /guru/* maupun /siswa/*', () {
      expect(
        resolveRedirect(authenticated(_wali), '/guru/notifikasi/1'),
        AppRoutes.wali,
      );
      expect(
        resolveRedirect(authenticated(_wali), '/siswa/nilai'),
        AppRoutes.wali,
      );
    });

    test('guru boleh membuka sub-route guru', () {
      expect(resolveRedirect(authenticated(_guru), '/guru/jadwal'), isNull);
      expect(resolveRedirect(authenticated(_guru), '/guru/kelas/1'), isNull);
      expect(
        resolveRedirect(authenticated(_guru), '/guru/penilaian/3/nilai'),
        isNull,
      );
    });

    test('siswa boleh membuka sub-route siswa', () {
      expect(
        resolveRedirect(authenticated(_siswa), '/siswa/rapor/11/99'),
        isNull,
      );
      expect(
        resolveRedirect(authenticated(_siswa), '/siswa/pembayaran-attempt/7'),
        isNull,
      );
    });
  });
}
