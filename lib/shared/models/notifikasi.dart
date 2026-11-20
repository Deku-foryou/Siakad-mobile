import '../../core/utils/json_cast.dart';
import 'page_meta.dart';

/// Item notifikasi siswa — `NotifikasiResource` backend.
/// `link`, `sumber_tabel`, `sumber_id` adalah path internal yang aman —
/// deep link HANYA dipakai bila targetnya dikenal di aplikasi ini.
class NotifikasiItem {
  const NotifikasiItem({
    required this.id,
    required this.judul,
    this.isi,
    this.jenis,
    this.prioritas,
    this.waktuDibuat,
    this.sumberTabel,
    this.sumberId,
    this.link,
    this.dibaca = false,
    this.dibacaPada,
  });

  final int id;
  final String judul;
  final String? isi;
  final String? jenis;
  final String? prioritas;
  final String? waktuDibuat;
  final String? sumberTabel;
  final int? sumberId;
  final String? link;
  final bool dibaca;
  final String? dibacaPada;

  factory NotifikasiItem.fromJson(Map<String, dynamic> json) => NotifikasiItem(
    id: JsonCast.intOrNull(json['id']) ?? 0,
    judul: (json['judul'] ?? '').toString(),
    isi: json['isi']?.toString(),
    jenis: json['jenis']?.toString(),
    prioritas: json['prioritas']?.toString(),
    waktuDibuat: json['waktu_dibuat']?.toString(),
    sumberTabel: json['sumber_tabel']?.toString(),
    sumberId: JsonCast.intOrNull(json['sumber_id']),
    link: json['link']?.toString(),
    dibaca: JsonCast.boolOrNull(json['dibaca']) ?? false,
    dibacaPada: json['dibaca_pada']?.toString(),
  );
}

/// `GET /siswa/notifikasi` response: items + `belum_dibaca`.
class NotifikasiListResponse {
  const NotifikasiListResponse({
    this.items = const [],
    required this.belumDibaca,
    this.meta,
  });

  final List<NotifikasiItem> items;
  final int belumDibaca;
  final PageMeta? meta;

  factory NotifikasiListResponse.fromJson(
    Map<String, dynamic> json,
    PageMeta? meta,
  ) => NotifikasiListResponse(
    items: json['items'] is List
        ? (json['items'] as List)
              .whereType<Map>()
              .map((e) => NotifikasiItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [],
    belumDibaca: JsonCast.intOrNull(json['belum_dibaca']) ?? 0,
    meta: meta,
  );
}

/// `POST .../read` response: `{id, dibaca, dibaca_pada}`.
class TandaiDibacaResult {
  const TandaiDibacaResult({required this.id, this.dibacaPada});

  final int id;
  final String? dibacaPada;
}

/// `POST .../read-all` response: `{ditandai, belum_dibaca}`.
class TandaiSemuaDibacaResult {
  const TandaiSemuaDibacaResult({
    required this.ditandai,
    required this.belumDibaca,
  });

  final int ditandai;
  final int belumDibaca;
}
