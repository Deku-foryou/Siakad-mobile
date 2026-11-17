import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

/// Factory Dio terpusat — SATU instance dipakai oleh seluruh fitur.
///
/// Base URL, timeout, header JSON, Bearer token, dan logging development
/// semuanya dikonfigurasi di sini agar konsisten lintas endpoint.
Dio createDio(AppConfig config, SecureStorageService storage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.connectTimeout,
      sendTimeout: config.sendTimeout,
      receiveTimeout: config.receiveTimeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 400,
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(storage),
    LoggingInterceptor(), // aktif hanya di debug mode; tidak membocorkan data
  ]);

  return dio;
}
