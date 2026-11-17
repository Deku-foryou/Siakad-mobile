import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../data/keuangan_repository.dart';
import '../data/models/beranda.dart';
import '../data/models/keuangan.dart';
import '../data/models/nilai.dart';
import '../data/models/notifikasi.dart';
import '../data/models/page_meta.dart';
import '../data/models/pengumuman.dart';
import '../data/paged_state.dart';
import '../data/siswa_repository.dart';
import 'paged_notifier.dart';

// ---------------------------------------------------------------- Repositories

final siswaRepositoryProvider = Provider<SiswaRepository>(
  (ref) => SiswaRepository(ref.watch(dioProvider)),
);

final keuanganRepositoryProvider = Provider<KeuanganRepository>(
  (ref) => KeuanganRepository(ref.watch(dioProvider)),
);

// ------------------------------------------------------- One-shot providers

final berandaProvider = FutureProvider.autoDispose<BerandaSiswa>(
  (ref) => ref.watch(siswaRepositoryProvider).beranda(),
);

final profilProvider = FutureProvider.autoDispose<ProfilSiswa>(
  (ref) => ref.watch(siswaRepositoryProvider).profil(),
);

/// arg: (tanggal 'YYYY-MM-DD'?, hari 1..7?). `tanggal` menang di backend.
final jadwalProvider = FutureProvider.autoDispose
    .family<JadwalResponse, (String? tanggal, int? hari)>(
      (ref, args) => ref
          .watch(siswaRepositoryProvider)
          .jadwal(tanggal: args.$1, hari: args.$2),
    );

final jadwalHariIniProvider = FutureProvider.autoDispose<JadwalResponse>(
  (ref) => ref.watch(siswaRepositoryProvider).jadwalHariIni(),
);

/// Nilai akhir (snapshot rapor final). Filter opsional semesterId/kelasId.
/// arg: (semesterId?, kelasId?)
final nilaiProvider = FutureProvider.autoDispose
    .family<List<NilaiKelompok>, (int? semesterId, int? kelasId)>(
      (ref, args) => ref
          .watch(siswaRepositoryProvider)
          .nilai(semesterId: args.$1, kelasId: args.$2),
    );

final raporProvider = FutureProvider.autoDispose<List<RaporEntry>>(
  (ref) => ref.watch(siswaRepositoryProvider).rapor(),
);

final raporDetailProvider = FutureProvider.autoDispose
    .family<RaporDetail, (int semesterId, int kelasId)>(
      (ref, args) => ref
          .watch(siswaRepositoryProvider)
          .raporDetail(semesterId: args.$1, kelasId: args.$2),
    );

final pengumumanDetailProvider = FutureProvider.autoDispose
    .family<PengumumanItem, int>(
      (ref, id) => ref.watch(siswaRepositoryProvider).pengumumanDetail(id),
    );

final notifikasiDetailProvider = FutureProvider.autoDispose
    .family<NotifikasiItem, int>(
      (ref, id) => ref.watch(siswaRepositoryProvider).notifikasiDetail(id),
    );

final unreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(siswaRepositoryProvider).unreadCount(),
);

final ringkasanProvider = FutureProvider.autoDispose<RingkasanKeuangan>(
  (ref) => ref.watch(keuanganRepositoryProvider).ringkasan(),
);

final saldoProvider = FutureProvider.autoDispose<num>(
  (ref) => ref.watch(keuanganRepositoryProvider).saldo(),
);

final tagihanDetailProvider = FutureProvider.autoDispose.family<Tagihan, int>(
  (ref, id) => ref.watch(keuanganRepositoryProvider).tagihanDetail(id),
);

final pembayaranDetailProvider = FutureProvider.autoDispose
    .family<Pembayaran, int>(
      (ref, id) => ref.watch(keuanganRepositoryProvider).pembayaranDetail(id),
    );

final attemptStatusProvider = FutureProvider.autoDispose
    .family<PaymentAttempt, int>(
      (ref, id) => ref.watch(keuanganRepositoryProvider).attemptStatus(id),
    );

class PengumumanNotifier extends PagedNotifier<PengumumanItem> {
  String tab = 'aktif';

  void setTab(String value) {
    if (tab == value) return;
    tab = value;
    refresh();
  }

  @override
  Future<PagedResult<PengumumanItem>> fetchPage(int page) =>
      ref.read(siswaRepositoryProvider).pengumuman(tab: tab, page: page);
}

final pengumumanProvider =
    NotifierProvider.autoDispose<
      PengumumanNotifier,
      PagedState<PengumumanItem>
    >(PengumumanNotifier.new);

class NotifikasiNotifier extends PagedNotifier<NotifikasiItem> {
  String? status; // 'read' | 'unread' | null

  void applyFilter({String? status}) {
    this.status = status;
    refresh();
  }

  @override
  Future<PagedResult<NotifikasiItem>> fetchPage(int page) => ref
      .read(siswaRepositoryProvider)
      .notifikasi(status: status, page: page)
      .then((r) => PagedResult(items: r.items, meta: r.meta));
}

final notifikasiProvider =
    NotifierProvider.autoDispose<
      NotifikasiNotifier,
      PagedState<NotifikasiItem>
    >(NotifikasiNotifier.new);

class TagihanNotifier extends PagedNotifier<Tagihan> {
  String? status; // 'belum_dibayar' | 'dibayar_sebagian' | 'lunas' | ...

  void applyFilter({String? status}) {
    this.status = status;
    refresh();
  }

  @override
  Future<PagedResult<Tagihan>> fetchPage(int page) =>
      ref.read(keuanganRepositoryProvider).tagihan(status: status, page: page);
}

final tagihanProvider =
    NotifierProvider.autoDispose<TagihanNotifier, PagedState<Tagihan>>(
      TagihanNotifier.new,
    );

class PembayaranNotifier extends PagedNotifier<Pembayaran> {
  @override
  Future<PagedResult<Pembayaran>> fetchPage(int page) =>
      ref.read(keuanganRepositoryProvider).pembayaran(page: page);
}

final pembayaranProvider =
    NotifierProvider.autoDispose<PembayaranNotifier, PagedState<Pembayaran>>(
      PembayaranNotifier.new,
    );

/// Mutation: tandai semua notifikasi dibaca lalu refresh badge & list.
/// Dipanggil dari UI; tidak optimistic.
class NotifikasiAction {
  NotifikasiAction(this._ref);

  final Ref _ref;

  Future<TandaiSemuaDibacaResult> markAllRead() async {
    final result = await _ref.read(siswaRepositoryProvider).markAllRead();
    _ref.invalidate(unreadCountProvider);
    return result;
  }

  Future<void> markRead(int id) async {
    await _ref.read(siswaRepositoryProvider).markRead(id);
    _ref.invalidate(unreadCountProvider);
    _ref.invalidate(notifikasiDetailProvider(id));
  }
}

final notifikasiActionProvider = Provider<NotifikasiAction>(
  NotifikasiAction.new,
);
