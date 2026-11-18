# LAPORAN FLUTTER PHASE 5 — GUARDIAN FEATURES (MODUL WALI MURID)

**Tanggal:** 2026-11-17 · **Status:** **PASS WITH LIMITATIONS**

Phase 5 (fitur wali murid pada Flutter SIAKAD Mobile) selesai diimplementasikan,
diverifikasi, dan didokumentasikan. Semua keterbatasan dicatat eksplisit di
bagian 12–13. **Penting:** hanya mock HTTP yang diuji; TIDAK ada klaim
pengujian live backend atau integration test live.

---

## 1. Hasil audit API wali (backend aktual, bukan hanya dokumentasi)

Audit dilakukan pada kode aktual Laravel (`C:\project-reyhan\template web`):
routes (`routes/api.php`), controller, form requests, resources, services,
middleware (`api.role`, `api.akun`, `api.password`), `WalimuridService`,
`BerandaWaliService`, `RaporSiswaService`/`RekapAbsensiService`, dan
`DOKUMENTASI_REST_API_SIAKAD.md` (dicek cocok dengan implementasi).

**Temuan utama audit:**

- Prefix `/api/v1/wali/*` — 19 endpoint; prefix `/api/v1/keuangan/*` dipakai
  juga untuk wali (role `siswa,wali`) dengan **`siswa_id` wajib** (query GET,
  body POST attempt). Tanpa siswa_id → 403.
- Gerbang akademik wali ditegakkan backend di
  `WalimuridService::pastikanAksesAkademikWali()`: relasi milik wali +
  `status_hubungan = verified` + `tanggal_berhenti` null + `tanggal_mulai`
  sudah berlaku + konteks akademik valid. Penolakan → 403 `AKSES_DITOLAK`.
- Keuangan memakai `relasiWaliAktifSiswa()`: verified + `tanggal_mulai <=`
  hari ini + `tanggal_berhenti` null/≥hari ini + wali aktif.
- `ApiResponse` envelope: `{success, message, data?, meta?}`; gagal
  `{success, message, code?, errors?}`. `meta` pagination hanya pada
  absensi harian/periode/perjam dan notifikasi (keuangan TIDAK mengirim
  `from`/`to`).
- Resource DTO: beranda anak (`BerandaResource`), jadwal (`JadwalResource`),
  absensi (`AbsensiHarianResource`/`AbsensiPerjamResource`), nilai
  (`NilaiKelompokResource` — nilai akhir rapor final), rapor
  (`RaporResource`/`RaporDetailResource`) — identik portal siswa.
- Beranda wali: identitas + konteks + **anak verified saja** + ringkasan
  (`jumlah_anak/menunggu/ditolak/berakhir`, `notifikasi_belum_dibaca`).
- `/wali/anak` mengembalikan SEMUA status relasi + `bisa_akses_akademik`
  (dihitung backend) + `kelas` (TA aktif) + histori.
- Notifikasi wali = modul notifikasi (user-scoped); **pengumuman wali
  TIDAK TERSEDIA** (modul pengumuman siswa-scoped; guru pun tidak punya).
- W5 `permintaan-putus` ADA di API, tetapi **tidak termasuk scope Phase 5**
  (spec §2 A–I tidak mencantumkannya) → tidak diimplementasikan.
- Tidak ada endpoint mutasi akademik untuk wali (semua read-only) — sesuai.

## 2. Daftar endpoint yang benar-benar digunakan

Profil/relasi:
- `GET /wali/profil` · `GET /wali/beranda` · `GET /wali/anak` · `GET /wali/anak/{siswaId}`

Akademik anak:
- `GET /wali/anak/{siswaId}/beranda`
- `GET /wali/anak/{siswaId}/jadwal` (`hari`/`tanggal`), `GET .../jadwal/hari-ini`
- `GET /wali/anak/{siswaId}/absensi/harian` · `GET .../absensi/periode` · `GET .../absensi/perjam`
- `GET /wali/anak/{siswaId}/nilai` (`semester_id`/`kelas_id` opsional)
- `GET /wali/anak/{siswaId}/rapor` · `GET .../rapor/{semesterId}/{kelasId}`

Notifikasi wali:
- `GET /wali/notifikasi` · `GET /wali/notifikasi/unread-count` · `GET /wali/notifikasi/{id}`
- `PATCH /wali/notifikasi/{id}/read` · `PATCH /wali/notifikasi/read-all`

