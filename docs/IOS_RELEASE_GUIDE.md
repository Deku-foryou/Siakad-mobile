# IOS RELEASE GUIDE — SIAKAD Mobile

**Status: Lingkungan pengembangan saat ini Windows — build iOS TIDAK dapat
diverifikasi di sesi ini.** Gunakan panduan ini di macOS untuk menyiapkan
distribusi iOS. Tidak ada klaim iOS release berhasil di sesi ini.

## Audit yang dapat dilakukan di Windows (sudah dilakukan)

| Aspek | Status |
|---|---|
| Config proyek | Xcode project (Swift) standar; `Runner.xcodeproj` valid; target deployment iOS 15.0 |
| Bundle identifier | `com.example.siakadMobile` (Runner), `com.example.siakadMobile.RunnerTests` (tests) |
| Display name | `Siakad Mobile` (CFBundleDisplayName) |
| ATS | Tidak ada exception — App Transport Security default: HTTP ditolak. Production WAJIB HTTPS ✓ |
| Permission descriptions | Info.plist tidak meminta camera/mic/lokasi/kontak — aplikasi tidak menggunakannya ✓ |
| URL schemes | Tidak ada custom scheme (deep link tidak dipakai) ✓ |
| Secure storage | `flutter_secure_storage` → Keychain (iOS default: accessible setelah first unlock) ✓ |
| iOS build number/version | Dari pubspec (`version: 1.0.0+1`) |
| Signing | Automatic signing belum diuji; butuh Apple Developer akun |
| RunnerTests | Template default (tidak dipakai di CI sesi ini) |

## Prasyarat (macOS + Xcode)

1. macOS dengan Xcode terbaru (sesuai requirement Flutter SDK).
2. **Apple Developer Program** (Apple ID + membership aktif) untuk distribusi.
3. macOS dengan perangkat iPhone untuk UAT fisik.

## Langkah persiapan

1. Clone repo ke macOS, `flutter pub get`.
2. Buka `ios/Runner.xcworkspace` di Xcode.
3. Pilih target `Runner` → Signing & Capabilities:
   - Centang **Automatically manage signing**.
   - Pilih **Team** (Apple Developer account).
   - Bundle identifier: ubah `com.example.siakadMobile` menjadi identifier
     resmi organisasi Anda bila diperlukan (mis. `id.sch.sekolah.siakad`)
     — JANGAN ubah tanpa koordinasi pemilik aplikasi.
4. `PRODUCT_BUNDLE_IDENTIFIER` untuk tests (`...RunnerTests`) sesuaikan bila
   bundle id utama diubah.
5. Capability: tidak diperlukan untuk fitur saat ini (tidak ada push
   notification — bila suatu hari ditambahkan, daftarkan APNs + entitlements).
6. Build:
   ```bash
   flutter build ios --release --dart-define=API_BASE_URL=https://<host>/api/v1
   ```
7. Archive (Product → Archive) → Upload ke App Store Connect → TestFlight →
   uji di perangkat → submit review.
8. Distribusi internal/TestFlight dengan `version` di `pubspec.yaml`.

## Checklist khusus iOS sebelum rilis

- [ ] Apple Developer account aktif & team terpilih di Xcode
- [ ] Bundle identifier resmi terdaftar di App Store Connect
- [ ] `API_BASE_URL` HTTPS (ATS menolak HTTP — tidak ada exception untuk produksi)
- [ ] Screens disusun sesuai wajib Apple (privacy policy URL, support URL)
- [ ] Screenshots untuk App Store (6.7", 6.5", 5.5", iPad bila relevan)
- [ ] App Review notes: sediakan kredensial demo untuk siswa/guru/wali
- [ ] TestFlight: minimal 1 siklus uji fisik sebelum rilis publik
- [ ] Crashlytics/observability dipertimbangkan untuk rilis production

## Batasan yang tersisa

- Bundle identifier `com.example.siakadMobile` — **contoh bawaan Flutter**,
  harus diganti dengan identifier organisasi sebelum rilis publik
  (keputusan pemilik aplikasi; tidak diubah di sesi ini).
- iOS signing, TestFlight, App Store submission — semuanya membutuhkan
  macOS + akun Apple Developer; di luar jangkauan sesi Windows ini.
- Tidak ada klaim bahwa aplikasi iOS berjalan/build sukses.
