import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exception.dart';

/// Normalisasi seluruh error Dio (dan error lain) menjadi [ApiException].
///
/// Aturan:
/// - Bila backend mengirim envelope error JSON, `message` dari backend
///   (Bahasa Indonesia, aman ditampilkan) dipakai apa adanya.
/// - Bila tidak ada `message` yang valid, gunakan fallback generik per status.
/// - Stack trace / detail internal server TIDAK PERNAH diteruskan ke UI.
class ErrorMapper {
  const ErrorMapper._();

  static ApiException map(Object error) {
    if (error is ApiException) return error;
    // Debug-only: tipe exception tanpa header/token/body aman ditampilkan.
    // Contoh: "type 'String' is not a subtype of type 'num?' in type cast"
    // — detail penting untuk mencari bug parsing di perangkat fisik.
    if (kDebugMode) {
      final detail = error is DioException
          ? 'DioException(type: ${error.type.name}, status: ${error.response?.statusCode})'
          : error.toString();
      debugPrint('[ErrorMapper] $detail');
    }
    if (error is DioException) return _mapDio(error);
    return ApiException(
      kind: ApiErrorKind.unknown,
      message: 'Terjadi kesalahan yang tidak dikenal.',
    );
  }

  static ApiException _mapDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          kind: ApiErrorKind.timeout,
          message:
              'Koneksi ke server melebihi batas waktu. '
              'Periksa jaringan Anda lalu coba lagi.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          kind: ApiErrorKind.noConnection,
          message:
              'Tidak dapat terhubung ke server. '
              'Periksa koneksi internet Anda.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          kind: ApiErrorKind.unknown,
          message: 'Sertifikat keamanan server tidak valid.',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          kind: ApiErrorKind.unknown,
          message: 'Permintaan dibatalkan.',
        );
      case DioExceptionType.badResponse:
        return _mapResponse(e.response);
      case DioExceptionType.unknown:
        final inner = e.error;
        if (inner is SocketException) {
          return const ApiException(
            kind: ApiErrorKind.noConnection,
            message:
                'Tidak dapat terhubung ke server. '
                'Periksa koneksi internet Anda.',
          );
        }
        return ApiException(
          kind: ApiErrorKind.unknown,
          message: 'Terjadi kesalahan yang tidak dikenal.',
        );
    }
  }

  static ApiException _mapResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final body = response?.data;

    if (body is Map) {
      final message = (body['message'] as String?)?.trim();
      final code = body['code'] as String?;
      final errors = _parseFieldErrors(body['errors']);
      return ApiException(
        kind: ApiErrorKind.http,
        statusCode: statusCode,
        code: code,
        message: (message != null && message.isNotEmpty)
            ? message
            : fallbackMessage(statusCode),
        fieldErrors: errors,
      );
    }

    // Body bukan JSON object (mis. HTML error page / kosong / terpotong).
    return ApiException(
      kind: ApiErrorKind.invalidResponse,
      statusCode: statusCode,
      message: fallbackMessage(statusCode),
    );
  }

  static Map<String, List<String>> _parseFieldErrors(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, List<String>>{};
    raw.forEach((key, value) {
      final messages = switch (value) {
        final List list => list.map((e) => e.toString()).toList(),
        _ => [value.toString()],
      };
      result[key.toString()] = messages;
    });
    return result;
  }

  /// Pesan fallback per HTTP status, diselaraskan dengan pesan backend
  /// (Bahasa Indonesia, aman ditampilkan).
  static String fallbackMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Permintaan tidak dapat diproses.';
      case 401:
        return 'Sesi Anda tidak valid atau telah berakhir. Silakan login kembali.';
      case 403:
        return 'Anda tidak memiliki akses.';
      case 404:
        return 'Data tidak ditemukan.';
      case 405:
        return 'Metode tidak diizinkan.';
      case 422:
        return 'Validasi gagal. Periksa kembali isian Anda.';
      case 429:
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 500:
        return 'Kesalahan server. Silakan coba lagi nanti.';
      case 503:
        return 'Layanan sedang tidak tersedia. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}
