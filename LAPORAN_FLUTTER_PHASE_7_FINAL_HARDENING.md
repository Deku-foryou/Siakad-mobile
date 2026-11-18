# LAPORAN FLUTTER PHASE 7 — FINAL HARDENING & RELEASE PREPARATION

**Tanggal:** 2026-11-17 · **Status:** **PASS WITH LIMITATIONS**

> **Catatan status:** kode & konfigurasi lolos HARDENING (analyze bersih,
> 339/339 automated test lulus, APK debug ter-build, release signing
> TERSEDIA namun **belum diisi** sehingga release artifact **tidak dapat
> dihasilkan**; manual UAT & live backend & Midtrans Sandbox = **NOT
> TESTED**). Aplikasi **bukan** "production-ready" secara rilis — ia siap
> masuk UAT akhir & distribusi setelah signing + UAT dipenuhi.

---

## 1. Ringkasan audit awal

Diperiksa: pubspec/lock, Android Gradle (kts), manifest main/debug/profile,
Gradle wrapper (9.3.1), AGP (9.1.0), Kotlin (2.4.0), AGP Java 17, Flutter
SDK (stable), `.gitignore`, `key.properties` absence, iOS (Windows audit),
secure storage, interceptor, AppConfig, seluruh fitur siswa/guru/wali,
alur pembayaran, wiring 401 (Phase 6), log.

### Temuan berdasarkan risiko

**Critical**

1. **Release build network & debug-key:**
   - INTERNET permission **hanya** di manifest debug/profile — release
     berpotensi tidak punya akses jaringan (fixed: INTERNET di main).
   - Release `signingConfig = signingConfigs.getByName("debug")` + TODO —
     release APK akan ter-sign dengan debug key (tidak bisa distribusi).
   - Default API `http://10.0.2.2:8000` aktif juga untuk release.
   → **Semua diperbaiki** (lihat §2, §4).

**High**

2. **`android:usesCleartextTraffic` tidak eksplisit** dan tidak ada kebijakan
   HTTPS untuk production; debug LAN developer bisa mendadak gagal setelah
   penguncian — solusi: cleartext=false di main (production HTTPS-only),
   cleartext=true hanya di debug (dev lokal).
3. **Backup Android tidak terkonfigurasi** — token (terenkripsi ESP) dan
   dokumen keuangan berpotensi ikut cloud-backup perangkat.
   → `allowBackup=false` + `fullBackupContent=false` +
   `dataExtractionRules` (exclude semua domain).
4. **`.gitignore` tidak mengecualikan `key.properties`/`*.keystore`/`*.jks`**
   → ditambahkan.
5. **401 mid-session sudah diperbaiki di Phase 6**; ditambah test konkurensi.

**Medium**

6. **Application label** "siakad_mobile" → "SIAKAD" (nama tampil).
7. **`dart-define=API_BASE_URL` wajib untuk release** (bukan opsional) —
   enforced via `kReleaseMode`/`kProfileMode` + `resolveBaseUrl` (pure,
   unit-testable); dev tetap `10.0.2.2`.
8. **pubspec description** placeholder ("A new Flutter project.").
9. **Logging** — `LoggingInterceptor` hanya method+path; diverifikasi tidak
   memuat Authorization/body/token via test capture.

**Low**

10. Application ID `com.example.siakad_mobile` (contoh) — TIDAK diubah
    (keputusan distribusi pemilik aplikasi; penggantian = perubahan
    instalasi; didokumentasikan, menunggu keputusan).
11. iOS bundle id `com.example.siakadMobile` (contoh) — sama (butuh keputusan
    org id + macOS untuk diganti).
12. `org.gradle.jvmargs=-Xmx8G` — tidak diubah (bukan penyebab masalah).
13. cupertino_icons 1.0.9 → 2.0.0 tersedia — tidak di-upgrade (tidak perlu
    untuk fungsionalitas; upgrade massal dilarang tanpa alasan).

## 2. Temuan security (setelah hardening)

