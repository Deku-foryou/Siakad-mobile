# Flutter Architecture — SIAKAD Mobile

Dokumen ini menjelaskan arsitektur fondasi aplikasi SIAKAD Mobile (Flutter),
yang dibangun di atas kontrak REST API backend Laravel (`/api/v1`).

**Sumber kebenaran bisnis adalah backend.** Flutter hanya menampilkan data
dan mengarahkan pengguna; otorisasi sesungguhnya selalu ditegakkan backend
(middleware `auth:sanctum` → `api.role` → `api.akun` → `api.password`).

## 1. Struktur Project

```
lib/
├── main.dart                     # Entry point: ProviderScope + SiakadApp
├── app/
│   ├── app.dart                  # MaterialApp.router (theme light/dark, GoRouter)
│   ├── router/
│   │   ├── app_router.dart       # routerProvider: route + redirect + refreshListenable
│   │   ├── app_routes.dart       # Konstanta path route & mapping role → home
│   │   └── redirect.dart         # resolveRedirect() — fungsi murni, dapat dites
│   └── theme/
│       ├── app_colors.dart       # Palet warna (seed teal)
│       ├── app_spacing.dart      # Skala spacing & radius
│       └── app_theme.dart        # ThemeData light & dark (Material 3)
├── core/
│   ├── config/app_config.dart    # API_BASE_URL via --dart-define, timeouts, validasi URL
│   ├── constants/app_constants.dart
│   ├── errors/
│   │   ├── api_exception.dart    # Tipe error standar + helper (isUnauthorized, ...)
│   │   └── error_mapper.dart     # DioException/HTTP → ApiException
│   ├── network/
│   │   ├── dio_client.dart       # factory createDio() — SATU instance untuk semua fitur
│   │   ├── auth_interceptor.dart # Sisip Bearer token; hapus sesi lokal saat 401
│   │   ├── logging_interceptor.dart # Dev-only; tanpa token/body/header
│   │   └── api_envelope.dart     # Pembaca envelope { success, message, data, ... }
│   ├── storage/
│   │   ├── secure_key_value_store.dart  # Abstraksi + implementasi flutter_secure_storage
│   │   └── secure_storage_service.dart  # Token + SessionMeta (save/read/clear)
│   └── widgets/                  # AppLoading, AppErrorView, AppEmptyView
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart          # POST /auth/login, /logout, /logout-all, /password, GET /auth/me
│   │   │   └── models/                       # AuthUser, AuthSession, MeSession (fromJson manual)
│   │   ├── application/
│   │   │   ├── auth_state.dart               # AuthStatus + AuthState
│   │   │   └── auth_controller.dart          # AuthController (Riverpod Notifier)
│   │   └── presentation/pages/                # splash_page, login_page, change_password_page
│   ├── siswa/presentation/siswa_home_page.dart   # placeholder
│   ├── guru/presentation/guru_home_page.dart     # placeholder
│   └── wali/presentation/wali_home_page.dart     # placeholder
└── shared/
    ├── providers/core_providers.dart          # appConfig, storage, dio, authRepository
    └── widgets/role_placeholder_page.dart     # Scaffold placeholder + logout actions
```

Prinsip: **feature-first** dengan pemisahan `data / application / presentation`.
Tidak ada Clean Architecture yang kaku; model ditulis manual (tanpa codegen)
agar dependency minimal dan mudah dipahami.

## 2. Layer & tanggung jawab

| Layer | Isi | Aturan |
|---|---|---|
| `core/` | Infrastruktur lintas fitur: config, network, storage, error, widget dasar | Tidak bergantung pada `features/` |
| `features/*/data` | Model + repository (akses API) | Tidak bergantung pada UI |
| `features/*/application` | State & controller (Riverpod) | Tidak bergantung pada widget |
| `features/*/presentation` | Pages/widgets | Tidak mengakses Dio langsung |
| `shared/` | Provider & widget lintas fitur | Boleh bergantung pada `core/` |

## 3. State management (Riverpod 3)

- Semua state lintas aplikasi lewat provider; **tidak ada global mutable state**.
- Provider inti (`shared/providers/core_providers.dart`):
  - `appConfigProvider` → `AppConfig` (dari `--dart-define`).
  - `secureKeyValueStoreProvider` → `SecureKeyValueStore` (produksi:
    `FlutterSecureKeyValueStore`; test: in-memory fake).
  - `secureStorageServiceProvider` → `SecureStorageService`.
  - `dioProvider` → instance Dio tunggal (`createDio`).
  - `authRepositoryProvider` → `AuthRepository`.
