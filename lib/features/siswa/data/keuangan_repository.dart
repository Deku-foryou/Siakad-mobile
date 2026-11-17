import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_envelope.dart';
import 'models/keuangan.dart';
import '../../../shared/models/page_meta.dart';

/// Dokumen privat hasil unduhan (bytes + nama file dari Content-Disposition).
class DokumenResult {
  const DokumenResult({
    required this.filename,
    required this.bytes,
    required this.contentType,
  });

  final String filename;
  final List<int> bytes;
  final String contentType;
}

/// Repository keuangan siswa — menghormati kebijakan backend:
///
/// - NOMINAL SELALU dari backend; client tidak pernah mengirim nominal.
/// - Payment attempt ≠ pembayaran; ledger hanya berubah dari webhook backend.
/// - Dokumen privat diakses lewat endpoint backend (bukan URL publik).
/// - Identitas selalu dari token; endpoint siswa tidak menerima siswa_id.
class KeuanganRepository {
  KeuanganRepository(this._dio);

  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Map<String, dynamic> _params(Map<String, Object?> raw) {
    final params = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value != null && value != '') params[key] = value;
    });
    return params;
  }

  static List<T> _listOf<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  Future<RingkasanKeuangan> ringkasan() => _guard(() async {
    final response = await _dio.get<dynamic>('/keuangan/ringkasan');
    return RingkasanKeuangan.fromJson(ApiEnvelope.dataObject(response));
  });

  Future<PagedResult<Tagihan>> tagihan({
    String? status,
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/keuangan/tagihan',
      queryParameters: _params({
        'status': status,
        'per_page': perPage,
        'page': page,
      }),
    );
    // `data` adalah array langsung (bukan {items}).
    final body = response.data;
    final raw = body is Map ? body['data'] : null;
    return PagedResult<Tagihan>(
      items: _listOf(raw, Tagihan.fromJson),
      meta: _metaOf(response),
    );
  });

  Future<Tagihan> tagihanDetail(int id) => _guard(() async {
    final response = await _dio.get<dynamic>('/keuangan/tagihan/$id');
    return Tagihan.fromJson(ApiEnvelope.dataObject(response));
  });

  Future<num> saldo() => _guard(() async {
    final response = await _dio.get<dynamic>('/keuangan/saldo');
    final data = ApiEnvelope.dataObject(response);
    final raw = data['saldo'];
    return raw is num ? raw : num.tryParse(raw?.toString() ?? '') ?? 0;
  });

  Future<PagedResult<Pembayaran>> pembayaran({
    int page = 1,
    int perPage = 15,
  }) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/keuangan/pembayaran',
      queryParameters: _params({'per_page': perPage, 'page': page}),
    );
    final body = response.data;
    final raw = body is Map ? body['data'] : null;
    return PagedResult<Pembayaran>(
      items: _listOf(raw, Pembayaran.fromJson),
      meta: _metaOf(response),
    );
  });

  Future<Pembayaran> pembayaranDetail(int id) => _guard(() async {
    final response = await _dio.get<dynamic>('/keuangan/pembayaran/$id');
    return Pembayaran.fromJson(ApiEnvelope.dataObject(response));
  });

  /// Buat payment attempt untuk tagihan. Nominal ditentukan server dari
  /// `tagihan.total_tagihan` — client hanya mengirim `tagihan_id`.
  ///
  /// Response 201: PaymentAttempt (status `created`/dll — BUKAN berarti lunas).
  /// 503: gateway tidak tersedia (Midtrans belum terkonfigurasi).
  Future<PaymentAttempt> buatAttempt({required int tagihanId}) =>
      _guard(() async {
        final response = await _dio.post<dynamic>(
          '/keuangan/pembayaran/attempts',
          data: {'tagihan_id': tagihanId},
        );
        return PaymentAttempt.fromJson(ApiEnvelope.dataObject(response));
      });

  /// Status attempt terkini dari server (sumber kebenaran transaksi).
  Future<PaymentAttempt> attemptStatus(int id) => _guard(() async {
    final response = await _dio.get<dynamic>(
      '/keuangan/pembayaran/attempts/$id',
    );
    return PaymentAttempt.fromJson(ApiEnvelope.dataObject(response));
  });

  // ---------------- Dokumen privat ----------------

  /// Bukti pembayaran manual (bila ada). Error: 403/404/500 JSON.
  Future<DokumenResult> unduhBukti(int pembayaranId) =>
      _downloadDokumen('/keuangan/pembayaran/$pembayaranId/bukti');

  /// Kuitansi resmi pembayaran. Error: 403/404 JSON.
  Future<DokumenResult> unduhKuitansi(int pembayaranId) =>
      _downloadDokumen('/keuangan/pembayaran/$pembayaranId/kuitansi');

  /// Dokumen refund. Error: 403/404/500(DOKUMEN_INTEGRITAS) JSON.
  Future<DokumenResult> unduhDokumenRefund(int dokumenId) =>
      _downloadDokumen('/keuangan/refund/dokumen/$dokumenId');

  Future<DokumenResult> _downloadDokumen(String path) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data ?? <int>[];
      final contentDisposition =
          response.headers.value('content-disposition') ?? '';
      final filename =
          _filenameFromContentDisposition(contentDisposition) ??
          _fallbackFilename(path);
      return DokumenResult(
        filename: filename,
        bytes: bytes,
        contentType:
            response.headers.value('content-type') ??
            'application/octet-stream',
      );
    } on DioException catch (e) {
      throw _mapDocumentError(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  static ApiException _mapDocumentError(DioException e) {
    final status = e.response?.statusCode;
    // Body adalah bytes karena responseType=bytes; decode bila JSON.
    Map<String, dynamic>? body;
    final raw = e.response?.data;
    try {
      if (raw is List<int>) {
        final decoded = jsonDecode(utf8.decode(raw));
        if (decoded is Map<String, dynamic>) body = decoded;
      } else if (raw is Map) {
        body = Map<String, dynamic>.from(raw);
      }
    } catch (_) {
      body = null;
    }

    if (body != null) {
      final message = (body['message'] as String?)?.trim();
      return ApiException(
        kind: ApiErrorKind.http,
        statusCode: status,
        code: body['code']?.toString(),
        message: (message != null && message.isNotEmpty)
            ? message
            : ErrorMapper.fallbackMessage(status),
        fieldErrors: const {},
      );
    }
    if (status == 403) {
      return const ApiException(
        kind: ApiErrorKind.http,
        statusCode: 403,
        code: 'FORBIDDEN',
        message: 'Anda tidak berhak mengakses dokumen ini.',
      );
    }
    if (status == 404) {
      return const ApiException(
        kind: ApiErrorKind.http,
        statusCode: 404,
        code: 'NOT_FOUND',
        message: 'Dokumen tidak ditemukan.',
      );
    }
    return ErrorMapper.map(e);
  }

  static String? _filenameFromContentDisposition(String header) {
    if (header.isEmpty) return null;
    // RFC 6266: filename*=UTF-8''... atau filename="..."
    final star = RegExp(
      "filename\\*=(?:UTF-8'')?\"?([^;\"]+)\"?",
      caseSensitive: false,
    ).firstMatch(header);
    if (star != null) {
      final value = star.group(1)?.trim();
      if (value != null && value.isNotEmpty) return Uri.decodeComponent(value);
    }
    final plain = RegExp(
      'filename="?([^;"]+)"?',
      caseSensitive: false,
    ).firstMatch(header);
    final value = plain?.group(1)?.trim();
    return (value != null && value.isNotEmpty) ? value : null;
  }

  static String _fallbackFilename(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final name = segments.isEmpty ? 'dokumen' : segments.last;
    return 'dokumen-$name-${DateTime.now().millisecondsSinceEpoch}';
  }

  static PageMeta? _metaOf(Response<dynamic> response) {
    final meta = ApiEnvelope.meta(response);
    return meta == null ? null : PageMeta.fromJson(meta);
  }
}
