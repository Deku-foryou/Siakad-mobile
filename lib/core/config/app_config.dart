/// Konfigurasi aplikasi terpusat.
///
/// Base URL API dikonfigurasi lewat `--dart-define` (lihat contoh di bawah)
/// dan TIDAK di-hardcode ke environment production manapun.
///
/// Contoh menjalankan aplikasi (Android emulator):
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
/// ```
///
/// Catatan penting perbedaan alamat:
/// - Android emulator : `http://10.0.2.2:<port>/api/v1` -> `10.0.2.2` adalah
///   alamat khusus yang menunjuk ke host machine (localhost emulator BUKAN
///   host machine).
/// - iOS simulator    : `http://localhost:<port>/api/v1` atau `http://127.0.0.1:<port>/api/v1`.
/// - Physical device  : gunakan IP LAN komputer, mis. `http://192.168.1.10:<port>/api/v1`,
///   pastikan perangkat dan komputer berada pada jaringan yang sama.
library;

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  /// Konfigurasi default untuk development lokal via Android emulator.
  /// Untuk iOS simulator / physical device gunakan `--dart-define=API_BASE_URL=...`.
  static const String _defaultDevBaseUrl = 'http://10.0.2.2:8000/api/v1';

  factory AppConfig.fromEnvironment() {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _defaultDevBaseUrl,
    );
    return AppConfig(apiBaseUrl: normalizeBaseUrl(baseUrl));
  }

  /// Base URL API, termasuk prefix `/api/v1`. Tanpa trailing slash.
  final String apiBaseUrl;

  final Duration connectTimeout;
  final Duration sendTimeout;
  final Duration receiveTimeout;

  /// Prefix path API. Seluruh endpoint berada di bawah prefix ini.
  static const String apiPrefix = '/api/v1';

  /// Nama field environment untuk override base URL.
  static const String baseUrlKey = 'API_BASE_URL';

  /// Normalisasi: trim + hapus trailing slash. Melempar [ArgumentError] bila
  /// bukan URL http(s) yang valid.
  static String normalizeBaseUrl(String raw) {
    final value = raw.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(
        raw,
        'API_BASE_URL',
        'Harus berupa URL http(s) valid, mis. http://10.0.2.2:8000/api/v1',
      );
    }
    return value;
  }

  @override
  String toString() => 'AppConfig(apiBaseUrl: $apiBaseUrl)';
}
