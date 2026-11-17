/// Klasifikasi error standar aplikasi SIAKAD Mobile.
///
/// `kind` membedakan kegagalan jaringan vs kegagalan HTTP vs respons
/// yang tidak dapat diparsing, sehingga UI dapat menampilkan pesan yang
/// sesuai tanpa menebak-nebak dari tipe exception Dio.
enum ApiErrorKind {
  /// Request dibatalkan / tidak terkirim karena tidak ada koneksi internet
  /// atau host tidak dapat dihubungi.
  noConnection,

  /// Connect / send / receive timeout.
  timeout,

  /// Respons HTTP error yang body-nya berupa envelope JSON API
  /// (`{ success: false, message, code?, errors? }`).
  http,

  /// Respons HTTP diterima, tetapi body bukan JSON object yang valid.
  invalidResponse,

  /// Kesalahan tak dikenal.
  unknown,
}

/// Exception standar aplikasi. Semua error API dinormalisasi menjadi tipe ini
/// oleh `ErrorMapper`, sehingga presentation layer tidak bergantung pada Dio.
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.code,
    this.fieldErrors = const {},
  });

  final ApiErrorKind kind;

  /// Pesan yang aman ditampilkan ke pengguna (Bahasa Indonesia dari backend,
  /// atau fallback generik). Tidak pernah memuat stack trace.
  final String message;

  /// HTTP status code bila ada respons dari server (null untuk timeout/no
  /// connection).
  final int? statusCode;

  /// `code` terstruktur dari envelope backend, mis. `ROLE_NOT_ALLOWED`,
  /// `ACCOUNT_INACTIVE`, `PASSWORD_CHANGE_REQUIRED`, `UNAUTHENTICATED`.
  /// `null` untuk error 422 dari backend (backend tidak mengirim code).
  final String? code;

  /// Error validasi per field (422). Keys = nama field.
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422;
  bool get isRateLimited => statusCode == 429;
  bool get isServerError => (statusCode ?? 0) >= 500;

  /// Code-code 403 khusus dari backend.
  bool get isAccountInactive => code == 'ACCOUNT_INACTIVE';
  bool get isPasswordChangeRequired => code == 'PASSWORD_CHANGE_REQUIRED';
  bool get isRoleNotAllowed => code == 'ROLE_NOT_ALLOWED';

  @override
  String toString() =>
      'ApiException(kind: $kind, statusCode: $statusCode, code: $code, message: $message)';
}