| Kontrol | Status | Bukti |
|---|---|---|
| Token hanya di flutter_secure_storage (EncryptedSharedPreferences/Keychain) | PASS | Audit `secure_storage_service.dart`, `secure_key_value_store.dart` |
| Tidak ada plaintext storage; tidak ada token di UI/log | PASS | Audit + `logging_interceptor_test.dart` (capture, 2 test) |
| Logout/logout-all membersihkan sesi lokal | PASS | Kode + test Phase 2/6 + `account_session_reset_test.dart` |
| 401 mid-session → sesi bersih + redirect login | PASS | `session_expiry_test.dart` (termasuk **dua 401 konkuren**) |
| Account inactive membersihkan sesi | PASS | Phase 2 (tidak diubah) |
| Force password change tidak bisa dilewati | PASS | Fase 2 (tidak diubah) |
| Session restore tidak redirect loop | PASS | 21 routing test Fase 5, tidak regresi |
| Pergantian akun tidak membawa data lama | PASS | `account_session_reset_test.dart` |
| Provider data sensitif dibersihkan saat sesi berakhir | PASS | autoDispose + accountSessionResetProvider |
| Secure storage: fail-fast, tidak ada silent insecure fallback | PASS | v11 defaults: RSA-OAEP + AES-GCM, API 23+; resetOnError=true (token saja — user re-login) |
| Backup policy tidak membocorkan token/dokumen | PASS | allowBackup=false + dataExtractionRules exclude-all |
| Tidak ada credential/serverKey/payment secret di source | PASS | Grep audit: bersih (hanya docs) |
| Dokumen privat (kuitansi/bukti/refund) via endpoint privat | PASS | Fase 3–6; tidak dipublikasikan |
| Payment URL/token tidak di log | PASS | Audit + logging test |
| Session expiry race (restore vs logout vs 401) | PASS | `_handleSessionExpired` idempotent (hanya bereaksi saat authenticated); test konkuren lulus |
| Notifikasi session expiry tidak berulang | PASS | Idempotent + test konkuren |

## 3. Temuan API/network

| Kontrol | Status | Bukti |
|---|---|---|
| Base URL via `--dart-define`; tidak hardcode production | PASS | `AppConfig`; grep: hanya `10.0.2.2` dev (debug-only) |
| `localhost`/`10.0.2.2` tidak aktif di release | PASS | `resolveBaseUrl(release: true)` mewajibkan URL eksplisit https |
| Prefix `/api/v1` tidak terduplikasi | PASS | `baseUrl` dipakai apa adanya; endpoint `/siswa/*` dst. menyertakan prefix dari base |
| Validasi base URL (format/host) | PASS | `normalizeBaseUrl` (throw ArgumentError) + test |
| Release HTTPS-only | PASS | `resolveBaseUrl(release)` — https wajib (escape hatch eksplisit `API_ALLOW_HTTP_IN_RELEASE=true`) |
| Cleartext traffic produksi ditolak | PASS | `usesCleartextTraffic="false"` main manifest |

## 4. Android release readiness

| Item | Status |
|---|---|
| Manifest production (INTERNET, SIAKAD, backup rules, no cleartext) | ✅ Perbaikan diterapkan; merged debug manifest terverifikasi |
| Debug manifest: INTERNET + cleartext dev (tools:replace) | ✅ teruji (debug APK build sukses) |
| Signing release terpisah dari debug | ✅ Dikonfigurasi via `android/key.properties` (tidak ada di repo) |
| Build release TANPA signing → **gagal jelas** (bukan debug key) | ✅ Diverifikasi: `assembleRelease` GAGAL dengan pesan instruksi |
| Keystore/password tidak di repo/Git | ✅ `.gitignore` + `key.properties.example` (placeholder) |
| Application ID | ⚠️ `com.example.siakad_mobile` — dipertahankan; perlu keputusan pemilik aplikasi |
| Version | `1.0.0+1` (pubspec) — perlu bump per distribusi |
| R8/shrinkResources | ❌ Tidak diaktifkan (sengaja; alasan di release guide) |
| Dart obfuscation | ❌ Tidak diaktifkan (crash trace tetap terbaca); symbol map guide tersedia |
| Permission yang dipakai | INTERNET (+plugin open_filex memakai READ_MEDIA/READ_EXTERNAL — plugin-injected, wajar) |

## 5. iOS release readiness

