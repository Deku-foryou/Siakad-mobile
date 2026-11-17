# LAPORAN — Flutter Phase 4: Teacher Features (Modul Guru)

**Tanggal:** 17 November 2026 · **Status:** **PASS WITH LIMITATIONS** (iOS & live-backend UAT belum diuji; Manual UAT fisik di luar scope tahap ini)
**Scope:** Seluruh fitur role `guru` terhubung ke Laravel REST API `/api/v1/guru/*`. Siswa/wali/autentikasi tidak diubah (tanpa regresi).

---

## 1. Status akhir

**PASS WITH LIMITATIONS** — seluruh fitur guru yang didukung API telah terimplementasi
dan teruji (mock). Tidak diuji live ke backend produksi; Manual UAT perangkat
fisik dilakukan terpisah oleh pengguna. iOS diblokir environment (Windows).

## 2. Fitur yang berhasil diimplementasikan

| Area | Fitur | Status |
|---|---|---|
| A | Dashboard guru — identitas (nama/NIP/kode guru), konteks TA/semester (+peringatan), kelas (mengajar ∪ wali), ringkasan (jumlah_kelas, jumlah_penugasan, pertemuan_hari_ini, absensi_perjam/harian_hari_ini), jadwal hari ini, unread badge notifikasi, quick actions, pull-to-refresh, error/empty state | ✅ |
| B | Profil guru — read-only (NIP, kode guru, nama, JK, TTL, telp, alamat, mapel, status) + info sesi (perangkat, masa berlaku token) + logout perangkat ini / semua perangkat | ✅ |
| C | Kelas & Siswa — daftar kelas (filter Semua/Mengajar/Wali, jumlah siswa, mapel chips, badge sumber), detail kelas (TA, jurusan, tingkat, wali, mapel, penugasan di kelas), daftar siswa aktif (nis/nisn/JK), tombol "Isi Absensi Harian" (khusus mengajar) | ✅ |
| D | Penugasan Mengajar — daftar (search mapel/kelas, TA), konteks otorisasi untuk Penilaian | ✅ |
| E | Jadwal Mengajar — filter hari (Semua/Sen..Min) + date picker + tombol "Hari Ini" (backend: tanggal > hari), daftar kanonis (jam ke, mulai–selesai, mapel, kelas, semester), detail jadwal | ✅ |
| F | Absensi Harian — riwayat (paginated, filter status), detail record, form grid pengisian (status chips hadir/sakit/izin/alpha per siswa + catatan, aksi "Semua Hadir"), simpan batch upsert; ubah record H+1 (PATCH) | ✅ |
| G | Absensi Per Jam — SegmentedButton Pertemuan/Riwayat; pertemuan per tanggal (default hari ini; **dipanggil hanya pada tab ini** — snapshot generation didokumentasikan), grid pertemuan (bisa_absen per pertemuan), simpan batch; riwayat (paginated, filter status); detail record; edit H+1 (PATCH) | ✅ |
| H | Penilaian — daftar penugasan (search), detail (komponen & bobot, total bobot aktif, badge `konfigurasi_valid=false`/`terkunci`), rekap siswa (terisi, draft, lengkap), form input nilai per komponen (keyboard numerik, validasi 0–100, disabled-mode terkunci/invalid), simpan batch (PUT) | ✅ |
| I | Notifikasi — list (filter Semua/Belum Dibaca/Dibaca, paginated), unread count badge (Beranda + shell), detail (tidak auto-mark; tombol "Tandai Dibaca"), "Tandai Semua Dibaca" (dialog konfirmasi, invalidate badge/list/detail) | ✅ |

## 3. Endpoint yang digunakan (persis dari kode backend)

