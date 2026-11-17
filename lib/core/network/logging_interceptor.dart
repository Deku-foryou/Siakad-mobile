import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logging HTTP khusus development.
///
/// DILARANG mencatat: header Authorization, body request/response, token,
/// password, cookie. Yang dicatat hanya method, path (tanpa query), status
/// code, dan durasi — cukup untuk debugging tanpa membocorkan data.
class LoggingInterceptor extends Interceptor {
  static const String _startKey = 'siakad.http.start';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    _log('-> ${options.method} ${options.uri.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(
      '<- ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri.path} (${_elapsed(response.requestOptions)}ms)',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    _log(
      '<- ${status ?? err.type.name} ${err.requestOptions.method} '
      '${err.requestOptions.uri.path} (${_elapsed(err.requestOptions)}ms)',
    );
    handler.next(err);
  }

  int _elapsed(RequestOptions options) {
    final start = options.extra[_startKey];
    if (start is int) return DateTime.now().millisecondsSinceEpoch - start;
    return -1;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[HTTP] $message');
  }
}
