part of '../main.dart';

const labelStatus = {
  'New': 'Perlu Dikerjakan',
  'Processing': 'Sedang Diproses',
  'Ready': 'Siap Diambil',
  'Completed': 'Selesai',
  'Cancelled': 'Dibatalkan',
};
const statusBerikut = {'New': 'Processing', 'Processing': 'Ready', 'Ready': 'Completed'};
const tombolStatus = {'New': 'Mulai Masak', 'Processing': 'Tandai Siap', 'Ready': 'Tandai Sudah Diambil'};

String urutanAmbil(Map order) {
  if (order['pickupMode'] == 'asap') return order['orderDate'];
  if (order['pickupDate'] != null) return order['pickupDate'];
  // Pesanan versi lama menyimpan jadwal sebagai teks.
  final lama = RegExp(r'^(\d{2})/(\d{2})/(\d{4})').firstMatch(order['pickupTime'] ?? '');
  if (lama != null) return '${lama[3]}-${lama[2]}-${lama[1]}';
  return '9999'; // jadwal opsional yang kosong ditampilkan terakhir
}

Future<void> simpanStatus(String id, String baru) async {
  final order = Map.of(orders.get(id) as Map);
  final lama = order['orderStatus'];
  final boleh = statusBerikut.containsKey(lama) &&
      (baru == statusBerikut[lama] || baru == 'Cancelled');
  if (!boleh) return;
  order['orderStatus'] = baru;
  if (baru == 'Completed' && order['paymentMethod'] == 'Tunai') {
    order['paymentStatus'] = 'Tunai diterima';
  }
  if (baru == 'Cancelled') order['paymentStatus'] = 'Dibatalkan';
  // Stok dihitung dari order aktif. Membuka ulang order batal tidak mengubah stok.
  await orders.put(id, order);
}

extension AdminPesanan on _AdminPageState {
  Widget halamanPesananAdmin() {
    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          for (final status in labelStatus.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(status.value),
                selected: filterPesanan == status.key,
                onSelected: (_) => setState(() => filterPesanan = status.key),
              ),
            ),
        ]),
      ),
      Expanded(child: daftarPesanan(ubahStatus: ubahStatus, filter: filterPesanan)),
    ]);
  }
}
String statusBayarTampil(Map order) {
  if (order['orderStatus'] == 'Cancelled') return 'Dibatalkan';
  if (order['paymentStatus'] != 'Lunas') return order['paymentStatus'] ?? 'Belum tercatat';
  if (order['paymentMethod'] != 'Tunai') return 'Simulasi pembayaran';
  return order['orderStatus'] == 'Completed' ? 'Lunas (catatan lama)' : 'Bayar saat ambil';
}