- `authStateProvider` = `NotifierProvider<AuthController, AuthState>`.
- Semua provider dapat di-override di test (`ProviderScope(overrides: ...)` /
  `ProviderContainer(overrides: ...)`), sehingga test tidak menyentuh platform
  channel maupun jaringan.

## 4. Network layer (Dio)

Satu-satunya cara membuat request HTTP adalah `dioProvider`. Fitur:

- Base URL terpusat dari `AppConfig` (prefix `/api/v1`).
- Timeout: connect 15 s, send 15 s, receive 30 s.
- `Accept: application/json`, `Content-Type: application/json`.
- `AuthInterceptor`: sisip `Authorization: Bearer <token>` dari secure storage;
  pada **401**, token + session meta lokal **dihapus otomatis** (backend
  mencabut token kedaluwarsa/invalid) — kecuali `/auth/login`, di mana 401
  berarti kredensial salah.
- `LoggingInterceptor`: aktif hanya di debug mode (`kDebugMode`); mencatat
  `METHOD /path`, status, dan durasi — **tidak pernah** mencatat header,
  body, token, atau password; query string tidak dicatat.
- Semua error HTTP dipetakan menjadi `ApiException` oleh `ErrorMapper`
  (lihat §7). 4xx/5xx melempar `DioException(badResponse)` karena
  `validateStatus` hanya menerima 2xx/3xx.

**Tidak ada refresh token.** Token Sanctum berlaku 30 hari. Jika 401 →
sesi lokal dibersihkan → pengguna diarahkan login ulang.

## 5. API configuration

Base URL **wajib** dikonfigurasi lewat `--dart-define`:

```bash
# Android emulator (10.0.2.2 = host machine)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1

# Physical device (IP LAN komputer, jaringan sama)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
```

Default bila tidak diisi: `http://10.0.2.2:8000/api/v1` (development Android
emulator), dan **tidak ada URL production yang di-hardcode**. Nilai
`API_BASE_URL` divalidasi (`normalizeBaseUrl`): harus http(s) + punya host;
trailing slash dinormalisasi. `localhost` **tidak** digunakan sebagai default
karena salah untuk Android emulator. Tidak ada credential/secret di source
code maupun di `AppConfig`.

## 6. Authentication flow

Status: `unknown → unauthenticated | sessionCheckFailed | authenticated`
(`sessionCheckFailed` = token tersimpan tetapi tidak bisa diverifikasi ke
`GET /auth/me`, mis. jaringan down; token dipertahankan, UI splash menampilkan
tombol *Coba Lagi*).

`restoreSession()` dijaga `_restoreInFlight` sehingga pemanggilan paralel
(microtask saat build + retry manual) tidak menghasilkan request `/auth/me`
ganda. `readToken()` dibungkus try/catch — kegagalan baca secure storage
menghasilkan `sessionCheckFailed` (bukan splash tanpa akhir).

**Defense-in-depth role:** setelah login maupun restore, `level` diverifikasi
terhadap whitelist (`siswa|guru|wali`). Role di luar itu → sesi lokal
dibersihkan → `unauthenticated` dengan `errorCode=ROLE_NOT_ALLOWED` dan pesan
"Akses tidak tersedia untuk aplikasi mobile…". Backend sendiri menolak lebih
dulu (403 `ROLE_NOT_ALLOWED`); validasi client mencegah sesi aneh "nyangkut"
dalam state authenticated.

```
App dibuka
  │
  ▼
unknown ── token tidak ada ──────────────► unauthenticated ─► /login
  │
  └─ token ada ──► GET /auth/me
                    ├─ 200 ──► authenticated (user + wajib_ganti_password dari response)
                    ├─ 401 / ACCOUNT_INACTIVE ──► clearSession() ─► unauthenticated
                    │   (notice: "Sesi berakhir. Silakan login kembali." /
                    │            "Akun tidak dapat digunakan...")
                    └─ error jaringan/5xx ──► sessionCheckFailed ─► splash (retry)
```

Operasi:

- **login** `POST /auth/login` `{username (trim+lowercase), password, device_name}`
  → simpan token + SessionMeta; state `authenticated`. Role di luar
  siswa/guru/wali ditolak backend (403 `ROLE_NOT_ALLOWED`, tidak ada token).
- **logout** `POST /auth/logout` → hapus token lokal (server gagal pun sesi
  lokal tetap dibersihkan; token server dibiarkan kedaluwarsa).
- **logout-all** `POST /auth/logout-all` → idem, semua perangkat.
- **change-password** `POST /auth/password` `{current_password, password,
  password_confirmation}` → **semua token dicabut backend** → sesi lokal
  dibersihkan → redirect `/login` dengan notice.
