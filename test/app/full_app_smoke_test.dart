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

/// Smoke test lintas-role & lintas-ukuran layar: shell aplikasi harus
/// ter-render tanpa exception (tidak ada RenderFlex overflow fatal).
///
/// Catatan: ini uji otomatis, BUKAN pengujian fisik.
Future<void> pumpRoleApp(
  WidgetTester tester,
  String role, {
  required Size size,
  double textScale = 1.0,
}) async {
  final store = FakeSecureKeyValueStore();
  await SecureStorageService(store).saveToken('1|token$role');
  final adapter = PathAdapter(
    overrides: {'/auth/me': (200, meSuccessBody(role: role))},
  );

  const config = AppConfig(apiBaseUrl: 'http://test.local/api/v1');
  final storage = SecureStorageService(store);

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);

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
  for (var i = 0; i < 8; i++) {
    await tester.drag(scrollable, const Offset(0, -240));
    await tester.pumpAndSettle();
  }
}

void main() {
  const sizes = <String, Size>{
    '320x568': Size(320, 568),
    '360x800': Size(360, 800),
    '393x852': Size(393, 852),
    '900x1200': Size(900, 1200),
  };

  for (final role in ['siswa', 'guru', 'wali']) {
    for (final entry in sizes.entries) {
      testWidgets('$role @ ${entry.key}: shell render tanpa exception', (
        tester,
      ) async {
        await pumpRoleApp(tester, role, size: entry.value);
        await scrollToBottom(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$role @ textScale 1.5: shell render tanpa exception', (
      tester,
    ) async {
      await pumpRoleApp(
        tester,
        role,
        size: const Size(360, 800),
        textScale: 1.5,
      );
      await scrollToBottom(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$role @ textScale 2.0: shell tidak crash', (tester) async {
      await pumpRoleApp(
        tester,
        role,
        size: const Size(360, 800),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('login @ 320x568: form tampil, tanpa exception', (tester) async {
    const size = Size(320, 568);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const config = AppConfig(apiBaseUrl: 'http://test.local/api/v1');
    final store = FakeSecureKeyValueStore();
    final storage = SecureStorageService(store);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          secureKeyValueStoreProvider.overrideWithValue(store),
          dioProvider.overrideWithValue(
            createDio(config, storage)..httpClientAdapter = PathAdapter(),
          ),
        ],
        child: const SiakadApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SIAKAD Mobile'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
