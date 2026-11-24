part of '../main.dart';

Future<void> simpanStatus(String id, String baru) async {
  final order = Map.of(orders.get(id) as Map);
  final lama = order['orderStatus'];
  final boleh =
      (lama == 'Processing' && ['Ready', 'Cancelled'].contains(baru)) ||
          (lama == 'Ready' && ['Completed', 'Cancelled'].contains(baru));
  if (!boleh) return;
  order['orderStatus'] = baru;
  if (baru == 'Cancelled') order['paymentStatus'] = 'Dibatalkan';
  // Stok dihitung dari order aktif. Membuka ulang order batal tidak mengubah stok.
  await orders.put(id, order);
}

extension AdminPesanan on _AdminPageState {
  Widget halamanPesananAdmin() {
    return daftarPesanan(ubahStatus: ubahStatus);
  }
}