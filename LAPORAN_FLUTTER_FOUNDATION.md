# LAPORAN — Flutter Foundation SIAKAD Mobile

**Tanggal:** 17 November 2026 · **Status:** PASS (Android) / iOS BLOCKED (environment)
**Scope:** Arsitektur, konfigurasi API, network layer, secure storage, autentikasi dasar, routing role-based, standardisasi error, testing, dokumentasi.

---

## 1. Ringkasan audit awal

### 1.1 Kondisi project Flutter (sebelum)
Proyek `siakad_mobile` adalah hasil `flutter create` standar (counter demo).
`lib/main.dart` berisi demo counter; `test/widget_test.dart` berisi counter
test; dependency hanya `cupertino_icons` + `flutter_lints`. Valid sebagai
project Flutter (Flutter 3.47.6 · Dart 3.13.5), bukan repository git.

### 1.2 Kontrak API aktual (diverifikasi langsung dari kode backend, bukan asumsi)
Diperiksa: `DOKUMENTASI_REST_API_SIAKAD.md`, `AuthController`,
`UserResource`, `ApiResponse`, `Handler.php`, middleware
`EnsureApiAccountActive` / `EnsureApiPasswordChanged` / `EnsureApiRole`,
`LoginRequest`, `UpdatePasswordRequest`, `routes/api.php`.

| Item | Temuan (bukti) |
|---|---|
| Login | `POST /auth/login` — request `{username(≤30, di-lowercase), password, device_name(wajib ≤100)}` → 200 `data{token, token_type:"Bearer", expires_at(ISO-8601), wajib_ganti_password(bool), user{…}}` (`AuthController::login` + `LoginRequest`) |
| Token | Sanctum PAT, umur 30 hari (`TOKEN_LIFETIME_MINUTES = 43200`), abilities `['mobile-api']`. **Tidak ada refresh token.** |
| Role | Field role = **`level`** pada `user` (`UserResource`): `siswa\|guru\|wali`. Nilai lain → `403 ROLE_NOT_ALLOWED`, token tidak dibuat. |
| `/auth/me` | `data{user{…}, token{name,last_used_at,expires_at}}` — token mentah tidak pernah dikembalikan. |
| `/auth/logout` · `/auth/logout-all` | POST; logout idempoten (token perangkat ini dihapus), logout-all mencabut seluruh token user. |
| `/auth/password` | POST `{current_password, password(min 8, confirmed), password_confirmation}` → password diubah + **seluruh token dicabut** (user wajib login ulang). |
| Wajib ganti password | `wajib_ganti_password=true` → endpoint operasional `403 PASSWORD_CHANGE_REQUIRED`; yang tetap boleh: `/auth/me`, `/auth/password`, `/auth/logout`, `/auth/logout-all` (`EnsureApiPasswordChanged`, routes `api.v1.auth.*`). |
| Akun nonaktif | `403 ACCOUNT_INACTIVE` + token yang sedang dipakai **dicabut** (`EnsureApiAccountActive`). |
| Login gagal | `401 INVALID_CREDENTIALS` (pesan generik anti-enumerasi), `429 TOO_MANY_REQUESTS` (throttle 5/menit), `422` validasi. |
| Envelope | Sukses `{success,message,data?,meta?}`; error `{success:false,message,code?,errors?}`. 401 sanctum → `UNAUTHENTICATED`; 500 fallback → `SERVER_ERROR`. |
| 401 umum | `{code:"UNAUTHENTICATED"}` (`AuthenticationException` renderable). |

### 1.3 Temuan audit (dicatat — backend TIDAK diubah sesuai batasan)
1. **Docs vs kode pada 422:** docs §5.2 menyatakan `code` selalu ada, tetapi
   renderable `ValidationException` mengembalikan 422 **tanpa** `code`
   (hanya `message` + `errors`). Dampak: client tidak boleh mensyaratkan
   `code`; frontend memakai `fieldErrors` persis dari `errors` map.
