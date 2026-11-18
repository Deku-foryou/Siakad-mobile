# LAPORAN FLUTTER PHASE 6 — INTEGRATION, UI/UX POLISH & CROSS-ROLE CONSISTENCY

**Tanggal:** 2026-11-17 · **Status:** **PASS WITH LIMITATIONS**

Phase 6 (audit, integrasi, penyempurnaan UI/UX, hardening regresi) selesai.
Tidak ada fitur business baru; tidak ada perubahan backend/database/kebijakan.
Manual UAT fisik **belum dilakukan** — pengguna melakukannya terpisah
(checklist disediakan, lihat §15).

---

## 1. Temuan audit awal (diklasifikasikan)

**Critical** — tidak ditemukan. Tidak ada bug keamanan fungsional; token tidak
pernah di-log; route guard aman; konteks wali↔anak terisolasi (Phase 5).

**High**

1. **401 mid-session tidak menutup sesi** — `AuthInterceptor` membersihkan
   token lokal saat server menjawab 401, tetapi `AuthState` tidak berubah;
   pengguna melihat error per halaman sampai app dibuka ulang. Router tidak
   diarahkan ke login.
2. **State non-autoDispose bocor antar akun** — `selectedAnakIdProvider`
   (wali) dan tab index 3 role ditulis di atas provider non-autoDispose dan
   tidak di-reset saat logout; data konteks akun lama bisa terbawa ke akun
   berikutnya pada perangkat yang sama.

**Medium**

3. Duplikasi `_ErrorBlock` (5 salinan identik) di siswa/guru/wali — melanggar
   konsistensi visual & memelihara noise.
4. Duplikasi `_initials` (13 salinan identik) untuk avatar inisial.
5. Warna semantik (success/warning/error/info) di-hardcode hex di 8+ file
   alih-alih referensi tunggal `AppColors`.
6. Wali sub-route (jadwal/absensi/nilai/rapor/keuangan-detail) tidak
   menampilkan identitas anak terpilih — membuka peluang salah membaca
   konteks anak (dan bertentangan dengan spec integrasi Fase 6).
7. `RolePlaceholderPage` unused (sisa Foundation) — dead code.
8. Kontras `StatusBadge.forStatus` OK tetapi sumber warna tidak terpusat.

**Low**

9. Beberapa IconButton tanpa `tooltip` (3 password toggle di change-password,
   dismiss banner login, error switcher wali).
10. Horizontal FilterChip rows setinggi 46 (<48dp target sentuh) — 8 tempat.
11. Tidak ada widget test responsiveness / dark mode / text scaling.
12. Guru sengaja men-embed notifikasi di ikon AppBar Beranda (bukan bottom
    nav badge seperti siswa/wali) — perbedaan pola, bukan bug (dipertahankan
    by design).

## 2. Daftar prioritas perbaikan

| Prioritas | Item | Status |
|---|---|---|
| High | 401 mid-session → sesi ditutup & diarahkan login (§3 + test `session_expiry_test.dart`) | ✅ |
| High | Reset state non-autoDispose saat sesi berakhir (§3 + `account_session_reset.dart` + test) | ✅ |
| Medium | Konsolidasi `_ErrorBlock` → `AppErrorRetry` (core) — 5 salinan dihapus | ✅ |
| Medium | Konsolidasi `_initials` → `Formatters.initials` — 13 salinan dihapus | ✅ |
| Medium | `AppColors` semantik dipakai di semua kode status (8 file diubah) | ✅ |
| Medium | `AnakAppBarTitle` — identitas anak (nama · kelas) di AppBar 9 halaman wali | ✅ |
| Medium | Hapus dead code (`role_placeholder_page.dart`) | ✅ |
| Low | Tooltips tombol ikon; touch target 48dp; test dark/responsive/textScale | ✅ |
| Docs | Checklist UAT Android; laporan; update arsitektur | ✅ |

## 3. Perubahan design system

- **Color**: `AppColors.success/warning/error/info` sebagai satu-satunya
  sumber warna semantik (nilai hex tidak berubah — branding teal 0xFF0F766E /
  seedDark 0xFF2DD4BF dipertahankan). `StatusBadge.forStatus` kini merujuk
  `AppColors`; hex inline di 8 file dihapus.
- **Typography**: `_textTheme` tidak diubah; konsistensi diverifikasi via
  widget test (`app_theme_test.dart`: brightness, useMaterial3, text colors).