| Item | Status |
|---|---|
| Audit statis (Swift/Xcode project, iOS 15, ATS default, no ATS exception, no camera/mic/lokasi perm) | ✅ (dokumen `docs/IOS_RELEASE_GUIDE.md`) |
| Bundle identifier `com.example.siakadMobile` | ⚠️ Contoh Flutter — perlu keputusan org id |
| Signing (Team, cert, provisioning) | ❌ Belum (butuh macOS + Apple Developer) |
| Build iOS / TestFlight / App Store | ❌ NOT TESTED (Windows; tidak ada klaim) |

## 6. Signing status

**BELUM TERSEDIA.** Tidak ada keystore di mesin ini dan pembuatannya
*hanya* hak pemilik aplikasi. `android/key.properties.example` tersedia
sebagai template; `build.gradle.kts` mengonfigurasi signing release dari
`key.properties` bila ada. Bukti: `flutter build apk --release` →
`assembleRelease` GAGAL dengan pesan:

> "Release signing belum dikonfigurasi. Buat android/key.properties dari
> key.properties.example, sediakan keystore, lalu jalankan ulang …"

Key alias/password **tidak pernah** dicetak; **tidak ada keystore yang
dibuat** (di luar scope instruksi).

## 7. Payment safety status

| Kontrol | Status |
|---|---|
| Flutter tidak menentukan nominal (selalu dari backend) | PASS (tidak berubah) |
| Client tidak men-settle pembayaran; status hanya dari server | PASS (attempt status polling; tidak ada settle endpoint di client) |
| snap_token/redirect_url tidak masuk log | PASS |
| Payment attempt via backend; retry tidak duplikasi tanpa backend guard | PASS |
| Dokumen privat via endpoint backend | PASS |
| 404/403/503 tertangani; tidak ada transaksi palsu | PASS |
| Midtrans Sandbox E2E | **BLOCKED** — credential Midtrans belum tersedia; mock test ≠ Sandbox E2E; tidak diklaim |

## 8. Dependency health

`flutter pub outdated` (informasi, tidak diubah):
- cupertino_icons 1.0.9 (latest 2.0.0 — tidak perlu untuk fungsionalitas),
  url_launcher_android/objective_c/vector_math/etc. — minor/patch, locked.
- Tidak ada dependency tidak terpakai yang jelas; tidak ada upgrade massal.
- Tidak ada dependency baru ditambahkan di Phase 7.

## 9. Hasil automated tests

| Metrik | Nilai |
|---|---|
| Total test | **339** (329 Phase 6 + **10 baru**) |
| Baru Phase 7 | 6 (`resolveBaseUrl` kebijakan build) + 3 (logging interceptor capture) + 1 (401 konkuren) |
| Gagal | 0 |
| Dilewati | 0 |
| `dart format .` | 151 file (2 changed) |
| `flutter analyze` | **No issues found** (run 111s) |
| `flutter test` | **+339 All tests passed** |

Batas pengujian: seluruhnya via mock (`FakeHttpClientAdapter`) —
**bukan live backend**; tidak ada klaim integration/Sandbox E2E lulus.

## 10. Hasil debug build

`flutter build apk --debug` → **SUKSES** (`app-debug.apk`, 122.0s;
234.61 MB; hanya warning Gradle `System::load` standar). Merged manifest
terverifikasi: INTERNET, label SIAKAD, allowBackup=false,
dataExtractionRules, cleartext=true (debug-only).

## 11. Hasil release APK

**BLOCKED — tidak dapat dihasilkan** (signing belum tersedia). Terverifikasi
gagal dengan pesan jelas (bukan diam-diam pakai debug key):
`assembleRelease` → "Release signing belum dikonfigurasi." (§6).

## 12. Hasil release AAB

**BLOCKED** — sama seperti §11 (`flutter build appbundle --release` akan
gagal dengan pesan yang sama).

## 13. File berubah

**Baru (8):** `CHECKLIST_FINAL_UAT_RELEASE.md`,
`docs/ANDROID_RELEASE_GUIDE.md`, `docs/IOS_RELEASE_GUIDE.md`,
`android/key.properties.example`,
`android/app/src/main/res/xml/data_extraction_rules.xml`,
`lib/core/network/session_expiry.dart` (Phase 6, tetap),
`lib/shared/application/account_session_reset.dart` (Phase 6, tetap),
`test/core/network/logging_interceptor_test.dart`,
`LAPORAN_FLUTTER_PHASE_7_FINAL_HARDENING.md`.

