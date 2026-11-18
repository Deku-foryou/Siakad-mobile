import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/app/router/app_routes.dart';
import 'package:siakad_mobile/app/router/redirect.dart';
import 'package:siakad_mobile/features/auth/application/auth_state.dart';
import 'package:siakad_mobile/features/auth/data/models/auth_user.dart';

const _wali = AuthUser(
  id: 3,
  name: 'Wali Uji',
  username: 'wali01',
  email: 'w@example.test',
  level: 'wali',
  statusAkun: 'aktif',
  wajibGantiPassword: false,
);

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

AuthState authenticated(AuthUser user) => AuthState(
  status: AuthStatus.authenticated,
  user: user,
  wajibGantiPassword: false,
);

/// Nested route di bawah /wali harus tetap terlindungi per role.
const _waliNested = [
  '/wali/anak/201',
  '/wali/anak/201/jadwal',
  '/wali/anak/201/absensi',
  '/wali/anak/201/nilai',
  '/wali/anak/201/rapor',
  '/wali/anak/201/rapor/11/99',
  '/wali/anak/201/keuangan/pembayaran',
  '/wali/anak/201/keuangan/tagihan/71',
  '/wali/anak/201/keuangan/pembayaran/901',
  '/wali/anak/201/keuangan/pembayaran-attempt/331',
  '/wali/notifikasi/9',
];

void main() {
  group('wali boleh membuka seluruh nested /wali/*', () {
    for (final location in _waliNested) {
      test(location, () {
        expect(resolveRedirect(authenticated(_wali), location), isNull);
      });
    }
  });

  group('siswa tidak bisa membuka /wali/* (termasuk nested)', () {
    for (final location in _waliNested) {
      test(location, () {
        expect(
          resolveRedirect(authenticated(_siswa), location),
          AppRoutes.siswa,
        );
      });
    }
  });

  group('guru tidak bisa membuka /wali/* (termasuk nested)', () {
    for (final location in _waliNested) {
      test(location, () {
        expect(resolveRedirect(authenticated(_guru), location), AppRoutes.guru);
      });
    }
  });

  group('wali tidak bisa membuka area siswa/guru (termasuk nested)', () {
    const forbidden = [
      '/siswa',
      '/siswa/jadwal',
      '/siswa/absensi',
      '/siswa/nilai',
      '/siswa/rapor/11/99',
      '/siswa/tagihan/71',
      '/siswa/pembayaran-attempt/331',
      '/guru',
      '/guru/kelas/1',
      '/guru/absensi/harian/grid/99',
      '/guru/notifikasi/9',
    ];
    for (final location in forbidden) {
      test(location, () {
        expect(resolveRedirect(authenticated(_wali), location), AppRoutes.wali);
      });
    }
  });

  group('unauthenticated ditolak dari seluruh /wali/*', () {
    for (final location in _waliNested) {
      test(location, () {
        expect(
          resolveRedirect(const AuthState.unauthenticated(), location),
          AppRoutes.login,
        );
      });
    }
  });
}
