import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/models/notifikasi.dart';
import '../../../shared/models/page_meta.dart';
import '../../../shared/data/paged_state.dart';
import '../../siswa/data/models/beranda.dart';
import '../../siswa/data/models/keuangan.dart';
import '../../siswa/data/models/nilai.dart';
import '../data/models/wali.dart';
import '../data/wali_keuangan_repository.dart';
import '../data/wali_repository.dart';
import 'wali_paged_notifier.dart';

// ---------------------------------------------------------------- Repositories

final waliRepositoryProvider = Provider<WaliRepository>(
  (ref) => WaliRepository(ref.watch(dioProvider)),
);

final waliKeuanganRepositoryProvider = Provider<WaliKeuanganRepository>(
  (ref) => WaliKeuanganRepository(ref.watch(dioProvider)),
);

// ------------------------------------------------------- Konteks anak terpilih
// Pemilihan anak HANYA in-memory (sesi aplikasi); tidak persisten.
// Sub-halaman akademik/keuangan anak memakai `:siswaId` pada route sehingga
// tidak bergantung pada state ini; shell (tab Beranda/Keuangan) memakainya.

/// Pilihan eksplisit wali (tap pada daftar anak). Null = belum memilih.
/// Hanya in-memory (sesi aplikasi); tidak persisten.
class SelectedAnakId extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? value) => state = value;
}

final selectedAnakIdProvider = NotifierProvider<SelectedAnakId, int?>(
  SelectedAnakId.new,
);

/// Daftar relasi wali (semua status). Sumber default anak terpilih:
/// pilihan eksplisit bila anak tsb `bisaAksesAkademik`, selain itu anak
/// verified pertama menurut urutan backend; null bila tidak ada.
final waliAnakListProvider = FutureProvider.autoDispose<AnakListResponse>(
  (ref) => ref.watch(waliRepositoryProvider).anak(),
);

/// ID anak efektif untuk konteks shell (Beranda/Keuangan).
/// Hanya anak dengan akses akademik (verified + belum berakhir) yang eligible.
/// Null bila tidak ada anak verified → UI menampilkan ajakan memilih anak.
final waliAnakAktifProvider = Provider<int?>((ref) {
  final list = ref.watch(waliAnakListProvider).value;
  if (list == null) return null;
  final eligible = list.anak.where((a) => a.bisaAksesAkademik).toList();
  final eksplisit = ref.watch(selectedAnakIdProvider);
  if (eksplisit != null && eligible.any((a) => a.siswa?.id == eksplisit)) {
    return eksplisit;
  }
  return eligible.isEmpty ? null : eligible.first.siswa?.id;
});

// ------------------------------------------------------- One-shot providers

final waliProfilProvider = FutureProvider.autoDispose<ProfilWali>(
  (ref) => ref.watch(waliRepositoryProvider).profil(),
);

final waliBerandaProvider = FutureProvider.autoDispose<BerandaWali>(
  (ref) => ref.watch(waliRepositoryProvider).beranda(),
);

final anakDetailProvider = FutureProvider.autoDispose.family<AnakDetail, int>(
  (ref, siswaId) => ref.watch(waliRepositoryProvider).anakDetail(siswaId),
);

/// Beranda anak terpilih (konteks akademik + kelas + jadwal hari ini).
/// family dengan argumen `siswaId` — cache terpisah per anak.
final anakBerandaProvider = FutureProvider.autoDispose
    .family<BerandaSiswa, int>(
      (ref, siswaId) => ref.watch(waliRepositoryProvider).anakBeranda(siswaId),
    );

/// Arg: (siswaId, tanggal?, hari?). `tanggal` menang di backend.
final anakJadwalProvider = FutureProvider.autoDispose
    .family<JadwalResponse, (int siswaId, String? tanggal, int? hari)>(
      (ref, args) => ref
          .watch(waliRepositoryProvider)
          .anakJadwal(args.$1, tanggal: args.$2, hari: args.$3),
    );

final anakJadwalHariIniProvider = FutureProvider.autoDispose
    .family<JadwalResponse, int>(
      (ref, siswaId) =>
          ref.watch(waliRepositoryProvider).anakJadwalHariIni(siswaId),
    );

final anakNilaiProvider = FutureProvider.autoDispose
    .family<List<NilaiKelompok>, (int siswaId, int? semesterId, int? kelasId)>(
      (ref, args) => ref
          .watch(waliRepositoryProvider)
          .anakNilai(args.$1, semesterId: args.$2, kelasId: args.$3),
    );

final anakRaporProvider = FutureProvider.autoDispose
    .family<List<RaporEntry>, int>(
      (ref, siswaId) => ref.watch(waliRepositoryProvider).anakRapor(siswaId),
    );

final anakRaporDetailProvider = FutureProvider.autoDispose
    .family<RaporDetail, (int siswaId, int semesterId, int kelasId)>(
      (ref, args) => ref
          .watch(waliRepositoryProvider)
          .anakRaporDetail(
            siswaId: args.$1,
            semesterId: args.$2,
            kelasId: args.$3,
          ),
    );

final waliUnreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(waliRepositoryProvider).unreadCount(),
);

final waliNotifikasiDetailProvider = FutureProvider.autoDispose
    .family<NotifikasiItem, int>(
      (ref, id) => ref.watch(waliRepositoryProvider).notifikasiDetail(id),
    );

// ---------------- Keuangan anak (family per siswaId) ----------------

final anakRingkasanKeuanganProvider = FutureProvider.autoDispose
    .family<RingkasanKeuangan, int>(
      (ref, siswaId) =>
          ref.watch(waliKeuanganRepositoryProvider).ringkasan(siswaId),
    );

final anakSaldoProvider = FutureProvider.autoDispose.family<num, int>(
  (ref, siswaId) => ref.watch(waliKeuanganRepositoryProvider).saldo(siswaId),
);

final anakTagihanDetailProvider = FutureProvider.autoDispose
    .family<Tagihan, (int siswaId, int tagihanId)>(
      (ref, args) => ref
          .watch(waliKeuanganRepositoryProvider)
          .tagihanDetail(args.$1, args.$2),
    );

final anakPembayaranDetailProvider = FutureProvider.autoDispose
    .family<Pembayaran, (int siswaId, int pembayaranId)>(
      (ref, args) => ref
          .watch(waliKeuanganRepositoryProvider)
          .pembayaranDetail(args.$1, args.$2),
    );

final anakAttemptStatusProvider = FutureProvider.autoDispose
    .family<PaymentAttempt, (int siswaId, int attemptId)>(
      (ref, args) => ref
          .watch(waliKeuanganRepositoryProvider)
          .attemptStatus(args.$1, args.$2),
    );

class WaliTagihanNotifier extends WaliPagedNotifier<Tagihan> {
  WaliTagihanNotifier(super.siswaId);

  String? status; // 'belum_dibayar' | 'dibayar_sebagian' | 'lunas' | ...

  void applyFilter({String? status}) {
    this.status = status;
    refresh();
  }

  @override
  Future<({List<Tagihan> items, PageMeta? meta})> fetchPage(int page) => ref
      .read(waliKeuanganRepositoryProvider)
      .tagihan(siswaId, status: status, page: page)
      .then((r) => (items: r.items, meta: r.meta));
}

final waliTagihanProvider = NotifierProvider.autoDispose
    .family<WaliTagihanNotifier, PagedState<Tagihan>, int>(
      WaliTagihanNotifier.new,
    );

class WaliPembayaranNotifier extends WaliPagedNotifier<Pembayaran> {
  WaliPembayaranNotifier(super.siswaId);
  @override
  Future<({List<Pembayaran> items, PageMeta? meta})> fetchPage(int page) => ref
      .read(waliKeuanganRepositoryProvider)
      .pembayaran(siswaId, page: page)
      .then((r) => (items: r.items, meta: r.meta));
}

final waliPembayaranProvider = NotifierProvider.autoDispose
    .family<WaliPembayaranNotifier, PagedState<Pembayaran>, int>(
      WaliPembayaranNotifier.new,
    );

// ---------------- Notifikasi wali (user-scoped, bukan per anak) ----------------

class WaliNotifikasiNotifier extends Notifier<PagedState<NotifikasiItem>> {
  String? status; // 'read' | 'unread' | null

  @override
  PagedState<NotifikasiItem> build() {
    Future.microtask(refresh);
    return const PagedState();
  }

  Future<PagedResult<NotifikasiItem>> fetchPage(int page) => ref
      .read(waliRepositoryProvider)
      .notifikasi(status: status, page: page)
      .then((r) => PagedResult(items: r.items, meta: r.meta));

  Future<void> refresh() async {
    state = state.copyWith(refreshing: true, clearError: true);
    try {
      final result = await fetchPage(1);
      state = PagedState<NotifikasiItem>(
        items: result.items,
        meta: result.meta,
        page: 1,
      );
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

  void applyFilter({String? status}) {
    this.status = status;
    refresh();
  }
}

final waliNotifikasiProvider =
    NotifierProvider.autoDispose<
      WaliNotifikasiNotifier,
      PagedState<NotifikasiItem>
    >(WaliNotifikasiNotifier.new);

/// Mutation: tandai semua / satu notifikasi dibaca lalu refresh badge & list.
class WaliNotifikasiAction {
  WaliNotifikasiAction(this._ref);

  final Ref _ref;

  Future<TandaiSemuaDibacaResult> markAllRead() async {
    final result = await _ref.read(waliRepositoryProvider).markAllRead();
    _ref.invalidate(waliUnreadCountProvider);
    return result;
  }

  Future<void> markRead(int id) async {
    await _ref.read(waliRepositoryProvider).markRead(id);
    _ref.invalidate(waliUnreadCountProvider);
    _ref.invalidate(waliNotifikasiDetailProvider(id));
  }
}

final waliNotifikasiActionProvider = Provider<WaliNotifikasiAction>(
  WaliNotifikasiAction.new,
);