Keuangan anak (grup `/keuangan`, wali wajib `siswa_id`):
- `GET /keuangan/ringkasan` · `GET /keuangan/tagihan[?status]` · `GET /keuangan/tagihan/{id}`
- `GET /keuangan/saldo` · `GET /keuangan/pembayaran` · `GET /keuangan/pembayaran/{id}`
- `POST /keuangan/pembayaran/attempts` · `GET /keuangan/pembayaran/attempts/{id}`
- Unduh privat: `GET /keuangan/pembayaran/{id}/bukti` · `GET .../kuitansi` · `GET /keuangan/refund/dokumen/{id}`

TIDAK dipakai: `POST /wali/anak/{siswaId}/permintaan-putus` (di luar scope).

## 3. Fitur yang berhasil diimplementasikan

Sesuai spec §2 A–I:

A. **Dashboard Wali** — identitas (nama/@username/badge), konteks TA+semester
   (+peringatan backend), ringkasan relasi (verified/menunggu/ditolak/berakhir),
   badge notifikasi belum dibaca, keuangan anak terpilih (label jelas dengan
   nama anak), daftar anak verified + quick action (dinonaktifkan bila tanpa
   anak terverifikasi), loading/empty/error/retry/refresh per section.
B. **Daftar Anak** — semua relasi (semua status) + filter status + badge;
   pemilihan anak (verified) menjadi konteks; empty-state "Belum Ada Relasi
   Anak" tanpa anak sama sekali; warning konteks akademik tidak valid.
C. **Detail & Profil Anak** — identitas (NIS/NISN/nama/JK/tahun masuk/status),
   hubungan (status, tanggal mulai/verifikasi/berhenti), kelas TA aktif,
   histori relasi (append-only), data beranda anak (konteks akademik + kelas +
   jadwal hari ini — read-only). TANPA tombol edit.
D. **Jadwal Anak** — filter hari (Semua/Senin..Minggu) + filter tanggal
   (menang atas hari, sesuai perilaku backend) + grouping per hari; jam,
   mapel, guru; empty/error/retry/refresh; hanya `siswaId` route.
E. **Absensi Anak** — 3 tab: **Harian** (filter status + rekap semester +
   ringkasan filter + pagination), **Periode** (date-range wajib + status +
   ringkasan periode + pagination; dari>sampai ditolak di UI dengan pesan),
   **Per Jam** (filter status + rekap_total seluruh riwayat + pagination).
   Persen kehadiran ditampilkan apa adanya dari backend (string lokal).
F. **Nilai & Rapor** — nilai akhir (snapshot finalisasi; chip filter
   semester·kelas yang tersedia; 404 `NILAI_NOT_FOUND` ditangani), KKTP per
   nilai, daftar rapor final + detail (nilai, rekap kehadiran, catatan wali
   kelas, nama sekolah). Tidak menghitung ulang nilai akhir.
G. **Pengumuman & Notifikasi** — hanya **notifikasi** (list + filter
   Semua/Belum Dibaca/Dibaca + pagination + detail + tandai satu dibaca +
   tandai semua dibaca + badge shell & beranda yang di-refresh setelah aksi).
   **Pengumuman tidak tersedia di API wali** → tidak diimplementasikan.
H. **Keuangan Anak** — ringkasan (kewajiban/dibayar/sisa/saldo), tagihan
   (list + filter status + pagination + detail + tombol Bayar), saldo,
   riwayat pembayaran (pagination + detail), unduh dokumen privat
   (bukti/kuitansi; mekanisme `PrivateDocumentService` Phase 3; BUKAN URL
   publik), payment attempt (nominal dari server; `siswa_id`+`tagihan_id`
   saja dikirim; double-submission dicegah; redirect Midtrans via
   url_launcher; status hanya dari server; K8).
I. **Profil & Sesi Wali** — profil read-only + relasi ringkasan + info sesi
   (perangkat, expiry token) + logout perangkat ini + logout semua perangkat
   (AuthController Phase 2).

## 4. Struktur model / repository / provider / halaman

**Models** (`lib/features/wali/data/models/wali.dart`):
`ProfilWali`, `RelasiRingkasan`, `BerandaWali` (+`AnakRingkas`,
`BerandaWaliRingkasan`), `AnakListResponse`, `AnakRelasi`, `AnakDetail`,
`AnakSiswa`, `HistoriRelasi`. Payload akademik/keuangan/notifikasi yang
identik dengan siswa **dipakai ulang** dari modul siswa
(`BerandaSiswa/JadwalResponse/AbsensiHarianResponse/AbsensiPeriodeResponse/
AbsensiPerjamResponse/NilaiKelompok/RaporEntry/RaporDetail/
RingkasanKeuangan/Tagihan/Pembayaran/PaymentAttempt` + `KonteksAkademik`) —
tidak ada duplikasi business logic maupun model kedap.

