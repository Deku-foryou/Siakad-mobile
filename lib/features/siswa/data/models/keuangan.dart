import '../../../../core/utils/json_cast.dart';

num? _numOf(Object? v) => v is num ? v : num.tryParse(v?.toString() ?? '');

/// `GET /keuangan/ringkasan` — nominal integer rupiah.
class RingkasanKeuangan {
  const RingkasanKeuangan({
    required this.totalKewajiban,
    required this.totalDibayar,
    required this.sisaKewajiban,
    required this.saldo,
  });

  final num totalKewajiban;
  final num totalDibayar;
  final num sisaKewajiban;
  final num saldo;

  factory RingkasanKeuangan.fromJson(Map<String, dynamic> json) =>
      RingkasanKeuangan(
        totalKewajiban: _numOf(json['total_kewajiban']) ?? 0,
        totalDibayar: _numOf(json['total_dibayar']) ?? 0,
        sisaKewajiban: _numOf(json['sisa_kewajiban']) ?? 0,
        saldo: _numOf(json['saldo']) ?? 0,
      );
}

/// Tagihan — `TagihanResource` backend. `data` list langsung (bukan `{items}`).
class Tagihan {
  const Tagihan({
    required this.id,
    required this.nama,
    required this.nominal,
    required this.terbayar,
    required this.sisa,
    required this.status,
    this.jatuhTempo,
  });

  final int id;
  final String nama;
  final num nominal;
  final num terbayar;
  final num sisa;
  final String status;
  final String? jatuhTempo;

  factory Tagihan.fromJson(Map<String, dynamic> json) => Tagihan(
    id: JsonCast.intOrNull(json['id']) ?? 0,
    nama: (json['nama'] ?? '').toString(),
    nominal: _numOf(json['nominal']) ?? 0,
    terbayar: _numOf(json['terbayar']) ?? 0,
    sisa: _numOf(json['sisa']) ?? 0,
    status: (json['status'] ?? '').toString(),
    jatuhTempo: json['jatuh_tempo']?.toString(),
  );
}

/// Pembayaran (ledger) — `PembayaranResource` backend.
class Pembayaran {
  const Pembayaran({
    required this.id,
    required this.nominal,
    this.metode,
    required this.status,
    this.dibayarPada,
  });

  final int id;
  final num nominal;
  final String? metode;
  final String status;
  final String? dibayarPada;

  factory Pembayaran.fromJson(Map<String, dynamic> json) => Pembayaran(
    id: JsonCast.intOrNull(json['id']) ?? 0,
    nominal: _numOf(json['nominal']) ?? 0,
    metode: json['metode']?.toString(),
    status: (json['status'] ?? '').toString(),
    dibayarPada: json['dibayar_pada']?.toString(),
  );
}

/// Payment attempt (Snap) — `PaymentAttemptResource` backend.
/// BUKAN bukti pembayaran — hanya instruksi transaksi.
class PaymentAttempt {
  const PaymentAttempt({
    required this.id,
    required this.orderId,
    required this.nominal,
    required this.status,
    this.snapToken,
    this.snapRedirectUrl,
  });

  final int id;
  final String orderId;
  final num nominal;
  final String status;
  final String? snapToken;
  final String? snapRedirectUrl;

  factory PaymentAttempt.fromJson(Map<String, dynamic> json) => PaymentAttempt(
    id: JsonCast.intOrNull(json['id']) ?? 0,
    orderId: (json['order_id'] ?? '').toString(),
    nominal: _numOf(json['nominal']) ?? 0,
    status: (json['status'] ?? '').toString(),
    snapToken: json['snap_token']?.toString(),
    snapRedirectUrl: json['snap_redirect_url']?.toString(),
  );
}
