import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/utils/formatters.dart';
import 'package:siakad_mobile/core/widgets/app_widgets.dart';

void main() {
  group('AsyncValueView', () {
    testWidgets('loading menampilkan progress indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueView<String>(
              value: const AsyncValue<String>.loading(),
              data: (d) => Text(d),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'error menampilkan pesan + tombol retry; retry memanggil aksi',
      (tester) async {
        var retried = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AsyncValueView<String>(
                value: AsyncValue<String>.error('boom', StackTrace.current),
                onRetry: () => retried++,
                data: (d) => Text(d),
              ),
            ),
          ),
        );
        expect(find.textContaining('Gagal memuat data'), findsOneWidget);
        await tester.tap(find.text('Coba Lagi'));
        expect(retried, 1);
      },
    );

    testWidgets('data kosong memakai empty view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueView<List<String>>(
              value: const AsyncData<List<String>>([]),
              isEmpty: (items) => items.isEmpty,
              empty: const Text('Kosong'),
              data: (items) => Text('Isi ${items.length}'),
            ),
          ),
        ),
      );
      expect(find.text('Kosong'), findsOneWidget);
    });

    testWidgets('data tampil normal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueView<String>(
              value: const AsyncData<String>('Berhasil'),
              data: (d) => Text(d),
            ),
          ),
        ),
      );
      expect(find.text('Berhasil'), findsOneWidget);
    });
  });

  group('AppErrorRetry', () {
    testWidgets('menampilkan pesan + memanggil onRetry', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorRetry(
              message: 'Gagal memuat.',
              onRetry: () => retried++,
            ),
          ),
        ),
      );
      expect(find.text('Gagal memuat.'), findsOneWidget);
      await tester.tap(find.text('Coba Lagi'));
      expect(retried, 1);
    });
  });

  group('StatusBadge', () {
    test('labelOf menerjemahkan status backend yang dikenal', () {
      expect(StatusBadge.labelOf('hadir'), 'Hadir');
      expect(StatusBadge.labelOf('lunas'), 'Lunas');
      expect(StatusBadge.labelOf('dibayar_sebagian'), 'Dibayar Sebagian');
      expect(StatusBadge.labelOf('tidak_dikenal'), 'tidak_dikenal');
    });

    test('forStatus memakai warna AppColors untuk status dikenal', () {
      expect(StatusBadge.forStatus('hadir'), isNotNull);
      expect(StatusBadge.forStatus('alpha'), isNotNull);
      expect(StatusBadge.forStatus('expired'), isNotNull);
      expect(StatusBadge.forStatus('yang_lain'), isNull);
    });
  });

  group('Formatters.initials', () {
    test('nama biasa → maks 2 inisial kapital', () {
      expect(Formatters.initials('Siswa Uji'), 'SU');
      expect(Formatters.initials('andika'), 'A');
      expect(Formatters.initials('  Budi  Santoso  '), 'BS');
    });

    test('nama kosong/aneh → ?', () {
      expect(Formatters.initials(''), '?');
      expect(Formatters.initials('   '), '?');
      expect(Formatters.initials(null), '?');
    });
  });
}