2. **`503` di docs §5.3** tidak memiliki handler khusus; jatuh ke fallback
   5xx (`SERVER_ERROR`, 500) atau pesan bawaan HttpExceptionInterface.
3. Endpoint operasional mengembalikan `403` (bukan `401`) untuk password
   wajib ganti / akun nonaktif — frontend membedakannya via `code`.
4. `expires_at` pada respons login adalah ISO-8601 dengan offset lokal
   (`+07:00`); diparse dengan `DateTime.tryParse` (aman terhadap offset).

## 2. Implementasi

**Arsitektur:** feature-first, layer `core / features(data,application,
presentation) / shared`, plus `app/router` & `app/theme`. Tidak ada
Clean Architecture kaku; serialization manual (tanpa codegen) agar
dependency minimal.

**Yang dibangun:**

- **Konfigurasi API terpusat** (`core/config/app_config.dart`) — base URL
  via `--dart-define=API_BASE_URL`, default development
  `http://10.0.2.2:8000/api/v1` (Android emulator; iOS simulator & physical
  device didokumentasikan), validasi URL (http/https + host), normalisasi
  trailing slash, prefix `/api/v1`, timeout connect/send 15 s & receive 30 s.
  Tidak ada URL production atau secret di source code.
- **Dio terpusat** (`core/network/dio_client.dart`) — satu instance via
  `dioProvider`; `AuthInterceptor` (sisip Bearer; hapus sesi lokal saat 401);
  `LoggingInterceptor` (khusus debug; tanpa token/header/body/query);
  `validateStatus` 2xx/3xx; header JSON.
- **Error standardisasi** (`core/errors/`) — `ApiException` +
  `ErrorMapper` menangani: timeout, no connection (incl. SocketException),
  400/401/403/404/405/422/429/500/503, body non-JSON, error tidak dikenal.
  Pesan backend dipakai bila tersedia; 422 diekspos sebagai `fieldErrors`.
- **Secure storage** (`flutter_secure_storage`) — token + `SessionMeta`
  minimal (id/nama/username/level/wajib_ganti_password/expires_at);
  `clearSession()` saat logout/401/ubah password. Tidak ada token di
  SharedPreferences/file plaintext/log. Token Sanctum 30 hari; **tanpa
  refresh token** (sesuai backend).
- **Auth foundation** (`features/auth/`) — `AuthRepository` (lima endpoint
  `/auth/*`), `AuthController` (Riverpod `Notifier`), state
  `unknown/unauthenticated/sessionCheckFailed/authenticated`. Sesi dipulihkan
  & **diverifikasi** lewat `GET /auth/me`; 401 → sesi dibersihkan → login;
  error jaringan → `sessionCheckFailed` (token dipertahankan, splash retry).
  Akun nonaktif (`ACCOUNT_INACTIVE`) dibersihkan; `wajib_ganti_password`
  diikuti; ganti password sukses → semua token dicabut → login ulang.
- **Routing** (GoRouter) — `/splash`, `/login`, `/change-password`,
  `/siswa`, `/guru`, `/wali`; `resolveRedirect()` murni & deterministik,
  `refreshListenable` dari riverpod; role siswa/guru/wali terkunci ke area
  masing-masing; wajib-ganti-password terkunci ke `/change-password`;
  pengguna unauthenticated dipaksa ke `/login`; tidak ada redirect loop
  (diuji). Route guard hanya UX — otorisasi tetap di backend.
- **UI foundation** — theme light & dark (Material 3, seed teal),
  typography, palet, spacing, input/button/card styling terpusat, widget
  `AppLoading`, `AppErrorView`, `AppEmptyView`; halaman placeholder
  siswa/guru/wali (identitas + tombol logout / logout semua perangkat) &
  login + change password sederhana. Tidak ada fitur bisnis.
- **Testing** — 62 test otomatis (lihat §4).

## 3. Dependency yang ditambahkan & alasan

