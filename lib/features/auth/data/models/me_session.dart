import 'auth_user.dart';

/// Respons `GET /auth/me`: profil akun + metadata token (tanpa token mentah).
class MeSession {
  const MeSession({
    required this.user,
    this.tokenName,
    this.lastUsedAt,
    this.tokenExpiresAt,
  });

  final AuthUser user;
  final String? tokenName;
  final DateTime? lastUsedAt;
  final DateTime? tokenExpiresAt;

  factory MeSession.fromMeJson(Map<String, dynamic> data) {
    final userJson = data['user'];
    if (userJson is! Map) {
      throw const FormatException(
        'Data user tidak ditemukan pada respons /auth/me.',
      );
    }
    final tokenJson = data['token'];
    DateTime? parseIso(Object? v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return MeSession(
      user: AuthUser.fromJson(Map<String, dynamic>.from(userJson)),
      tokenName: tokenJson is Map ? tokenJson['name']?.toString() : null,
      lastUsedAt: tokenJson is Map ? parseIso(tokenJson['last_used_at']) : null,
      tokenExpiresAt: tokenJson is Map
          ? parseIso(tokenJson['expires_at'])
          : null,
    );
  }
}
