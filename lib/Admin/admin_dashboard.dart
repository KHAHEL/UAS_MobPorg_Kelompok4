part of '../main.dart';

extension AdminDashboard on _AdminPageState {
  Widget halamanDashboard() {
    final habis = daftarMenu.where((m) => stok(m) == 0).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('Jumlah menu'),
          trailing: Text('${daftarMenu.length}'),
        ),
        ListTile(
          title: const Text('Jumlah pesanan'),
          trailing: Text('${orders.length}'),
        ),
        ListTile(
          title: const Text('Transaksi tercatat'),
          trailing: Text('${orders.length}'),
        ),
        ListTile(title: const Text('Menu habis'), trailing: Text('$habis')),
      ],
    );
  }
}