# LAPORAN — Flutter Phase 2: Authentication UI & Backend Integration

**Tanggal:** 17 November 2026 · **Status:** **PASS (Android)** · iOS **BLOCKED** (environment Windows)
**Scope:** Login UI, integrasi API, session restoration, role-based navigation, force password change, logout/logout-all, error handling, automated tests, dokumentasi.

---

## 1. Ringkasan audit (sebelum implementasi)

**Yang sudah ada & bekerja (Phase 1, dipertahankan):** `AuthRepository` (5 endpoint
`/auth/*`), `AuthController`, state `unknown/unauthenticated/sessionCheckFailed/authenticated`,
`AuthInterceptor` (Bearer + hapus sesi saat 401), `resolveRedirect()` GoRouter murni,
`SecureStorageService`, theme light/dark, placeholder role + tombol logout, 62 tests.

**Gap terhadap scope Phase 2 yang ditemukan & diperbaiki:**

| # | Temuan | Perbaikan |
|---|---|---|
| 1 | Interceptor 401 menghapus sesi juga untuk `401 INVALID_CREDENTIALS` dari `/auth/login` (kondisi salah: salah password bisa menghapus sesi tersimpan) | `AuthInterceptor` kini mengecualikan path `/auth/login` dari pembersihan sesi; tercakup test |
| 2 | `restoreSession()` tidak dijaga paralel; `readToken()` tak dibungkus try/catch → splash berpotensi tanpa akhir bila secure storage gagal | Flag `_restoreInFlight`; `readToken()` try/catch → `sessionCheckFailed` + tombol retry; build tidak memicu `/auth/me` ganda |
| 3 | **Role tidak divalidasi** pasca login/restore — `level` tak dikenal tetap `authenticated` (sesi "nyangkut") | Defense-in-depth: `AppConstants.isMobileRole()`; role tak valid → sesi dibersihkan + `errorCode=ROLE_NOT_ALLOWED` + pesan ramah |
| 4 | `AuthState` tidak membawa `code` error → UI tidak bisa memetakan kode backend spesifik | `AuthState` += `errorCode` (nullable; 422 backend tanpa code tetap aman) dan `deviceName` |
| 5 | Tidak ada guard anti double-submit di sisi controller | `login()`/`changePassword()`/`logout*()` no-op saat `isSubmitting`; tombol UI dinonaktifkan |
| 6 | Login form: belum ada `autofillHints`, `autovalidateMode`, keyboard config | Ditambahkan (autofill username/password, `onUserInteraction`, `textCapitalization none`, keyboard dismiss on drag) |
| 7 | Dashboard placeholder hanya identitas dasar; belum ada info sesi; konten overflow di layar kecil (terdeteksi test) | `_SessionCard` (nama, @username, role, status sesi, perangkat, masa berlaku token — **tanpa token**); body scrollable anti-overflow |
| 8 | `SessionMeta` tidak menyimpan nama perangkat | `device_name` ditambahkan (toleran parser lama) |
| 9 | Test yang diminta spek belum ada (repository-level, widget, unknown-role) | Ditambahkan: `auth_repository_test.dart` (14), `auth_flow_widget_test.dart` (12), extend `auth_controller_test.dart` (+10 → 24), `redirect_test.dart` (+1 → 17) |

Tidak ada perubahan arsitektur; tidak ada dependency baru; backend Laravel tidak diubah.

## 2. Fitur yang diimplementasikan

- **Login UI** (`login_page.dart`) — branding SIAKAD, username (trim+lowercase di repository), password + toggle visibility, validasi (username wajib ≤30, password wajib), autovalidate `onUserInteraction`, `autofillHints`, keyboard action Next/Done, scroll anti keyboard menutupi input, loading state pada tombol (spinner + disabled, anti double-tap), banner error/notice dismissable, pesan ramah per kode backend (`ROLE_NOT_ALLOWED`, `ACCOUNT_INACTIVE`, `TOO_MANY_REQUESTS`, 401 generik, 422 field errors).
- **Session restoration** — splash menampilkan "Memeriksa sesi…", token dibaca (dengan fallback aman), diverifikasi via `GET /auth/me`; 401/ACCOUNT_INACTIVE → bersihkan sesi → login (notice); gagal jaringan → `sessionCheckFailed` + retry; paralel restore dicegah.
- **Role-based navigation** — `level` backend: siswa→`/siswa`, guru→`/guru`, wali→`/wali`; role tak dikenal ditolak (clear + error). Guard murni, tanpa redirect loop.
- **Force password change** — `wajib_ganti_password=true` → terkunci ke `/change-password` dari semua lokasi (deep link tidak bisa melewati; diuji). Setelah sukses, semua token dicabut backend → sesi lokal dibersihkan → login + notice "Password berhasil diubah…".
- **Logout & Logout-all** — di dashboard placeholder setiap role (AppBar + tombol khusus); dialog konfirmasi; request dikirim DULU, baru sesi lokal dibersihkan (termasuk saat server 401 — pengguna tidak terjebak). Bersih tanpa sisa data user.
- **Dashboard placeholder** — identitas + informasi sesi (status, perangkat, masa berlaku token), logout/logout-all; scrollable; tetap Material 3 dan theme-aware (dark mode).

