import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/application/paged_notifier.dart';
import '../../../shared/data/paged_state.dart';
import '../../../shared/models/notifikasi.dart';
import '../../../shared/models/page_meta.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/guru_repository.dart';
import '../data/models/absensi.dart';
import '../data/models/guru.dart';
import '../data/models/penilaian.dart';

// ---------------------------------------------------------------- Repository

final guruRepositoryProvider = Provider<GuruRepository>(
  (ref) => GuruRepository(ref.watch(dioProvider)),
);

// ------------------------------------------------------- One-shot providers

final guruProfilProvider = FutureProvider.autoDispose<GuruProfil>(
  (ref) => ref.watch(guruRepositoryProvider).profil(),
);

final guruBerandaProvider = FutureProvider.autoDispose<GuruBeranda>(
  (ref) => ref.watch(guruRepositoryProvider).beranda(),
);

final guruKelasListProvider = FutureProvider.autoDispose<KelasListResponse>(
  (ref) => ref.watch(guruRepositoryProvider).kelas(),
);

final guruKelasDetailProvider = FutureProvider.autoDispose
    .family<KelasRingkas, int>(
      (ref, id) => ref.watch(guruRepositoryProvider).kelasDetail(id),
    );

final guruKelasSiswaProvider = FutureProvider.autoDispose
    .family<KelasSiswaResponse, int>(
      (ref, id) => ref.watch(guruRepositoryProvider).kelasSiswa(id),
    );

final guruPenugasanListProvider = FutureProvider.autoDispose<List<Penugasan>>(
  (ref) => ref.watch(guruRepositoryProvider).penugasan(),
);

final guruPenugasanDetailProvider = FutureProvider.autoDispose
    .family<PenugasanDetail, int>(
      (ref, id) => ref.watch(guruRepositoryProvider).penugasanDetail(id),
    );

final guruPenugasanSiswaProvider = FutureProvider.autoDispose
    .family<PenugasanSiswaResponse, int>(
      (ref, id) => ref.watch(guruRepositoryProvider).penugasanSiswa(id),
    );

/// arg: (tanggal 'YYYY-MM-DD'?, hari 1..7?). `tanggal` menang di backend.
final guruJadwalProvider = FutureProvider.autoDispose
    .family<JadwalGuruResponse, (String? tanggal, int? hari)>(
      (ref, args) => ref
          .watch(guruRepositoryProvider)
          .jadwal(tanggal: args.$1, hari: args.$2),
    );

final guruJadwalHariIniProvider =
    FutureProvider.autoDispose<JadwalGuruResponse>(
      (ref) => ref.watch(guruRepositoryProvider).jadwalHariIni(),
    );

final guruJadwalDetailProvider = FutureProvider.autoDispose
    .family<JadwalGuruItem, int>(
      (ref, id) => ref.watch(guruRepositoryProvider).jadwalDetail(id),
    );

/// arg: (kelasId, tanggal 'YYYY-MM-DD'?).
final guruAbsensiHarianGridProvider = FutureProvider.autoDispose
    .family<AbsensiHarianGrid, (int kelasId, String? tanggal)>(
      (ref, args) => ref
          .watch(guruRepositoryProvider)
          .absensiHarianGrid(kelasId: args.$1, tanggal: args.$2),
    );

/// arg: (pertemuanId,) — pakai family tuple agar konsisten.
final guruPertemuanDetailProvider = FutureProvider.autoDispose
    .family<AbsensiPerjamGrid, int>(
      (ref, id) => ref.watch(guruRepositoryProvider).pertemuanDetail(id),
    );

final guruAbsensiPerjamDetailProvider = FutureProvider.autoDispose
    .family<GuruAbsensiPerjamDetail, int>(
      (ref, id) => ref.watch(guruRepositoryProvider).absensiPerjamDetail(id),
    );

final guruAbsensiHarianDetailProvider = FutureProvider.autoDispose
    .family<GuruAbsensiHarianDetail, int>(
      (ref, id) => ref.watch(guruRepositoryProvider).absensiHarianDetail(id),
    );

final guruUnreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(guruRepositoryProvider).unreadCount(),
);