| # | Endpoint | Penggunaan |
|---|---|---|
| G1 | `GET /guru/profil` | Tab Profil |
| G2 | `GET /guru/beranda` | Tab Beranda |
| G3 | `GET /guru/kelas` | Tab Kelas (list) |
| G4 | `GET /guru/kelas/{id}` | Detail kelas |
| G5 | `GET /guru/kelas/{id}/siswa` | Daftar siswa |
| G6 | `GET /guru/penugasan` | Tab Penilaian (list) + detail kelas |
| G7 | `GET /guru/jadwal?tanggal\|hari` | `/guru/jadwal` |
| G8 | `GET /guru/jadwal/hari-ini` | repository support |
| G9 | `GET /guru/jadwal/{id}` | Detail jadwal |
| G11 | `GET /guru/absensi/harian` | Riwayat |
| G12 | `GET /guru/absensi/harian/{id}` | Detail record |
| G13 | `POST /guru/absensi/harian` | Grid harian (upsert per siswa) |
| G14 | `PATCH /guru/absensi/harian/{id}` | Edit record |
| G15 | `GET /guru/kelas/{kelasId}/absensi` | Grid pengisian harian |
| G16 | `GET /guru/absensi/perjam` | Riwayat per jam |
| G17 | `GET /guru/absensi/perjam/pertemuan` | Tab Per Jam (side-effect snapshot — terdokumentasi) |
| G18 | `GET /guru/absensi/perjam/pertemuan/{id}` | Grid pertemuan |
| G19 | `POST /guru/absensi/perjam` | Simpan grid pertemuan |
| G20 | `GET /guru/absensi/perjam/{id}` | Detail record |
| G21 | `PATCH /guru/absensi/perjam/{id}` | Edit record |
| G22 | `GET /guru/penilaian/penugasan/{id}` | Detail penugasan |
| G23 | `GET /guru/penilaian/penugasan/{id}/siswa` | Rekap siswa |
| G24 | `PUT /guru/penilaian/penugasan/{id}/nilai` | Simpan nilai batch |
| G25 | `PATCH /guru/penilaian/penugasan/{id}/nilai` | Simpan satu nilai (repository) |
| G26 | `GET /guru/notifikasi` | List notifikasi |
| G27 | `GET /guru/notifikasi/unread-count` | Badge |
| G28 | `GET /guru/notifikasi/{id}` | Detail |
| G29 | `PATCH /guru/notifikasi/{id}/read` | Tandai dibaca |
| G30 | `PATCH /guru/notifikasi/read-all` | Tandai semua dibaca |

Tidak digunakan (tidak ada di scope spek): G10 (rekap-kelas) — tersedia, tidak diperlukan; G8 (hari-ini) — terdaftar di repository; G25 — terdaftar di repository (PATCH satu nilai), UI memakai PUT batch.

**Catatan kritis:** tidak ada `guru_id`/`user_id` yang dikirim client (diverifikasi test). Identitas selalu dari token — backend menegakkan otorisasi per request (anti-IDOR).

## 4. Daftar file dibuat / diubah

**Dibuat (lib/ — 44 file baru):**

```
lib/features/guru/data/models/guru.dart          (GuruProfil, GuruBeranda, KelasRingkas, JadwalGuruItem, ...)
lib/features/guru/data/models/absensi.dart       (GuruAbsensiHarianItem, PerjamItem, AbsensiHarianGrid, PertemuanItem, ...)
lib/features/guru/data/models/penilaian.dart     (KomponenNilai, PenugasanDetail, SiswaPenilaian, ...)
lib/features/guru/data/guru_repository.dart      (22 endpoint + mutasi; AbsensiRecordInput/AbsensiPerjamRecordInput)
lib/features/guru/application/guru_providers.dart
lib/features/guru/application/guru_tab_index.dart
lib/features/guru/presentation/guru_shell.dart
lib/features/guru/presentation/beranda/guru_dashboard_page.dart
lib/features/guru/presentation/kelas/{guru_kelas_page,guru_kelas_detail_page,guru_siswa_page}.dart
lib/features/guru/presentation/jadwal/{guru_jadwal_page,guru_jadwal_detail_page}.dart
lib/features/guru/presentation/absensi/guru_absensi_page.dart
lib/features/guru/presentation/absensi/harian/{guru_absensi_harian_tab,guru_harian_detail_page,
                                               guru_harian_edit_page,guru_harian_grid_page}.dart
lib/features/guru/presentation/absensi/perjam/{guru_absensi_perjam_tab,guru_perjam_grid_page,
                                               guru_perjam_detail_page,guru_perjam_edit_page}.dart
lib/features/guru/presentation/penilaian/{guru_penilaian_page,guru_penilaian_detail_page,
                                          guru_nilai_input_page}.dart
lib/features/guru/presentation/notifikasi/{guru_notifikasi_page,guru_notifikasi_detail_page}.dart
lib/features/guru/presentation/profil/guru_profil_page.dart
```

