import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_envelope.dart';
import 'models/auth_session.dart';
import 'models/me_session.dart';

/// Repository autentikasi — satu-satunya pintu ke endpoint `/auth/*`.
///
/// Seluruh error dinormalisasi menjadi [ApiException]; presentation layer
/// tidak bergantung pada Dio. Token disimpan oleh caller (AuthController +
/// SecureStorageService), bukan di sini.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// `POST /auth/login` — publik, throttle 5/menit dari backend.
  Future<AuthSession> login({
    required String username,
    required String password,
    required String deviceName,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/auth/login',
        data: {
          'username': username.trim().toLowerCase(),
          'password': password,
          'device_name': deviceName,
        },
      );
      return AuthSession.fromLoginJson(ApiEnvelope.dataObject(response));
    } on ApiException {
      rethrow;
    } on FormatException catch (e) {
      throw ApiException(
        kind: ApiErrorKind.invalidResponse,
        message: e.message,
      );
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// `GET /auth/me` — memvalidasi token tersimpan dan mengambil profil akun
  /// beserta metadata token (tanpa token mentah).
  Future<MeSession> me() async {
    try {
      final response = await _dio.get<dynamic>('/auth/me');
      return MeSession.fromMeJson(ApiEnvelope.dataObject(response));
    } on FormatException catch (e) {
      throw ApiException(
        kind: ApiErrorKind.invalidResponse,
        message: e.message,
      );
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// `POST /auth/logout` — hapus token perangkat ini (idempoten di backend).
  Future<void> logout() async {
    try {
      await _dio.post<dynamic>('/auth/logout');
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// `POST /auth/logout-all` — hapus SEMUA token user (seluruh perangkat).
  Future<void> logoutAll() async {
    try {
      await _dio.post<dynamic>('/auth/logout-all');
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// `POST /auth/password` — ganti password. Backend mencabut SEMUA token;
  /// pengguna wajib login ulang setelahnya.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/auth/password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmation,
        },
      );
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}
