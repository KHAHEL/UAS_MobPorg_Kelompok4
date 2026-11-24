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

  Widget tombol(IconData icon, VoidCallback? onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: biruMuda,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.black26 : warnaBiru,
        ),
      ),
    );
  }

  Widget kartuItem(Map item) {
    final menu = menus.get(item['id']);
    final bisaTambah = menu != null && dalamCart(item['id']) < stok(menu);
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
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
                        color: Colors.black54,
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
            tombol(Icons.remove, () => ubahJumlah(item, -1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                "${item['quantity']}",
                style: const TextStyle(fontSize: 15),
              ),
            ),
            tombol(Icons.add, bisaTambah ? () => ubahJumlah(item, 1) : null),
            IconButton(
              tooltip: 'Hapus item',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => cart.remove(item)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final masalah = cekKeranjang();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Keranjang')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final item in cart) kartuItem(item),
          const SizedBox(height: 8),
          if (masalah != null) Text(masalah),
          Text(
            'Total ${formatRupiah(totalPrice)}',
            style: const TextStyle(fontSize: 20),
          ),
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