- **Spacing**: teks teks 48dp; `AppSpacing.radius = 12` dipertahankan;
  filtered chip rows dinaikkan 46 → 48.
- **Komponen reusable** (`core/widgets/app_widgets.dart`):
  `AsyncValueView` (loading/empty/error/retry) — dipertahankan;
  **baru** `AppErrorRetry` (inline error+retry terpusat) menggantikan
  5 salinan `_ErrorBlock`; `AppEmptyView`/`AppErrorView`/`AppLoading`/
  `SectionHeader`/`MenuCard`/`SkeletonBox` dipertahankan.
- **Formatters.initials** — inisial nama dipusatkan di `Formatters` (core).
- **Theme**: Material 3, light & dark (`AppTheme.light/.dark`), themeMode
  `system`; kontras teks divalidasi (rasio ≥ 4.5 terukur via luminance).

## 4. Perubahan navigation

- Tidak ada perubahan route/struktur GoRouter (11 route wali dari Fase 5
  dipertahankan). Guard role tidak diubah.
- **Baru**: sesi yang kedaluwarsa/dicabut di TENGAH pemakaian kini menutup
  sesi bersih & diarahkan ke `/login` (lihat §6.1).
- Setelah logout/forced-expiry, state lintas-fitur di-reset (lihat §6.1) —
  pergantian akun di perangkat sama tidak membawa konteks lama.
- Tab index siswa/guru/wali + pilihan anak wali di-reset; provider data
  autoDispose dibuang otomatis saat shell lama dilepas.
- Back navigation & redirect loop dicegah (ada 21 routing test Fase 5; tidak
  ada regresi).

## 5. Perbaikan UX state

- **Loading/empty/error/retry**: pola seragam melalui `AsyncValueView` +
  `AppErrorRetry` (satu desain: ikon `cloud_off`, pesan Indonesia, FilledButton
  "Coba Lagi"); error API tetap dipetakan dari backend (tidak mengubah arti
  error 401/403/404/422/429/5xx; 422 membawa fieldErrors).
- **Empty vs error** sudah dibedakan di seluruh list (siswa/guru/wali);
  tidak ada data dummy.
- **Refresh**: pull-to-refresh sudah ada; konteks filter tetap terjaga
  (contoh: wali absensi periode/dari–sampai & status; tagihan status;
  notifikasi filter) karena filter disimpan di notifier, bukan di state hasil.
- **Anti double-submit**: tombol Bayar/simpan/absensi/nilai terkunci saat
  memproses; aksi konfirmasi pakai dialog (nilai, pembayaran, logout).
- **Form**: scrollview `SingleChildScrollView` untuk keyboard; toggle
  password ber-tooltip; login/change password `TextInputAction` benar;
  422 menampilkan error per field.
- **Anak terpilih selalu terlihat** di halaman akademik & finansial wali
  (AppBar dua baris: judul + `Nama · Kelas`).

## 6. Temuan cache & sesi (ditambah perbaikan)

### 6.1 Sesi & pergantian akun

- **401 mid-session (HIGH, diperbaiki)** — `AuthInterceptor` sekarang memanggil
  `SessionExpiry.notify()` setelah membersihkan token lokal; `AuthController`
  subscribe ke broadcast stream (`session_expiry.dart`) dan memanggil
  `_handleSessionExpired()`: state → `unauthenticated` + notice
  "Sesi Anda telah berakhir. Silakan login kembali." GoRouter refresh
  redirect ke `/login`. Tidak mengubah kebijakan token/backend; tidak
  menimpa notice yang lebih spesifik dari alur logout (urutan: interceptor →
  controller; notice logout ditulis terakhir oleh `_logoutInternal` sehingga
  tetap menang saat 401 pada logout).
- **Reset lintas-fitur (HIGH, diperbaiki)** —
  `accountSessionResetProvider` (shared/application) mendengarkan transisi
  ke `unauthenticated` lalu menginvalidasi `selectedAnakIdProvider`,
  `siswaTabIndexProvider`, `guruTabIndexProvider`, `waliTabIndexProvider`.
  Di-watch di root `SiakadApp`. Data autoDispose (beranda/profil/list) otomatis
  dibuang saat layar lama terlepas.
- Logout perangkat ini / logout semua tetap bekerja (mock-tested); forced
  change password tidak bisa dilewati (tidak diubah); error jaringan TIDAK
  menghapus sesi valid (Foundation dipertahankan).
