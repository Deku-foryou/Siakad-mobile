import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../shared/models/page_meta.dart';
import '../../../shared/data/paged_state.dart';

/// Paged notifier versi family untuk konteks anak (`siswaId` via konstruktor —
/// pola family Riverpod 3).
///
/// Setiap nilai `siswaId` menghasilkan instance notifier terpisah, sehingga
/// data anak A TIDAK PERNAH tercampur dengan anak B, dan state lama otomatis
/// dilepas (autoDispose) saat tidak ada yang menonton.
abstract class WaliPagedNotifier<Item> extends Notifier<PagedState<Item>> {
  WaliPagedNotifier(this.siswaId);

  final int siswaId;

  @override
  PagedState<Item> build() {
    Future.microtask(refresh);
    return const PagedState();
  }

  Future<({List<Item> items, PageMeta? meta})> fetchPage(int page);

  Future<void> refresh() async {
    state = state.copyWith(refreshing: true, clearError: true);
    try {
      final result = await fetchPage(1);
      state = PagedState<Item>(items: result.items, meta: result.meta, page: 1);
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