**Repositories:** `WaliRepository` (endpoint `/wali/*`; parameter `siswaId`
hanya sebagai path param), `WaliKeuanganRepository` (endpoint `/keuangan/*`;
menyisipkan `siswa_id` — query GET / body POST attempt \u003E upload dokumen
tanpa siswa_id).

**Providers** (`application/wali_providers.dart`, `wali_absensi_notifiers.dart`,
`wali_paged_notifier.dart`, `wali_tab_index.dart`):
- one-shot `.autoDispose.family` per siswaId (anakBeranda/jadwal/jadwalHariIni/
  nilai/rapor/raporDetail/ringkasanKeuangan/saldo/tagihanDetail/
  pembayaranDetail/attemptStatus);
- notifier family per siswaId untuk tagihan (filter status) dan pembayaran
  (PagedNotifier generik) serta absensi harian/periode/perjam (state
  khusus `WaliAbsensiListState` dengan rekap/ringkasan/filter dari backend);
- `waliAnakListProvider`, `selectedAnakIdProvider` (in-memory),
  `waliAnakAktifProvider` (eligible = `bisa_akses_akademik`);
- notifikasi (user-scoped): `waliNotifikasiProvider` + `waliUnreadCountProvider`
  + `WaliNotifikasiAction` (mark read/all + invalidate badge).

**Halaman** (pola siswa/guru; IndexedStack + bottom nav 5 tab):
`wali_shell.dart` → Beranda (`wali_dashboard_page.dart`), Anak
(`wali_anak_page.dart`), Keuangan (`wali_keuangan_page.dart`), Notifikasi,
Profil; sub-route `/wali/anak/:siswaId[/jadwal|absensi|nilai|rapor[/:semesterId/:kelasId]|keuangan/...]`
serta `/wali/notifikasi/:id` (menutupi shell). Widget reusable:
`widgets/child_switcher.dart` (`ChildSwitcher`, `PilihAnakKosong`),
`widgets/relasi_widgets.dart` (`RelasiStatus`, `RelasiTerkunciBanner`).

Routes ditambahkan di `app_routes.dart` + `app_router.dart` (nested routes
dengan parameter int tervalidasi; `_parseIntParam` menolak id ≤ 0/non-numeric).

## 5. Strategi pemilihan & perpindahan konteks anak

1. Sub-halaman akademik/keuangan anak membawa **`:siswaId` sebagai route
   param** — konteks eksplisit, deep-linkable, anti-ambigu.
2. Tab shell Beranda/Keuangan memakai `waliAnakAktifProvider`:
   eligible = relasi `bisa_akses_akademik` (verdict backend); pilihan
   eksplisit (tap anak di Beranda/tab Anak) dihormati selama anak tsb tetap
   eligible; selain itu fallback ke anak verified pertama; null bila tidak ada.
3. Perpindahan Beranda/Anak/Keuangan/Notifikasi/Profil memakai tab IndexedStack
   — state tab terjaga; sub-halaman anak dibuka via router.
4. ChildSwitcher (dropdown) tersedia di tab Keuangan; tap anak verified di
   daftar/detail memindahkan konteks (sets `selectedAnakIdProvider`) lalu
   membuka halaman terkait dengan `:siswaId` route param.

## 6. Strategi isolasi cache antar-anak

- **Family provider keyed by siswaId** untuk semua data child-scoped;
  ganti anak → instance provider/notifier baru → data baru dari jaringan.
  Tidak ada `ref` global "anak aktif" di dalam repository.
- `FutureProvider.autoDispose.family` + notifier family autoDispose →
  state dibuang saat tidak ada watcher.
- Notifier per anak menjaga filter (absensi/tagihan) di instance masing-masing.
- Notifikasi (user-scoped) sengaja **bukan** per-anak; tidak membawa `siswa_id`.
- Keuangan/pembayaran/detail selalu memanggil ulang dengan siswaId tsb;
  family key mencegah data anak sebelumnya tampil saat kembali.
- Widget test + "Relasi dan isolasi anak" diuji terpisah
  (`wali_isolation_test.dart`) — lihat §7.
