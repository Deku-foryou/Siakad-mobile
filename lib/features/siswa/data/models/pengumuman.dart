/// Item pengumuman siswa — `PengumumanResource` backend.
class PengumumanItem {
  const PengumumanItem({
    required this.id,
    required this.judul,
    this.isi,
    this.kategori,
    this.prioritas,
    this.waktuTerbit,
    this.berlakuDari,
    this.berlakuSampai,
    this.dibaca = false,
    this.dibacaPada,
  });

  final int id;
  final String judul;
  final String? isi;
  final String? kategori;
  final String? prioritas;
  final String? waktuTerbit;
  final String? berlakuDari;
  final String? berlakuSampai;
  final bool dibaca;
  final String? dibacaPada;

  factory PengumumanItem.fromJson(Map<String, dynamic> json) => PengumumanItem(
    id: (json['id'] as num?)?.toInt() ?? 0,
    judul: (json['judul'] ?? '').toString(),
    isi: json['isi']?.toString(),
    kategori: json['kategori']?.toString(),
    prioritas: json['prioritas']?.toString(),
    waktuTerbit: json['waktu_terbit']?.toString(),
    berlakuDari: json['berlaku_dari']?.toString(),
    berlakuSampai: json['berlaku_sampai']?.toString(),
    dibaca: json['dibaca'] as bool? ?? false,
    dibacaPada: json['dibaca_pada']?.toString(),
  );
}
