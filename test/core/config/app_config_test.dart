import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('default constructor menyimpan base URL & timeouts', () {
      const config = AppConfig(apiBaseUrl: 'http://10.0.2.2:8000/api/v1');
      expect(config.apiBaseUrl, 'http://10.0.2.2:8000/api/v1');
      expect(config.connectTimeout, const Duration(seconds: 15));
      expect(config.sendTimeout, const Duration(seconds: 15));
      expect(config.receiveTimeout, const Duration(seconds: 30));
    });

    test('normalizeBaseUrl menghapus trailing slash dan spasi', () {
      expect(
        AppConfig.normalizeBaseUrl('  http://10.0.2.2:8000/api/v1/  '),
        'http://10.0.2.2:8000/api/v1',
      );
      expect(
        AppConfig.normalizeBaseUrl('https://siakad.example.id/api/v1///'),
        'https://siakad.example.id/api/v1',
      );
    });

    test('normalizeBaseUrl menolak URL tanpa skema / host', () {
      expect(
        () => AppConfig.normalizeBaseUrl('10.0.2.2:8000/api/v1'),
        throwsArgumentError,
      );
      expect(
        () => AppConfig.normalizeBaseUrl('ftp://example.id/api/v1'),
        throwsArgumentError,
      );
      expect(() => AppConfig.normalizeBaseUrl(''), throwsArgumentError);
    });

    test('prefix API adalah /api/v1', () {
      expect(AppConfig.apiPrefix, '/api/v1');
    });

    test('environment key terdokumentasi', () {
      expect(AppConfig.baseUrlKey, 'API_BASE_URL');
    });
  });
}
