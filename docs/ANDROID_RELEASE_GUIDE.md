# ANDROID RELEASE GUIDE — SIAKAD Mobile

Panduan membangun APK/AAB release SIAKAD Mobile untuk Android.

**Status saat dokumen dibuat: `signing PENDING` — keystore tidak tersedia.**
Release artifact **belum dapat dihasilkan** sampai pemilik proyek membuat
keystore (lihat bagian "Persiapan Keystore Windows" di bawah).
`flutter build apk --release` GAGAL JELAS dengan pesan instruksi (tidak pernah
diam-diam memakai debug key — lihat `android/app/build.gradle.kts`).

## Aplikasi ID (Permanen)

Application ID permanen: **`com.apps.siakad`** — diterapkan di:

- `android/app/build.gradle.kts`: `namespace = "com.apps.siakad"` &
  `applicationId = "com.apps.siakad"`.
- `android/app/src/main/kotlin/com/apps/siakad/MainActivity.kt`:
  `package com.apps.siakad`.
- Diterapkan statik dalam `test/build_configuration_test.dart` (di Phase H).

**Peringatan:** perubahan application ID memiliki sifat breaking — instalasi
ap versi sebelumnya (`com.example.siakad_mobile`) bertentangan (install
ulang diperlukan). Koordinasikan dengan pemilik aplikasi.

## Prasyarat

1. Flutter SDK sesuai `.dart_tool/version` (stable terpasang di mesin).
2. Android SDK (via Android Studio) + Gradle wrapper (disertakan).
3. Java 17+ (sesuai `compileOptions` / AGP 9.x).
4. `android/key.properties` + keystore release (bagian "Persiapan Keystore
   Windows" & "Release Signing").
5. URL backend production (**HTTPS**), mis.
   `https://siakad.sekolah.sch.id/api/v1` — gunakan domain produksi asli milik
   instansi/pemilik proyek, jangan gunakan contoh/placeholder sebagai
   konfigurasi produksi.

## Konfigurasi API (wajib)

Build release tidak boleh memakai default development (`http://10.0.2.2:8000`).
Pada release/profile, `AppConfig.fromEnvironment()` mewajibkan:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<host>/api/v1
flutter build appbundle --release --dart-define=API_BASE_URL=https://<host>/api/v1
```

- Tanpa `API_BASE_URL` → aplikasi **gagal saat startup** dengan error yang jelas.
- URL `http://` tanpa `API_ALLOW_HTTP_IN_RELEASE=true` → gagal (production
  wajib HTTPS). Pengecualian hanya untuk pengujian LAN interim:
  `--dart-define=API_ALLOW_HTTP_IN_RELEASE=true` (JANGAN untuk produksi).
- Prefix `/api/v1` disertakan dalam base URL (mis. `https://host/api/v1`).
- `--dart-define` **bukan** tempat secret — semua nilainya ter-embed di APK
  dan dapat diekstrak. Jangan pernah taruh key/token di `--dart-define`.

## Release Signing

### Status keystore

- **`android/key.properties` TIDAK ada** saat ini (disadari — file tidak
  dibuat). Signing release belum tersedia.
- **Kita tidak membuat keystore otomatis tanpa keterlibatan pemilik.**
  Pembuatan dilakukan PEMILIK APLIKASI.

### Persiapan Keystore (Windows) — perintah eksekusi

Simpan keystore di **luar repository** (contoh path aman).

```powershell
# 1. Buat keystore (jalankan sekali, simpan di LUAR repository)
keytool -genkeypair -v `
  -keystore "$HOME\siakad-keys\siakad-release.jks" `
  -alias siakad-release -keyalg RSA -keysize 2048 `
  -validity 10000
#    Isi password & data secara interaktif; JANGAN simpan password di script/chat/repo.

# 2. Salin android/key.properties.example -> android/key.properties, isi (lihat contoh di atas):
#    storeFile=$HOME\siakad-keys\siakad-release.jks   (path ABSOLUT, atau relatif terhadap dir android/)
#    storePassword=<password-keystore>
#    keyAlias=siakad-release
#    keyPassword=<password-key>

