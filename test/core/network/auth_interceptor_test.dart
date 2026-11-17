import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/config/app_config.dart';
import 'package:siakad_mobile/core/network/dio_client.dart';
import 'package:siakad_mobile/core/storage/secure_storage_service.dart';

import '../../fakes/fake_http_client_adapter.dart';
import '../../fakes/fake_secure_key_value_store.dart';

void main() {
  late FakeSecureKeyValueStore store;
  late SecureStorageService storage;
  late FakeHttpClientAdapter adapter;

  setUp(() {
    store = FakeSecureKeyValueStore();
    storage = SecureStorageService(store);
    adapter = FakeHttpClientAdapter();
  });

  Dio dioWithFake() {
    return createDio(
      const AppConfig(apiBaseUrl: 'http://test.local/api/v1'),
      storage,
    )..httpClientAdapter = adapter;
  }

  test('header Authorization Bearer disisipkan bila token ada', () async {
    await storage.saveToken('1|rahasia');
    final dio = dioWithFake();
    adapter.respondJson(200, {
      'success': true,
      'message': 'Berhasil',
      'data': {},
    });

    await dio.get<dynamic>('/siswa/profil');

    expect(adapter.requests, hasLength(1));
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer 1|rahasia',
    );
  });

  test('header Authorization tidak disisipkan bila token kosong', () async {
    final dio = dioWithFake();
    adapter.respondJson(200, {
      'success': true,
      'message': 'Berhasil',
      'data': {},
    });

    await dio.get<dynamic>('/auth/login');

    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('base URL terpusat dan timeout terkonfigurasi', () {
    final dio = dioWithFake();
    expect(dio.options.baseUrl, 'http://test.local/api/v1');
    expect(dio.options.connectTimeout, const Duration(seconds: 15));
    expect(dio.options.sendTimeout, const Duration(seconds: 15));
    expect(dio.options.receiveTimeout, const Duration(seconds: 30));
    expect(dio.options.headers['Accept'], 'application/json');
  });

  test('header Content-Type dan Accept JSON', () async {
    final dio = dioWithFake();
    adapter.respondJson(200, {
      'success': true,
      'message': 'Berhasil',
      'data': {},
    });

    await dio.post<dynamic>('/auth/login', data: const {});

    expect(
      adapter.requests.single.headers['Content-Type'],
      contains('application/json'),
    );
    expect(adapter.requests.single.headers['Accept'], 'application/json');
  });
}