- Token/dokumen tidak pernah di-log (LoggingInterceptor hanya path/status).

### 6.2 Cache & isolasi

- Isolasi cache antar-anak (family provider keyed by `siswaId`) tetap utuh —
  diuji pembanding A/B + perpindahan konteks (Fase 5, tidak regresi).
- Tidak ada data role lama setelah pergantian akun (fix 6.1) — diuji
  (`account_session_reset_test.dart`).
- Invalidation setelah mutasi: notifikasi badge di-refresh setelah
  mark-read/read-all; tagihan/detail di-invalidate setelah attempt dibuat;
  beranda di-invalidate saat refresh manual.
- Cache antara role tidak pernah bercampur (prefix guard + provider terpisah
  per fitur).

## 7. Optimasi performance

- Widget tree: `AppErrorRetry` terpusat mengurangi kelas widget; const
  dipakai luas (banyak subclass const); tidak ada animasi baru.
- Provider: seluruh provider data `autoDispose` — tidak ada retensi
  lintas halaman; tidak ada prefetch anak non-terpilih; tidak ada
  `keepAlive` baru.
- `IndexedStack` (shell) dipertahankan (trade-off sadar: state tab terjaga
  vs memori minimal — layak untuk 5 tab).
- Tidak ada dependency baru; tidak ada micro-optimization tanpa bukti;
  tidak ada gambar aset besar (semua ikon Material).
- Startup: sesi hanya diverifikasi ke `GET /auth/me` sekali di splash.

## 8. File yang diubah/dibuat

**Baru (9):** `lib/core/network/session_expiry.dart`,
`lib/shared/application/account_session_reset.dart`,
`test/app/account_session_reset_test.dart`,
`test/app/responsive_dark_test.dart`,
`test/app/theme/app_theme_test.dart`,
`test/core/widgets/app_widgets_test.dart`,
`test/features/auth/session_expiry_test.dart`,
`CHECKLIST_UAT_ANDROID_PHASE_6.md`,
`LAPORAN_FLUTTER_PHASE_6_INTEGRATION_UI_UX.md`.

**Dimodifikasi (±38):** `lib/app/app.dart` (watch reset provider),
`lib/core/network/auth_interceptor.dart` (signal 401), `lib/core/utils/
formatters.dart` (+`initials`), `lib/core/widgets/app_widgets.dart`
(+`AppErrorRetry`, AppColors semantic), `lib/features/auth/application/
auth_controller.dart` (listener 401 mid-session), `change_password_page.dart`
(+tooltip), `login_page.dart` (+tooltip), 5× hapus `_ErrorBlock` (diganti
`AppErrorRetry`), 13× hapus `_initials` (diganti `Formatters.initials`),
8× hex semantik → `AppColors`, 8× tinggi chip rows 46→48,
9× AppBar wali → `AnakAppBarTitle` (baru, di `child_switcher.dart`),
`guru_kelas_page.dart` (48dp), `role_placeholder_page.dart` **dihapus**,
`docs/FLUTTER_ARCHITECTURE.md` (+§15), `test` fakes tidak berubah.

Tidak ada perubahan pada Foundation/session restore logic (mekanisme
autentikasi tidak diubah), tidak ada perubahan backend.

## 9. Hasil test & assertion

`flutter test` — **seluruh 329 test lulus** (sebelumnya 298; +31 test Phase
6). `flutter analyze` — **No issues found**. `dart format .` — 150 file
(28 diubah). `flutter build apk --debug` — **sukses**
(`app-debug.apk`, Gradle 103.3s).

Test Phase 6 baru:
- `app_theme_test.dart` (13) — Material 3, light/dark scheme & brightness,
  tombol ≥48, input radius, card radius/elevation, warna teks vs background
  (rasio ≥ 4.5), `AppColors` semantik.
- `app_widgets_test.dart` (10) — AsyncValueView loading/empty/error/retry,
  AppErrorRetry (+aksi), StatusBadge label/warna, Formatters.initials.
- `session_expiry_test.dart` (2) — **401 mid-session**: login → 401 →
  sesi tertutup + notice; logout membersihkan token.
- `account_session_reset_test.dart` (1) — login wali (pilih tab 3, anak 201)
  → logout → semua state non-autoDispose kembali default/null.