## 3. Alur login dan pemulihan sesi

```
Buka app ─► unknown ─► token? tidak → unauthenticated ─► /login
                     └ ya → GET /auth/me
                          ├─ 200 + role valid → authenticated (+ wajib? → /change-password)
                          ├─ 200 + role tak dikenal → clearSession → unauthenticated (errorCode ROLE_NOT_ALLOWED)
                          ├─ 401 / ACCOUNT_INACTIVE → clearSession → unauthenticated (+ notice)
                          └─ jaringan/5xx → sessionCheckFailed → splash (retry / ke login)
Login ─► POST /auth/login {username, password, device_name} ─► 200 → token+meta tersimpan (secure storage)
       → authenticated (redirect per role) · gagal → banner error (kredensial generik / akun / role / 429 / 422 / jaringan)
```

Username dari input di-trim dan di-lowercase sebelum dikirim (implementasi backend
juga menormalisasi). `device_name` dari platform (`Flutter Android`/`Flutter iOS`,
fallback aman `Flutter`). Token hanya tersimpan di secure storage; tidak pernah
di-log/ditampilkan.

## 4. Alur force password change

Login/restore dengan `wajib_ganti_password=true` → router memaksa `/change-password`
pada semua lokasi (tidak bisa deep-link ke `/siswa` dll). Form: password lama, baru
(min 8, ≠ lama), konfirmasi (harus sama) — validasi client; 422 backend ditampilkan
(termasuk `current_password` salah). Submit loading-state + anti double-tap. Sukses
→ semua token dicabut (backend) → clearSession → redirect `/login` + notice login-ulang.

## 5. Alur logout dan logout-all

Tap Logout (AppBar / per-perangkat) atau "Logout Semua Perangkat" → dialog konfirmasi
→ `POST /auth/logout` / `POST /auth/logout-all` → sesi lokal dibersihkan **setelah**
request dikirim (gagal jaringan/401 pun tetap dibersihkan) → auth state reset →
redirect `/login` (+ notice). Tidak ada data user lama yang tersisa.

## 6. Perubahan file

**Dimodifikasi (lib/):** `features/auth/application/auth_state.dart` (+`errorCode`,
+`deviceName`), `features/auth/application/auth_controller.dart` (role guard,
`_restoreInFlight`, `readToken` aman, anti double-submit, `_friendlyMessage`),
`features/auth/presentation/pages/login_page.dart` (autofill/autovalidate/keyboard/doc),
`shared/widgets/role_placeholder_page.dart` (session card, scroll anti-overflow,
LayoutBuilder), `core/network/auth_interceptor.dart` (exception `/auth/login` untuk 401),
`core/constants/app_constants.dart` (`mobileRoles`, `isMobileRole`),
`core/storage/secure_storage_service.dart` (`SessionMeta.deviceName`).

**Dimodifikasi (docs/reports):** `docs/FLUTTER_ARCHITECTURE.md` (Phase 2 flows),
`LAPORAN_FLUTTER_FOUNDATION.md` (addendum koreksi).

**Test baru:** `test/features/auth/auth_repository_test.dart` (14),
`test/features/auth/auth_flow_widget_test.dart` (12).
**Test diperluas:** `test/features/auth/auth_controller_test.dart` (14 → 24),
`test/app/router/redirect_test.dart` (16 → 17).

**Tidak ada dependency baru.** Tidak ada perubahan pada `pubspec.yaml` di Phase 2.

## 7. Dependency baru

Tidak ada. Seluruh fitur diselesaikan dengan dependency Phase 1 (`dio`,
`flutter_riverpod`, `go_router`, `flutter_secure_storage`).

## 8. Automated tests & hasil

```
dart format .    ✓ (47 file)
flutter analyze  ✓ No issues found!
flutter test     ✓ All tests passed! (100/100)
```

Per file (test definition count = lulus):

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
| **Total** | **100** |

Cakupan spek:

- **Repository/API (15):** semua ✓ — login sukses, lowercase, device_name, token tersimpan, kredensial salah, akun nonaktif, role not allowed, 429, 422 tanpa code, `/auth/me` sukses, `/auth/me` 401, logout, logout-all, changePassword sukses, changePassword gagal.
- **Auth state (13):** semua ✓ — initial unauthenticated, login sukses/gagal, restore sukses/tanpa token/401/offline (token dipertahankan), nonaktif, role tak dikenal (login & restore), force password change, logout, logout-all, changePassword membersihkan sesi (termasuk 401), anti double-submit, paralel restore.
- **Routing (8):** semua ✓ — redirect per role, belum login → login, wajib ganti password terkunci (deep link tidak bisa lewat), role salah → home sendiri, titik-stabil tanpa redirect loop, role tak dikenal → login.
- **Widget (9):** semua ✓ — form tampil, validasi kosong, toggle visibility, loading state + redirect per role, pesan gagal (401/429/403), change password form (mismatch confirm), dialog logout-all, tombol logout, dashboard identitas + info sesi.

Test menggunakan fake (`FakeSecureKeyValueStore`, `FakeHttpClientAdapter`, `_GateAdapter`
untuk loading state deterministik) — tanpa backend sungguhan/kredensial.

## 9. `flutter analyze`

```
Analyzing siakad-mobile...
No issues found! (ran in 8.4s)
```

## 10. Android debug build

```
flutter build apk --debug → ✓ Built build\app\outputs\flutter-apk\app-debug.apk (205 MB)
(warning gradle "restricted method" bersifat informasional; exit code 1 dari stderr PowerShell, build sukses)
```

## 11. Keterbatasan iOS & physical device

- **iOS: belum diuji** — environment adalah Windows; iOS memerlukan macOS + Xcode.
  Tidak ada klaim iOS build berhasil.
- **Physical device: belum diuji** — butuh IP LAN yang dapat dijangkau perangkat;
  `--dart-define=API_BASE_URL=http://<ip-lan>:8000/api/v1` terdokumentasi.
- **Integrasi live ke backend nyata** belum diuji (butuh kredensial staging
  siswa/guru/wali + backend TLS); seluruh alur diverifikasi via mock HTTP yang
  mereproduksi envelope backend apa adanya.
- Login tetap memerlukan koneksi — tidak ada mode offline-mutation (by design).

## 12. Temuan teknis

1. 401 `/auth/login` ≠ 401 token kedaluwarsa — interceptor membedakan (diperbaiki; sebelumnya rawan menghapus sesi valid).
2. Secure storage `readToken()` bisa melempar → sekarang tidak lagi membuat splash tanpa akhir.
3. `LayoutBuilder`+`ConstrainedBox`+`SingleChildScrollView` menjaga dashboard tidak overflow di layar kecil (ditemukan oleh widget test).
4. Backend tetap sumber kebenaran: flag `wajib_ganti_password` & `level` selalu dibaca ulang dari `/auth/me` pasca restore; tidak ada flag "terpercaya" yang disimpan lokal.
5. 422 backend tanpa `code` — UI tidak mensyaratkannya; `fieldErrors` dari `errors` dipakai apa adanya.
6. Logout saat jaringan down: sesi lokal selalu dibersihkan; token di server kedaluwarsa (30 hari) — dijelaskan ke pengguna via perilaku login ulang.
7. Token tidak pernah tampil di UI/log; log HTTP hanya `METHOD /path`, status, durasi.

## 13. Status Git

Project Flutter **bukan** repository git. Tidak ada perintah Git write apa pun
(init/commit/push/reset/checkout/stash) yang dijalankan. Perubahan berupa file
baru/modifikasi di working directory. Backend Laravel tidak disentuh.

## 14. Kriteria penerimaan

| Kriteria | Status |
|---|---|
| Login benar-benar terhubung ke Laravel API (mock-verified envelope persis) | ✅ |
| Token disimpan secara aman | ✅ secure storage; tidak ada di log/UI |
| Session restoration berfungsi | ✅ (termasuk retry & anti-ganda) |
| Role siswa/guru/wali diarahkan dengan benar | ✅ |
| Force password change tidak dapat dilewati | ✅ (deep link terkunci; diuji) |
| Logout current & logout-all berfungsi | ✅ |
| Error backend dipetakan dengan benar | ✅ (400–503, timeout, no-connection, invalid body) |
| Tidak ada token/password bocor melalui log | ✅ |
| Tidak ada redirect loop | ✅ (uji titik-stabil) |
| Automated tests lulus | ✅ 100/100 |
| `flutter analyze` bersih | ✅ No issues found |
| Android debug build berhasil | ✅ |
| Dokumentasi & laporan lengkap | ✅ |
| iOS build | ⛔ BLOCKED (environment) |
