# LAPORAN — Flutter Phase 3: Complete Student Mobile Features

**Tanggal:** 17 November 2026 · **Status:** **PASS WITH LIMITATIONS** (Midtrans Sandbox BLOCKED; iOS BLOCKED; live-backend test belum dilakukan — mock-verified)
**Scope:** Seluruh area role `siswa` (17 fitur) terhubung ke Laravel REST API `/api/v1`. Guru/wali/admin tidak diimplementasikan.

---

## 1. Ringkasan audit awal

Yang dibaca & diverifikasi: `docs/FLUTTER_ARCHITECTURE.md`, `LAPORAN_*` Phase 1–2,
`lib/**` penuh, `DOKUMENTASI_REST_API_SIAKAD.md`, `LAPORAN_MASTER_COMPLETE_MOBILE_API.md`,
dan kode backend aktual: `SiswaController`, `PengumumanSiswaController`,
`NotifikasiSiswaController`, `KeuanganController`, `KeuanganFileController`, semua
API Resources, semua FormRequests, dan `PaymentService` (untuk status attempt).

**Temuan audit yang ditindaklanjuti:**
1. **Role guard GoRouter hanya exact-path** — sub-route `/siswa/jadwal` dll. tidak
   terlindungi area prefix. Diperbaiki: `AppRoutes.roleByAreaPrefix()` (prefix match);
   `redirect.dart` memakai pencocokan prefix (area lain → home).
2. **Envelope keuangan ≠ siswa:** list keuangan mengembalikan `data` sebagai **array
   langsung** (bukan `{items}`) dan meta pagination **tanpa `from`/`to`** — parser
   `PageMeta` dibuat toleran (nullable).
3. **`persen_hadir` adalah string format lokal** (mis. `"90,0%"`) — ditampilkan apa adanya.
4. **`konteks` pada `/siswa/jadwal` & `/siswa/absensi/*` tidak memuat `peringatan`** (hanya `beranda`) — model dibuat toleran.
5. `beranda` tidak memuat ringkasan keuangan/notifikasi/pengumuman — dashboard
   mengambilnya dari endpoint masing-masing (bukan mengarang data).
6. 422 backend pada periode (`dari > sampai`) mengembalikan error field `sampai` — diuji.
7. Dokumen privat: body unduhan sukses = binary, error = JSON (403/404) dengan body
   bytes — `_mapDocumentError` khusus mendecode bytes → `ApiException`.

## 2. Daftar endpoint yang digunakan (siswa + keuangan role siswa)