**Dimodifikasi (11):** `.gitignore`, `android/app/build.gradle.kts`
(release signing lokal), `android/app/src/main/AndroidManifest.xml`
(INTERNET, SIAKAD, backup rules, no cleartext), `android/app/src/debug/
AndroidManifest.xml` (cleartext dev only), `lib/core/config/app_config.dart`
(release gate + `resolveBaseUrl` testable), `lib/core/network/
logging_interceptor.dart` (injectable logger), `pubspec.yaml`
(description), `test/core/config/app_config_test.dart`,
`test/features/auth/session_expiry_test.dart`, `docs/FLUTTER_ARCHITECTURE.md`
(+§16), `android/app/src/debug/AndroidManifest.xml` (lihat atas).

## 14. Keterbatasan

1. Signing belum tersedia → release APK/AAB **terblokir** (harus dibuat
   pemilik aplikasi — see §6).
2. Manual UAT fisik = NOT TESTED (`CHECKLIST_FINAL_UAT_RELEASE.md`).
3. Live backend & Midtrans Sandbox E2E = NOT TESTED/BLOCKED.
4. iOS build/TestFlight = NOT TESTED (Windows).
5. Dark mode hanya terverifikasi otomatis (belum inspeksi fisik).
6. Layout 320×568 lulus test otomatis; verifikasi fisik menunggu UAT.
7. Distribution (Play Console/App Store) = di luar agent; dilakukan pemilik.

## 15. UAT yang belum dilakukan

Semua item §A–E di `CHECKLIST_FINAL_UAT_RELEASE.md` "NOT TESTED" kecuali
yang secara eksplisit ditandai PASS (F5–F8, statis). Pengguna menjalankan
UAT fisik.

## 16. Kebutuhan deployment eksternal

- Keystore release (pemilik) → `android/key.properties`.
- Backend production HTTPS + (opsional) Midtrans sandbox/produksi untuk E2E.
- Apple Developer account (iOS).
- Play Console (AAB) + App Store Connect (iOS).

## 17. Konfirmasi

- Backend Laravel/database/migration/seeder **TIDAK diubah** (tidak ada file
  di `C:\project-reyhan\template web` yang disentuh).
- **`.env` TIDAK diakses** (penuh maupun sebagian); `key.properties` tidak
  dibuat/tidak dibaca (hanya `.example`); tidak ada keystore dibuat.
- **Tidak ada Git write** (tidak ada add/commit/push/reset/checkout/stash/
  clean/restore); hanya `git status/diff/ls-files` read-only.
- Kebijakan keuangan/akademik/absensi/penilaian/relasi wali **tidak diubah**.

## 18. Git status akhir (read-only) & ringkasan

`git status --short`:

```
 M .gitignore
 M android/app/build.gradle.kts
 M android/app/src/debug/AndroidManifest.xml
 M android/app/src/main/AndroidManifest.xml
 M docs/FLUTTER_ARCHITECTURE.md
 M lib/core/config/app_config.dart
 M lib/core/network/logging_interceptor.dart
 M pubspec.yaml
 M test/core/config/app_config_test.dart
 M test/features/auth/session_expiry_test.dart
?? CHECKLIST_FINAL_UAT_RELEASE.md
?? android/app/src/main/res/xml/
?? android/key.properties.example
?? docs/ANDROID_RELEASE_GUIDE.md
?? docs/IOS_RELEASE_GUIDE.md
?? test/core/network/logging_interceptor_test.dart
?? LAPORAN_FLUTTER_PHASE_7_FINAL_HARDENING.md
```

`git diff --check`: hanya warning LF→CRLF (tidak ada whitespace error).

**Ringkasan:** Phase 7 = PASS WITH LIMITATIONS. Keamanan token/session
diperketat + diverifikasi (incl. 401 konkuren), release configuration
benar & fail-fast (signing clear failure), backup Android aman, logging
terverifikasi tidak bocor, 339/339 test lulus, APK debug ter-build.
Terblokir untuk rilis: signing keystore (pemilik), manual UAT fisik,
live backend & Midtrans Sandbox E2E, iOS build. Tidak ada yang diklaim
melebihi bukti; aplikasi **bukan** yet production-released.
