import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class _QueuedResponse {
  _QueuedResponse(this.statusCode, this.body);
  final int statusCode;
  final String body;
}

/// Fake HttpClientAdapter Dio: melayani response ter-antre dan mencatat
/// seluruh request (untuk asersi header/URL) tanpa jaringan sungguhan.
class FakeHttpClientAdapter implements HttpClientAdapter {
  final List<_QueuedResponse> _queue = [];
  final List<RequestOptions> requests = [];
  Object? error; // bila diisi, setiap fetch melempar error ini

  /// Antrekan response JSON.
  void respondJson(int statusCode, Object? body) {
    _queue.add(_QueuedResponse(statusCode, jsonEncode(body)));
  }

  /// Antrekan response body non-JSON (mis. HTML error page).
  void respondRaw(int statusCode, String rawBody) {
    _queue.add(_QueuedResponse(statusCode, rawBody));
  }

  int get queueLength => _queue.length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (error != null) throw error!;
    if (_queue.isEmpty) {
      throw StateError(
        'FakeHttpClientAdapter: tidak ada response ter-antre untuk '
        '${options.method} ${options.uri}',
      );
    }
    final next = _queue.removeAt(0);
    return ResponseBody.fromString(
      next.body,
      next.statusCode,
      headers: const {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