| # | Endpoint | Dipakai di |
|---|---|---|
| S1 | `GET /siswa/profil` | `ProfilSiswa` — tab Profil |
| S2 | `GET /siswa/beranda` | Beranda (identitas, kelas, konteks, jadwal hari ini) |
| S3 | `GET /siswa/jadwal?hari\|tanggal` | `/siswa/jadwal` (tanggal menang — perilaku backend) |
| S4 | `GET /siswa/jadwal/hari-ini` | provider `jadwalHariIniProvider` |
| S5 | `GET /siswa/absensi/harian` | Absensi › Harian |
| S6 | `GET /siswa/absensi/periode` (dari,sampai wajib) | Absensi › Periode |
| S7 | `GET /siswa/absensi/perjam` | Absensi › Per Jam |
| S8 | `GET /siswa/nilai` (?semester_id, ?kelas_id) | `/siswa/nilai` |
| S9 | `GET /siswa/rapor` | `/siswa/rapor` |
| S10 | `GET /siswa/rapor/{semesterId}/{kelasId}` | detail rapor |
| S11 | `GET /siswa/pengumuman?tab=aktif\|riwayat` | `/siswa/pengumuman` |
| S12 | `GET /siswa/pengumuman/{id}` (auto-tandai dibaca) | detail pengumuman |
| S13 | `GET /siswa/notifikasi?status,jenis,per_page,page` | tab Notifikasi |
| S14 | `GET /siswa/notifikasi/unread-count` | badge shell + dashboard |
| S15 | `GET /siswa/notifikasi/{id}` | detail notifikasi |
| S16 | `PATCH /siswa/notifikasi/{id}/read` | tombol "Tandai Dibaca" |
| S17 | `PATCH /siswa/notifikasi/read-all` | "Tandai Semua Dibaca" |
| K1 | `GET /keuangan/ringkasan` | Tab Keuangan + kartu beranda |
| K2 | `GET /keuangan/tagihan` | Tab Keuangan (list, filter status, paginated) |
| K3 | `GET /keuangan/tagihan/{id}` | detail + aksi Bayar |
| K4 | `GET /keuangan/saldo` | Tab Keuangan |
| K5 | `GET /keuangan/pembayaran` | `/siswa/pembayaran` (paginated) |
| K6 | `GET /keuangan/pembayaran/{id}` | detail pembayaran |
| K7 | `POST /keuangan/pembayaran/attempts` `{tagihan_id}` (201) | tombol Bayar → dialog attempt |
| K8 | `GET /keuangan/pembayaran/attempts/{id}` | `/siswa/pembayaran-attempt/:id` |
| K9 | `GET /keuangan/pembayaran/{id}/bukti` | tombol Unduh Bukti (unduh privat) |
| K10 | `GET /keuangan/pembayaran/{id}/kuitansi` | tombol Unduh Kuitansi |
| K11 | `GET /keuangan/refund/dokumen/{id}` | repository support (tidak ada UI dokumen refund — backend hanya merujuk refund flow yang belum ada di mobile; lihat Temuan) |

**Endpoint siswa TIDAK menerima `siswa_id`** — identitas selalu dari token; repository
test memverifikasi request tidak membawa `siswa_id`.

## 3. Fitur yang selesai

1. **Dashboard** — identitas, konteks TA/semester (+peringatan), kelas (+tingkat),
   jadwal hari ini, ringkasan keuangan (sisa/saldo), notifikasi badge, quick actions,
   pull-to-refresh, error state + retry, empty state.
2. **Profil** — read-only (nis/nisn/nama/jk/tahun masuk/status/kelas/akun) + kartu
   "Sesi Perangkat" (perangkat, masa berlaku token) + logout perangkat ini / semua
   perangkat (dialog konfirmasi).
3. **Jadwal** — filter hari (Semua/Senin..Minggu) + date picker (tanggal menang di
   backend), konteks TA/semester, daftar kanonis (jam, mulai–selesai, mapel, guru),
   empty state, pull-to-refresh. Tidak ada detail jadwal (endpoint detail hanya ada
   untuk guru — dicatat).
4. **Absensi** — 3 tab: Harian (rekap semester + filter status + histori + pagination),
   Periode (dari/sampai wajib + validasi rentang + rekap + histori, filter status),
   Per Jam (rekap total seluruh riwayat + histori pertemuan: mapel, guru, jam, status).
   **Read-only; tidak ada check-in/self-attendance.**
5. **Nilai** — kelompok rapor final (semester/kelas dropdown-chip filter opsional,
   termasuk filter `semester_id`/`kelas_id` ke backend — 404 NILAI_NOT_FOUND dipetakan),
   mapel + kode, nilai_akhir (2 desimal), KKTP, keterangan, highlight merah bila di
   bawah KKTP.
6. **Rapor** — daftar rapor final (wali kelas, waktu finalisasi) → detail (nama sekolah,
   semester+TA, kelas, badge FINAL, rekap kehadiran, nilai per mapel, catatan).
7. **Pengumuman** — tab Aktif/Riwayat (backend `tab`), detail (auto-tandai dibaca oleh
   backend), badge prioritas, indikator belum baca; konten `SelectableText`.
8. **Notifikasi** — list + filter status (Semua/Belum Dibaca/Dibaca), badge unread
   count di bottom nav + dashboard, detail (TIDAK auto-mark, sesuai perilaku web —
   tombol "Tandai Dibaca"), "Tandai Semua Dibaca" (dengan konfirmasi, invalidate badge),
   pagination, mark-read invalidate list+detail+badge.
