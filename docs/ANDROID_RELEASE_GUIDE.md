# ANDROID RELEASE GUIDE — SIAKAD Mobile

Panduan membangun APK/AAB release SIAKAD Mobile untuk Android.

**Status saat dokumen ini dibuat: signing BELUM tersedia — release artifact
belum dapat dihasilkan.** `flutter build apk --release` GAGAL JELAS dengan
pesan instruksi (tidak pernah diam-diam memakai debug key). Lihat bagian
"Membuat Release Signing" di bawah.

## Prasyarat

1. Flutter SDK sesuai `.dart_tool/version` (stable terpasang di mesin).
2. Android SDK (via Android Studio) + Gradle wrapper (disertakan).
3. Java 17+ (sesuai `compileOptions` / AGP 9.x).
4. `android/key.properties` + keystore release (bagian "Release Signing").
5. URL backend production (**HTTPS**), mis. `https://siakad.sekolah.sch.id/api/v1`.

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

1. **Jangan membuat keystore di mesin ini tanpa instruksi pemilik proyek.**
   Pembuatan key dilakukan PEMILIK APLIKASI:
   ```powershell
   keytool -genkeypair -v `
     -keystore android/app/siakad-release.jks `
     -alias siakad-release -keyalg RSA -keysize 2048 `
     -validity 10000
   ```   # isi password & data secara interaktif; JANGAN simpan password di script/chat
2. Salin `android/key.properties.example` → `android/key.properties`, isi:
   ```properties
   storeFile=app/siakad-release.jks
   storePassword=<password-keystore>
   keyAlias=siakad-release
   keyPassword=<password-key>
   ```
3. `.gitignore` sudah mengecualikan `key.properties`, `*.keystore`, `*.jks`.
   **Jangan pernah commit file tersebut.**
4. Verifikasi: `git status --short` tidak menampilkan `key.properties` maupun
   file keystore.
5. Backup keystore di lokasi terpisah — kehilangan keystore = tidak bisa
   memperbarui aplikasi di Play Store.

Setelah tersedia, build release akan memakai `signingConfigs.release`
(otomatis via `android/app/build.gradle.kts`). Tanpa `key.properties`,
`assembleRelease`/`bundleRelease` GAGAL JELAS (lihat `build.gradle.kts`).

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

Sumber: `pubspec.yaml` → `version: 1.0.0+1`

- `versionName` = `1.0.0`, `versionCode` = `1`.
- Naikkan untuk setiap distribusi: `version: 1.0.1+2`, dst.
- Jangan mengganti application ID `com.example.siakad_mobile` tanpa
  persetujuan pemilik aplikasi (terkait instalasi yang sudah ada).

## Output Artifact

- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk` (~234 MB)
- Release APK: `build/app/outputs/flutter-apk/app-release.apk` (jika berhasil)
- Release AAB: `build/app/outputs/bundle/release/app-release.aab` (jika berhasil)

## Instalasi & UAT

```powershell
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Lihat `CHECKLIST_FINAL_UAT_RELEASE.md` — seluruh item fisik saat ini
**NOT TESTED** dan menunggu pengujian Anda.

## Crash/Symbol Map

Dart obfuscation TIDAK diaktifkan (menjaga keterbacaan crash stack trace).
Jika suatu saat diaktifkan:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=<dir>
```

`<dir>` berisi `app.*.map.json` — simpan aman di luar repository, dan gunakan
`flutter symbolize -i <stacktrace.txt> -o out.txt` untuk membaca trace.

## Batasan lingkungan

- Tidak ada keystore → release artifact **belum dapat dihasilkan** di sesi ini
  (build `--release` gagal jelas; lihat laporan Phase 7).
- Pengujian fisik, screenshot, dan ukuran artifact release = **NOT TESTED** /
  **BLOCKED**.
- URL production TIDAK boleh ditebak; aplikasi gagal startup bila tidak diisi.

## Prosedur distribusi

1. Keystore tersedia + `key.properties` diisi pemilik aplikasi.
2. `flutter analyze`, `flutter test`, `dart format .` → bersih.
3. AAB release dibangun dengan `API_BASE_URL=https://...`.
4. Upload ke Play Console (deret internal → closed testing → production) —
   di luar scope agent; dilakukan pemilik aplikasi.
5. Perbarui `versionCode`, commit tag rilis, dan tag di changelog aplikasi.
