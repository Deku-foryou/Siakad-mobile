import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../shared/models/page_meta.dart';
import '../data/wali_repository.dart';
import '../../siswa/data/models/absensi.dart';
import 'wali_providers.dart';

/// State untuk list absensi anak dengan ringkasan (harian/periode/perjam).
/// Sama dengan siswa, tetapi terikat pada `siswaId` (family).
class WaliAbsensiListState<Item> {
  const WaliAbsensiListState({
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
  final RekapAbsensi? rekap;
  final RekapAbsensi? rekapTotal;
  final PageMeta? meta;
  final int page;
  final bool busy;
  final bool refreshing;
  final String? error;
  final String? dari;
  final String? sampai;
  final String? status;

  bool get hasMore => meta?.hasMore ?? false;
  bool get isEmpty => items.isEmpty && !busy && error == null;

  WaliAbsensiListState<Item> copyWith({
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
  }) => WaliAbsensiListState<Item>(
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

abstract class _WaliAbsensiNotifier<Item>
    extends Notifier<WaliAbsensiListState<Item>> {
  _WaliAbsensiNotifier(this.siswaId);

  final int siswaId;

  @override
  WaliAbsensiListState<Item> build() {
    Future.microtask(refresh);
    return const WaliAbsensiListState();
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
      state = WaliAbsensiListState<Item>(
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

class WaliAbsensiHarianNotifier
    extends _WaliAbsensiNotifier<AbsensiHarianItem> {
  WaliAbsensiHarianNotifier(super.siswaId);

  WaliRepository get _repo => ref.read(waliRepositoryProvider);

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
    final r = await _repo.anakAbsensiHarian(
      siswaId,
      status: state.status,
      page: page,
    );
    return (
      items: r.items,
      rekap: r.ringkasan,
      rekapTotal: r.rekapSemester,
      meta: r.meta,
    );
  }
}

final waliAbsensiHarianProvider = NotifierProvider.autoDispose
    .family<
      WaliAbsensiHarianNotifier,
      WaliAbsensiListState<AbsensiHarianItem>,
      int
    >(WaliAbsensiHarianNotifier.new);

class WaliAbsensiPeriodeNotifier
    extends _WaliAbsensiNotifier<AbsensiHarianItem> {
  WaliAbsensiPeriodeNotifier(super.siswaId);

  WaliRepository get _repo => ref.read(waliRepositoryProvider);

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
      // Belum ada filter periode â†’ tunggu user memilih rentang tanggal.
      return (
        items: const <AbsensiHarianItem>[],
        rekap: null,
        rekapTotal: null,
        meta: null,
      );
    }
    final r = await _repo.anakAbsensiPeriode(
      siswaId,
      dari: state.dari!,
      sampai: state.sampai!,
      status: state.status,
      page: page,
    );
    return (items: r.items, rekap: r.ringkasan, rekapTotal: null, meta: r.meta);
  }
}

final waliAbsensiPeriodeProvider = NotifierProvider.autoDispose
    .family<
      WaliAbsensiPeriodeNotifier,
      WaliAbsensiListState<AbsensiHarianItem>,
      int
    >(WaliAbsensiPeriodeNotifier.new);

class WaliAbsensiPerjamNotifier
    extends _WaliAbsensiNotifier<AbsensiPerjamItem> {
  WaliAbsensiPerjamNotifier(super.siswaId);

  WaliRepository get _repo => ref.read(waliRepositoryProvider);

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
    final r = await _repo.anakAbsensiPerjam(
      siswaId,
      dari: state.dari,
      sampai: state.sampai,
      status: state.status,
      page: page,
    );
    return (
      items: r.items,
      rekap: r.rekap,
      rekapTotal: r.rekapTotal,
      meta: r.meta,
    );
  }
}

final waliAbsensiPerjamProvider = NotifierProvider.autoDispose
    .family<
      WaliAbsensiPerjamNotifier,
      WaliAbsensiListState<AbsensiPerjamItem>,
      int
    >(WaliAbsensiPerjamNotifier.new);
