import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';
import 'session_expiry.dart';

/// Menyisipkan header `Authorization: Bearer <token>` pada setiap request
/// (bila token tersedia) dan menghapus token lokal bila server menjawab 401.
///
/// Header TIDAK PERNAH dicatat oleh logger; token tidak pernah muncul di log.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final SecureStorageService _storage;

  /// Path yang tidak memicu pembersihan sesi meski server menjawab 401.
  /// 401 dari `/auth/login` berarti kredensial salah (`INVALID_CREDENTIALS`),
  /// bukan token kedaluwarsa — sesi pengguna tidak boleh ikut terhapus.
  static const String _loginPath = '/auth/login';

  bool _isLoginPath(String path) {
    final p = path.toLowerCase();
    return p == _loginPath || p.endsWith(_loginPath);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _storage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Gagal membaca secure storage: lanjutkan request tanpa token.
      // Server akan menjawab 401 bila endpoint memerlukan autentikasi.
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        !_isLoginPath(err.requestOptions.path)) {
      // Sanctum mengembalikan 401 untuk token kedaluwarsa/tidak valid.
      // Token lokal tidak lagi berguna — hapus agar request berikutnya
      // tidak memakai token mati. Lalu beri sinyal agar AuthController
      // menutup sesi secara bersih (state → unauthenticated).
      try {
        await _storage.clearSession();
      } catch (_) {
        // Jangan gagalkan pipeline error hanya karena pembersihan storage gagal.
      }
      SessionExpiry.notify();
    }
    handler.next(err);
  }
}