final guruNotifikasiDetailProvider = FutureProvider.autoDispose
    .family<NotifikasiItem, int>(
      (ref, id) => ref.watch(guruRepositoryProvider).notifikasiDetail(id),
    );

/// PERHATIAN: panggil provider ini HANYA saat pengguna membuka tab Per Jam
/// (backend men-generate snapshot pertemuan yang belum ada — idempoten).
final guruPertemuanProvider = FutureProvider.autoDispose
    .family<PertemuanResponse, String?>(
      (ref, tanggal) =>
          ref.watch(guruRepositoryProvider).pertemuan(tanggal: tanggal),
    );

// ------------------------------------------------------ Paged list controllers

class GuruAbsensiHarianNotifier extends PagedNotifier<GuruAbsensiHarianItem> {
  String? dari;
  String? sampai;
  String? status;
  int? kelasId;

  void applyFilter({
    String? dari,
    String? sampai,
    String? status,
    int? kelasId,
  }) {
    this.dari = dari;
    this.sampai = sampai;
    this.status = status;
    this.kelasId = kelasId;
    refresh();
  }

  @override
  Future<PagedResult<GuruAbsensiHarianItem>> fetchPage(int page) => ref
      .read(guruRepositoryProvider)
      .absensiHarian(
        dari: dari,
        sampai: sampai,
        status: status,
        kelasId: kelasId,
        page: page,
      );
}

final guruAbsensiHarianProvider =
    NotifierProvider.autoDispose<
      GuruAbsensiHarianNotifier,
      PagedState<GuruAbsensiHarianItem>
    >(GuruAbsensiHarianNotifier.new);

class GuruAbsensiPerjamNotifier extends PagedNotifier<GuruAbsensiPerjamItem> {
  String? dari;
  String? sampai;
  String? status;
  int? kelasId;

  void applyFilter({
    String? dari,
    String? sampai,
    String? status,
    int? kelasId,
  }) {
    this.dari = dari;
    this.sampai = sampai;
    this.status = status;
    this.kelasId = kelasId;
    refresh();
  }

  @override
  Future<PagedResult<GuruAbsensiPerjamItem>> fetchPage(int page) => ref
      .read(guruRepositoryProvider)
      .absensiPerjam(
        dari: dari,
        sampai: sampai,
        status: status,
        kelasId: kelasId,
        page: page,
      );
}

final guruAbsensiPerjamProvider =
    NotifierProvider.autoDispose<
      GuruAbsensiPerjamNotifier,
      PagedState<GuruAbsensiPerjamItem>
    >(GuruAbsensiPerjamNotifier.new);

class GuruNotifikasiNotifier extends PagedNotifier<NotifikasiItem> {
  String? status; // 'read' | 'unread' | null

  void applyFilter({String? status}) {
    this.status = status;
    refresh();
  }

  @override
  Future<PagedResult<NotifikasiItem>> fetchPage(int page) => ref
      .read(guruRepositoryProvider)
      .notifikasi(status: status, page: page)
      .then((r) => PagedResult(items: r.items, meta: r.meta));
}

final guruNotifikasiProvider =
    NotifierProvider.autoDispose<
      GuruNotifikasiNotifier,
      PagedState<NotifikasiItem>
    >(GuruNotifikasiNotifier.new);

/// Mutation: tandai semua notifikasi dibaca lalu refresh badge & list.
class GuruNotifikasiAction {
  GuruNotifikasiAction(this._ref);

  final Ref _ref;

  Future<TandaiSemuaDibacaResult> markAllRead() async {
    final result = await _ref.read(guruRepositoryProvider).markAllRead();
    _ref.invalidate(guruUnreadCountProvider);
    return result;
  }

  Future<void> markRead(int id) async {
    await _ref.read(guruRepositoryProvider).markRead(id);
    _ref.invalidate(guruUnreadCountProvider);
    _ref.invalidate(guruNotifikasiDetailProvider(id));
    _ref.invalidate(guruNotifikasiProvider);
  }
}

final guruNotifikasiActionProvider = Provider<GuruNotifikasiAction>(
  GuruNotifikasiAction.new,
);
