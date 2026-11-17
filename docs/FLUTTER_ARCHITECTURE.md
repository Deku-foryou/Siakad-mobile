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
│   │   └── api_envelope.dart     # Pembaca envelope { success, message, data, meta? }
│   ├── storage/
│   │   ├── secure_key_value_store.dart  # Abstraksi + implementasi flutter_secure_storage
│   │   └── secure_storage_service.dart  # Token + SessionMeta (save/read/clear)
│   ├── utils/formatters.dart     # tanggal (id), rupiah, status label/warna helper
│   └── widgets/
│       ├── app_loading.dart, app_error_view.dart, app_empty_view.dart
│       └── app_widgets.dart      # AsyncValueView, SectionHeader, StatusBadge, InfoRow,
│                                 # InfoCard, MenuCard, SkeletonBox
├── features/
│   ├── auth/  (lihat §6)
│   ├── siswa/                    # LENGKAP — lihat §12 (Siswa Module)
│   │   ├── data/
│   │   │   ├── models/           # page_meta, beranda, absensi, nilai, pengumuman,
│   │   │   │                     # notifikasi, keuangan (manual fromJson)
│   │   │   ├── siswa_repository.dart      # akademik + komunikasi siswa (read-only)
│   │   │   ├── keuangan_repository.dart   # keuangan (K1–K11) + dokumen privat
│   │   │   ├── private_document_service.dart # save bytes ke app-documents dir + open_filex
│   │   │   └── paged_state.dart  # PagedResult/PageMeta bersama + PagedState
│   │   ├── application/
│   │   │   ├── siswa_providers.dart       # repository + FutureProviders (+ autoDispose.family)
│   │   │   ├── paged_notifier.dart       # base PagedNotifier (halaman list generik)
│   │   │   ├── absensi_notifiers.dart    # state absensi khusus (rekap + list)
│   │   │   └── siswa_tab_index.dart      # SiswaTabIndex — index tab di shell
│   │   └── presentation/
│   │       ├── siswa_shell.dart           # Scaffold + NavigationBar (5 tab, IndexedStack)
│   │       ├── beranda/  akademik/  keuangan/  notifikasi/  pengumuman/  profil/
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

Route utama:

```
/splash · /login · /change-password
/siswa                                # shell siswa (NavigationBar: Beranda, Akademik,
                                      # Keuangan, Notifikasi, Profil) — tab di IndexedStack
/siswa/jadwal · /siswa/absensi · /siswa/nilai · /siswa/rapor
/siswa/rapor/:semesterId/:kelasId
/siswa/pengumuman · /siswa/pengumuman/:id · /siswa/notifikasi/:id
/siswa/pembayaran · /siswa/pembayaran/:id · /siswa/tagihan/:id
/siswa/pembayaran-attempt/:id
/guru · /wali                         # placeholder
```

Initial: `/splash`. Redirect **murni & deterministik** (`resolveRedirect`),
dengan `refreshListenable` yang dipicu perubahan `authStateProvider`.

**Guard area berbasis PREFIX** (`AppRoutes.roleByAreaPrefix`): `/siswa`,
`/siswa/jadwal`, dst. hanya untuk role siswa — begitu juga guru/wali.
Sub-route area role lain → home sendiri.

| State | Aturan redirect |
|---|---|
| `unknown` | paksa `/splash` |
| `sessionCheckFailed` | izinkan `/splash` & `/login`; lainnya → `/splash` |
| `unauthenticated` | izinkan `/login`; lainnya → `/login` |
| `authenticated` + `wajibGantiPassword` | paksa `/change-password` (satu-satunya halaman) |
| `authenticated` | `/splash`,`/login`,`/change-password` → home role; area role lain (prefix) → home sendiri |

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
- Flow pembayaran Midtrans end-to-end (Snap) belum diuji — tidak ada kredensial
  Sandbox; seluruh alur Attempt diuji lewat mock. Integrasi webhook tetap
  server-to-server.
- FCM/APNs, offline mutation, refresh token, admin/superadmin mobile.
- Fitur guru & wali (masih placeholder).
- iOS build belum diuji (butuh macOS + Xcode).
- Preview/buka PDF dokumen privat memakai viewer bawaan perangkat
  (`open_filex`), bukan viewer PDF di dalam aplikasi.

## 12. Siswa Module (Phase 3)

Area siswa berfitur penuh di atas `/auth/*` Phase 2:

| Kelompok | Endpoint backend | Halaman/Route |
|---|---|---|
| Beranda | `GET /siswa/beranda` (+unread-count, ringkasan, pengumuman) | tab Beranda |
| Profil | `GET /siswa/profil` (+info sesi lokal & logout) | tab Profil |
| Jadwal | `GET /siswa/jadwal`, `GET /siswa/jadwal/hari-ini` | `/siswa/jadwal` |
| Absensi | `GET /siswa/absensi/harian` · `/periode` · `/perjam` | `/siswa/absensi` |
| Nilai | `GET /siswa/nilai` (rapor final saja) | `/siswa/nilai` |
| Rapor | `GET /siswa/rapor`, `GET /siswa/rapor/{s}/{k}` | `/siswa/rapor`, detail |
| Pengumuman | `GET /siswa/pengumuman`, `/pengumuman/{id}` (auto mark read) | `/siswa/pengumuman*` |
| Notifikasi | `GET/PATCH /siswa/notifikasi*` (+`unread-count`, read-all) | tab Notifikasi |
| Keuangan | `GET /keuangan/ringkasan` | tab Keuangan |
| Tagihan | `GET /keuangan/tagihan`, `/tagihan/{id}` (create attempt) | detail |
| Saldo | `GET /keuangan/saldo` | tab Keuangan |
| Pembayaran | `GET /keuangan/pembayaran`, `/pembayaran/{id}` | `/siswa/pembayaran*` |
| Attempt | `POST /keuangan/pembayaran/attempts`, `GET .../attempts/{id}` | dialog + `/siswa/pembayaran-attempt/:id` |
| Dokumen | `GET /keuangan/pembayaran/{id}/bukti|kuitansi`, `GET /keuangan/refund/dokumen/{id}` | tombol di detail pembayaran |

**Pola data:** satu-shot data via `FutureProvider.autoDispose(.family)`;
list ter-paginasi via `NotifierProvider.autoDispose` + `PagedNotifier<T>`
(`application/paged_notifier.dart` + `paged_state.dart`) — state `items/meta/
busy/refreshing/error`, tombol "Muat Lebih Banyak". Absensi memakai state
ringkasan khusus (`AbsensiListState`) karena response membawa `ringkasan`/
`rekap_semester`/`rekap_total`.

**Keuangan — aturan ketat:** attempt hanya mengirim `tagihan_id` (nominal
selalu ditentukan server dari `total_tagihan`); UI tidak pernah menganggap
attempt sebagai pembayaran; status transaksi selalu mengikuti response
backend; dokumen privat diunduh via endpoint backend dengan Bearer token →
`PrivateDocumentService` menyimpan di `<app-documents>/dokumen_privat/` →
dibuka dengan `open_filex` (tidak ada URL publik yang dibangun sendiri).

**Tidak ada business logic backend yang diduplikasi** (nilai akhir, rekap
absensi, status tagihan dikonsumsi apa adanya) dan **tidak ada mutasi**
ademik; siswa hanya bisa tandai notifikasi dibaca.
