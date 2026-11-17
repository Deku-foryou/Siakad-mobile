import 'auth_user.dart';

/// Sesi hasil login: token + metadata. Dibuat oleh AuthRepository dari
/// respons `POST /auth/login` dan dipakai untuk menyimpan sesi lokal.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.tokenType,
    required this.wajibGantiPassword,
    required this.user,
    this.expiresAt,
  });

  final String token;
  final String tokenType;
  final DateTime? expiresAt;
  final bool wajibGantiPassword;
  final AuthUser user;

  factory AuthSession.fromLoginJson(Map<String, dynamic> data) {
    final token = (data['token'] ?? '').toString();
    final userJson = data['user'];
    if (token.isEmpty) {
      throw const FormatException('Token tidak ditemukan pada respons login.');
    }
    if (userJson is! Map) {
      throw const FormatException(
        'Data user tidak ditemukan pada respons login.',
      );
    }
    return AuthSession(
      token: token,
      tokenType: (data['token_type'] ?? 'Bearer').toString(),
      expiresAt: data['expires_at'] != null
          ? DateTime.tryParse(data['expires_at'].toString())
          : null,
      wajibGantiPassword: (data['wajib_ganti_password'] as bool?) ?? false,
      user: AuthUser.fromJson(Map<String, dynamic>.from(userJson)),
    );
  }
}