- **Role backend**: `/auth/me` selalu mengembalikan `user.level`
  (`siswa|guru|wali`) dan `wajib_ganti_password`. Field ini dipakai router.
  Client memvalidasi ulang role pasca login/restore; role tak dikenal →
  sesi dibersihkan (defense-in-depth).
- **Anti double-submit**: `login` dan `changePassword` no-op saat
  `state.isSubmitting == true`; tombol UI juga dinonaktifkan selama proses.
- **Interceptor 401**: token lokal dihapus saat 401 dari endpoint mana pun,
  **kecuali `/auth/login`** (401 di sana = `INVALID_CREDENTIALS`, bukan sesi
  kedaluwarsa).
- **Akun nonaktif**: middleware `api.akun` mengembalikan 403 `ACCOUNT_INACTIVE`
  (dan mencabut token); frontend membersihkan sesi & mengarahkan ke login.
- **Wajib ganti password**: `/auth/me` tetap boleh diakses; endpoint
  operasional mengembalikan 403 `PASSWORD_CHANGE_REQUIRED`. Frontend
  mengarahkan ke `/change-password` (lihat §8).

## 7. Error handling

Semua error API dinormalisasi menjadi `ApiException`:

| Skenario | `ApiException` |
|---|---|
| Timeout (connect/send/receive) | `kind=timeout` |
| Tidak ada koneksi / DNS / Socket | `kind=noConnection` |
| HTTP 400/401/403/404/405/422/429/500/503 | `kind=http`, `statusCode`, `code?`, `fieldErrors?` (422) |
| Body bukan JSON object | `kind=invalidResponse` |
| Lainnya | `kind=unknown` |

Aturan:

- Pesan backend (Bahasa Indonesia, aman) dipakai bila tersedia; jika tidak,
  fallback per status (`ErrorMapper.fallbackMessage`).
- `fieldErrors` dari envelope 422 dipetakan per field — dicatat sebagai
  **temuan**: backend tidak mengirim `code` pada 422
  (`ValidationException` renderable tidak meneruskannya), sedangkan docs
  §5.2 menyatakan `code` selalu ada.
- Stack trace / detail internal **tidak pernah** tampil ke pengguna.
- 401 dari endpoint mana pun (kecuali `/auth/login`) → `AuthInterceptor`
  menghapus sesi lokal → router mengarahkan ke `/login`.

## 8. Routing (GoRouter)

Route: `/splash`, `/login`, `/change-password`, `/siswa`, `/guru`, `/wali`.
Initial: `/splash`. Redirect **murni & deterministik** (`resolveRedirect`),
dengan `refreshListenable` yang dipicu perubahan `authStateProvider`.

| State | Aturan redirect |
|---|---|
| `unknown` | paksa `/splash` |
| `sessionCheckFailed` | izinkan `/splash` & `/login`; lainnya → `/splash` |
| `unauthenticated` | izinkan `/login`; lainnya → `/login` |
| `authenticated` + `wajibGantiPassword` | paksa `/change-password` (satu-satunya halaman) |
| `authenticated` | `/splash`,`/login`,`/change-password` → home role; area role lain → home sendiri |

Home role: `siswa → /siswa`, `guru → /guru`, `wali → /wali`.

Tidak ada redirect loop (dijamin oleh uji di
`test/app/router/redirect_test.dart` yang memeriksa stabilitas titik tetap
untuk semua kombinasi status × lokasi). Role routing di frontend **hanya
untuk UX**; backend tetap menegakkan otorisasi per request.

## 9. Secure storage

`flutter_secure_storage` (EncryptedSharedPreferences / Keychain). Disimpan:

- `siakad.auth_token` — token Sanctum (satu-satunya kredensial).
- `siakad.session_meta` — JSON minimal: `user_id, user_name, username, level,
  wajib_ganti_password, token_expires_at, device_name` (UI/splash; sumber
  kebenaran tetap `/auth/me`).

Tidak disimpan: password, data akademik, data pribadi anak, token di log.
Token **tidak pernah** di SharedPreferences / plaintext file. Fungsi:
`saveToken / readToken / deleteToken / saveSessionMeta / readSessionMeta /
clearSession`.

## 10. Menjalankan aplikasi

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Kualitas kode
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

## 11. Yang belum termasuk (by design)

- Biometrik / lupa password / registrasi dari mobile.
- Fitur bisnis siswa/guru/wali (baru placeholder: identitas + informasi sesi
  + logout/logout-all).
- FCM/APNs, offline mutation, refresh token, admin/superadmin mobile.
- iOS build belum diuji (butuh macOS + Xcode).
