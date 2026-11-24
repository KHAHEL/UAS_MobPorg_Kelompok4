part of '../main.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const warnaBiru = Color(0xFF2196F3);

  void ubahJumlah(Map item, int delta) {
    setState(() {
      item['quantity'] += delta;
      if (item['quantity'] <= 0) cart.remove(item);
    });
  }

  // Pop-up konfirmasi sebelum item dihapus dari keranjang
  Future<void> konfirmasiHapus(Map item) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pesanan?'),
        content: Text("${item['name']} akan dihapus dari keranjang."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ya == true && mounted) setState(() => cart.remove(item));
  }

  Widget tombol(IconData icon, String label, VoidCallback? onTap) {
    return IconButton(
      tooltip: label,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: biruMuda,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      color: warnaBiru,
      disabledColor: Colors.black26,
      icon: Icon(icon),
    );
  }

  Widget kartuItem(Map item) {
    final menu = menus.get(item['id']);
    final bisaTambah = menu != null && dalamCart(item['id']) < stok(menu);
    return GestureDetector(
        onLongPress: () => konfirmasiHapus(item),
        child: Card(
          color: Theme.of(context).cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(children: [
                  fotoMenu(menu is Map ? menu : {}, ukuran: 76),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item['level'] != '')
                          Text(
                            'Pedas: ${item['level']}',
                            style: const TextStyle(
                              fontSize: 13,

                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          formatRupiah(item['price']),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: warnaBiru,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const Divider(),
                Row(
                  children: [
                    const Spacer(),
                    tombol(Icons.remove, 'Kurangi', () => ubahJumlah(item, -1)),
                    Text("${item['quantity']}", style: _title),
                    tombol(Icons.add, 'Tambah jumlah',
                        bisaTambah ? () => ubahJumlah(item, 1) : null),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final masalah = cekKeranjang();
    return Scaffold(
      // DIUBAH: backgroundColor dihapus, warna latar sekarang ikut tema
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: const [SwitchModeGelap()],
      ),
      body: _PageList(
        children: [
          if (cart.isNotEmpty) const Text('Item pesanan', style: _heading),
          const SizedBox(height: 8),
          for (final item in cart) kartuItem(item),
          const SizedBox(height: 8),
          if (masalah != null) Text(masalah),
          const SizedBox(height: 16),
          Text(
            'Total ${formatRupiah(totalPrice)}',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: masalah != null
                ? null
                : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentPage()),
              );
              if (mounted) setState(() {});
            },
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
  }
}