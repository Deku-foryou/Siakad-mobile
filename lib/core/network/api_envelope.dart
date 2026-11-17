import 'package:dio/dio.dart';

import '../errors/api_exception.dart';

/// Helper untuk membaca envelope respons backend:
/// `{ success, message, data?, meta? }` (sukses) atau
/// `{ success: false, message, code?, errors? }` (error).
class ApiEnvelope {
  const ApiEnvelope._();

  /// Mengembalikan `data` envelope sebagai map. Melempar [ApiException]
  /// bila respons bukan envelope JSON object yang valid.
  static Map<String, dynamic> dataObject(Response<dynamic> response) {
    final body = _asMap(response.data);
    if (body == null) {
      throw const ApiException(
        kind: ApiErrorKind.invalidResponse,
        message: 'Respons server tidak valid.',
      );
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    // `data` boleh null (mis. logout) — kembalikan map kosong.
    if (data == null) return <String, dynamic>{};
    throw const ApiException(
      kind: ApiErrorKind.invalidResponse,
      message: 'Format data respons server tidak valid.',
    );
  }

  /// Pesan dari envelope (untuk snackbar/log), boleh null.
  static String? message(Response<dynamic> response) {
    final body = _asMap(response.data);
    final msg = body?['message'];
    return msg is String && msg.trim().isNotEmpty ? msg.trim() : null;
  }

  static Map<String, dynamic>? _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}
