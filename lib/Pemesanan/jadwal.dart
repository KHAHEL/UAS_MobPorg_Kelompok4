part of '../main.dart';

// Jam operasional selalu memakai waktu Jakarta, termasuk pada HP di zona lain.
DateTime sekarangWib() => DateTime.now().toUtc().add(const Duration(hours: 7));

String? masalahJadwal(DateTime ambil, DateTime sekarang) {
  if (!ambil.isAfter(sekarang)) return 'Pilih jam pengambilan yang belum lewat.';
  final batas = DateTime.utc(sekarang.year, sekarang.month, sekarang.day + 4);
  if (!ambil.isBefore(batas)) return 'Pilih tanggal maksimal 3 hari ke depan.';
  final menit = ambil.hour * 60 + ambil.minute;
  if (menit < 600 || menit > 1260) return 'Pilih jam antara 10.00 dan 21.00 WIB.';
  return null;
}

String duaDigit(int n) => n.toString().padLeft(2, '0');

String teksAmbil(DateTime waktu) =>
    '${duaDigit(waktu.day)}/${duaDigit(waktu.month)}/${waktu.year} '
        '${duaDigit(waktu.hour)}:${duaDigit(waktu.minute)} WIB';

bool terlambatDiambil(Map order) {
  if (order['orderStatus'] != 'Ready') return false;
  final jadwal = DateTime.tryParse(order['pickupDate'] ?? '');
  if (jadwal == null) return false;
  // Nota lama yang hanya berisi tanggal disimpan dengan jam 00.00.
  if (order['pickupMode'] == null && jadwal.hour == 0 && jadwal.minute == 0) return false;
  final jamWib = DateTime.utc(jadwal.year, jadwal.month, jadwal.day, jadwal.hour, jadwal.minute);
  return sekarangWib().isAfter(jamWib);
}

// Simpan angka tanggal dan jam WIB tanpa penanda zona, seperti nota lama.
String teksIsoWib(DateTime w) => w.toIso8601String().split('Z').first;
