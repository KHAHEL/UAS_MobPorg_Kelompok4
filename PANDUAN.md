# BlueBite — Panduan UAS

Aplikasi pemesanan satu restoran untuk Android. Pembeli langsung masuk ke Home. Admin memakai menu Info → Login admin dengan username `admin` dan password `admin123`. Akun ini khusus demo lokal.

## Menjalankan di Android Studio

1. Ekstrak ZIP. Di Android Studio pilih **Open**, lalu buka folder **bluebite** yang berisi `pubspec.yaml`.
2. Pastikan plugin Flutter dan Dart aktif. Gunakan Flutter 3.35.7 (Dart 3.9.2) untuk menyamai versi pengujian. Periksa instalasi Android dengan `flutter doctor`.
3. Jalankan `flutter pub get` dari terminal folder proyek. Pilih emulator atau HP Android yang sudah terdeteksi, lalu jalankan `lib/main.dart` dengan tombol **Run** atau `flutter run`. Pengunduhan dependency pertama kali memerlukan internet. Pemesanan dan penyimpanan bekerja secara lokal.
4. Untuk mengulang pemeriksaan, jalankan `flutter analyze` dan `flutter test`.

## Isi proyek

| File | Isi |
|---|---|
| lib/main.dart | Inisialisasi Hive, tema, data awal, Home, Menu, detail makanan, keranjang, pembayaran, riwayat, dan perhitungan stok. |
| lib/admin_page.dart | Login demo, dashboard, formulir tambah/edit, stok, konfirmasi hapus, pesanan, dan transaksi. |
| pubspec.yaml | Dependency Flutter, Hive, hive_flutter, dan alat pengujian. |
| test/bluebite_test.dart | Pengujian alur pembeli, admin, perhitungan stok, dan penyimpanan lokal. |
| android/ | Konfigurasi Android standar dari Flutter. |

## Alur demo kelas

1. Buka **Lihat menu**, cari Nasi Goreng, pilih level pedas dan masukkan 2 porsi. Tambahkan 1 Mie Ayam. Keranjang menunjukkan **Rp70.000**. Tombol kurang pada jumlah 1 menghapus baris tersebut.
2. Buka **Checkout**, pilih Tunai, QRIS, atau Transfer Bank, lalu konfirmasi. Buka **Riwayat** dan ketuk nomor pesanan untuk melihat rincian. Stok Nasi Goreng yang awalnya 20 menjadi 18 saat checkout berhasil.
3. Buka **Info → Login admin**. Di **Menu**, buat makanan, ubah harga atau stok, lalu keluar untuk melihat perubahan sebagai pembeli. Menu berstok 1–5 ditandai stok rendah dan menu berstok 0 ditandai habis.
4. Di **Pesanan**, buka nomor pesanan. Tandai Ready lalu Completed, atau batalkan saat masih Processing/Ready. Buka **Transaksi** untuk melihat nominal, metode, dan status pembayaran. Setiap pesanan terkonfirmasi menghasilkan satu catatan transaksi, termasuk transaksi yang kemudian dibatalkan.
5. Tutup aplikasi lalu buka kembali untuk melihat menu dan riwayat yang tersimpan.

## Cara kerja Hive

Box `menus` menyimpan menu dengan ID tetap. Box `orders` menyimpan salinan item, jumlah, harga saat checkout, metode pembayaran, waktu, dan status. Perubahan nama, harga, atau penghapusan menu tidak mengubah nota lama.

Stok yang terlihat = stok dasar menu dikurangi jumlah porsi dari seluruh pesanan yang belum dibatalkan. Keranjang belum dihitung. Saat checkout, cukup simpan satu pesanan ke Hive untuk mencatat transaksi sekaligus mengurangi stok tersedia. Saat admin mengisi stok baru, angka yang dimasukkan adalah jumlah yang tersedia saat itu. Pesanan berstatus Cancelled dikeluarkan dari hitungan sehingga pembatalan berulang tidak menambah stok lagi.

Keranjang menggunakan List sementara dan akan kosong saat aplikasi ditutup. Menu dan riwayat tersimpan pada perangkat yang sama. Semua pembayaran disimulasikan. Ikon makanan tersedia offline. Data awal ditambahkan pada penggunaan pertama.

## Hasil pemeriksaan

Flutter 3.35.7 dan Dart 3.9.2 berhasil mengambil dependency. Pemeriksaan `flutter analyze` selesai tanpa temuan. Sepuluh pengujian otomatis lulus dalam dua eksekusi berturut-turut.

| Pemeriksaan | Hasil yang diamati |
|---|---|
| Pemesanan normal | 2 Nasi Goreng + 1 Mie Ayam = Rp70.000. Stok masing-masing menjadi 18 dan 14. |
| Keranjang | Varian pedas berbagi stok yang sama. Item identik digabung. Jumlah dapat dikurangi dan item bisa dihapus. Checkout dinonaktifkan ketika kosong. |
| Konfirmasi ganda | Dua ketukan menghasilkan satu pesanan. |
| Perubahan menu | Checkout ditolak ketika harga berubah, menu sudah dihapus, atau jumlah melampaui stok. |
| Riwayat dan penyimpanan | Pesanan serta stok terbaca setelah file Hive ditutup dan dibuka ulang. Penghapusan menu tidak mengubah isi nota lama. |
| Admin | Login salah ditolak. Formulir divalidasi. Menu bisa ditambah, diubah, dan dihapus. Stok 0 terlihat sebagai Habis bagi pembeli. |
| Status dan transaksi | Admin dapat mengubah status. Pembatalan mengembalikan stok sekali. Pesanan Completed tetap selesai. |
| Antarmuka | Home, pencarian, filter, pilihan pedas, metode bayar, riwayat, dan transaksi diuji melalui widget Flutter. Keranjang juga diuji pada lebar 320 piksel. |

Pengujian penyimpanan menggunakan file Hive di disk. Pengujian antarmuka menggunakan Hive dalam memori supaya setiap skenario dimulai dari data kosong. Konfigurasi Android dibuat dari template Flutter karena sumber UTS yang cocok dengan prompt berisi file Dart terpisah.

Build Android debug berhasil melalui Gradle 8.12 dengan JDK 21. Tanda tangan APK debug berhasil diverifikasi. Salinan proyek yang diekstrak dari ZIP juga lulus analisis dan 10 pengujian. Peluncuran pada HP fisik atau emulator belum diuji.
