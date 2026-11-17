import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/errors/api_exception.dart';
import 'package:siakad_mobile/features/siswa/application/siswa_providers.dart';

import '../../fakes/harness.dart';

void main() {
  group('ringkasan & saldo', () {
    test('ringkasan sukses: nominal integer terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, ringkasanKeuanganBody());

      final repo = h.container.read(keuanganRepositoryProvider);
      final ringkasan = await repo.ringkasan();

      expect(ringkasan.totalKewajiban, 1500000);
      expect(ringkasan.totalDibayar, 500000);
      expect(ringkasan.sisaKewajiban, 1000000);
      expect(ringkasan.saldo, 250000);
      expect(h.adapter.requests.single.path, '/keuangan/ringkasan');
      // Siswa tidak mengirim siswa_id.
      expect(
        h.adapter.requests.single.queryParameters.containsKey('siswa_id'),
        isFalse,
      );
    });

    test('saldo sukses', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {'saldo': 175000},
      });

      final repo = h.container.read(keuanganRepositoryProvider);
      expect(await repo.saldo(), 175000);
    });
  });

  group('tagihan', () {
    Map<String, dynamic> tagihanBody({String status = 'belum_dibayar'}) => {
      'success': true,
      'message': 'Berhasil',
      'data': [
        {
          'id': 42,
          'nama': 'SPP November 2026',
          'nominal': 750000,
          'terbayar': 250000,
          'sisa': 500000,
          'status': status,
          'jatuh_tempo': '2026-11-30',
        },
      ],
      'meta': {'current_page': 1, 'per_page': 15, 'last_page': 1, 'total': 1},
    };

    test('daftar tagihan: data array + meta tanpa from/to', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, tagihanBody());

      final repo = h.container.read(keuanganRepositoryProvider);
      final result = await repo.tagihan();

      expect(result.items.single.nama, 'SPP November 2026');
      expect(result.items.single.terbayar, 250000);
      expect(result.items.single.sisa, 500000);
      expect(result.meta?.from, isNull); // keuangan tidak mengirim from/to
      expect(result.meta?.total, 1);
    });

    test('filter status tagihan dikirim sebagai query', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, tagihanBody(status: 'lunas'));

      final repo = h.container.read(keuanganRepositoryProvider);
      await repo.tagihan(status: 'lunas', page: 2);

      final q = h.adapter.requests.single.queryParameters;
      expect(q['status'], 'lunas');
      expect(q['page'], 2);
    });

    test('detail tagihan sukses', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'id': 42,
          'nama': 'SPP November 2026',
          'nominal': 750000,
          'terbayar': 750000,
          'sisa': 0,
          'status': 'lunas',
          'jatuh_tempo': '2026-11-30',
        },
      });

      final repo = h.container.read(keuanganRepositoryProvider);
      final tagihan = await repo.tagihanDetail(42);

      expect(tagihan.status, 'lunas');
      expect(tagihan.sisa, 0);
      expect(h.adapter.requests.single.path, '/keuangan/tagihan/42');
    });

    test('detail tagihan tidak ditemukan: 404 dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(404, {
        'success': false,
        'message': 'Resource tidak ditemukan.',
        'code': 'NOT_FOUND',
      });

      final repo = h.container.read(keuanganRepositoryProvider);
      try {
        await repo.tagihanDetail(999);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.isNotFound, isTrue);
      }
    });
  });

  group('pembayaran', () {
    Map<String, dynamic> pembayaranBody() => {
      'success': true,
      'message': 'Berhasil',
      'data': [
        {
          'id': 17,
          'nominal': 500000,
          'metode': 'midtrans',
          'status': 'success',
          'dibayar_pada': '2026-11-17T09:00:00+07:00',
        },
      ],
      'meta': {'current_page': 1, 'per_page': 15, 'last_page': 1, 'total': 1},
    };

    test('riwayat pembayaran sukses', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, pembayaranBody());

      final repo = h.container.read(keuanganRepositoryProvider);
      final result = await repo.pembayaran();

      expect(result.items.single.nominal, 500000);
      expect(result.items.single.status, 'success');
      expect(h.adapter.requests.single.queryParameters['siswa_id'], isNull);
    });

    test('detail pembayaran sukses', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'id': 17,
          'nominal': 500000,
          'metode': 'midtrans',
          'status': 'success',
          'dibayar_pada': '2026-11-17T09:00:00+07:00',
        },
      });

      final repo = h.container.read(keuanganRepositoryProvider);
      final pembayaran = await repo.pembayaranDetail(17);

      expect(pembayaran.id, 17);
      expect(pembayaran.metode, 'midtrans');
    });
  });

  group('payment attempt', () {
    test('buat attempt: hanya tagihan_id, tanpa nominal', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(201, {
        'success': true,
        'message': 'Pembayaran dibuat.',
        'data': {
          'id': 8,
          'order_id': 'PAY-2026-0008',
          'nominal': 500000,
          'status': 'created',
          'snap_token': 'snap-token-uji',
          'snap_redirect_url':
              'https://app.sandbox.midtrans.com/snap/v2/vtweb/xyz',
        },
      });

      final repo = h.container.read(keuanganRepositoryProvider);
      final attempt = await repo.buatAttempt(tagihanId: 42);

      expect(attempt.status, 'created');
      expect(attempt.nominal, 500000); // dari backend
      expect(attempt.orderId, 'PAY-2026-0008');
      expect(attempt.snapRedirectUrl, isNotNull);

      final request = h.adapter.requests.single;
      expect(request.path, '/keuangan/pembayaran/attempts');
      expect(request.method, 'POST');
      expect((request.data as Map).keys, ['tagihan_id']); // payload minimal!
      expect((request.data as Map)['tagihan_id'], 42);
    });

    test('attempt gagal: 503 gateway tanpa code dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(503, {
        'success': false,
        'message': 'Gateway pembayaran tidak tersedia saat ini.',
      });

      final repo = h.container.read(keuanganRepositoryProvider);
      try {
        await repo.buatAttempt(tagihanId: 42);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 503);
        expect(e.message, contains('Gateway pembayaran'));
      }
    });

    test('attempt status: GET /attempts/{id}', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'id': 8,
          'order_id': 'PAY-2026-0008',
          'nominal': 500000,
          'status': 'pending',
          'snap_token': 'snap-token-uji',
          'snap_redirect_url': null,
        },
      });

      final repo = h.container.read(keuanganRepositoryProvider);
      final attempt = await repo.attemptStatus(8);

      expect(attempt.status, 'pending');
      expect(h.adapter.requests.single.path, '/keuangan/pembayaran/attempts/8');
    });
  });

  group('dokumen privat', () {
    test(
      'unduh bukti sukses: bytes + filename dari Content-Disposition',
      () async {
        final h = buildTestHarness();
        addTearDown(h.container.dispose);
        h.adapter.queueBytes(
          200,
          Uint8List.fromList([1, 2, 3, 4, 5]),
          filename: 'bukti-17.pdf',
        );

        final repo = h.container.read(keuanganRepositoryProvider);
        final dokumen = await repo.unduhBukti(17);

        expect(dokumen.filename, 'bukti-17.pdf');
        expect(dokumen.bytes, [1, 2, 3, 4, 5]);
        expect(h.adapter.requests.single.path, '/keuangan/pembayaran/17/bukti');
      },
    );

    test('unduh kuitansi error 404: pesan backend dipakai', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(404, {
        'success': false,
        'message': 'Kuitansi tidak tersedia.',
        'code': 'KUITANSI_NOT_FOUND',
      });

      final repo = h.container.read(keuanganRepositoryProvider);
      try {
        await repo.unduhKuitansi(17);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.code, 'KUITANSI_NOT_FOUND');
        expect(e.message, 'Kuitansi tidak tersedia.');
      }
    });

    test('unduh dokumen 403: pesan backend dipakai', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(403, {
        'success': false,
        'message': 'Anda tidak berhak mengakses dokumen ini.',
        'code': 'FORBIDDEN',
      });

      final repo = h.container.read(keuanganRepositoryProvider);
      try {
        await repo.unduhBukti(999);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.isForbidden, isTrue);
        expect(e.message, 'Anda tidak berhak mengakses dokumen ini.');
      }
    });
  });
}
