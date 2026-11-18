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
│   │   │   ├── models/           # (shared/models: page_meta) beranda, absensi, nilai,
│   │   │   │                     # pengumuman, keuangan (manual fromJson)
│   │   │   ├── siswa_repository.dart      # akademik + komunikasi siswa (read-only)
│   │   │   ├── keuangan_repository.dart   # keuangan (K1–K11) + dokumen privat
│   │   │   └── private_document_service.dart # save bytes ke app-documents dir + open_filex
│   │   ├── application/
│   │   │   ├── siswa_providers.dart       # repository + FutureProviders (+ autoDispose.family)
│   │   │   └── absensi_notifiers.dart    # state absensi khusus (rekap + list)
│   │   └── presentation/
│   │       ├── siswa_shell.dart           # Scaffold + NavigationBar (5 tab, IndexedStack)
│   │       ├── beranda/  akademik/  keuangan/  notifikasi/  pengumuman/  profil/
│   ├── guru/                     # LENGKAP — lihat §13 (Guru Module)
│   │   ├── data/
│   │   │   ├── models/           # guru.dart, absensi.dart, penilaian.dart (manual)
│   │   │   └── guru_repository.dart      # G1–G30 (22 endpoint yang dipakai) + mutasi
│   │   ├── application/
│   │   │   ├── guru_providers.dart        # repository + providers + paged notifiers
│   │   │   └── guru_tab_index.dart        # GuruTabIndex
│   │   └── presentation/
│   │       ├── guru_shell.dart             # Scaffold + NavigationBar (5 tab, IndexedStack)
│   │       ├── beranda/  kelas/  jadwal/  absensi/  penilaian/  notifikasi/  profil/
│   └── wali/presentation/wali_home_page.dart     # placeholder
└── shared/
    ├── data/paged_state.dart             # PagedResult (dipakai siswa & guru)
    ├── models/                           # page_meta.dart, notifikasi.dart
    ├── application/paged_notifier.dart   # base PagedNotifier (generic list)
    ├── providers/core_providers.dart     # appConfig, storage, dio, authRepository
    └── widgets/role_placeholder_page.dart # Scaffold placeholder + logout actions
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
/guru                                 # shell guru (NavigationBar: Beranda, Kelas,
                                      # Absensi, Penilaian, Profil)
