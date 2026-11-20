# IOS RELEASE GUIDE — SIAKAD Mobile

**Status: Lingkungan pengembangan saat ini Windows — build iOS TIDAK dapat
diverifikasi di sesi ini.** Gunakan panduan ini di macOS untuk menyiapkan
distribusi iOS. Tidak ada klaim iOS release berhasil di sesi ini.

## Audit statis yang dilakukan di sesi ini (Windows)

| Aspek | Status |
|---|---|
| Bundle identifier (Runner) | `com.apps.siakad` — `PRODUCT_BUNDLE_IDENTIFIER = com.apps.siakad` (3 build configs: Debug/Release/Profile), `ios/Runner.xcodeproj/project.pbxproj` |
| Bundle identifier (tests) | `com.apps.siakad.RunnerTests` — `ios/Runner.xcodeproj/project.pbxproj` (3 build configs) & `macos/Runner.xcodeproj/project.pbxproj` (3 build configs) |
| Bundle identifier (macOS Runner) | `com.apps.siakad` — `macos/Runner/Configs/AppInfo.xcconfig` |
| Application ID | `com.apps.siakad` (diterapkan; verifikasi statik dalam `test/build_configuration_test.dart` — Phase H) |
| Application ID lama | `com.example.siakadMobile` / `com.example.siakad_mobile` — **tidak lagi aktif** dalam konfigurasi build |
| Display name | `Siakad Mobile` (CFBundleDisplayName) |
| ATS | Tidak ada exception — App Transport Security default: HTTP ditolak. Production WAJIB HTTPS ✓ |
| Deployment target | iOS 15.0 (`IPHONEOS_DEPLOYMENT_TARGET = 15.0` dalam pbxproj) |
| Permission descriptions | Info.plist tidak meminta camera/mic/lokasi/kontak — aplikasi tidak menggunakannya ✓ |
| Team ID / signing | **Tidak diset — tidak dinyatakan (jangan invent: ga ada value di pbxproj).** Apple Developer account diperlukan; pilih Team di Xcode & daftarkan bundle ID di App Store Connect |
| Build number/version | Dari pubspec (`version: 1.0.0+1`) |
| RunnerTests | Template default (tidak dipakai di CI sesi ini) |

## Prasyarat (macOS + Xcode)

1. macOS dengan Xcode terbaru (sesuai requirement Flutter SDK).
2. **Apple Developer Program** (Apple ID + membership aktif) untuk distribusi.
3. macOS dengan perangkat iPhone untuk UAT fisik.

## Langkah persiapan

1. Clone repo ke macOS, `flutter pub get`.
2. Buka `ios/Runner.xcworkspace` di Xcode.
3. Target `Runner` → Signing & Capabilities:
   - Centang **Automatically manage signing**.
   - Pilih **Team** (Apple Developer account).
   - Bundle identifier: `com.apps.siakad` (sudah diterapkan statik).
4. Capability: tidak diperlukan untuk fitur saat ini (tidak ada push
   notification — bila suatu hari ditambahkan, daftarkan APNs + entitlements).
5. Build (untuk mencoba):
   ```bash
   flutter build ios --release --dart-define=API_BASE_URL=https://<host>/api/v1
   ```
   (API_BASE_URL = domain produksi HTTPS asli milik instansi — jangan gunakan
   contoh/placeholder dalam konfigurasi produksi.)
6. Archive (Product → Archive) → Upload ke App Store Connect → TestFlight →
   uji di perangkat → submit review.
7. Distribusi internal/TestFlight dengan `version` di `pubspec.yaml`.

## Catatan teknis iOS (hasil audit statik)

- `CFBundleIdentifier` = `$(PRODUCT_BUNDLE_IDENTIFIER)` (dinamis — mengikuti
  pbxproj).
- Runner: `PRODUCT_BUNDLE_IDENTIFIER = com.apps.siakad` (semua 3 build configs).
- RunnerTests: `PRODUCT_BUNDLE_IDENTIFIER = com.apps.siakad.RunnerTests` (3).
- macOS target: `macos/Runner/Configs/AppInfo.xcconfig` →
  `PRODUCT_BUNDLE_IDENTIFIER = com.apps.siakad`.
- Info.plist (Runner): `CFBundleIdentifier = $(PRODUCT_BUNDLE_IDENTIFIER)`.
- Deployment target: iOS 15.0.

## Checklist khusus iOS sebelum rilis

- [ ] Apple Developer account aktif & team terpilih di Xcode
- [ ] Bundle identifier resmi terdaftar di App Store Connect (`com.apps.siakad`)
- [ ] `API_BASE_URL` HTTPS (ATS menolak HTTP — tidak ada exception untuk produksi)
- [ ] Screens disusun sesuai wajib Apple (privacy policy URL, support URL)
- [ ] Screenshots untuk App Store (6.7", 6.5", 5.5", iPad bila relevan)
- [ ] App Review notes: sediakan kredensial demo untuk siswa/guru/wali
- [ ] TestFlight: minimal 1 siklus uji fisik sebelum rilis publik
- [ ] Crashlytics/observability dipertimbangkan untuk rilis production

## Blocker di sesi Windows ini

- Build iOS tidak bisa diverifikasi/run di Windows (Apple toolchain).
- Butuh macOS + Apple Developer account + Team + sertifikat — blokir lain:
  (1) pendaftaran bundle ID di App Store Connect, (2) certificate Team
  selection di Xcode.

## Batasan yang tersisa

- Build iOS **tidak dapat diverifikasi di sesi Windows ini** — klaim bahwa
  iOS berjalan/build sukses HANYA setelah di-test di macOS dengan Xcode.
- Tidak ada Team ID yang dinyatakan (Apple Developer akun diperlukan).
- Identifier sebelumnya (`com.example.siakadMobile`) telah diubah ke
  `com.apps.siakad` — koordinasikan migrasi dengan pemilik aplikasi.
