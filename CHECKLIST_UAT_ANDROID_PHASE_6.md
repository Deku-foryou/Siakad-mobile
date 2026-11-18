# CHECKLIST UAT ANDROID — PHASE 6 (SIAKAD Mobile)

Checklist manual untuk HP Android fisik. **Manual UAT belum dilakukan** —
pengguna menjalankannya sendiri pada perangkat fisik. Jangan centang apa pun
sebelum benar-benar dicoba.

Legenda: ☐ = belum diuji · ✅ = lulus · ❌ = gagal (catat detail di kolom Catatan)

## Persiapan

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 0.1 | Pasang APK debug: `flutter build apk --debug`, install via `adb install -r build/app/outputs/flutter-apk/app-debug.apk` | Aplikasi terpasang & terbuka | ☐ | |
| 0.2 | Pastikan HP terhubung ke jaringan yang bisa mengakses backend (IP dev terkini) | Tidak ada layar kosong/gagal konek terus-menerus | ☐ | |
| 0.3 | Sediakan akun uji: 1 siswa, 1 guru, 1 wali (dengan minimal 2 anak terverifikasi) | Akun dikenal kredensialnya | ☐ | |

## 1. Login siswa

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 1.1 | Buka aplikasi, lihat splash → login | Splash tidak hang; form login tampil | ☐ | |
| 1.2 | Login dengan kredensial siswa valid | Masuk ke Beranda Siswa; tidak menampilkan menu guru/wali | ☐ | |
| 1.3 | Login dengan password salah | Pesan error ramah tampil; tidak menutup sesi lain | ☐ | |
| 1.4 | Login dengan akun guru | Tidak masuk area guru? (ditolak/ diarahkan sesuai role guard) — aplikasi hanya menerima role mobile yang valid | ☐ | |
| 1.5 | Akun dengan kewajiban ganti password (bila ada) | Dialihkan ke layar Ganti Password; tidak bisa melewati dengan tombol back | ☐ | |

## 2. Navigasi dashboard & fitur siswa

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 2.1 | Cek Beranda: identitas, konteks TA/semester, ringkasan keuangan, jadwal hari ini, badge notifikasi | Data tampil tanpa placeholder rusak | ☐ | |
| 2.2 | Buka tab Akademik → Jadwal (filter hari & tanggal) | Jadwal tampil; ganti filter tidak menghapus konteks | ☐ | |
| 2.3 | Absensi: tab Harian / Periode (pilih rentang) / Per Jam; filter status | Data + rekap tampil; pagination "Muat Lebih Banyak" bekerja | ☐ | |
| 2.4 | Nilai & Rapor: buka daftar rapor → detail | Nilai akhir tampil; KKTP tampil; tidak bisa mengedit | ☐ | |
| 2.5 | Pengumuman: daftar → detail | Detail tampil; badge/status terbaca | ☐ | |
| 2.6 | Notifikasi: buka daftar, filter Semua/Belum Dibaca/Dibaca; tandai satu & semua dibaca | Badge beranda berkurang sesuai; tanpa crash | ☐ | |
| 2.7 | Keuangan: ringkasan, tagihan, detail tagihan, coba "Bayar" (bila gateway sandbox aktif), riwayat pembayaran, unduh kuitansi bila ada | Pembayaran TIDAK bisa di-settle sendiri; status hanya dari server; dokumen tersimpan lokal & bisa dibuka | ☐ | |
| 2.8 | Pull-to-refresh di Beranda / list | Data termuat ulang tanpa hilang konteks filter | ☐ | |
| 2.9 | Back dari halaman detail ke list | Kembali ke daftar; state filter terjaga | ☐ | |

## 3. Login guru

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 3.1 | Logout, lalu login sebagai guru | Masuk Beranda Guru; tidak ada data siswa sebelumnya | ☐ | |
| 3.2 | Menu: Beranda / Kelas / Absensi / Penilaian / Profil | 5 tab bekerja; badge notifikasi di ikon Beranda | ☐ | |

## 4. Navigasi kelas, absensi, dan penilaian

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 4.1 | Kelas → detail kelas → daftar siswa | Data kelas & siswa tampil | ☐ | |
| 4.2 | Absensi Harian: pilih kelas → grid; simpan absensi | Simpan sukses; anti double-submit (tombol terkunci saat menyimpan) | ☐ | |
| 4.3 | Absensi Per Jam: pilih pertemuan; edit & simpan | Data tersimpan; tidak bisa mengedit kelas yang bukan diajar | ☐ | |
| 4.4 | Penilaian: buka penugasan → input nilai → Duplikasi nilai batch | Konfirmasi tampil; nilai tersimpan; bobot=100 & terkunci ditegakkan backend | ☐ | |
| 4.5 | Error: coba akses menu siswa (via deep link) | Dialihkan ke Beranda Guru | ☐ | |

