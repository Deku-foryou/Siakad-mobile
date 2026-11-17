import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import 'siswa_providers.dart';
import '../data/models/absensi.dart';
import '../../../shared/models/page_meta.dart';

/// State untuk list absensi dengan ringkasan (harian/periode/perjam).
class AbsensiListState<Item> {
  const AbsensiListState({
    this.items = const [],
    this.rekap,
    this.rekapTotal,
    this.meta,
    this.page = 1,
    this.busy = false,
    this.refreshing = false,
    this.error,
    this.dari,
    this.sampai,
    this.status,
  });

  final List<Item> items;

  /// `ringkasan` (harian/periode) atau `rekap` (per jam).
  final RekapAbsensi? rekap;

  /// `rekap_semester` (harian) atau `rekap_total` (per jam).
  final RekapAbsensi? rekapTotal;

  final PageMeta? meta;
  final int page;
  final bool busy;
  final bool refreshing;
  final String? error;

  /// Filter aktif (untuk chip & retry).
  final String? dari;
  final String? sampai;
  final String? status;

  bool get hasMore => meta?.hasMore ?? false;
  bool get isEmpty => items.isEmpty && !busy && error == null;

  AbsensiListState<Item> copyWith({
    List<Item>? items,
    RekapAbsensi? rekap,
    RekapAbsensi? rekapTotal,
    PageMeta? meta,
    int? page,
    bool? busy,
    bool? refreshing,
    String? error,
    bool clearError = false,
    String? dari,
    String? sampai,
    String? status,
    bool clearFilter = false,
  }) => AbsensiListState<Item>(
    items: items ?? this.items,
    rekap: rekap ?? this.rekap,
    rekapTotal: rekapTotal ?? this.rekapTotal,
    meta: meta ?? this.meta,
    page: page ?? this.page,
    busy: busy ?? this.busy,
    refreshing: refreshing ?? this.refreshing,
    error: clearError ? null : (error ?? this.error),
    dari: clearFilter ? null : (dari ?? this.dari),
    sampai: clearFilter ? null : (sampai ?? this.sampai),
    status: clearFilter ? null : (status ?? this.status),
  );
}

abstract class _AbsensiNotifier<Item> extends Notifier<AbsensiListState<Item>> {
  @override
  AbsensiListState<Item> build() {
    // Muat halaman pertama setelah build selesai.
    Future.microtask(refresh);
    return const AbsensiListState();
  }

  Future<
    ({
      List<Item> items,
      RekapAbsensi? rekap,
      RekapAbsensi? rekapTotal,
      PageMeta? meta,
    })
  >
  fetch(int page);

  Future<void> refresh() async {
    state = state.copyWith(refreshing: true, clearError: true);
    try {
      final r = await fetch(1);
      state = AbsensiListState<Item>(
        items: r.items,
        rekap: r.rekap,
        rekapTotal: r.rekapTotal,
        meta: r.meta,
        dari: state.dari,
        sampai: state.sampai,
        status: state.status,
      );
    } on Object catch (e) {
      state = state.copyWith(refreshing: false, busy: false, error: _msg(e));
    }
  }

  Future<void> loadMore() async {
    if (state.busy || !state.hasMore) return;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final next = state.page + 1;
      final r = await fetch(next);
      state = state.copyWith(
        items: [...state.items, ...r.items],
        rekap: r.rekap ?? state.rekap,
        rekapTotal: r.rekapTotal ?? state.rekapTotal,
        meta: r.meta,
        page: next,
        busy: false,
      );
    } on Object catch (e) {
      state = state.copyWith(busy: false, error: _msg(e));
    }
  }

  String _msg(Object e) {
    if (e is ApiException) return e.message;
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}

class AbsensiHarianNotifier extends _AbsensiNotifier<AbsensiHarianItem> {
  void applyFilter({String? status}) {
    state = state.copyWith(status: status, clearError: true);
    refresh();
  }

  @override
  Future<
    ({
      List<AbsensiHarianItem> items,
      RekapAbsensi? rekap,
      RekapAbsensi? rekapTotal,
      PageMeta? meta,
    })
  >
  fetch(int page) async {
    final r = await ref
        .read(siswaRepositoryProvider)
        .absensiHarian(status: state.status, page: page);
    return (
      items: r.items,
      rekap: r.ringkasan,
      rekapTotal: r.rekapSemester,
      meta: r.meta,
    );
  }
}

final absensiHarianProvider =
    NotifierProvider.autoDispose<
      AbsensiHarianNotifier,
      AbsensiListState<AbsensiHarianItem>
    >(AbsensiHarianNotifier.new);

class AbsensiPeriodeNotifier extends _AbsensiNotifier<AbsensiHarianItem> {
  bool get hasFilter => state.dari != null && state.sampai != null;

  void applyFilter({
    required String dari,
    required String sampai,
    String? status,
  }) {
    state = state.copyWith(
      dari: dari,
      sampai: sampai,
      status: status,
      clearError: true,
    );
    refresh();
  }

  @override
  Future<
    ({
      List<AbsensiHarianItem> items,
      RekapAbsensi? rekap,
      RekapAbsensi? rekapTotal,
      PageMeta? meta,
    })
  >
  fetch(int page) async {
    if (!hasFilter) {
      // Belum ada filter periode â€” tunggu user memilih rentang tanggal.
      return (
        items: const <AbsensiHarianItem>[],
        rekap: null,
        rekapTotal: null,
        meta: null,
      );
    }
    final r = await ref
        .read(siswaRepositoryProvider)
        .absensiPeriode(
          dari: state.dari!,
          sampai: state.sampai!,
          status: state.status,
          page: page,
        );
    return (items: r.items, rekap: r.ringkasan, rekapTotal: null, meta: r.meta);
  }
}

final absensiPeriodeProvider =
    NotifierProvider.autoDispose<
      AbsensiPeriodeNotifier,
      AbsensiListState<AbsensiHarianItem>
    >(AbsensiPeriodeNotifier.new);

class AbsensiPerjamNotifier extends _AbsensiNotifier<AbsensiPerjamItem> {
  void applyFilter({String? status}) {
    state = state.copyWith(status: status, clearError: true);
    refresh();
  }

  @override
  Future<
    ({
      List<AbsensiPerjamItem> items,
      RekapAbsensi? rekap,
      RekapAbsensi? rekapTotal,
      PageMeta? meta,
    })
  >
  fetch(int page) async {
    final r = await ref
        .read(siswaRepositoryProvider)
        .absensiPerjam(status: state.status, page: page);
    return (
      items: r.items,
      rekap: r.rekap,
      rekapTotal: r.rekapTotal,
      meta: r.meta,
    );
  }
}

final absensiPerjamProvider =
    NotifierProvider.autoDispose<
      AbsensiPerjamNotifier,
      AbsensiListState<AbsensiPerjamItem>
    >(AbsensiPerjamNotifier.new);
