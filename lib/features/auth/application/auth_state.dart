import '../data/models/auth_user.dart';

enum AuthStatus {
  /// Belum diketahui — sedang memulihkan sesi (splash).
  unknown,

  /// Tidak ada sesi valid; pengguna harus login.
  unauthenticated,

  /// Token tersimpan ditemukan tetapi tidak dapat diverifikasi ke server
  /// (mis. jaringan down). Pengguna dapat mencoba lagi dari splash.
  sessionCheckFailed,

  /// Sesi terverifikasi via `GET /auth/me`.
  authenticated,
}

/// State autentikasi tunggal yang dikonsumsi router & UI.
class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.wajibGantiPassword = false,
    this.tokenExpiresAt,
    this.deviceName,
    this.isSubmitting = false,
    this.errorMessage,
    this.errorCode,
    this.fieldErrors = const {},
    this.notice,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  const AuthState.unauthenticated({
    String? notice,
    String? errorMessage,
    String? errorCode,
  }) : this(
         status: AuthStatus.unauthenticated,
         notice: notice,
         errorMessage: errorMessage,
         errorCode: errorCode,
       );

  const AuthState.sessionCheckFailed(String message)
    : this(status: AuthStatus.sessionCheckFailed, errorMessage: message);

  final AuthStatus status;
  final AuthUser? user;
  final bool wajibGantiPassword;
  final DateTime? tokenExpiresAt;

  /// Nama perangkat sesuai metadata token di backend
  /// (mis. 'Flutter Android'), berasal dari `/auth/me` atau dari login.
  /// Bukan data sensitif dan tidak pernah berisi token.
  final String? deviceName;

  /// Sedang memproses login / change-password / logout (untuk disable tombol).
  final bool isSubmitting;

  /// Pesan error yang aman ditampilkan (sudah dinormalisasi).
  final String? errorMessage;

  /// `code` terstruktur dari backend bila ada (mis. `ROLE_NOT_ALLOWED`,
  /// `ACCOUNT_INACTIVE`, `TOO_MANY_REQUESTS`). Null untuk error tanpa code
  /// (mis. 422). Dipakai UI untuk pemetaan pesan yang spesifik.
  final String? errorCode;

  /// Error validasi 422 per field.
  final Map<String, List<String>> fieldErrors;

  /// Pesan info sekali tampil (mis. "Password berhasil diubah").
  final String? notice;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Role mobile pengguna, atau null bila belum login.
  String? get role => user?.level;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool? wajibGantiPassword,
    DateTime? tokenExpiresAt,
    String? deviceName,
    bool? isSubmitting,
    String? errorMessage,
    String? errorCode,
    Map<String, List<String>>? fieldErrors,
    String? notice,
    bool clearUser = false,
    bool clearError = false,
    bool clearNotice = false,
    bool clearFieldErrors = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      wajibGantiPassword: clearUser
          ? false
          : (wajibGantiPassword ?? this.wajibGantiPassword),
      tokenExpiresAt: clearUser
          ? null
          : (tokenExpiresAt ?? this.tokenExpiresAt),
      deviceName: clearUser ? null : (deviceName ?? this.deviceName),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      fieldErrors: clearFieldErrors
          ? const {}
          : (fieldErrors ?? this.fieldErrors),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}