# 3. Backup keystore & password (lihat "Backup keystore & password" di bawah).
```

### Release Signing (aplikasi)

1. Konfigurasi `android/key.properties`:
   ```properties
   storeFile=$HOME\siakad-keys\siakad-release.jks
   storePassword=<password-keystore>
   keyAlias=siakad-release
   keyPassword=<password-key>
   ```
2. `.gitignore` sudah mengecualikan `key.properties`, `*.keystore`, `*.jks`.
   **Jangan pernah commit file tersebut.**
3. Verifikasi: `git status --short` tidak menampilkan `key.properties` maupun
   file keystore.
4. Backup keystore & password — lihat bagian di bawah.
5. Selesai. `android/app/build.gradle.kts` otomatis menggunakan
   `signingConfigs.release` (via `android/key.properties`). Tanpa
   `key.properties`, `assembleRelease`/`bundleRelease` GAGAL JELAS (lihat
   `build.gradle.kts`). **Tidak ada fallback signing debug.**

### Backup keystore & password

- **Keystore:** kehilangan keystore = tidak bisa memperbarui aplikasi di
  Play Store. Backup ke lokasi terpisah (hard disk cadangan atau media aman,
  tidak di server kode kontrolan, tidak didistribusikan publik).
- **Password:** simpan di password manager perusahaan, atau nota sandi
  terpisah dari `key.properties` (file ini gitignored, tetap lindungi).

## Build Commands

```powershell
# Debug APK (untuk UAT harian)
flutter build apk --debug

# Release APK (setelah signing tersedia)
flutter build apk --release --dart-define=API_BASE_URL=https://<host>/api/v1

# Release App Bundle untuk Play Store
flutter build appbundle --release --dart-define=API_BASE_URL=https://<host>/api/v1
```

> R8/resource shrinking sengaja TIDAK diaktifkan: aplikasi mayoritas Dart
> murni dan plugin (open_filex, flutter_secure_storage) tidak memerlukan
> ProGuard rules; mengaktifkan tanpa pengujian perangkat berisiko merusak
> fitur. Keputusan dapat ditinjau bersama saat uji perangkat.

## Versi & Versioning

Sumber: `pubspec.yaml` → `version: 1.0.0+1`.

- `versionName` = `1.0.0`, `versionCode` = `1`.
- Naikkan untuk setiap distribusi (contoh `version: 1.0.1+2`).
- Application ID = `com.apps.siakad` (permanent; lihat bagian atas).
- Bump `versionCode` + commit + tag rilis di changelog aplikasi.

## Output Artifact

- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk` (~246 MB)
- Release APK: `build/app/outputs/flutter-apk/app-release.apk` (jika berhasil)
- Release AAB: `build/app/outputs/bundle/release/app-release.aab` (jika berhasil)

## Instalasi & UAT

```powershell
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Lihat `CHECKLIST_FINAL_UAT_RELEASE.md` — Checklist fisik dicabut di bawah:
**Redmi 9A (UAT fisik)**, berdiri sendiri dari automated testing.

## Crash/Symbol Map

Dart obfuscation TIDAK diaktifkan (menjaga keterbacaan crash stack trace).
Jika suatu saat diaktifkan:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=<dir>
```

`<dir>` berisi `app.*.map.json` — simpan aman di luar repository, dan gunakan
`flutter symbolize -i <stacktrace.txt> -o out.txt` untuk membaca trace.

## Batasan lingkungan

- Signing: `android/key.properties` + keystore **tidak dibuat** di sesi ini
  (owner bertanggung jawab); kami menyediakan perintah Windows di atas.
- Release artifact **belum dapat dihasilkan** di sesi ini — build
  `--release` gagal jelas; lihat `build.gradle.kts`.
- Pendaftaran bundle ID `com.apps.siakad` (iOS) & `com.apps.siakad` (macOS)
  di App Store Connect — dilakukan owner, bukan di sesi ini.
- UDP/updater: aplikasi masih versi `1.0.0+1`.

## Prosedur distribusi

1. Keystore tersedia + `android/key.properties` diisi pemilik aplikasi.
2. `flutter analyze`, `flutter test`, `dart format .` → bersih.
3. `flutter build apk --release --dart-define=API_BASE_URL=https://...` &
   `flutter build appbundle --release --dart-define=API_BASE_URL=https://...`.
4. Install ke Redmi 9A → jalankan **Redmi 9A checklist** (UAT fisik,
   `CHECKLIST_FINAL_UAT_RELEASE.md`).
5. Upload ke Play Console (deret internal → closed testing → production) —
   di luar scope agent; dilakukan pemilik aplikasi.
6. Perbarui `versionCode`, commit tag rilis, dan tag di changelog aplikasi.
