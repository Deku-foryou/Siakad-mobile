// Regulasi konfigurasi Release & Deployment Readiness — final verification (§9).
// Pemeriksaan statik (file-based) tanpa dependencies:
// - Identifier permanen `com.apps.siakad` konsisten di Android/iOS/macOS/Linux build config.
// - Tidak ada identifier lama aktif (`com.example.siakad_mobile`, `com.example.siakadMobile`,
//   `com.deku.siakad`) di konfigurasi build.
// - Release — menolak cleartext HTTP (manifest + gate AppConfig).
// - Release — tidak memakai debug signing fallback.
// - Debug — tetap memakai backend lokal HTTP (manifest).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/config/app_config.dart';

const String kAppId = 'com.apps.siakad';

String _read(String path) => File(path).readAsStringSync();

bool _exists(String path) => File(path).existsSync();

bool _isSkipped(String p) =>
    p.contains(r'\.gradle\') ||
    p.contains(r'\build\') ||
    p.contains(r'\ephemeral\');

List<String> _walkFiles(String root, List<String> exts) {
  final out = <String>[];
  if (!Directory(root).existsSync()) return out;
  for (final e in Directory(
    root,
  ).listSync(recursive: true, followLinks: false)) {
    if (e is! File) continue;
    final p = e.path;
    if (_isSkipped(p)) continue;
    final lower = p.toLowerCase();
    if (exts.any((x) => lower.endsWith(x))) out.add(p);
  }
  return out;
}

void _expectTreeNoContains(
  String root,
  List<String> needles,
  List<String> exts,
) {
  final hits = <String>[];
  for (final f in _walkFiles(root, exts)) {
    final c = _read(f);
    for (final n in needles) {
      if (c.contains(n)) hits.add('$f -> "$n"');
    }
  }
  expect(
    hits,
    isEmpty,
    reason: '$root masih mengandung identifier lama: $hits',
  );
}

void main() {
  group('Permanent Application ID — Android (§3)', () {
    test('namespace & applicationId di android/app/build.gradle.kts', () {
      final g = _read('android/app/build.gradle.kts');
      expect(g, contains('namespace = "$kAppId"'));
      expect(g, contains('applicationId = "$kAppId"'));
    });

    test('MainActivity package di android/app/src/main/kotlin/com/apps/siakad/MainActivity.kt (file di-move)', () {
      const p = 'android/app/src/main/kotlin/com/apps/siakad/MainActivity.kt';
      expect(
        _exists(p),
        isTrue,
        reason: 'MainActivity.kt harus di-move ke package com/apps/siakad',
      );
      expect(_read(p), contains('package $kAppId'));
    });

    test('Tidak ada identifier lama aktif di android/ (file .kt/.java/.kts/.xml/.gradle/.cmake/.properties)', () {
      _expectTreeNoContains(
        'android',
        ['com.example', 'com.deku.siakad'],
        [
          '.kt',
          '.java',
          '.kts',
          '.xml',
          '.gradle',
          '.cmake',
          '.properties',
          'cmakelists.txt',
        ],
      );
    });

    test('Tidak ada identifier lama aktif di linux/CMakeLists.txt', () {
      _expectTreeNoContains(
        'linux',
        ['com.example', 'com.deku.siakad'],
        ['.cmake', '.txt', '.c', '.h', '.cpp'],
      );
    });
  });

  group('Permanent Application ID — iOS & macOS (§3)', () {
    test(
      'iOS pbxproj — PRODUCT_BUNDLE_IDENTIFIER = com.apps.siakad (Runner)',
      () {
        final p = _read('ios/Runner.xcodeproj/project.pbxproj');
        expect(p, contains('PRODUCT_BUNDLE_IDENTIFIER = $kAppId;'));
      },
    );

    test(
      'iOS pbxproj — PRODUCT_BUNDLE_IDENTIFIER = com.apps.siakad.RunnerTests',
      () {
        final p = _read('ios/Runner.xcodeproj/project.pbxproj');
        expect(p, contains('PRODUCT_BUNDLE_IDENTIFIER = $kAppId.RunnerTests;'));
      },
    );

    test(
      'macOS pbxproj — PRODUCT_BUNDLE_IDENTIFIER = com.apps.siakad.RunnerTests',
      () {
        final p = _read('macos/Runner.xcodeproj/project.pbxproj');
        expect(p, contains('PRODUCT_BUNDLE_IDENTIFIER = $kAppId.RunnerTests;'));
      },
    );

    test(
      'macOS AppInfo.xcconfig — PRODUCT_BUNDLE_IDENTIFIER = com.apps.siakad',
      () {
        expect(
          _read('macos/Runner/Configs/AppInfo.xcconfig'),
          contains('PRODUCT_BUNDLE_IDENTIFIER = $kAppId'),
        );
      },
    );

    test('Tidak ada identifier lama aktif di ios/ (termasuk pbxproj)', () {
      _expectTreeNoContains(
        'ios',
        ['com.example.siakadMobile', 'com.deku.siakad'],
        ['.xml', '.plist', '.m', '.h', '.swift', '.pbxproj'],
      );
    });

    test('Tidak ada identifier lama aktif di macos/ (bundle ID; Product-copyright out of scope)', () {
      _expectTreeNoContains(
        'macos',
        ['com.example.siakadMobile', 'com.deku.siakad'],
        ['.xml', '.xcconfig', '.pbxproj'],
      );
    });
  });

  group('Android Release Security — mainifest & signing (§5, §4)', () {
    test('Main manifest — release menolak cleartext: android:usesCleartextTraffic="false"', () {
      expect(
        _read('android/app/src/main/AndroidManifest.xml'),
        contains('android:usesCleartextTraffic="false"'),
      );
    });

    test(
      'Debug manifest — usesCleartextTraffic="true" (UAT backend lokal HTTP)',
      () {
        expect(
          _read('android/app/src/debug/AndroidManifest.xml'),
          contains('android:usesCleartextTraffic="true"'),
        );
      },
    );

    test('Tidak ada network security config di android/app/src/main/res', () {
      expect(
        _exists('android/app/src/main/res/xml/network_security_config.xml'),
        isFalse,
      );
    });

    test('Tidak ada debug signing fallback di build.gradle.kts', () {
      expect(
        _read('android/app/build.gradle.kts'),
        isNot(contains('signingConfigs.getByName("debug")')),
      );
    });
  });

  group('Release HTTPS Gate — AppConfig (§5)', () {
    test('Release menolah HTTP tanpa escape hatch: resolveBaseUrl(release, http) throws', () {
      expect(
        () => AppConfig.resolveBaseUrl(
          'http://10.0.2.2:8000/api/v1',
          release: true,
          allowHttpInRelease: false,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Release mengizinkan http hanya bila escape hatch eksplisit (dokoned, sejalan §5)', () {
      expect(
        AppConfig.resolveBaseUrl(
          'http://10.0.2.2:8000/api/v1',
          release: true,
          allowHttpInRelease: true,
        ),
        'http://10.0.2.2:8000/api/v1',
      );
    });

    test('Release wajib HTTPS: https URL dicekakan (returns normally)', () {
      expect(
        AppConfig.resolveBaseUrl(
          'https://api.example.test/api/v1',
          release: true,
          allowHttpInRelease: false,
        ),
        'https://api.example.test/api/v1',
      );
    });

    test('Release tanpa API_BASE_URL → StateError (wajib isi)', () {
      expect(
        () => AppConfig.resolveBaseUrl(
          '',
          release: true,
          allowHttpInRelease: false,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Debug tetap memakai backend lokal HTTP (default dev URL)', () {
      final dev = AppConfig.resolveBaseUrl(
        '',
        release: false,
        allowHttpInRelease: false,
      );
      expect(dev, startsWith('http://'));
    });
  });
}
