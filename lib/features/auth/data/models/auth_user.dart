/// Model user mobile sesuai `UserResource` backend:
/// `{ id, name, username, email, level, status_akun, wajib_ganti_password }`.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.level,
    required this.statusAkun,
    required this.wajibGantiPassword,
  });

  final int id;
  final String name;
  final String username;
  final String email;

  /// Role mobile: `siswa` | `guru` | `wali`.
  final String level;
  final String statusAkun;
  final bool wajibGantiPassword;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return AuthUser(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      statusAkun: (json['status_akun'] ?? '').toString(),
      wajibGantiPassword: json['wajib_ganti_password'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'level': level,
    'status_akun': statusAkun,
    'wajib_ganti_password': wajibGantiPassword,
  };
}