## 5. Login wali

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 5.1 | Logout, login sebagai wali | Beranda Wali tampil; ringkasan relasi & daftar anak terverifikasi tampil | ☐ | |
| 5.2 | Wali tanpa anak terverifikasi (akun khusus bila ada) | Empty-state informatif; tidak ada data palsu | ☐ | |
| 5.3 | Wali dengan anak pending saja | Badge "Menunggu Verifikasi"; detail anak menampilkan banner terkunci; menu akademik/keuangan tidak tersedia | ☐ | |

## 6. Perpindahan antar-anak

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 6.1 | Pilih anak A → buka Jadwal/Absensi/Nilai/Rapor | Data anak A tampil; nama & kelas anak terpilih terlihat di AppBar | ☐ | |
| 6.2 | Pindah ke anak B → buka halaman sama | Data BERBEDA (anak B) — bukan data anak A; tidak ada flicker data lama | ☐ | |
| 6.3 | Kembali ke anak A | Data A tampil lagi, filter terjaga | ☐ | |
| 6.4 | Keuangan: ganti anak via dropdown → ringkasan/tagihan berbeda | Angka keuangan berbeda per anak; tidak bercampur | ☐ | |
| 6.5 | Notifikasi wali | Daftar notifikasi user-scoped (bukan per anak) | ☐ | |

## 7. Pemeriksaan akademik dan keuangan anak

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 7.1 | Jadwal anak: filter hari & tanggal; kosongkan jadwal | Tampil grouping per hari; empty state benar | ☐ | |
| 7.2 | Absensi anak: Harian/Periode/Per Jam + filter status | Rekap tampil; alpha/izin/sakit/hadir benar; tanpa aksi edit | ☐ | |
| 7.3 | Nilai anak + raport detail | Nilai akhir + KKTP + rekap kehadiran + catatan wali kelas | ☐ | |
| 7.4 | Keuangan anak: ringkasan, tagihan, detail tagihan | Angka dari server; detail lengkap; Bayar hanya bila tagihan belum lunas | ☐ | |
| 7.5 | Riwayat pembayaran + unduh kuitansi (bila tersedia) | Dokumen tersimpan & dapat dibuka; bukan URL publik | ☐ | |

## 8. Notifikasi

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 8.1 | Badge belum dibaca di shell/beranda (siswa & wali) | Sesuai jumlah server; berkurang setelah tandai dibaca | ☐ | |
| 8.2 | Mark read satu notifikasi | Status berubah; badge turun | ☐ | |
| 8.3 | Mark all read | Semua terbaca; badge hilang | ☐ | |

## 9. Logout dan pergantian akun

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 9.1 | Logout perangkat ini → login akun lain di perangkat sama | Tidak ada data akun sebelumnya (tab, anak terpilih, cache) | ☐ | |
| 9.2 | Logout semua perangkat (hati-hati: mencabut token) | Semua sesi tercabut; login ulang diperlukan | ☐ | |
| 9.3 | Ganti password (akun uji) | Dialihkan login ulang; password baru berfungsi | ☐ | |

## 10. Penanganan koneksi terputus

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 10.1 | Aktifkan mode pesawat → buka beberapa halaman | Empty/error state ramah; tidak crash; retry tersedia | ☐ | |
| 10.2 | Matikan mode pesawat → retry | Data termuat kembali | ☐ | |
| 10.3 | 401/token dicabut saat aplikasi terbuka | Sesi berakhir bersih; diarahkan login dengan notice | ☐ | |

## 11. Tampilan light/dark

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 11.1 | Ubah tema perangkat ke Dark Mode → buka aplikasi | Seluruh halaman readable; kontras teks cukup; tidak ada area putih silau | ☐ | |
| 11.2 | Kembali ke Light Mode | Tampilan konsisten dengan branding teal | ☐ | |

## 12. Pemeriksaan keyboard dan ukuran layar

| # | Langkah | Hasil yang diharapkan | ☐/✅/❌ | Catatan |
|---|---|---|---|---|
| 12.1 | Buka keyboard di form login/ganti password | Form tidak tertutup keyboard; bisa scroll | ☐ | |
| 12.2 | HP kecil (±360dp) & tablet/hp besar | Tidak ada overflow/teks terpotong | ☐ | |
| 12.3 | Text scaling perangkat 1.3x–2x | Konten masih terbaca; tombol tetap bisa diketuk | ☐ | |
| 12.4 | Tombol & chip: target sentuh nyaman | Tidak ada tombol/ikon terlalu kecil (<48dp) | ☐ | |

## Catatan akhir

- Temuan bug: laporkan dengan langkah reproduksi + screenshot + role +
  versi backend/mobile.
- Jangan melakukan UAT dengan data siswa/guru/wali sungguhan di luar akun uji.