- `responsive_dark_test.dart` (7) — layar 320×568 & 900×1200, textScale
  1.5x & 2.0x, dark & light mode (no exception), semantics bottom nav.
- Tema/shared/responsive test tidak menghapus/mengubah test lama.

Batas pengujian: seluruh test memakai mock `FakeHttpClientAdapter` — **BUKAN** live backend; tidak ada klaim integration/live test; perilaku backend tidak diverifikasi terhadap server sungguhan di sesi ini.

## 10. Hasil analyze / format / build

- `dart format .` → `Formatted 150 files (28 changed)`
- `flutter analyze` → **No issues found**
- `flutter test` → **+329 All tests passed**
- `flutter build apk --debug` → **sukses** (hanya peringatan Gradle
  `java.lang.System::load` standar)

## 11. Batasan yang tersisa

1. **Manual UAT fisik belum dilakukan** (checklist tersedia, §15).
2. **401 mid-session**: sesi ditutup — namun kebijakan "token expired 401 =
   sesi berakhir" tetap milik Foundation; skenario gateway/downtime yang
   menjawab 401 palsu tidak dibedakan (by design).
3. **Dark theme** diverifikasi hanya via widget test (bukan inspeksi visual
   di perangkat — perlu UAT).
4. **Guru** sengaja tidak memakai bottom nav badge (notifikasi via ikon
   AppBar Beranda) — konsisten di dalam guru; tidak disamakan siswa/wali.
5. Pengumuman wali tetap **tidak tersedia** (backend).
6. Layout 320×568 lulus test otomatis, TAPI verifikasi visual perangkat kecil
   menunggu UAT.
7. Live backend & Midtrans E2E belum diverifikasi di sesi ini.

## 12. Ringkasan file (stat)

`git diff --stat`: 38 file, **+313 / −578** (net removal — konsolidasi).

## 13. Checklist UAT Android

Dokumen terpisah: `CHECKLIST_UAT_ANDROID_PHASE_6.md` — 12 bagian (login siswa,
navigasi fitur siswa, login + alur guru, wali + perpindahan anak,
akademik/keuangan anak, notifikasi, logout & pergantian akun, koneksi
terputus, light/dark, keyboard & ukuran layar). **Manual UAT belum dilakukan**;
tidak ada klaim hasil UAT.

## 14. Konfirmasi backend/database & perintah Git

- **Backend Laravel TIDAK diubah** — tidak ada file di
  `C:\project-reyhan\template web` yang disentuh; tidak ada perubahan
  schema/migration/seeder/trigger/index; tidak ada endpoint baru; tidak ada
  perubahan kebijakan akademik/absensi/penilaian/keuangan/pembayaran/relasi.
- `AGENTS.md` backend dibaca & dipatuhi; **`.env` tidak diakses**;
  `php artisan` tidak dijalankan.
- **Tidak ada perintah Git write** — hanya `git status --short` /
  `git diff --stat` (read-only). Tidak ada commit/push/reset/stash.

## 15. Git status (read-only) & ringkasan

```
 M docs/FLUTTER_ARCHITECTURE.md        M lib/features/siswa/... (±5)
 M lib/app/app.dart                    M lib/features/wali/... (±20)
 M lib/core/network/auth_interceptor.dart
 M lib/core/utils/formatters.dart      D lib/shared/widgets/role_placeholder_page.dart
 M lib/core/widgets/app_widgets.dart
 M lib/features/auth/... (3 file)      ?? CHECKLIST_UAT_ANDROID_PHASE_6.md
 M lib/features/guru/... (8 file)      ?? lib/core/network/session_expiry.dart
                                       ?? lib/shared/application/account_session_reset.dart
                                       ?? test/app/account_session_reset_test.dart
                                       ?? test/app/responsive_dark_test.dart
                                       ?? test/app/theme/
                                       ?? test/core/widgets/
                                       ?? test/features/auth/session_expiry_test.dart
```

**Ringkasan:** Phase 6 = PASS WITH LIMITATIONS. Desain siswa/guru/wali kini
berbagi design system tunggal (semantic colors, komponen reusable, 48dp
target, tooltip); konteks anak wali selalu terlihat; sesi mid-flight 401 dan
pergantian akun ditangani dengan benar; +31 test regresi/integrasi total
329 lulus; APK debug ter-build; backend tidak berubah. Keterbatasan tersisa:
manual UAT fisik & live backend belum dijalankan (menunggu Anda).
