/// Meta pagination backend (untuk endpoint yang mengirimkannya).
///
/// Catatan: endpoint keuangan TIDAK mengirim `from`/`to` — parser ini
/// menoleransinya (nullable).
class PageMeta {
  const PageMeta({
    required this.currentPage,
    required this.perPage,
    required this.lastPage,
    required this.total,
    this.from,
    this.to,
  });

  final int currentPage;
  final int perPage;
  final int lastPage;
  final int total;
  final int? from;
  final int? to;

  bool get hasMore => currentPage < lastPage;

  factory PageMeta.fromJson(Map<String, dynamic> json) {
    int? asInt(Object? v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    return PageMeta(
      currentPage: asInt(json['current_page']) ?? 1,
      perPage: asInt(json['per_page']) ?? 15,
      lastPage: asInt(json['last_page']) ?? 1,
      total: asInt(json['total']) ?? 0,
      from: asInt(json['from']),
      to: asInt(json['to']),
    );
  }
}

/// Halaman list berisi items + meta pagination (opsional).
class PagedResult<T> {
  const PagedResult({required this.items, this.meta});

  final List<T> items;
  final PageMeta? meta;
}
