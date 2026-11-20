import 'dart:convert';

import '../utils/json_cast.dart';
import 'secure_key_value_store.dart';

/// Metadata sesi non-sensitif yang disimpan bersama token agar splash
/// dapat menampilkan konteks awal. Sumber kebenaran tetap `GET /auth/me`.
class SessionMeta {
  const SessionMeta({
    required this.userId,
    required this.userName,
    required this.username,
    required this.level,
    required this.wajibGantiPassword,
    this.tokenExpiresAt,
    this.deviceName,
  });

  final int userId;
  final String userName;
  final String username;
  final String level;
  final bool wajibGantiPassword;
  final DateTime? tokenExpiresAt;
  final String? deviceName;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_name': userName,
    'username': username,
    'level': level,
    'wajib_ganti_password': wajibGantiPassword,
    'token_expires_at': tokenExpiresAt?.toIso8601String(),
    'device_name': deviceName,
  };

  factory SessionMeta.fromJson(Map<String, dynamic> json) {
    final id = json['user_id'];
    return SessionMeta(
      userId: id is int ? id : int.parse(id.toString()),
      userName: (json['user_name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      wajibGantiPassword:
          JsonCast.boolOrNull(json['wajib_ganti_password']) ?? false,
      tokenExpiresAt: json['token_expires_at'] != null
          ? DateTime.tryParse(json['token_expires_at'].toString())
          : null,
      deviceName: json['device_name']?.toString(),
    );
  }
}

/// Penyimpanan sesi berbasis secure storage.
///
/// Yang disimpan: token Sanctum (wajib) + metadata sesi minimum
/// (id/nama/username/level/wajib_ganti_password/expires_at).
/// Yang TIDAK disimpan: password, data akademik, data pribadi anak, dsb.
class SecureStorageService {
  SecureStorageService(this._store);

  final SecureKeyValueStore _store;

  static const String tokenKey = 'siakad.auth_token';
  static const String sessionMetaKey = 'siakad.session_meta';

  // ---- Token -----------------------------------------------------------

  Future<void> saveToken(String token) => _store.write(tokenKey, token);

  Future<String?> readToken() => _store.read(tokenKey);

  Future<void> deleteToken() => _store.delete(tokenKey);

  // ---- Metadata sesi ---------------------------------------------------

  Future<void> saveSessionMeta(SessionMeta meta) =>
      _store.write(sessionMetaKey, jsonEncode(meta.toJson()));

  Future<SessionMeta?> readSessionMeta() async {
    final raw = await _store.read(sessionMetaKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return SessionMeta.fromJson(decoded);
      if (decoded is Map) {
        return SessionMeta.fromJson(Map<String, dynamic>.from(decoded));
      }
      return null;
    } on FormatException {
      // Data korup — bersihkan agar tidak dipakai terus-menerus.
      await _store.delete(sessionMetaKey);
      return null;
    }
  }

  Future<void> deleteSessionMeta() => _store.delete(sessionMetaKey);

  /// Hapus seluruh jejak sesi lokal (dipanggil saat logout / 401 /
  /// password berhasil diubah).
  Future<void> clearSession() async {
    await _store.delete(tokenKey);
    await _store.delete(sessionMetaKey);
  }
}
