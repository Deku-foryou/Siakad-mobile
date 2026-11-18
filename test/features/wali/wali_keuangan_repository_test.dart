import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/errors/api_exception.dart';
import 'package:siakad_mobile/features/wali/application/wali_providers.dart';

import '../../fakes/harness.dart';

/// Repository keuangan wali — endpoint `/keuangan/*` bersama siswa,
/// tetapi untuk wali SELALU membawa `siswa_id` (query/body).
void main() {
  group('ringkasan & saldo', () {
    test('ringkasan: siswa_id dikirim sebagai query param', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, ringkasanKeuanganBody());

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      final ringkasan = await repo.ringkasan(201);

      expect(ringkasan.sisaKewajiban, 1000000);
      expect(ringkasan.saldo, 250000);

      final request = h.adapter.requests.single;
      expect(request.path, '/keuangan/ringkasan');
      expect(request.queryParameters['siswa_id'], 201);
    });

    test('ringkasan 403 (relasi bukan verified) dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(403, {
        'success': false,
        'message': 'Akses ditolak atau data tidak ditemukan.',
      });

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      try {
        await repo.ringkasan(202);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 403);
      }
    });

    test('saldo: parsing num & string', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter
        ..respondJson(200, {
          'success': true,
          'message': 'Berhasil',
          'data': {'saldo': 250000},
        })
        ..respondJson(200, {
          'success': true,
          'message': 'Berhasil',
          'data': {'saldo': '175000'},
        });

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      expect(await repo.saldo(201), 250000);
      expect(await repo.saldo(201), 175000);

      expect(
        h.adapter.requests.map((r) => r.queryParameters['siswa_id']),
        everyElement(201),
      );
    });
  });

  group('tagihan & pembayaran', () {
    test('tagihan: siswa_id + status filter + pagination meta', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': [
          {
            'id': 71,
            'nama': 'SPP November',
            'nominal': 500000,
            'terbayar': 150000,
            'sisa': 350000,
            'status': 'dibayar_sebagian',
            'jatuh_tempo': '2026-11-30',
          },
        ],
        'meta': {
          'current_page': 1,
          'per_page': 15,
          'last_page': 2,
          'total': 20,
        },
      });

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      final result = await repo.tagihan(201, status: 'dibayar_sebagian');

      expect(result.items.single.nama, 'SPP November');
      expect(result.items.single.sisa, 350000);
      expect(result.meta?.hasMore, isTrue);

      final request = h.adapter.requests.single;
      expect(request.queryParameters['siswa_id'], 201);
      expect(request.queryParameters['status'], 'dibayar_sebagian');
    });

    test('tagihan kosong: data [] tanpa error', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, tagihanListBody());

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      final result = await repo.tagihan(201);

      expect(result.items, isEmpty);
    });

    test('tagihan detail: siswa_id dikirim', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'id': 71,
          'nama': 'SPP November',
          'nominal': 500000,
          'terbayar': 0,
          'sisa': 500000,
          'status': 'belum_dibayar',
          'jatuh_tempo': '2026-11-30',
        },
      });

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      final detail = await repo.tagihanDetail(201, 71);

      expect(detail.id, 71);
      expect(detail.status, 'belum_dibayar');

      final request = h.adapter.requests.single;
      expect(request.path, '/keuangan/tagihan/71');
      expect(request.queryParameters['siswa_id'], 201);
    });

    test('pembayaran: siswa_id dikirim, list terpetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': [
          {
            'id': 901,
            'nominal': 500000,
            'metode': 'midtrans',
            'status': 'success',
            'dibayar_pada': '2026-11-10T09:30:00+07:00',
          },
        ],
        'meta': {'current_page': 1, 'per_page': 15, 'last_page': 1, 'total': 1},
      });

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      final result = await repo.pembayaran(201);

      expect(result.items.single.status, 'success');
      expect(h.adapter.requests.single.queryParameters['siswa_id'], 201);
    });

    test('pembayaran detail: siswa_id dikirim', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'id': 901,
          'nominal': 500000,
          'metode': 'midtrans',
          'status': 'success',
          'dibayar_pada': '2026-11-10T09:30:00+07:00',
        },
      });

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      final detail = await repo.pembayaranDetail(201, 901);

      expect(detail.id, 901);
      expect(h.adapter.requests.single.queryParameters['siswa_id'], 201);
    });
  });

  group('payment attempt', () {
    test('buat attempt: body mengirim tagihan_id + siswa_id', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(201, {
        'success': true,
        'message': 'Pembayaran dibuat.',
        'data': {
          'id': 331,
          'order_id': 'ORD-331',
          'nominal': 350000,
          'status': 'created',
          'snap_token': 'snap-token-abc',
          'snap_redirect_url':
              'https://app.midtrans.com/snap/v4/redirection/abc',
        },
      });

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      final attempt = await repo.buatAttempt(siswaId: 201, tagihanId: 71);

      expect(attempt.id, 331);
      expect(attempt.orderId, 'ORD-331');
      expect(attempt.status, 'created');

      final request = h.adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/keuangan/pembayaran/attempts');
      expect(request.data, isA<Map>());
      final body = Map<String, dynamic>.from(request.data as Map);
      expect(body['tagihan_id'], 71);
      expect(body['siswa_id'], 201);
      expect(body.containsKey('nominal'), isFalse);
    });

    test('buat attempt 503 (gateway tidak tersedia) dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(503, {
        'success': false,
        'message': 'Gateway pembayaran tidak tersedia saat ini.',
      });

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      try {
        await repo.buatAttempt(siswaId: 201, tagihanId: 71);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 503);
      }
    });

    test('attempt status: siswa_id dikirim; status dari server', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(200, {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'id': 331,
          'order_id': 'ORD-331',
          'nominal': 350000,
          'status': 'pending',
          'snap_token': null,
          'snap_redirect_url': null,
        },
      });

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      final attempt = await repo.attemptStatus(201, 331);

      expect(attempt.status, 'pending');
      expect(h.adapter.requests.single.queryParameters['siswa_id'], 201);
    });
  });

  group('dokumen privat', () {
    test('unduh bukti sukses: bytes + filename dari content-disposition', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.queueBytes(200, [1, 2, 3, 4], filename: 'bukti-901.pdf');

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      final dokumen = await repo.unduhBukti(901);

      expect(dokumen.bytes, [1, 2, 3, 4]);
      expect(dokumen.filename, 'bukti-901.pdf');
      expect(dokumen.contentType, 'application/pdf');

      final request = h.adapter.requests.single;
      expect(request.path, '/keuangan/pembayaran/901/bukti');
      // Endpoint dokumen TIDAK membawa siswa_id — ownership dicek server-side.
      expect(request.queryParameters, isEmpty);
    });

    test('unduh kuitansi 403 dipetakan sebagai ApiException(403)', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(403, {
        'success': false,
        'message': 'Anda tidak berhak mengakses dokumen ini.',
        'code': 'FORBIDDEN',
      });

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      try {
        await repo.unduhKuitansi(901);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 403);
      }
    });

    test('unduh kuitansi 404 dipetakan sebagai ApiException(404)', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(404, {
        'success': false,
        'message': 'Kuitansi tidak tersedia.',
        'code': 'KUITANSI_NOT_FOUND',
      });

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      try {
        await repo.unduhKuitansi(901);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 404);
        expect(e.code, 'KUITANSI_NOT_FOUND');
      }
    });

    test('unduh dokumen refund 403 dipetakan', () async {
      final h = buildTestHarness();
      addTearDown(h.container.dispose);
      h.adapter.respondJson(403, {
        'success': false,
        'message': 'Anda tidak berhak mengakses dokumen ini.',
        'code': 'FORBIDDEN',
      });

      final repo = h.container.read(waliKeuanganRepositoryProvider);
      try {
        await repo.unduhDokumenRefund(55);
        fail('harus melempar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 403);
      }
    });
  });
}
