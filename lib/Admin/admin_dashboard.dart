part of '../main.dart';

extension AdminDashboard on _AdminPageState {
  Widget halamanDashboard() {
    final habis = daftarMenu.where((m) => stok(m) == 0).length;
    return _PageList(
      children: [
        const Text('Ringkasan restoran', style: _heading),
        const SizedBox(height: 16),
        for (final data in [
          (Icons.restaurant_menu, 'Jumlah menu', daftarMenu.length),
          (Icons.receipt_long, 'Jumlah pesanan', orders.length),
          (Icons.payment, 'Transaksi tercatat', orders.length),
          (Icons.inventory_2_outlined, 'Menu habis', habis),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: biruMuda,
                foregroundColor: Colors.black,
                child: Icon(data.$1),
              ),
              title: Text(data.$2),
              trailing: Text('${data.$3}', style: _heading),
            ),
          ),
      ],
    );
  }
}