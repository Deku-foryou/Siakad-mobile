import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/app/app.dart';
import 'package:siakad_mobile/core/config/app_config.dart';
import 'package:siakad_mobile/core/network/dio_client.dart';
import 'package:siakad_mobile/core/storage/secure_storage_service.dart';
import 'package:siakad_mobile/shared/providers/core_providers.dart';

import '../fakes/fake_secure_key_value_store.dart';
import '../fakes/harness.dart';
import '../fakes/path_adapter.dart';

/// Uji integrasi aplikasi di ukuran layar & mode terang/gelap berbeda.
/// Perubahan ukuran view di-reset via addTearDown agar tidak bocor antar-test.
Future<void> pumpWaliAppView(
  WidgetTester tester, {
  Size? logicalSize,
  double textScale = 1.0,
  Brightness brightness = Brightness.light,
}) async {
  final store = FakeSecureKeyValueStore();
  await SecureStorageService(store).saveToken('1|tokenwali');
  final adapter = PathAdapter(
    overrides: {'/auth/me': (200, meSuccessBody(role: 'wali'))},
  );

  const config = AppConfig(apiBaseUrl: 'http://test.local/api/v1');
  final storage = SecureStorageService(store);

  if (logicalSize != null) {
    tester.view.physicalSize = logicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final dispatcher = tester.view.platformDispatcher;
  dispatcher.platformBrightnessTestValue = brightness;
  addTearDown(dispatcher.clearPlatformBrightnessTestValue);
  dispatcher.textScaleFactorTestValue = textScale;
  addTearDown(dispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        secureKeyValueStoreProvider.overrideWithValue(store),
        dioProvider.overrideWithValue(
          createDio(config, storage)..httpClientAdapter = adapter,
        ),
      ],
      child: const SiakadApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> scrollToBottom(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 10; i++) {
    await tester.drag(scrollable, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('layar kecil (320x568) dashboard wali tanpa overflow', (
    tester,
  ) async {
    await pumpWaliAppView(tester, logicalSize: const Size(320, 568));
    expect(find.text('Wali Uji'), findsWidgets);
    await scrollToBottom(tester);
    // Tidak ada exception = tidak ada RenderFlex overflow fatal.
    expect(tester.takeException(), isNull);
  });

  testWidgets('layar besar (900x1200) dashboard wali normal', (tester) async {
    await pumpWaliAppView(tester, logicalSize: const Size(900, 1200));
    expect(find.text('Wali Uji'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text scaling 1.5x: dashboard masih terbaca & tanpa overflow', (
    tester,
  ) async {
    await pumpWaliAppView(tester, textScale: 1.5);
    expect(find.text('Wali Uji'), findsWidgets);
    await scrollToBottom(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text scaling 2.0x: tidak crash pada konten panjang', (
    tester,
  ) async {
    await pumpWaliAppView(tester, textScale: 2.0);
    expect(find.text('Wali Uji'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark mode: shell wali render & konten tampil', (tester) async {
    await pumpWaliAppView(tester, brightness: Brightness.dark);
    expect(find.text('Wali Uji'), findsWidgets);
    expect(find.text('Ringkasan Relasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('light mode eksplisit: shell wali render normal', (tester) async {
    await pumpWaliAppView(tester, brightness: Brightness.light);
    expect(find.text('Wali Uji'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('semantics: bottom navigation punya label untuk semua tab', (
    tester,
  ) async {
    await pumpWaliAppView(tester);
    for (final label in [
      'Beranda',
      'Anak',
      'Keuangan',
      'Notifikasi',
      'Profil',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
  });
}