**Dipindahkan ke shared (reuse siswa + guru):** `shared/data/paged_state.dart`,
`shared/application/paged_notifier.dart`, `shared/models/page_meta.dart`,
`shared/models/notifikasi.dart`.

**Diubah:** `lib/app/router/app_router.dart` (routes guru), `lib/app/router/app_routes.dart` (konstanta prefix guru), `test/fakes/path_adapter.dart` (method-prefixed override keys), `test/fakes/harness.dart` (+11 guru mock bodies), `test/app/router/redirect_test.dart` (+5 prefix-guard tests), `docs/FLUTTER_ARCHITECTURE.md` (§13 Guru Module, tree, route list), `test/features/auth/auth_flow_widget_test.dart` & siswa tests (import path notif/meta, notifikasi mock, pump behavior — semua hijau), `lib/features/guru/presentation/absensi/harian/guru_harian_grid_page.dart` (Baris info Grid diubah ke `Wrap` — lihat Temuan #7).

**Dihapus:** `lib/features/guru/presentation/guru_home_page.dart` (placeholder).

**Test baru:** `test/features/guru/guru_repository_test.dart` (26), `test/features/guru/guru_widget_test.dart` (5), +5 redirect prefix-guard tests.

**Tidak ada dependency baru** (Phase 4).

## 5. Ringkasan arsitektur

Feature-first; `core/` (Dio terpusat, error mapper, secure storage), `features/<role>/{data,application,presentation}`, `shared/` (paged infra, models, formatters, widgets). Guru mengikuti pola Phase 3:

- One-shot data → `FutureProvider.autoDispose(.family)`
- List ter-paginasi → `NotifierProvider.autoDispose` + shared `PagedNotifier<T>`
- Grid absensi/nilai → `ConsumerStatefulWidget` + repository langsung (state form lokal)
- Bottom nav 5 tab + `IndexedStack` (state preserved), route guard prefix `/guru/*` (siswa area tidak bisa diakses role lain)

## 6. Hasil testing

```
dart format .   ✓ (114 file)
flutter analyze ✓ No issues found!
flutter test    ✓ All tests passed! (185/185)
```

| File | Jumlah |
|---|---|
| test/widget_test.dart | 1 |
| test/app/router/redirect_test.dart | 22 |
| test/core/config/app_config_test.dart | 5 |
| test/core/errors/error_mapper_test.dart | 19 |
| test/core/network/auth_interceptor_test.dart | 4 |
| test/core/storage/secure_storage_service_test.dart | 4 |
| test/features/auth/auth_controller_test.dart | 24 |
| test/features/auth/auth_flow_widget_test.dart | 12 |
| test/features/auth/auth_repository_test.dart | 14 |
| **test/features/guru/guru_repository_test.dart** | **26** |
| **test/features/guru/guru_widget_test.dart** | **5** |
| test/features/siswa/siswa_repository_test.dart | 24 |
| test/features/siswa/keuangan_repository_test.dart | 14 |
| test/features/siswa/siswa_pages_widget_test.dart | 11 |
| **Total** | **185** |

Test meliputi: repository (parsing response aktual dari kode backend — payload attempt minimal, PATCH/PUT payloads, filter params, GURU_NOT_LINKED), widget (dashboard render, navigasi badge notifikasi, alur grid harian end-to-end, alur input nilai end-to-end), route guard sub-route (prefix), regresi auth (100+ test Phase 2/3).

## 7. Analyze, format, build

- `flutter analyze`: **No issues found!**
- `dart format .`: 114 file, bersih.
- `flutter build apk --debug`: ✅ `app-debug.apk` (245 MB). Warning gradle "Restricted methods will be blocked" bersifat informasional; tidak mempengaruhi build.

## 8. Batasan belum terselesaikan

1. **iOS: BLOCKED** (Windows) — butuh macOS + Xcode. Tidak ada klaim iOS build.
2. **Live backend: belum diuji** — seluruh integrasi diverifikasi via mock HTTP yang mereproduksi envelope persis (kode backend). Manual UAT di HP Android fisik oleh pengguna terpisah.
3. **Midtrans / UAT gateway: tidak termasuk scope Phase 4** (Phase 3 mencatat BLOCKED).
4. **G10 (rekap-kelas) & G25 (PATCH single nilai) terdaftar di repository** tetapi tidak memiliki UI khusus — dapat ditambahkan bila diperlukan tanpa perubahan arsitektur.
5. **Data stale setelah mark-read di tab notifikasi lain**: invalidate mencakup badge + list + detail; angka tab bisa tertinggal 1 frame (dapat di-refresh dengan pull-to-refresh).

## 9. Risiko dan temuan backend (didokumentasikan, BUKAN diperbaiki)

1. **`GET /guru/absensi/perjam/pertemuan` memicu `generateUntukTanggal()`** — menulis snapshot pertemuan baru (idempoten). Flutter memanggilnya hanya pada tab Per Jam, tidak di dashboard/prefetch.
2. **Kebijakan H+1** untuk edit absensi ditegakkan backend (DomainException → 422 GAGAL_UBAH/GAGAL_SIMPAN). Flutter tidak menebak; menampilkan pesan backend.
3. **Harian anti-mass**: POST harian konteks TA/semester dari server; 422 KONTEKS_TIDAK_VALID bila belum valid.
4. **Grid hanya kelas `diajar`** untuk pengisian; `wali` tidak bisa diabsen — Flutter menonaktifkan tombol isi untuk wali-only (defensa UI; backend tetap otoritatif).
5. **`konfigurasi_valid=false` / `terkunci=true`** (total bobot aktif ≠ 100 atau rapor difinalisasi) → input nilai dinonaktifkan; backend juga menolak (422). Pesan jelas ke pengguna.
6. **API jadwal**: `tanggal` menang atas `hari` bila keduanya diisi (backend); UI memilih salah satunya (chip hari me-reset tanggal dan sebaliknya).
7. **Temuan layout (diperbaiki)**: nilai header Grid memakai `Row`+`Spacer`; layout test menunjukkan `BoxConstraints infinite width` di jalur tertentu → diganti `Wrap` (perilaku identik, constraints aman). Ini perubahan UI, bukan perubahan kebijakan.
8. **Tidak ada endpoint export nilai/rapor guru** — tidak diimplementasikan (by design).
9. **`persen_hadir`** = string format lokal (mis. "90,0%") — dirender apa adanya.

## 10. Konfirmasi backend dan database tidak berubah

Tidak ada file Laravel yang dibaca-dengan-menulis. Tidak ada migration/schema/config/`.env` yang diubah. Kontrak API tidak dibuat ulang — Flutter hanya mengkonsumsi apa adanya.

## 11. Konfirmasi Git

Tidak ada perintah Git write apa pun yang dijalankan (tidak ada `add/commit/push/reset/checkout/stash/init`). Repository Flutter sudah ada (2 commit sebelum Phase 4, dibuat pengguna). Phase 4 dikerjakan seluruhnya di working tree; pengguna membuat checkpoint commit sendiri (disarankan: `feat(flutter): implement teacher mobile features`).

## 12. Status Git (setelah Phase 4)

```
 M lib/app/router/app_router.dart
 M lib/app/router/app_routes.dart
 D lib/features/guru/presentation/guru_home_page.dart
 M lib/features/siswa/application/{absensi_notifiers.dart,siswa_providers.dart}
 D lib/features/siswa/application/paged_notifier.dart
 M lib/features/siswa/data/{keuangan_repository.dart,siswa_repository.dart}
 M lib/features/siswa/data/models/absensi.dart
 D lib/features/siswa/data/models/{notifikasi.dart,page_meta.dart}
 D lib/features/siswa/data/paged_state.dart
 M lib/features/siswa/presentation/notifikasi/siswa_notifikasi_page.dart
 M test/app/router/redirect_test.dart
 M test/fakes/{harness.dart,path_adapter.dart}
 M test/features/auth/auth_flow_widget_test.dart
?? lib/features/guru/application/ data/ presentation/ (44 file)
?? lib/shared/application/ data/ models/
?? test/features/guru/
```

Backend Laravel tidak muncul di `git status` (direktori terpisah, tidak disentuh).
