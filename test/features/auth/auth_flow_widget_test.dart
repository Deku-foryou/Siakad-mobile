import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/app/app.dart';
import 'package:siakad_mobile/core/config/app_config.dart';
import 'package:siakad_mobile/core/network/dio_client.dart';
import 'package:siakad_mobile/core/storage/secure_storage_service.dart';
import 'package:siakad_mobile/shared/providers/core_providers.dart';

import '../../fakes/fake_http_client_adapter.dart';
import '../../fakes/path_adapter.dart';
import '../../fakes/fake_secure_key_value_store.dart';
import '../../fakes/harness.dart' show loginSuccessBody, meSuccessBody;

ProviderScope _app({
  required FakeSecureKeyValueStore store,
  required HttpClientAdapter adapter,
}) {
  const config = AppConfig(apiBaseUrl: 'http://test.local/api/v1');
  final storage = SecureStorageService(store);
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      secureKeyValueStoreProvider.overrideWithValue(store),
      dioProvider.overrideWithValue(
        createDio(config, storage)..httpClientAdapter = adapter,
      ),
    ],
    child: const SiakadApp(),
  );
}

void main() {
  testWidgets('login form tampil dengan elemen wajib', (tester) async {
    final store = FakeSecureKeyValueStore();
    final adapter = FakeHttpClientAdapter();

    await tester.pumpWidget(_app(store: store, adapter: adapter));
    await tester.pumpAndSettle();

    expect(find.text('SIAKAD Mobile'), findsWidgets);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
    expect(
      find.text('Hanya untuk siswa, guru, dan wali murid.'),
      findsOneWidget,
    );
  });

  testWidgets('validasi input kosong: pesan wajib diisi tampil', (
    tester,
  ) async {
    final store = FakeSecureKeyValueStore();
    final adapter = FakeHttpClientAdapter();

    await tester.pumpWidget(_app(store: store, adapter: adapter));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump();

    expect(find.text('Username wajib diisi.'), findsOneWidget);
    expect(find.text('Password wajib diisi.'), findsOneWidget);
    expect(adapter.requests, isEmpty); // tidak ada request terkirim
  });

  testWidgets('toggle password visibility mengubah obscureText', (
    tester,
  ) async {
    final store = FakeSecureKeyValueStore();
    final adapter = FakeHttpClientAdapter();

    await tester.pumpWidget(_app(store: store, adapter: adapter));
    await tester.pumpAndSettle();

    TextField passwordField() => tester.widget<TextField>(
      find.descendant(
        of: find.byType(TextFormField).last,
        matching: find.byType(TextField),
      ),
    );

    expect(passwordField().obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(passwordField().obscureText, isTrue);
  });

  testWidgets('login sukses: diarahkan ke area sesuai role', (tester) async {
    final store = FakeSecureKeyValueStore();
    final adapter = PathAdapter(
      overrides: {'/auth/login': (200, loginSuccessBody())},
    );

    await tester.pumpWidget(_app(store: store, adapter: adapter));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'siswa01');
    await tester.enterText(find.byType(TextFormField).last, 'rahasia');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    // Shell siswa tampil (bottom nav Beranda/Akademik/Keuangan/Notifikasi/Profil).
    expect(find.text('Beranda'), findsWidgets);
    expect(adapter.requests.any((r) => r.path == '/auth/login'), isTrue);
    final loginRequest = adapter.requests.firstWhere(
      (r) => r.path == '/auth/login',
    );
    expect((loginRequest.data as Map)['username'], 'siswa01');
  });

  testWidgets('login gagal: pesan backend ditampilkan', (tester) async {
    final store = FakeSecureKeyValueStore();
    final adapter = FakeHttpClientAdapter();

    await tester.pumpWidget(_app(store: store, adapter: adapter));
    await tester.pumpAndSettle();

    adapter.respondJson(401, {
      'success': false,
      'message': 'Username atau password salah.',
      'code': 'INVALID_CREDENTIALS',
    });

    await tester.enterText(find.byType(TextFormField).first, 'siswa01');
    await tester.enterText(find.byType(TextFormField).last, 'salah');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Username atau password salah.'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget); // tetap di halaman login
  });

  testWidgets('login rate limit: pesan ramah 429 ditampilkan', (tester) async {
    final store = FakeSecureKeyValueStore();
    final adapter = FakeHttpClientAdapter();

    await tester.pumpWidget(_app(store: store, adapter: adapter));
    await tester.pumpAndSettle();

    adapter.respondJson(429, {
      'success': false,
      'message': 'Terlalu banyak percobaan. Coba lagi nanti.',
      'code': 'TOO_MANY_REQUESTS',
    });

    await tester.enterText(find.byType(TextFormField).first, 'siswa01');
    await tester.enterText(find.byType(TextFormField).last, 'rahasia');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Terlalu banyak'), findsOneWidget);
  });

  testWidgets('login role tidak diizinkan: pesan akses mobile', (tester) async {
    final store = FakeSecureKeyValueStore();
    final adapter = FakeHttpClientAdapter();

    await tester.pumpWidget(_app(store: store, adapter: adapter));
    await tester.pumpAndSettle();

    adapter.respondJson(403, {
      'success': false,
      'message': 'Akses ditolak untuk role ini.',
      'code': 'ROLE_NOT_ALLOWED',
    });

    await tester.enterText(find.byType(TextFormField).first, 'admin01');
    await tester.enterText(find.byType(TextFormField).last, 'rahasia');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Akses tidak tersedia'), findsOneWidget);
  });

  testWidgets('dashboard siswa tampil identitas + informasi sesi', (
    tester,
  ) async {
    final store = FakeSecureKeyValueStore();
    final storage = SecureStorageService(store);
    await storage.saveToken('1|tokenvalid');
    final adapter = PathAdapter();

    await tester.pumpWidget(_app(store: store, adapter: adapter));
    await tester.pumpAndSettle();

    // Buka tab Profil (informasi sesi ada di sana — mungkin di bawah lipatan).
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.text('Siswa Uji'), findsWidgets);
    expect(find.text('@siswa01'), findsOneWidget);

    // Seksi "Sesi Perangkat" berada di bawah — gulir sampai terlihat.
    await tester.scrollUntilVisible(
      find.text('Sesi aktif'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sesi aktif'), findsOneWidget);
    expect(find.text('Flutter Android'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Logout Semua Perangkat'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Logout Semua Perangkat'), findsOneWidget);
  });

  testWidgets('tombol logout: dialog konfirmasi, konfirmasi -> login', (
    tester,
  ) async {
    final store = FakeSecureKeyValueStore();
    final storage = SecureStorageService(store);
    await storage.saveToken('1|tokenvalid');
    final adapter = PathAdapter(
      overrides: {
        '/auth/logout': (
          200,
          {'success': true, 'message': 'Logout berhasil', 'data': null},
        ),
      },
    );

    await tester.pumpWidget(_app(store: store, adapter: adapter));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Logout Perangkat Ini'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Logout Perangkat Ini'));
    await tester.pumpAndSettle(); // dialog muncul

    expect(find.text('Keluar dari akun pada perangkat ini?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Masuk'), findsOneWidget); // kembali ke login
    expect(await storage.readToken(), isNull);
  });

  testWidgets('logout semua perangkat: dialog konfirmasi tampil', (
    tester,
  ) async {
    final store = FakeSecureKeyValueStore();
    final storage = SecureStorageService(store);
    await storage.saveToken('1|tokenvalid');
    final adapter = PathAdapter(
      overrides: {
        '/auth/logout-all': (
          200,
          {
            'success': true,
            'message': 'Seluruh perangkat telah logout.',
            'data': null,
          },
        ),
      },
    );

    await tester.pumpWidget(_app(store: store, adapter: adapter));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    // Tombol logout-all berada di bagian bawah — gulir sampai terlihat.
    await tester.scrollUntilVisible(
      find.text('Logout Semua Perangkat'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Logout Semua Perangkat'));
    await tester.pumpAndSettle();

    expect(find.textContaining('SEMUA perangkat'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Masuk'), findsOneWidget);
    expect(await storage.readToken(), isNull);
    expect(adapter.requests.last.path, '/auth/logout-all');
  });

  testWidgets('wajib ganti password diarahkan ke /change-password', (
    tester,
  ) async {
    final store = FakeSecureKeyValueStore();
    final storage = SecureStorageService(store);
    await storage.saveToken('1|tokenvalid');
    final adapter = FakeHttpClientAdapter();
    adapter.respondJson(200, meSuccessBody(wajibGantiPassword: true));

    await tester.pumpWidget(_app(store: store, adapter: adapter));
    await tester.pumpAndSettle();

    expect(find.text('Anda Wajib Mengganti Password'), findsOneWidget);
    expect(find.text('Profil'), findsNothing);
  });

  testWidgets('change password: konfirmasi tidak cocok menampilkan validasi', (
    tester,
  ) async {
    final store = FakeSecureKeyValueStore();
    final storage = SecureStorageService(store);
    await storage.saveToken('1|tokenvalid');
    final adapter = FakeHttpClientAdapter();
    adapter.respondJson(200, meSuccessBody(wajibGantiPassword: true));

    await tester.pumpWidget(_app(store: store, adapter: adapter));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'lama123');
    await tester.enterText(fields.at(1), 'baru12345');
    await tester.enterText(fields.at(2), 'beda12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan Password Baru'));
    await tester.pump();

    expect(find.text('Konfirmasi password tidak cocok.'), findsOneWidget);
  });
}
