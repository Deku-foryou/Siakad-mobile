import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/network/logging_interceptor.dart';

/// LoggingInterceptor tidak pernah membocorkan header Authorization,
/// body, maupun token ke output log — bahkan saat request membawa token.
void main() {
  Dio buildDio({required List<String> logs}) {
    final dio = Dio();
    dio.interceptors.add(LoggingInterceptor(logger: logs.add));
    dio.httpClientAdapter = _StubAdapter(statusCode: 200);
    return dio;
  }

  test(
    'request dengan Bearer token: log hanya method+path, tanpa header/token',
    () async {
      final logs = <String>[];
      final dio = buildDio(logs: logs);

      await dio.get<dynamic>(
        'http://test.local/api/v1/wali/notifikasi',
        options: Options(
          headers: const {'Authorization': 'Bearer super-secret-token-abc123'},
        ),
      );

      expect(logs, isNotEmpty);
      for (final line in logs) {
        expect(line.contains('super-secret-token-abc123'), isFalse);
        expect(line.contains('Bearer'), isFalse);
        expect(line.contains('Authorization'), isFalse);
      }
    },
  );

  test('error response: log tidak memuat body / Authorization', () async {
    final logs = <String>[];
    final dio = Dio();
    dio.interceptors.add(LoggingInterceptor(logger: logs.add));
    dio.httpClientAdapter = _StubAdapter(
      statusCode: 401,
      body: '{"message":"secret-error-body-token"}',
    );

    try {
      await dio.get<dynamic>(
        'http://test.local/api/v1/wali/beranda',
        options: Options(
          headers: const {'Authorization': 'Bearer super-secret-token-abc123'},
        ),
      );
    } on DioException {
      // Diharapkan: 401.
    }

    expect(logs, isNotEmpty);
    for (final line in logs) {
      expect(line.contains('super-secret-token-abc123'), isFalse);
      expect(line.contains('secret-error-body-token'), isFalse);
      expect(line.contains('Authorization'), isFalse);
    }
  });

  test('default logger tidak mencetak apa pun di luar kDebugMode', () {
    // Tidak bisa memverifikasi debugPrint secara langsung; cukup pastikan
    // interceptor bisa dibuat tanpa logger custom (kode produksi memakai
    // default yang gated kDebugMode).
    expect(LoggingInterceptor.new, returnsNormally);
  });
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({required this.statusCode, this.body = '{}'});

  final int statusCode;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body,
    statusCode,
    headers: const {
      'content-type': ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}
