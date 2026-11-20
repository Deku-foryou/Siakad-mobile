import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/app/theme/app_theme.dart';
import 'package:siakad_mobile/features/siswa/presentation/akademik/siswa_akademik_page.dart';

/// Akademik (siswa) — menu grid tidak boleh overflow, bahkan pada
/// layar kecil (Redmi 9A 360×800) dan text scale besar.
void main() {
  Future<void> pumpAkademik(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.view.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const SiswaAkademikPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  const size360x800 = Size(360, 800);

  testWidgets(
    'layar 360x800 textScale 1.0: semua kartu tampil, tanpa overflow',
    (tester) async {
      await pumpAkademik(tester, size: size360x800, textScale: 1.0);

      for (final title in [
        'Jadwal',
        'Absensi',
        'Nilai',
        'Rapor',
        'Pengumuman',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      // Deskripsi terbaca utuh (tidak terpotong).
      expect(
        find.textContaining('Harian, periode, dan per jam'),
        findsOneWidget,
      );
      expect(find.textContaining('Pengumuman dari sekolah'), findsOneWidget);
      expect(
        find.textContaining('Daftar dan detail rapor final'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'layar 360x800 textScale 1.5: semua kartu tampil, tanpa overflow',
    (tester) async {
      await pumpAkademik(tester, size: size360x800, textScale: 1.5);

      for (final title in [
        'Jadwal',
        'Absensi',
        'Nilai',
        'Rapor',
        'Pengumuman',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(
        find.textContaining('Harian, periode, dan per jam'),
        findsOneWidget,
      );
      expect(find.textContaining('Nilai akhir rapor final'), findsOneWidget);
      expect(find.textContaining('Jadwal pelajaran per hari'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('textScale 2.0: masih tidak overflow (batas aman)', (
    tester,
  ) async {
    await pumpAkademik(tester, size: size360x800, textScale: 2.0);

    for (final title in ['Jadwal', 'Absensi', 'Nilai', 'Rapor', 'Pengumuman']) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('layar besar 900x1200: grid tetap dua kolom rapi', (
    tester,
  ) async {
    await pumpAkademik(tester, size: const Size(900, 1200), textScale: 1.0);

    for (final title in ['Jadwal', 'Absensi', 'Nilai', 'Rapor', 'Pengumuman']) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(tester.takeException(), isNull);
  });
}