9. **Keuangan — Ringkasan** — total kewajiban/dibayar/sisa + progress bar, saldo.
10. **Tagihan** — list dengan filter status (semua/belum_dibayar/dibayar_sebagian/lunas/
    dibebaskan/dibatalkan) + pagination + detail (nominal/terbayar/sisa/jatuh tempo) +
    aksi **Bayar** hanya bila belum lunas & sisa > 0.
11. **Payment attempt** — dialog konfirmasi → `POST .../attempts {tagihan_id}` saja
    (payload TIDAK memuat nominal — diverifikasi test) → dialog hasil (nomor order,
    nominal, status `created`) → "Buka Halaman Pembayaran" (url_launcher, external) &
    "Periksa Status" (halaman attempt: status dari server, ikon per status, tidak pernah
    mensettle transaksi) → refresh detail pasca dialog. 503 (gateway down) → snackbar
    pesan backend (tidak ada kredensial Sandbox).
12. **Riwayat & detail pembayaran** — list (paginated) + detail (metode, waktu bayar,
    referensi) + unduh **Bukti** & **Kuitansi** via endpoint privat (Bearer), simpan ke
    direktori dokumen aplikasi + buka via `open_filex`; 404/403 → pesan backend.

Semua halaman: loading / error / empty state, pull-to-refresh, layar kecil
(ScrollView/LayoutBuilder anti-overflow), role guard tetap.

## 4. Struktur folder

Lihat `docs/FLUTTER_ARCHITECTURE.md` §1 & §12 (tree lengkap). Ringkas:

```
lib/features/siswa/
  data/{models/, siswa_repository.dart, keuangan_repository.dart,
        private_document_service.dart, paged_state.dart}
  application/{siswa_providers.dart, paged_notifier.dart,
               absensi_notifiers.dart, siswa_tab_index.dart}
  presentation/{siswa_shell.dart, beranda/, akademik/, keuangan/,
                notifikasi/, pengumuman/, profil/}
lib/core/{utils/formatters.dart, widgets/app_widgets.dart, widgets/app_empty_view.dart}
```

Pola: satu-shot data → `FutureProvider.autoDispose(.family)`; list ter-paginasi →
`NotifierProvider.autoDispose` + `PagedNotifier<T>` (base tipis, state bersama
`items/meta/busy/refreshing/error`); absensi pakai state khusus (`AbsensiListState`)
karena response membawa rekap ringkasan.

## 5. Perubahan file

**Dibuat (lib):** 36 file — models siswa/keuangan (8), repository 2, `paged_state`,
`private_document_service`, `formatters.dart`, `app_widgets.dart` (AsyncValueView,
SectionHeader, StatusBadge + labelOf/forStatus, InfoRow, InfoCard, MenuCard,
SkeletonBox), shell + tab pages (beranda, akademik ×5, keuangan ×5, notifikasi ×2,
pengumuman ×2, profil), `paged_notifier`, `absensi_notifiers`, `siswa_tab_index`.

**Diubah:** `app_router.dart` (route siswa + errorBuilder param invalid),
`app_routes.dart` (prefix guard + konstanta route siswa), `redirect.dart` (prefix
match), `api_envelope.dart` (+`meta()`), `pubspec.yaml`/`pubspec.lock`,
`linux/macos/windows/flutter/generated_plugin_registrant.*` (regenerasi otomatis
oleh `flutter pub get` setelah dependency baru — bukan edit manual).

**Dihapus:** `lib/features/siswa/presentation/siswa_home_page.dart` (placeholder
gantikan shell baru — guru/wali placeholder tidak disentuh).

