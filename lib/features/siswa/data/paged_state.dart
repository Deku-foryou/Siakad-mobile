import '../../../core/errors/api_exception.dart';
import 'models/page_meta.dart';

/// State generik untuk list paginated.
class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.meta,
    this.page = 1,
    this.busy = false,
    this.refreshing = false,
    this.error,
  });

  final List<T> items;
  final PageMeta? meta;
  final int page;

  /// Sedang memuat (termasuk load-more).
  final bool busy;

  /// Sedang refresh dari atas (pull-to-refresh).
  final bool refreshing;

  final String? error;

  bool get hasMore => meta?.hasMore ?? false;
  bool get isEmpty => !busy && error == null && items.isEmpty;

  PagedState<T> copyWith({
    List<T>? items,
    PageMeta? meta,
    int? page,
    bool? busy,
    bool? refreshing,
    String? error,
    bool clearError = false,
  }) => PagedState<T>(
    items: items ?? this.items,
    meta: meta ?? this.meta,
    page: page ?? this.page,
    busy: busy ?? this.busy,
    refreshing: refreshing ?? this.refreshing,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Pesan aman untuk UI dari error apapun.
String pesanError(Object error) {
  if (error is ApiException) return error.message;
  return 'Terjadi kesalahan. Silakan coba lagi.';
}