- Tidak ada persistensi pilihan anak (in-memory saja) — tidak ada cache
  basi antar sesi.
- (Tidak memakai `keepAlive` untuk provider ber-payload anak; tidak ada
  prefetch anak non-pilih.)

## 7. Penanganan relasi pending/verified/terminated

| Status relasi | Perilaku UI |
|---|---|
| `verified` (dan `tanggal_berhenti` null) | Bisa akses akademik & keuangan; menu aktif; keuangan memakai siswa_id; halaman render normal |
| `pending` | Tab Anak: badge "Menunggu Verifikasi"; Detail: `RelasiTerkunciBanner` + histori relasi; menu akademik/keuangan TIDAK dirender; `anakBerandaProvider` baru dipanggil saat akses ada; akses via URL langsung → backend 403 `AKSES_DITOLAK` → halaman error + pesan backend (tidak pernah menampilkan data palsu) |
| `rejected` | Idem — badge "Ditolak"; tidak eligible jadi anakAktif; keuangan → empty-state |
| `terminated` | Idem — badge "Berakhir"; tidak eligible; banner terkunci tampil; akumulasi historis ditampilkan apa adanya |
| `tanggal_berhenti` terisi & masih berlaku (window berakhir) | Backend yang menilai; Flutter tidak menghitung; verdict `bisa_akses_akademik` dihormati |
| Konteks akademik tidak valid (`konteks.valid = false` / peringatan) | Banner peringatan tampil apa adanya dari backend; halaman akademik tetap render bila backend mengizinkan |

Backend tetap otoritas — Flutter tidak mengimplementasikan ulang kebijakan
`status_hubungan`/`tanggal_berhenti`. Tidak ada anak verified → tab
Keuangan & kartu beranda keuangan menampilkan empty-state informatif;
quick action akademik dinonaktifkan.

## 8. File yang dibuat & diubah

**Dibuat (32):**
- `lib/features/wali/application/`: `wali_providers.dart`,
  `wali_absensi_notifiers.dart`, `wali_paged_notifier.dart`, `wali_tab_index.dart`
- `lib/features/wali/data/`: `wali_repository.dart`,
  `wali_keuangan_repository.dart`, `models/wali.dart`
- `lib/features/wali/presentation/`: `wali_shell.dart`,
  `beranda/wali_dashboard_page.dart`,
  `anak/wali_anak_page.dart`, `anak/wali_anak_detail_page.dart`,
  `akademik/wali_jadwal_page.dart`, `akademik/wali_absensi_page.dart`,
  `akademik/wali_nilai_page.dart`, `akademik/wali_rapor_page.dart`,
  `akademik/wali_rapor_detail_page.dart`,
  `keuangan/wali_keuangan_page.dart`, `keuangan/wali_tagihan_detail_page.dart`,
  `keuangan/wali_pembayaran_page.dart`, `keuangan/wali_pembayaran_detail_page.dart`,
  `keuangan/wali_attempt_status_page.dart`,
  `notifikasi/wali_notifikasi_page.dart`, `notifikasi/wali_notifikasi_detail_page.dart`,
  `profil/wali_profil_page.dart`,
  `widgets/child_switcher.dart`, `widgets/relasi_widgets.dart`
- `test/features/wali/`: `wali_repository_test.dart`,
  `wali_keuangan_repository_test.dart`, `wali_isolation_test.dart`,
  `wali_routing_test.dart`, `wali_widget_test.dart`

**Diubah (6):** `lib/app/router/app_router.dart` (+imports, +11 route,
`_parseIntParam`), `lib/app/router/app_routes.dart` (+konstanta route wali
nested), `docs/FLUTTER_ARCHITECTURE.md` (+§14 Wali Module),
`test/fakes/harness.dart` (+fixture wali), `test/fakes/path_adapter.dart`
(+fallback `/wali/*`), `lib/features/wali/presentation/wali_home_page.dart`
**dihapus** (diganti WaliShell penuh).

Tidak ada perubahan pada Foundation/Auth (tidak ada bug konkret), tidak ada
perubahan pada backend Laravel/database/migration/seeder, tidak ada halaman
siswa/guru yang diubah.

## 9. Hasil test & assertion

`flutter test` — **seluruh 298 test lulus** (185 regresi phase 1–4 + **113
test wali baru**). `flutter analyze` — **No issues found**. `dart format .` —
144 file diformat (25 diubah). `flutter build apk --debug` — **sukses**:
`build\app\outputs\flutter-apk\app-debug.apk` (Gradle `assembleDebug` 134.9s;
hanya peringatan `java.lang.System::load` standar dari Gradle worker).

