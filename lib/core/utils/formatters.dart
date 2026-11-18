/// Formatter tanggal & rupiah (manual, tanpa dependency tambahan).
///
/// Backend memakai format `YYYY-MM-DD`, ISO-8601, dan `hari` 1..7 (1=Senin).
class Formatters {
  const Formatters._();

  static const List<String> _bulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _hari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// `YYYY-MM-DD` → `17 November 2026`. Input tidak valid → string asli.
  static String tanggalPanjang(String? isoDate) {
    final d = _parseDate(isoDate);
    if (d == null) return isoDate ?? '-';
    return '${d.day} ${_bulan[d.month - 1]} ${d.year}';
  }

  /// `YYYY-MM-DD` → `Sel, 17 Nov 2026`.
  static String tanggalPendek(String? isoDate) {
    final d = _parseDate(isoDate);
    if (d == null) return isoDate ?? '-';
    return '${_hari[d.weekday - 1].substring(0, 3)}, ${d.day} '
        '${_bulan[d.month - 1].substring(0, 3)} ${d.year}';
  }

  /// Nama hari 1..7 (1=Senin).
  static String namaHari(int? hari) {
    if (hari == null || hari < 1 || hari > 7) return '-';
    return _hari[hari - 1];
  }

  /// ISO-8601 → `17 Nov 2026, 09:20` (waktu lokal perangkat).
  static String dateTimeLokal(String? iso) {
    final parsed = DateTime.tryParse(iso ?? '');
    if (parsed == null) return iso ?? '-';
    final d = parsed.toLocal();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_bulan[d.month - 1].substring(0, 3)} ${d.year}, $hh:$mm';
  }

  /// Integer rupiah → `Rp 150.000`.
  static String rupiah(num? value) {
    if (value == null) return '-';
    final intValue = value.round();
    final digits = intValue.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final pos = digits.length - i;
      buffer.write(digits[i]);
      if (pos > 1 && pos % 3 == 1) buffer.write('.');
    }
    return 'Rp ${intValue < 0 ? '-' : ''}$buffer';
  }

  /// Persen hadir dari backend (string lokal, mis. "87,5%") → tampilkan apa adanya.
  static String persenHadir(String? value) =>
      (value == null || value.isEmpty) ? '-' : value;

  /// Inisial nama (maks 2 huruf kapital) untuk avatar. Nama kosong → '?'.
  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    final letters = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.length < 10) return null;
    return DateTime.tryParse(value.substring(0, 10));
  }
}