/guru/jadwal · /guru/jadwal/:id
/guru/kelas/:id · /guru/kelas/:id/siswa
/guru/penilaian/:id · /guru/penilaian/:id/nilai
/guru/absensi/harian/:id · /guru/absensi/harian/:id/edit
/guru/absensi/harian/grid/:kelasId
/guru/absensi/perjam/:id · /guru/absensi/perjam/:id/edit
/guru/absensi/perjam/grid/:pertemuanId
/guru/notifikasi · /guru/notifikasi/:id
/wali                                 # placeholder
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
- Fitur wali (masih placeholder).
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
(`shared/application/paged_notifier.dart` + `shared/data/paged_state.dart`) — state `items/meta/
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

## 13. Guru Module (Phase 4)

Area guru berfitur penuh di atas kontrak `/api/v1/guru/*`:

| Kelompok | Endpoint backend | Halaman/Route |
|---|---|---|
| Beranda | `GET /guru/beranda` | tab Beranda |
| Profil | `GET /guru/profil` | tab Profil |
| Kelas | `GET /guru/kelas`, `GET /guru/kelas/{id}`, `GET /guru/kelas/{id}/siswa` | tab Kelas, `/guru/kelas/:id`, `/siswa` |
| Penugasan | `GET /guru/penugasan` | tab Penilaian |
| Jadwal | `GET /guru/jadwal`, `GET /guru/jadwal/hari-ini`, `GET /guru/jadwal/{id}` | `/guru/jadwal`, detail |
| Absensi harian | `GET /guru/absensi/harian`, `GET .../harian/{id}`, `GET /guru/kelas/{id}/absensi`, `POST /guru/absensi/harian`, `PATCH .../harian/{id}` | tab Absensi · Harian, grid, edit |
| Absensi per jam | `GET /guru/absensi/perjam`, `GET .../perjam/{id}`, `GET .../pertemuan`, `GET .../pertemuan/{id}`, `POST /guru/absensi/perjam`, `PATCH .../perjam/{id}` | tab Absensi · Per Jam |
| Penilaian | `GET /guru/penilaian/penugasan/{id}`, `GET .../siswa`, `PUT .../nilai`, `PATCH .../nilai` | `/guru/penilaian/:id`, `/nilai` |
| Notifikasi | `GET /guru/notifikasi*` | `/guru/notifikasi`, detail |

**Aturan khusus:**
- `GuruRepository` TIDAK PERNAH mengirim `guru_id`/`user_id`; identitas dari token.
- `GET /guru/absensi/perjam/pertemuan` memicu `generateUntukTanggal()` di backend
  (snapshot idempoten) → hanya dipanggil saat pengguna membuka tab Per Jam,
  bukan di dashboard/prefetch.
- Isi/edit absensi: hanya kelas yang `diajar` (backend menegakkan); H+1 enforced
  backend; grid dipakai untuk simpan massal (upsert per siswa, payload
  `{tanggal, kelas_id, records[]}`).
- Penilaian: bobot=100 dan terkunci ditegakkan backend; UI menampilkan
  disabled-mode bila `terkunci` atau `konfigurasi_valid=false` (bukan
  memblokir backend); payload batch `{nilai: {siswa: {komponen: 0..100|null}}}`.
- Bottom navigation 5 tab dengan `IndexedStack` (state preserved); notifikasi
  via icon AppBar Beranda dengan badge unread.
- Shell guru memakai prefix guard `/guru/*` (area role lain → home sendiri).

## 14. Wali Module (Phase 5)

Area wali berfitur penuh di atas kontrak `/api/v1/wali/*` (role `wali`,
`api.role:wali` + `api.akun` + `api.password`) dan grup `/api/v1/keuangan/*`
(role `siswa,wali`). Untuk wali, SEMUA endpoint keuangan JSON mewajibkan
`siswa_id` (query GET / body POST attempt) dan backend menegakkan relasi
verified. Endpoint dokumen privat TIDAK menerima parameter — ownership
dinilai dari token (relasi verified + pembayaran milik anak tsb).

### 14.1 Endpoint yang dipakai

| Kelompok | Endpoint backend | Halaman/Route |
|---|---|---|
| Profil | `GET /wali/profil` | tab Profil |
| Beranda | `GET /wali/beranda` | tab Beranda |
| Daftar anak | `GET /wali/anak` | tab Anak |
| Detail anak | `GET /wali/anak/{siswaId}` | `/wali/anak/:siswaId` |
| Beranda anak | `GET /wali/anak/{siswaId}/beranda` | Detail anak (konteks akademik) |
| Jadwal | `GET /wali/anak/{siswaId}/jadwal` (`hari`/`tanggal`), `GET .../jadwal/hari-ini` | `/wali/anak/:siswaId/jadwal` |
| Absensi | `GET .../absensi/harian`, `GET .../absensi/periode`, `GET .../absensi/perjam` | `/wali/anak/:siswaId/absensi` |
| Nilai | `GET .../nilai` (`semester_id`/`kelas_id` opsional) | `/wali/anak/:siswaId/nilai` |
| Rapor | `GET .../rapor`, `GET .../rapor/{semesterId}/{kelasId}` | `/wali/anak/:siswaId/rapor`, `/wali/anak/:siswaId/rapor/:semesterId/:kelasId` |
| Notifikasi | `GET /wali/notifikasi`, `GET /wali/notifikasi/unread-count`, `GET /wali/notifikasi/{id}`, `PATCH /wali/notifikasi/{id}/read`, `PATCH /wali/notifikasi/read-all` | tab Notifikasi, `/wali/notifikasi/:id` |
| Keuangan | `GET /keuangan/ringkasan`, `GET /keuangan/tagihan[?status]`, `GET /keuangan/tagihan/{id}`, `GET /keuangan/saldo`, `GET /keuangan/pembayaran`, `GET /keuangan/pembayaran/{id}`, `POST /keuangan/pembayaran/attempts`, `GET /keuangan/pembayaran/attempts/{id}`, `GET /keuangan/pembayaran/{id}/bukti`, `GET /keuangan/pembayaran/{id}/kuitansi`, `GET /keuangan/refund/dokumen/{id}` | tab Keuangan, `/wali/anak/:siswaId/keuangan/*` |

`POST /wali/anak/{siswaId}/permintaan-putus` (W5) **tidak diimplementasikan**
(di luar scope Phase 5). Pengumuman wali **tidak tersedia** di backend
(modul pengumuman siswa-scoped) — wali hanya punya notifikasi.

### 14.2 Konteks anak & isolasi cache

- Sub-halaman akademik/keuangan anak memakai `:siswaId` pada **route param**
  (eksplisit, deep-linkable, tidak ambigu).
- Seluruh provider child-scoped adalah `.family` keyed by `siswaId`
  (`FutureProvider.autoDispose.family` untuk one-shot; notifier family
  `.family` dengan konstruktor `Notifier(this.siswaId)` — pola family
  Riverpod 3) → cache anak A tidak pernah tertukar dengan anak B;
  state lama dilepas otomatis (autoDispose) saat tidak ada watcher.
- Tab shell (Beranda/Keuangan) memakai `waliAnakAktifProvider` (turunan dari
  daftar anak + pilihan eksplisit in-memory `selectedAnakIdProvider`):
  hanya anak dengan `bisa_akses_akademik == true` (verdict backend) yang
  eligible; pilihan eksplisit anak pending/rejected/terminated diabaikan
  (fallback ke anak verified pertama menurut urutan backend); null bila
  tidak ada anak verified → UI menampilkan empty-state informatif.
- Pemilihan anak TIDAK dipersistenkan; sesi baru mulai dari default backend.
- Ganti anak → provider family baru → fetch baru dari jaringan; tidak ada
  data "pinjaman" dari cache anak sebelumnya.
- Notifier family per anak dipakai untuk absensi (harian/periode/perjam),
  tagihan (dengan filter status) dan pembayaran (paginated).

### 14.3 Relasi wali↔anak

- Backend adalah otoritas akses: relasi `verified` + `tanggal_berhenti IS NULL`
  (+ `tanggal_mulai <= hari ini` untuk akademik). Flutter TIDAK menghitung
  ulang kebijakan ini — hanya merender `bisa_akses_akademik` dari payload
  backend dan menghormati 403 `AKSES_DITOLAK` (error view + pesan backend).
- Relasi pending/rejected/terminated: tab Anak menampilkan seluruh relasi
  (filter Semua/Terverifikasi/Menunggu/Ditolak/Berakhir) dengan badge status;
  Detail anak menampilkan `RelasiTerkunciBanner` dan TIDAK merender menu
  akademik/keuangan (provider anak-beranda baru dipanggil saat akses ada).
- Tanpa anak verified: Beranda menampilkan status "Belum Ada Relasi Anak",
  tab Keuangan menampilkan `PilihAnakKosong`, quick action akademik
  dinonaktifkan. Tidak ada data akademik/finansial palsu yang ditampilkan.
- Detail anak menampilkan histori relasi (append-only, read-only).

### 14.4 Keamanan

- Route guard prefix `/wali/*` (role siswa/guru ditolak → home masing-masing;
  role wali ditolak dari `/siswa/*` & `/guru/*`); nested routes otomatis
  terlindungi karena pencocokan prefix; guard autentikasi tidak diubah.
- `WaliRepository` TIDAK PERNAH mengirim `user_id`; identitas dari token.
  `siswaId` hanya path parameter yang divalidasi backend tiap request.
- Keuangan wali: `siswa_id` divalidasi backend (relasi verified) tiap request.
- Dokumen privat (bukti/kuitansi/refund) diunduh lewat endpoint backend
  (ownership server-side) → disimpan di folder dokumen aplikasi (BUKAN
  penyimpanan publik) via `PrivateDocumentService` → dibuka via `open_filex`.
  URL dokumen tidak pernah dipublikasikan.
- Payment attempt: client hanya mengirim `tagihan_id` + `siswa_id`; nominal
  SELALU dari server; status settlement tidak pernah di-set dari client;
  `snap_token`/`snap_redirect_url` hanya dibuka via url_launcher.
- Tidak ada mutasi akademik; notifikasi hanya tandai dibaca; badge
  diperbarui setelah aksi (invalidate unread-count).
- Log HTTP tidak pernah mencatat token/dokumen.

### 14.5 Notifikasi & pengumuman

- Notifikasi wali = modul notifikasi (user-scoped — BUKAN per anak):
  list/detail/unread-count/mark-read/read-all; badge unread di shell
  (Notifikasi tab) & beranda; refresh badge setelah aksi mark-all-read
  maupun mark-read.
- Pengumuman wali: **TIDAK TERSEDIA** di backend → tidak ada halaman
  pengumuman untuk wali (bukan pekerjaan yang belum selesai, melainkan
  kontrak backend yang memang tidak menyediakannya).