Pemetaan matriks uji (spec §6):

| # | Uji | Lokasi |
|---|---|---|
| 1 | Seluruh endpoint wali yang digunakan terpetakan (19 wali + keuangan) | `wali_repository_test.dart`, `wali_keuangan_repository_test.dart` (mock FakeHttpClientAdapter, path + method + query/body diassert) |
| 2 | Parsing response aktual | idem (profil/beranda/anak/jadwal/absensi/nilai/rapor/notifikasi/tagihan/pembayaran/attempt) |
| 3 | Response kosong (anak [], itens [], rapor final [], tagihan []) | `daftar anak kosong`, `rapor kosong`, `tagihan kosong` |
| 4 | Error HTTP (403/404/500/503) | AKSES_DITOLAK, ANAK_NOT_FOUND, NILAI_NOT_FOUND, RAPOR_NOT_FOUND, NOTIFIKASI_NOT_FOUND, WALI_NOT_ACTIVE, 503 gateway |
| 5 | Error validasi 422 + fieldErrors | `absensi harian 422`, `periode 422` |
| 6 | Pagination/meta | absensi harian (page 2), periode, notifikasi list (meta total/hasMore) |
| 7 | Wali dengan satu anak | fixture harness (2 anak; default pemilihan) |
| 8 | Wali dengan banyak anak | `anakAktif default/dia/verified dihormati` |
| 9 | Wali tanpa anak terverifikasi | `tanpa anak verified → null` + widget test tab Keuangan empty-state |
| 10 | Perpindahan konteks A → B | `family provider: jadwal A/B terisolasi`, `absensi family A/B terpisah` |
| 11 | Cache tidak mencampur antar-anak | idem + family autoDispose |
| 12 | Tidak ada data anak lain saat konteks berganti | idem (path + data diassert) |
| 13 | Response akses ditolak (403/422 dari backend) | `AKSES_DITOLAK` harian+nilai |
| 14–19 | Profil, jadwal, absensi (3 tab), nilai (kelompok+filter 404), rapor (daftar+detail), loading/empty/error/retry/refresh | `wali_repository_test.dart`, widget coverage (Keuangan/Anak/Detail pending) |
| 20–23 | Notifikasi list/detail/unread/mark-read/read-all + badge refresh | `wali_repository_test.dart` (list/detail/read/read-all/unread), badge di shell via `wali_unread_count` |
| 24–29 | Keuangan: ringkasan/tagihan/saldo/pembayaran/detail + dokumen privat + attempt | `wali_keuangan_repository_test.dart` (siswa_id terkirim, 403 relasi pending, dokumen 403/404, filename dari content-disposition, bytes) |
| 30–35 | Routing: wali buka `/wali/*` ✓, siswa/guru ditolak ✓ (semua nested), wali ditolak di `/siswa/*` `/guru/*` ✓, nested terlindungi ✓, tidak ada regresi auth/siswa/guru ✓ (298 lulus) | `wali_routing_test.dart` (21 kasus), full suite |
| 36 | Regression check | 298/298 pass |

Batas pengujian: **semua melalui FakeHttpClientAdapter/mock** — bukan live
backend; konkurensi TIDAK diuji (tidak ada backend staging yang dipanggil).

## 10. Hasil analyze / format / build

- `dart format .` → `Formatted 144 files (25 changed)` (perubahan hanya file
  fase-5 + file yang memang disentuh).
- `flutter analyze` → **No issues found!**
- `flutter test` → **298 passed**
- `flutter build apk --debug` → **sukses** (`app-debug.apk`; ±135 detik;
  exit code PowerShell 1 hanya karena warning Gradle di stderr).

## 11. Temuan / keterbatasan backend

1. **Pengumuman wali tidak tersedia** — modul pengumuman siswa-scoped;
   guru pun tidak mendapatkannya. Tidak diimplementasikan (bukan bug).
2. **`/wali/anak/{siswaId}/permintaan-putus` (W5) ada** tetapi di luar scope
   Phase 5 → tidak diimplementasikan.
3. Ekspor CSV/PDF rekap/rapor wali — tidak tersedia via API mobile (web saja);
   tidak diimplementasikan.
