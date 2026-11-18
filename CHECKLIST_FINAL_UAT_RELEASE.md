# CHECKLIST FINAL UAT & RELEASE — SIAKAD Mobile

Status pengujian fisik: **NOT TESTED** — pengguna menjalankan sendiri di HP
Android fisik (dan iPhone bila tersedia). JANGAN centang apa pun sebelum
benar-benar dicoba. Status yang sah: `PASS` / `FAIL` / `BLOCKED` /
`NOT TESTED`.

## A. Perangkat fisik

| # | Item | Status | Catatan |
|---|---|---|---|
| A1 | Instalasi fresh (aplikasi belum pernah terpasang) | NOT TESTED | |
| A2 | Login siswa (role guard, shell siswa tampil) | NOT TESTED | |
| A3 | Login guru | NOT TESTED | |
| A4 | Login wali (daftar anak, pemilihan anak) | NOT TESTED | |
| A5 | Pergantian akun (logout → login role lain; data akun lama tidak bocor) | NOT TESTED | |
| A6 | Logout perangkat ini | NOT TESTED | |
| A7 | Logout semua perangkat | NOT TESTED | |
| A8 | Token expired (tunggu > masa token / cabut token di server → app tidak crash, sesi ditutup + diarahkan login) | NOT TESTED | |
| A9 | Koneksi terputus (mode pesawat) → error view ramah, retry bekerja | NOT TESTED | |
| A10 | App background → resume setelah >5 menit (sesi ditampilkan benar; tidak redirect loop) | NOT TESTED | |
| A11 | Rotasi (bila diaktifkan pada perangkat) | NOT TESTED | |
| A12 | Keyboard (form login/ganti password tidak tertutup) | NOT TESTED | |
| A13 | Light / dark mode | NOT TESTED | |
| A14 | Notifikasi (badge, baca satu/semua) | NOT TESTED | |
| A15 | Unduh dokumen privat (kuitansi/bukti) → tersimpan & bisa dibuka | NOT TESTED | |

## B. Fitur akademik (siswa & wali)

| # | Item | Status | Catatan |
|---|---|---|---|
| B1 | Jadwal (filter hari/tanggal, sinkron backend) | NOT TESTED | |
| B2 | Absensi harian + per periode + per jam | NOT TESTED | |
| B3 | Nilai akhir (snapshot final, KKTP) | NOT TESTED | |
| B4 | Rapor (daftar + detail) | NOT TESTED | |
| B5 | Pengumuman (siswa) | NOT TESTED | |
| B6 | Notifikasi (daftar/detail/mark read/mark all) | NOT TESTED | |

## C. Guru

| # | Item | Status | Catatan |
|---|---|---|---|
| C1 | Kelas & siswa | NOT TESTED | |
| C2 | Absensi harian (grid + simpan) | NOT TESTED | |
| C3 | Absensi per jam | NOT TESTED | |
| C4 | Penilaian (input nilai + konfirmasi, anti double-submit) | NOT TESTED | |
| C5 | Notifikasi ikon Beranda | NOT TESTED | |

## D. Wali

| # | Item | Status | Catatan |
|---|---|---|---|
| D1 | Pemilihan anak (verified saja yang eligible) | NOT TESTED | |
| D2 | Isolasi data antar-anak (A → B tidak menampilkan data A) | NOT TESTED | |
| D3 | Akademik anak (jadwal/absensi/nilai/rapor) | NOT TESTED | |
| D4 | Keuangan anak (ringkasan/tagihan/pembayaran/saldo) | NOT TESTED | |
| D5 | Dokumen privat keuangan anak | NOT TESTED | |
| D6 | Anak pending/terminated: banner terkunci; tidak ada data palsu | NOT TESTED | |
| D7 | Notifikasi wali (user-scoped) | NOT TESTED | |

## E. Finance

| # | Item | Status | Catatan |
|---|---|---|---|
| E1 | Daftar tagihan (filter status) | NOT TESTED | |
| E2 | Payment attempt (nominal dari server; konfirmasi sebelum dibuat) | NOT TESTED | |
| E3 | Payment redirect (Midtrans Snap dibuka; kembali ke app tidak auto "lunas") | NOT TESTED | |
| E4 | Verifikasi status dari server (attempt status; berubah hanya dari webhook backend) | NOT TESTED | |
| E5 | Bukti pembayaran | NOT TESTED | |
| E6 | Kuitansi / dokumen refund | NOT TESTED | |
| E7 | Midtrans Sandbox E2E berkonfigurasi valid | NOT TESTED / BLOCKED (credential belum tersedia) | |

## F. Release

| # | Item | Status | Catatan |
|---|---|---|---|
| F1 | Release signing terkonfigurasi (android/key.properties + keystore) | BLOCKED (keystore belum tersedia) | |
| F2 | Install release build ke perangkat | BLOCKED (menunggu F1) | |
| F3 | Application ID: `com.example.siakad_mobile` (belum diganti — perlu keputusan pemilik aplikasi) | NOT TESTED | |
| F4 | Version: versionName 1.0.0 / versionCode 1 (dari pubspec) | NOT TESTED | |
| F5 | Permission: hanya INTERNET (+ plugin open_filex) — tidak ada permission spekulatif | PASS (audit statis merged manifest debug; release sama + cleartext=false) | Merged manifest debug terverifikasi |
| F6 | API base URL release wajib https:// + API_BASE_URL eksplisit | PASS (enforce di kode; startup gagal jelas jika tidak diisi) | |
| F7 | Crash/error logging — LoggingInterceptor debug-only; release bersih | PASS (audit statis) | |
| F8 | Backup policy: allowBackup=false + dataExtractionRules exclude-all | PASS (audit statis) | |
| F9 | Ukuran artifact release | BLOCKED (release belum bisa dibangun — signing belum tersedia) | Debug APK: ~234 MB |
| F10 | Nomor build sesuai distribusi | NOT TESTED | |

## Catatan penggunaan

- Status kode: verifikasi statis/otomatis saja — bukan pengujian fisik.
- UAT fisik menunggu ketersediaan perangkat & backend staging/production
  dengan konfigurasi HTTPS.
- Midtrans Sandbox E2E membutuhkan credential Midtrans (client key + server
  key terkonfigurasi di backend) — di luar kemampuan sesi ini; tandai
  BLOCKED sampai tersedia.