| Dependency | Versi | Alasan |
|---|---|---|
| `dio` | ^5.11.1 | HTTP client terpusat (spec); interceptor, timeout, error handling |
| `flutter_riverpod` | ^3.5.0 | State management (spec); provider yang dapat di-override untuk testing |
| `go_router` | ^18.1.4 | Routing + redirect terpusat (spec) |
| `flutter_secure_storage` | ^11.2.0 | Penyimpanan token terenkripsi (spec) |

Tidak menambahkan `build_runner`/`json_serializable` — model ditulis manual
(payload kecil, dependency lebih sedikit). Tidak ada dependency lain.

## 4. Hasil testing

Perintah dijalankan (semua di environment Windows lokal):

```
flutter pub get   ✓
dart format .     ✓ (45 file)
flutter analyze   ✓ No issues found!
flutter test      ✓ All tests passed! (62 tests)
flutter build apk --debug  ✓ Built build\app\outputs\flutter-apk\app-debug.apk (171 MB)
```

Perincian uji (11 area wajib — semua terpenuhi):

1. API configuration — `test/core/config/app_config_test.dart` (default, normalisasi, validasi URL, prefix)
2. Secure storage — `test/core/storage/secure_storage_service_test.dart` (token, SessionMeta roundtrip, data korup, clearSession)
3. Dio interceptor — `test/core/network/auth_interceptor_test.dart` (Bearer disisipkan/ditiadakan; 401 membersihkan sesi; base URL/timeout/header)
4. Authorization header — idem (`auth_interceptor_test.dart`, asersi header persis)
5. Error mapping — `test/core/errors/error_mapper_test.dart` (semua status wajib + timeout + noConnection + body invalid + fallback)
6. Auth state — `test/features/auth/auth_controller_test.dart` (restore, login sukses/gagal/422, logout, logout-all, change-password)
7. Session restoration — idem (token valid → authenticated; 401 → clear; network fail → sessionCheckFailed + token dipertahankan; wajib_ganti_password dipulihkan)
8. Logout & pembersihan token — idem (logout, logout-all, server gagal pun sesi lokal dibersihkan)
9. Role-based redirect — `test/app/router/redirect_test.dart` (siswa/guru/wali terkunci)
10. Force password change redirect — idem (wajib → `/change-password`; stabil, tanpa loop)
11. Unauthorized response handling — idem + `error_mapper_test.dart` (interceptor menghapus token pada 401; state unauthenticated)

Ditambah: uji stabilitas titik tetap redirect (semua status × lokasi,
anti redirect loop) dan smoke test widget (`test/widget_test.dart`:
tanpa sesi → tampil halaman login).

Test menggunakan fake (`FakeSecureKeyValueStore` in-memory,
`FakeHttpClientAdapter` untuk Dio) — tidak ada backend sungguhan / kredensial.

## 5. Hasil build

| Target | Hasil |
|---|---|
| Android debug APK | ✅ PASS — `app-debug.apk` (171 MB), dibangun di SDK lokal (Platform 35/36 diunduh otomatis oleh gradle) |
| iOS | ⛔ BLOCKED — tidak diuji; environment adalah Windows, iOS membutuhkan macOS + Xcode |

## 6. Daftar file yang dibuat/diubah

**Diubah:** `pubspec.yaml` (+4 dependency), `pubspec.lock`, `lib/main.dart`,
`test/widget_test.dart` (diganti dari counter test).

**Dibuat (lib/):** seluruh struktur `app/` (app, router ×3, theme ×3),
`core/` (config, constants, errors ×2, network ×4, storage ×2, widgets ×3),
`features/auth/` (data: repository + 3 models; application: state + controller;
presentation: splash/login/change_password), placeholder `features/siswa|guru|wali`,
`shared/providers/core_providers.dart`, `shared/widgets/role_placeholder_page.dart`.

**Dibuat (test/):** `fakes/` (3 file), `core/config`, `core/storage`,
`core/errors`, `core/network`, `features/auth`, `app/router`, `widget_test.dart`.

