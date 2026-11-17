import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/app/app.dart';
import 'package:siakad_mobile/core/config/app_config.dart';
import 'package:siakad_mobile/core/network/dio_client.dart';
import 'package:siakad_mobile/core/storage/secure_storage_service.dart';
import 'package:siakad_mobile/shared/providers/core_providers.dart';

import 'fakes/fake_http_client_adapter.dart';
import 'fakes/fake_secure_key_value_store.dart';

void main() {
  testWidgets('tanpa sesi: aplikasi menampilkan halaman login', (tester) async {
    final store = FakeSecureKeyValueStore();
    final storage = SecureStorageService(store);
    final adapter = FakeHttpClientAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(apiBaseUrl: 'http://test.local/api/v1'),
          ),
          secureKeyValueStoreProvider.overrideWithValue(store),
          dioProvider.overrideWithValue(
            createDio(
              const AppConfig(apiBaseUrl: 'http://test.local/api/v1'),
              storage,
            )..httpClientAdapter = adapter,
          ),
        ],
        child: const SiakadApp(),
      ),
    );

    // Frame pertama: splash + pemulihan sesi (tanpa token).
    expect(find.text('SIAKAD Mobile'), findsWidgets);

    await tester.pumpAndSettle();

    // Setelah restore selesai (tanpa token) router mengarahkan ke /login.
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
  });
}