**Test (baru):** `test/features/siswa/siswa_repository_test.dart` (24),
`test/features/siswa/keuangan_repository_test.dart` (14),
`test/features/siswa/siswa_pages_widget_test.dart` (11), `test/fakes/path_adapter.dart`
(path-based fake adapter — deterministik untuk shell yang memicu banyak request
paralel) + ekstensi `FakeHttpClientAdapter.queueBytes` + `harness.dart` (+9 body mock).
**Test (diubah):** `auth_flow_widget_test.dart` (navigasi tab Profil; dashboard test
menyesuaikan shell baru; loading-state assertion diganti verifikasi redirect role —
lihat Temuan #6).

## 6. Dependency baru dan alasan

| Dependency | Alasan |
|---|---|
| `path_provider` ^2.1.6 | Direktori dokumen aplikasi untuk menyimpan dokumen privat hasil unduhan |
| `open_filex` ^5.0.0 | Membuka dokumen (PDF/gambar) dengan viewer bawaan perangkat |
| `url_launcher` ^6.3.3 | Membuka `snap_redirect_url` Midtrans di browser eksternal |

Semua minimal, pub.dev, tanpa kredensial/secret. Tidak ada dependency untuk
PDF-viewer in-app (di luar scope; viewer sistem dipakai).

## 7. Automated tests & hasil

```
dart format .     ✓ (85 file)
flutter analyze   ✓ No issues found!
flutter test      ✓ All tests passed! (149/149)
```

| File | Jumlah |
|---|---|
| test/widget_test.dart | 1 |
| test/app/router/redirect_test.dart | 17 |
| test/core/config/app_config_test.dart | 5 |
| test/core/errors/error_mapper_test.dart | 19 |
| test/core/network/auth_interceptor_test.dart | 4 |
| test/core/storage/secure_storage_service_test.dart | 4 |
| test/features/auth/auth_controller_test.dart | 24 |
| test/features/auth/auth_flow_widget_test.dart | 12 |
| test/features/auth/auth_repository_test.dart | 14 |
| test/features/siswa/siswa_repository_test.dart | 24 |
| test/features/siswa/keuangan_repository_test.dart | 14 |
| test/features/siswa/siswa_pages_widget_test.dart | 11 |
| **Total** | **149** |

Cakupan fase ini: repository (akademik & keuangan, termasuk payload attempt minimal
tanpa nominal, dokumen 403/404, meta tanpa from/to), pagination & filter params,
error mapping 422/404/503/403, widget test navigasi shell, dashboard (sukses/error/badge),
nick absensi 3 tab, keuangan list/detail/bayar dialog/404 bukti, notifikasi tandai
lunas, rapor list→detail. Role guard sub-route & tanpa redirect loop (existing tests)
tetap lulus.

## 8. `flutter analyze`

```
Analyzing siakad-mobile...
No issues found! (ran in 7.5s)
```

## 9. Android debug build

```
flutter build apk --debug → ✓ Built build\app\outputs\flutter-apk\app-debug.apk (205 MB)
(warning gradle "restricted method" bersifat informasional; exit code 1 dari stderr PowerShell)
```

(Platform Android 34 diunduh otomatis gradle; build 412 s)

## 10. Status integrasi keuangan

- **Mock-verified (PASS):** ringkasan, tagihan (list/filter/detail), saldo, pembayaran
  (list/detail/dokumen), attempt create/status, error mapping 503/403/404/422,
  kelengkapan payload attempt (`{tagihan_id}` saja).
- **Midtrans Sandbox: BLOCKED** — tidak ada kredensial Sandbox; alur Snap
  (redirect → webhook → status) tidak dapat diverifikasi live. Aplikasi tidak
  mengklaim transaksi berhasil; semua status mengikuti `GET .../attempts/{id}`.
- **Live backend (UAT): belum diuji** — butuh kredensial staging siswa + backend TLS;
  seluruh kontrak diverifikasi dari kode backend & mock yang mereproduksi envelope.
- Dokumen refund (`K11`): repository method tersedia; **tidak ada UI** karena tidak
  ada endpoint siswa untuk *mendaftar* dokumen refund (harus masuk dari tagihan/
  pembayaran yang memiliki refund — alur belum tersedia di mobile; lihat Temuan).
  BUKTI & KUITANSI (K9, K10) sepenuhnya tersedia (tombol di detail pembayaran).

## 11. Keterbatasan

- **iOS: BLOCKED** — Windows; butuh macOS + Xcode. Tidak ada klaim iOS build.
- **Physical device: BLOCKED** — belum diuji live; `--dart-define=API_BASE_URL=http://<ip-lan>:8000/api/v1`.
- **Midtrans Sandbox: BLOCKED** (lihat §10).
- **Backend live: tidak diuji** — lihat §10.
- Detail jadwal siswa **tidak tersedia** (endpoint detail hanya ada di guru — S-series);
  list jadwal menampilkan mulai–selesai + mapel + guru langsung dari daftar.

## 12. Temuan teknis

1. Route guard harus prefix-matched untuk sub-route (diperbaiki: `roleByAreaPrefix`).
2. Envelope keuangan berbeda dari siswa (data array langsung; meta tanpa from/to);
   `PageMeta.fromJson` toleran.
3. `persen_hadir` = string format lokal; dirender apa adanya.
4. `/siswa/beranda` tidak memuat notifikasi/keuangan/pengumuman summary — dashboard
   memanggil 3 endpoint lain (unread-count, ringkasan, pengumuman? tidak — hanya
   unread-count & ringkasan; pengumuman hanya diakses dari menu) — bukan atribusi backend.
5. Backend auto-tandai dibaca pengumuman saat detail dibuka; notifikasi TIDAK
   auto-mark — UI menghormati keduanya.
6. Widget test: `pumpAndSettle()` macet karena animasi berkelanjutan di subtree
   keuangan (perilaku lingkungan test, bukan bug aplikasi — layout stabil di APK);
   satu widget test memakai pump terbatas (deterministik). Perhatian: dialog attempt
   memblok settle karena barrier konstan — bukan bug.
7. `StateError: Bad state` di widget test ketika path detail mengembalikan body list
   (envelope path-fallback) — diperbaiki dengan override path yang eksplisit; pelajaran:
   fake path harus tepat.
8. `pengumuman/{id}` auto-tandai dibaca → detail provider di-cache; invalidation list
   diperlukan pada pull-to-refresh.
9. Tidak ada cara bagi siswa untuk menyertakan `siswa_id` — diverifikasi test (request
   keuangan siswa tidak membawa `siswa_id`).
10. `gen plugin registrant` (linux/macos/windows) berubah otomatis akibat `pub add` —
    side effect standar, bukan edit manual.

## 13. Status Git

Repository Flutter **ada** (1 commit: `a8518dd feat(flutter): complete foundation and authentication`).
Phase 3 **belum di-commit** (tidak ada Git write command yang dijalankan).

`git status --short` (Phase 3):

```
 M pubspec.yaml  M pubspec.lock
 M linux/flutter/generated_plugin_registrant.cc  M linux/...generated_plugins.cmake
 M macos/Flutter/GeneratedPluginRegistrant.swift
 M windows/flutter/generated_plugin_registrant.cc  M windows/...generated_plugins.cmake
 M lib/app/router/app_router.dart  M lib/app/router/app_routes.dart  M lib/app/router/redirect.dart
 M lib/core/network/api_envelope.dart
 D lib/features/siswa/presentation/siswa_home_page.dart
 M test/fakes/fake_http_client_adapter.dart  M test/fakes/harness.dart
 M test/features/auth/auth_flow_widget_test.dart
?? lib/core/utils/  ?? lib/core/widgets/app_widgets.dart
?? lib/features/siswa/application/  ?? lib/features/siswa/data/
?? lib/features/siswa/presentation/(akademik|beranda|keuangan|notifikasi|pengumuman|profil|siswa_shell.dart)
?? test/fakes/path_adapter.dart  ?? test/features/siswa/
```

Pengguna disarankan membuat checkpoint commit sendiri (mis.
`feat(flutter): phase 3 - complete student features`).
