import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/config/app_config.dart';
import 'package:siakad_mobile/core/errors/api_exception.dart';
import 'package:siakad_mobile/core/errors/error_mapper.dart';
import 'package:siakad_mobile/core/network/dio_client.dart';
import 'package:siakad_mobile/core/storage/secure_storage_service.dart';

import '../../fakes/fake_http_client_adapter.dart';
import '../../fakes/fake_secure_key_value_store.dart';

void main() {
  DioException dioError([DioExceptionType type = DioExceptionType.unknown]) {
    return DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
    );
  }

  ApiException httpError(int status, Object? body) {
    return ErrorMapper.map(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: status,
          data: body,
        ),
      ),
    );
  }

  group('timeout & koneksi', () {
    test('connection/send/receive timeout -> timeout', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final e = ErrorMapper.map(dioError(t));
        expect(e.kind, ApiErrorKind.timeout);
        expect(e.statusCode, isNull);
        expect(e.message, isNotEmpty);
      }
    });

    test('connectionError -> noConnection', () {
      final e = ErrorMapper.map(dioError(DioExceptionType.connectionError));
      expect(e.kind, ApiErrorKind.noConnection);
    });

    test('SocketException di unknown -> noConnection', () {
      final e = ErrorMapper.map(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.unknown,
          error: const SocketException('no route to host'),
        ),
      );
      expect(e.kind, ApiErrorKind.noConnection);
    });
  });

  group('HTTP error mapping', () {
    test('400 dipetakan dengan pesan backend', () {
      final e = httpError(400, {
        'success': false,
        'message': 'Permintaan salah.',
        'code': 'BAD_REQUEST',
      });
      expect(e.statusCode, 400);
      expect(e.message, 'Permintaan salah.');
      expect(e.code, 'BAD_REQUEST');
      expect(e.kind, ApiErrorKind.http);
    });

    test('401 UNAUTHENTICATED', () {
      final e = httpError(401, {
        'success': false,
        'message': 'Belum terautentikasi atau token tidak valid.',
        'code': 'UNAUTHENTICATED',
      });
      expect(e.isUnauthorized, isTrue);
      expect(e.code, 'UNAUTHENTICATED');
    });

    test('400 tanpa body JSON object -> fallback', () {
      final e = httpError(400, '<html>bukan json</html>');
      expect(e.kind, ApiErrorKind.invalidResponse);
      expect(e.message, ErrorMapper.fallbackMessage(400));
    });

    test('403 ROLE_NOT_ALLOWED', () {
      final e = httpError(403, {
        'success': false,
        'message': 'Akses ditolak untuk role ini.',
        'code': 'ROLE_NOT_ALLOWED',
      });
      expect(e.isForbidden, isTrue);
      expect(e.isRoleNotAllowed, isTrue);
    });

    test('403 ACCOUNT_INACTIVE', () {
      final e = httpError(403, {
        'success': false,
        'message': 'Akun tidak dapat digunakan. Hubungi admin sekolah.',
        'code': 'ACCOUNT_INACTIVE',
      });
      expect(e.isAccountInactive, isTrue);
    });

    test('403 PASSWORD_CHANGE_REQUIRED', () {
      final e = httpError(403, {
        'success': false,
        'message': 'Anda wajib mengganti password terlebih dahulu.',
        'code': 'PASSWORD_CHANGE_REQUIRED',
      });
      expect(e.isPasswordChangeRequired, isTrue);
    });

    test('404 NOT_FOUND', () {
      final e = httpError(404, {
        'success': false,
        'message': 'Resource tidak ditemukan.',
        'code': 'NOT_FOUND',
      });
      expect(e.isNotFound, isTrue);
      expect(e.message, 'Resource tidak ditemukan.');
    });

    test('405 METHOD_NOT_ALLOWED', () {
      final e = httpError(405, {
        'success': false,
        'message': 'Metode tidak diizinkan.',
        'code': 'METHOD_NOT_ALLOWED',
      });
      expect(e.statusCode, 405);
      expect(e.message, 'Metode tidak diizinkan.');
    });

    test('422 dengan errors map (tanpa code, sesuai backend)', () {
      final e = httpError(422, {
        'success': false,
        'message': 'Validasi gagal.',
        'errors': {
          'username': ['Username wajib diisi.'],
          'password': ['Password wajib diisi.', 'Terlalu pendek.'],
        },
      });
      expect(e.isValidation, isTrue);
      expect(e.code, isNull);
      expect(e.fieldErrors['username'], ['Username wajib diisi.']);
      expect(e.fieldErrors['password'], [
        'Password wajib diisi.',
        'Terlalu pendek.',
      ]);
      expect(e.message, 'Validasi gagal.');
    });

    test('429 TOO_MANY_REQUESTS', () {
      final e = httpError(429, {
        'success': false,
        'message': 'Terlalu banyak percobaan. Coba lagi nanti.',
        'code': 'TOO_MANY_REQUESTS',
      });
      expect(e.isRateLimited, isTrue);
    });

    test('500 SERVER_ERROR', () {
      final e = httpError(500, {
        'success': false,
        'message': 'Kesalahan server. Silakan coba lagi.',
        'code': 'SERVER_ERROR',
      });
      expect(e.isServerError, isTrue);
      expect(e.message, 'Kesalahan server. Silakan coba lagi.');
    });

    test('503 tanpa code', () {
      final e = httpError(503, {
        'success': false,
        'message': 'Layanan sedang tidak tersedia.',
      });
      expect(e.statusCode, 503);
      expect(e.message, 'Layanan sedang tidak tersedia.');
    });

    test('error tanpa message memakai fallback per status', () {
      final e = httpError(500, {'success': false});
      expect(e.message, ErrorMapper.fallbackMessage(500));
    });
  });

  group('integrasi Dio + ErrorMapper + adapter fake', () {
    late FakeSecureKeyValueStore store;
    late SecureStorageService storage;
    late FakeHttpClientAdapter adapter;
    late Dio dio;

    setUp(() {
      store = FakeSecureKeyValueStore();
      storage = SecureStorageService(store);
      adapter = FakeHttpClientAdapter();
      dio = createDio(
        const AppConfig(apiBaseUrl: 'http://test.local/api/v1'),
        storage,
      )..httpClientAdapter = adapter;
    });

    test('401 menghapus token dari secure storage (via interceptor)', () async {
      await storage.saveToken('1|tokenmati');
      adapter.respondJson(401, {
        'success': false,
        'message': 'Belum terautentikasi atau token tidak valid.',
        'code': 'UNAUTHENTICATED',
      });

      await expectLater(
        () => dio.get<dynamic>('/auth/me'),
        throwsA(isA<DioException>()),
      );
      expect(await storage.readToken(), isNull);
    });

    test('error timeout via adapter dimapping oleh mapper', () async {
      adapter.error = const SocketException('connection refused');
      try {
        await dio.get<dynamic>('/auth/me');
        fail('harus melempar DioException');
      } catch (e) {
        final mapped = ErrorMapper.map(e);
        expect(mapped.kind, ApiErrorKind.noConnection);
      }
    });

    test('envelope error 422 melalui jalur Dio penuh', () async {
      adapter.respondJson(422, {
        'success': false,
        'message': 'Validasi gagal.',
        'errors': {
          'current_password': ['Password saat ini salah.'],
        },
      });
      try {
        await dio.post<dynamic>('/auth/password', data: const {});
        fail('harus melempar DioException');
      } catch (e) {
        final mapped = ErrorMapper.map(e);
        expect(mapped.isValidation, isTrue);
        expect(mapped.fieldErrors['current_password'], [
          'Password saat ini salah.',
        ]);
      }
    });
  });
}
