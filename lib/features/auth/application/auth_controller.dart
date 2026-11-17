import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/auth_repository.dart';
import '../data/models/me_session.dart';
import 'auth_state.dart';

/// Controller autentikasi (Riverpod Notifier).
///
/// - Memulihkan sesi saat aplikasi dibuka (`restoreSession`).
/// - Token TIDAK PERNAH dianggap valid hanya karena tersimpan — selalu
///   diverifikasi ke `GET /auth/me`.
/// - 401 dari server → sesi lokal dibersihkan → pengguna diarahkan login.
/// - Role diverifikasi pasca login/restore; role di luar siswa/guru/wali
///   ditolak (sesi dibersihkan) — defense-in-depth di samping backend.
/// - TIDAK ada refresh token (backend tidak menyediakannya).
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;
  late final SecureStorageService _storage;

  /// Mencegah restore berjalan paralel (splash bisa memanggil ulang via retry).
  bool _restoreInFlight = false;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _storage = ref.watch(secureStorageServiceProvider);
    // Mulai pemulihan sesi setelah build selesai.
    Future.microtask(restoreSession);
    return const AuthState.unknown();
  }

  // ------------------------------------------------------------------
  // Pemulihan sesi
  // ------------------------------------------------------------------

  Future<void> restoreSession() async {
    if (_restoreInFlight) return; // restore sedang berjalan — jangan dobel.
    _restoreInFlight = true;
    state = const AuthState.unknown();
    try {
      String? token;
      try {
        token = await _storage.readToken();
      } catch (_) {
        // Secure storage gagal dibaca (mis. keystore terkunci). Token
        // TIDAK dihapus; pengguna dapat mencoba lagi dari splash.
        state = AuthState.sessionCheckFailed(
          'Tidak dapat membaca data sesi perangkat. Coba lagi.',
        );
        return;
      }
      if (token == null || token.isEmpty) {
        state = const AuthState.unauthenticated();
        return;
      }
      try {
        final me = await _repository.me();
        if (!_isAllowedRole(me.user.level)) {
          await _rejectRole();
          return;
        }
        await _storage.saveSessionMeta(_metaOf(me));
        state = AuthState(
          status: AuthStatus.authenticated,
          user: me.user,
          wajibGantiPassword: me.user.wajibGantiPassword,
          tokenExpiresAt: me.tokenExpiresAt,
          deviceName: me.tokenName,
        );
      } on ApiException catch (e) {
        if (e.isUnauthorized || e.isAccountInactive) {
          // Token kedaluwarsa/dicabut atau akun dinonaktifkan — sesi dibersihkan.
          await _storage.clearSession();
          state = AuthState.unauthenticated(
            notice: e.isAccountInactive
                ? 'Akun tidak dapat digunakan. Hubungi admin sekolah.'
                : 'Sesi Anda telah berakhir. Silakan login kembali.',
          );
          return;
        }
        // Error jaringan / server: token dipertahankan, pengguna bisa coba lagi.
        state = AuthState.sessionCheckFailed(
          'Tidak dapat memverifikasi sesi. Periksa koneksi Anda lalu coba lagi.',
        );
      } catch (_) {
        state = AuthState.sessionCheckFailed(
          'Tidak dapat memverifikasi sesi. Periksa koneksi Anda lalu coba lagi.',
        );
      }
    } finally {
      _restoreInFlight = false;
    }
  }

  // ------------------------------------------------------------------
  // Login / logout
  // ------------------------------------------------------------------

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (state.isSubmitting) return; // guard double-tap dari controller.
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearFieldErrors: true,
      clearNotice: true,
    );
    try {
      final session = await _repository.login(
        username: username,
        password: password,
        deviceName: _deviceName(),
      );
      if (!_isAllowedRole(session.user.level)) {
        // Backend idealnya menolak lebih dulu (403 ROLE_NOT_ALLOWED), tetapi
        // defense-in-depth: jangan pernah membuka dashboard untuk role lain.
        await _storage.clearSession();
        state = AuthState.unauthenticated(
          errorCode: 'ROLE_NOT_ALLOWED',
          errorMessage: _roleNotAllowedMessage,
        );
        return;
      }
      final deviceName = _deviceName();
      await _storage.saveToken(session.token);
      await _storage.saveSessionMeta(
        SessionMeta(
          userId: session.user.id,
          userName: session.user.name,
          username: session.user.username,
          level: session.user.level,
          wajibGantiPassword: session.wajibGantiPassword,
          tokenExpiresAt: session.expiresAt,
          deviceName: deviceName,
        ),
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
        wajibGantiPassword: session.wajibGantiPassword,
        tokenExpiresAt: session.expiresAt,
        deviceName: deviceName,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _friendlyMessage(e),
        errorCode: e.code,
        fieldErrors: e.fieldErrors,
      );
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
    }
  }

  /// Logout perangkat ini. Server gagal pun sesi lokal tetap dibersihkan.
  Future<void> logout() async {
    if (state.isSubmitting) return;
    await _logoutInternal(allDevices: false);
  }

  /// Logout seluruh perangkat milik user.
  Future<void> logoutAll() async {
    if (state.isSubmitting) return;
    await _logoutInternal(allDevices: true);
  }

  Future<void> _logoutInternal({required bool allDevices}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      if (allDevices) {
        await _repository.logoutAll();
      } else {
        await _repository.logout();
      }
    } on ApiException {
      // 401 (token sudah tidak valid) maupun error jaringan/server:
      // sesi lokal TETAP dibersihkan; token di server kedaluwarsa (30 hari).
    } catch (_) {
      // Abaikan — pembersihan lokal tetap dijalankan.
    }
    await _storage.clearSession();
    state = AuthState.unauthenticated(
      notice: allDevices
          ? 'Seluruh perangkat telah logout. Silakan login kembali.'
          : 'Anda telah logout.',
    );
  }

  // ------------------------------------------------------------------
  // Ganti password
  // ------------------------------------------------------------------

  /// Mengganti password. Backend mencabut SEMUA token setelahnya,
  /// sehingga pengguna selalu diarahkan login ulang.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    if (state.isSubmitting) return false; // guard double-tap.
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearFieldErrors: true,
    );
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmation: confirmation,
      );
      await _storage.clearSession();
      state = const AuthState.unauthenticated(
        notice: 'Password berhasil diubah. Silakan login kembali.',
      );
      return true;
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.isAccountInactive) {
        await _storage.clearSession();
        state = const AuthState.unauthenticated(
          notice: 'Sesi Anda telah berakhir. Silakan login kembali.',
        );
        return false;
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
        errorCode: e.code,
        fieldErrors: e.fieldErrors,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
      return false;
    }
  }

  // ------------------------------------------------------------------
  // Role & pesan
  // ------------------------------------------------------------------

  static const String _roleNotAllowedMessage =
      'Akses tidak tersedia untuk aplikasi mobile. '
      'Aplikasi ini hanya untuk siswa, guru, dan wali murid.';

  bool _isAllowedRole(String? level) => AppConstants.isMobileRole(level);

  /// Sesi role tidak valid: bersihkan lokal, arahkan ke login, tampilkan error.
  Future<void> _rejectRole() async {
    await _storage.clearSession();
    state = const AuthState.unauthenticated(
      errorCode: 'ROLE_NOT_ALLOWED',
      errorMessage: _roleNotAllowedMessage,
    );
  }

  /// Pemetaan pesan ramah untuk kode error backend yang dikenal.
  /// Backend biasanya sudah mengirim pesan Indonesia yang aman — pakai bila ada.
  String _friendlyMessage(ApiException e) {
    switch (e.code) {
      case 'ROLE_NOT_ALLOWED':
        return _roleNotAllowedMessage;
      case 'ACCOUNT_INACTIVE':
        return 'Akun tidak dapat digunakan. Hubungi admin sekolah.';
      case 'TOO_MANY_REQUESTS':
        return 'Terlalu banyak percobaan login. '
            'Tunggu sebentar lalu coba lagi.';
      default:
        return e.message;
    }
  }

  // ------------------------------------------------------------------
  // Util
  // ------------------------------------------------------------------

  void clearNotice() => state = state.copyWith(clearNotice: true);

  void clearError() => state = state.copyWith(clearError: true);

  SessionMeta _metaOf(MeSession me) => SessionMeta(
    userId: me.user.id,
    userName: me.user.name,
    username: me.user.username,
    level: me.user.level,
    wajibGantiPassword: me.user.wajibGantiPassword,
    tokenExpiresAt: me.tokenExpiresAt,
    deviceName: me.tokenName,
  );

  String _deviceName() {
    try {
      if (Platform.isIOS) return 'Flutter iOS';
      if (Platform.isAndroid) return 'Flutter Android';
      return 'Flutter';
    } catch (_) {
      return 'Flutter';
    }
  }
}

final authStateProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