**Dibuat (docs):** `docs/FLUTTER_ARCHITECTURE.md`, laporan ini.
`README.md` tidak diubah (template); `ROADMAP.md` **tidak ada** di project
Flutter — tidak dibuat duplikat (file `ROADMAP.md` yang ada adalah milik
project Laravel dan tidak disentuh).

## 7. Temuan & keterbatasan

- **Temuan backend (bukan untuk diperbaiki di tahap ini):** 422 tanpa `code`
  (§1.3.1); 503 tanpa handler khusus (§1.3.2). Client sudah menanganinya.
- **401 vs 403:** akun nonaktif & password-wajib-ganti dikembalikan sebagai
  `403` dengan `code`, bukan 401 — client sengaja membedakan via `code`.
- **Session check failure:** saat jaringan down ketika aplikasi dibuka,
  pengguna tidak otomatis logout; splash menampilkan retry (`sessionCheckFailed`).
- **Token mati di server:** bila logout gagal karena jaringan, token di server
  tetap ada sampai kedaluwarsa (30 hari) atau diganti password — by design;
  sesi lokal selalu dibersihkan.
- **iOS build belum diuji** (Windows). **Midtrans/E2E** tidak termasuk scope.
- **Placeholder:** tidak ada data asli; bootstrap session hanya memvalidasi
  token + profil.
- Warning gradle `License … accepted` selama build tercatat normal; APK berhasil.

## 8. Status Git

Project Flutter **bukan** repository git (`Is directory a git repo: no`).
Tidak ada perintah Git write apa pun yang dijalankan. Tidak ada commit,
push, reset, checkout, stash. Perubahan seluruhnya berupa file baru/modifikasi
di working directory (untuk yang bukan repo: tidak ada tracking).

## 9. Kriteria selesai — rekap

| Kriteria | Status |
|---|---|
| Struktur Flutter rapi & konsisten | ✅ |
| API configuration berfungsi (dart-define) | ✅ (unit tested) |
| Dio client berfungsi | ✅ (unit tested, debug APK) |
| Secure storage berfungsi | ✅ (unit tested) |
| Auth foundation terintegrasi kontrak aktual | ✅ (login/me/logout/logout-all/password) |
| Role routing berfungsi | ✅ (redirect unit tested) |
| Force password change routing | ✅ (unit tested) |
| Error handling terstandarisasi | ✅ (11+ status/kasus) |
| Automated tests lulus | ✅ 62/62 |
| `flutter analyze` bersih | ✅ No issues found |
| Android debug build | ✅ PASS |
| Dokumentasi & laporan | ✅ |
| iOS build | ⛔ BLOCKED (Windows; butuh macOS+Xcode) |

---

## Addendum - Koreksi pada Phase 2 (Authentication UI & Backend Integration)

Selama Phase 2 ditemukan dan diperbaiki empat hal pada fondasi:

1. Interceptor 401 menghapus sesi juga untuk 401 dari /auth/login (kredensial salah / INVALID_CREDENTIALS). Sekarang path login dikecualikan dari pembersihan sesi - sesi pengguna yang valid tidak terhapus hanya karena salah password. Tercakup test auth_interceptor_test.dart (401 non-login membersihkan sesi) dan auth_controller_test.dart (login 401 tidak menghapus token).
2. Splash berpotensi tanpa akhir bila readToken() melempar exception - sekarang dibungkus try/catch dan menghasilkan sessionCheckFailed dengan tombol retry. Restore paralel juga dicegah via _restoreInFlight (tidak ada request /auth/me ganda).
3. Role tidak divalidasi pasca login/restore - sekarang level siswa/guru/wali diverifikasi client (defense-in-depth); role tak dikenal -> sesi dibersihkan + error ROLE_NOT_ALLOWED.
4. AuthState kini membawa errorCode & deviceName (untuk UI dan pemetaan pesan error spesifik); SessionMeta menyimpan device_name.

Lihat LAPORAN_FLUTTER_PHASE_2_AUTHENTICATION.md untuk detail lengkap.
