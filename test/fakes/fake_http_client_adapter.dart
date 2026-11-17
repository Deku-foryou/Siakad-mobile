import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class _QueuedResponse {
  _QueuedResponse(this.statusCode, this.body);
  final int statusCode;
  final String body;
}

class _QueuedBytes {
  _QueuedBytes(
    this.statusCode,
    this.bytes, {
    this.filename,
    this.contentType = 'application/octet-stream',
  });
  final int statusCode;
  final List<int> bytes;
  final String? filename;
  final String contentType;
}

/// Fake HttpClientAdapter Dio: melayani response ter-antre dan mencatat
/// seluruh request (untuk asersi header/URL) tanpa jaringan sungguhan.
class FakeHttpClientAdapter implements HttpClientAdapter {
  final List<_QueuedResponse> _queue = [];
  final List<_QueuedBytes> _queueBytes = [];
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

  /// Antrekan response binary (mis. PDF dokumen privat) dengan header
  /// Content-Disposition agar filename bisa diuji.
  void queueBytes(
    int statusCode,
    List<int> bytes, {
    String? filename,
    String contentType = 'application/pdf',
  }) {
    _queueBytes.add(
      _QueuedBytes(
        statusCode,
        bytes,
        filename: filename,
        contentType: contentType,
      ),
    );
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
    if (_queueBytes.isNotEmpty) {
      final next = _queueBytes.removeAt(0);
      final headers = <String, List<String>>{
        'content-type': [next.contentType],
      };
      if (next.filename != null) {
        headers['content-disposition'] = [
          'attachment; filename="${next.filename}"',
        ];
      }
      return ResponseBody.fromBytes(
        next.bytes,
        next.statusCode,
        headers: headers,
      );
    }
    if (_queue.isEmpty && _queueBytes.isEmpty) {
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