4. Keuangan: `tanggal_berhenti` untuk relasi **terminated hari ini** masih
   dianggap berlaku (`tanggal_berhenti >= hari ini`) oleh
   `relasiWaliAktifSiswa()` — perilaku backend dipertahankan apa adanya.
5. Kebijakan akademik mewajibkan `tanggal_mulai <=` hari ini; relasi yang
   masa berlakunya sudah lewat dianggap tidak valid oleh backend — Flutter
   tidak menggandakan logika.
6. `/keuangan/*` untuk wali mewajibkan `siswa_id`; tanpa itu 403 — Flutter
   selalu menyertakannya (query/body), termasuk pada polling attempt status.
7. Notifikasi wali: belum ada deep link internal untuk target selain daftar —
   `NotifikasiItem.link` hanya path backend; hanya ditampilkan, tidak
   dipakai untuk navigasi internal.
8. Keuangan Midtrans E2E tidak diuji live (butuh Midtrans sandbox aktif);
   hanya kontrak JSON + error 503 yang dites via mock.
9. `waliProfil`/`waliBeranda` tidak memiliki data akademik anak — anak yang
   pending tidak dapat data (by design backend).

## 12. Fitur API yang belum dapat diintegrasikan & alasannya

| Fitur | Alasan |
|---|---|
| Pengumuman wali | Tidak tersedia di backend (modul siswa-scoped) |
| Permintaan putus relasi (W5) | Di luar scope Phase 5 (spec §2 A–I) |
| Ekspor CSV/PDF rekap/rapor | Tidak tersedia via API mobile |
| Live smoke test backend | Tidak ada lingkungan backend yang dipanggil; semua test via mock |
| Settlement/payment E2E (Midtrans) | Membutuhkan gateway sandbox live; di luar kemampuan test ini |

## 13. Konfirmasi backend & database tidak berubah

- Backend Laravel **tidak diubah sama sekali** — tidak ada file di
  `C:\project-reyhan\template web` yang disentuh; tidak ada perubahan
  schema/migration/seeder/trigger/index; tidak ada endpoint baru; kebijakan
  relasi wali↔anak tidak diubah.
- `AGENTS.md` backend dibaca dan dipatuhi (termasuk larangan membaca/
  menulis `.env` — tidak ada akses `.env` sama sekali; tidak ada perintah
  `migrate:*`/`route:list` yang menulis; `php artisan` tidak dijalankan).
- **Tidak ada perintah Git write dijalankan** (tidak ada commit/push/stash/
  reset/checkout/clean). Hanya `git status --short`/`git diff --stat`
  (read-only).

## 14. Git status & ringkasan perubahan

`git status --short` (read-only):

```
 M docs/FLUTTER_ARCHITECTURE.md
 M lib/app/router/app_router.dart
 M lib/app/router/app_routes.dart
 D lib/features/wali/presentation/wali_home_page.dart
 M test/fakes/harness.dart
 M test/fakes/path_adapter.dart
?? lib/features/wali/application/
?? lib/features/wali/data/
?? lib/features/wali/presentation/akademik/
?? lib/features/wali/presentation/anak/
?? lib/features/wali/presentation/beranda/
?? lib/features/wali/presentation/keuangan/
?? lib/features/wali/presentation/notifikasi/
?? lib/features/wali/presentation/profil/
?? lib/features/wali/presentation/wali_shell.dart
?? lib/features/wali/presentation/widgets/
?? test/features/wali/
```

`git diff --stat`: 6 file dimodifikasi, 464 insertions(+), 20 deletions(-) —
terdiri dari 11 route wali (`/wali/*` nested dengan parameter id tervalidasi),
konstanta route, section 14 di `docs/FLUTTER_ARCHITECTURE.md`, fixture wali di
`test/fakes/harness.dart` dan fallback `/wali/*` di `test/fakes/path_adapter.dart`.
Seluruh file fitur wali baru (27 file) + 5 file test wali baru (untracked).

**Ringkasan:** Phase 5 dinyatakan **PASS WITH LIMITATIONS** — seluruh fitur
wali yang didukung API terintegrasi & read-only; isolasi konteks/cache
antar-anak terikat family provider keyed by `siswaId`; role guard aman
(nested terproteksi); tidak ada data dummy; 298/298 automated tests lulus;
analyze bersih; APK debug ter-build. Keterbatasan: pengumuman wali tidak
tersedia (API), permintaan-putus tidak diimplementasikan (scope), live
backend & Midtrans E2E belum diverifikasi (hanya mock).
