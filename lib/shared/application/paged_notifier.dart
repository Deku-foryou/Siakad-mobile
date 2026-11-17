import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/page_meta.dart';
import '../data/paged_state.dart';

import '../../../core/errors/api_exception.dart';

/// Base controller untuk list paginated read-only.
///
/// Subclass menyediakan [fetchPage]; filter disimpan pada field subclass.
/// State: item terkumpul + meta halaman terakhir + busy/refreshing/error.
abstract class PagedNotifier<T> extends Notifier<PagedState<T>> {
  @override
  PagedState<T> build() {
    // Muat halaman pertama setelah build selesai.
    Future.microtask(refresh);
    return const PagedState();
  }

  Future<PagedResult<T>> fetchPage(int page);

  Future<void> refresh() async {
    state = state.copyWith(refreshing: true, clearError: true);
    try {
      final result = await fetchPage(1);
      state = PagedState<T>(items: result.items, meta: result.meta, page: 1);
    } on ApiException catch (e) {
      state = state.copyWith(refreshing: false, busy: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        refreshing: false,
        busy: false,
        error: 'Terjadi kesalahan. Silakan coba lagi.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.busy || !state.hasMore) return;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final next = state.page + 1;
      final result = await fetchPage(next);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        meta: result.meta,
        page: next,
        busy: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        busy: false,
        error: 'Terjadi kesalahan. Silakan coba lagi.',
      );
    }
  }
}
