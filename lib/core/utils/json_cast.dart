/// Parsing toleran untuk nilai JSON dari backend.
///
/// Beberapa driver MySQL/PHP mengirim integer/boolean sebagai string
/// (mis. `tahun_masuk: "2024"`, `wajib_ganti_password: "1"`), sehingga
/// cast keras (`as num?` / `as bool?`) melempar `TypeError` yang sulit
/// didiagnosis di perangkat fisik — sementara HTTP tetap 200.
///
/// Seluruh model/repository memakai helper ini untuk angka & boolean.
class JsonCast {
  const JsonCast._();

  static int? intOrNull(Object? value) {
    if (value is num) return value.toInt();
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return int.tryParse(s) ?? double.tryParse(s)?.toInt();
  }

  static double? doubleOrNull(Object? value) {
    if (value is num) return value.toDouble();
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return double.tryParse(s);
  }

  /// true/false/1/0/"true"/"false"/"1"/"0" (case-insensitive). Lainnya → null.
  static bool? boolOrNull(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value?.toString().trim().toLowerCase();
    switch (s) {
      case 'true':
      case '1':
        return true;
      case 'false':
      case '0':
        return false;
      default:
        return null;
    }
  }
}
