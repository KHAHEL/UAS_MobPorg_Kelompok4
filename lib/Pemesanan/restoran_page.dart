part of '../main.dart';

class RestoranPage extends StatefulWidget {
  const RestoranPage({super.key});
  @override
  State<RestoranPage> createState() => _RestoranPageState();
}

class _RestoranPageState extends State<RestoranPage> {
  int tab = 0;
  String cari = '', filter = 'Semua';
  Future<void> buka(Widget halaman) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => halaman));
    if (mounted) setState(() {});
  }

  Widget halamanMenu() {
    final hasil = daftarMenu
        .where(
          (m) =>
      (filter == 'Semua' || filter == m['category']) &&
          m['name'].toString().toLowerCase().contains(
            cari.trim().toLowerCase(),
          ),
    )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          initialValue: cari,
          decoration: const InputDecoration(
            labelText: 'Cari makanan atau minuman',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (s) => setState(() => cari = s),
        ),
        DropdownButton<String>(
          isExpanded: true,
          value: filter,
          items: [
            for (final k in ['Semua', ...kategori])
              DropdownMenuItem(value: k, child: Text(k)),
          ],
          onChanged: (s) => setState(() => filter = s!),
        ),
        if (hasil.isEmpty) const Text('Menu tidak ditemukan.'),
        for (final m in hasil)
          TemaTerang( // BARU: kotak biru tetap tema terang
            child: Card(
              elevation: 0,
              color: biruMuda,
              child: ListTile(
                leading: fotoMenu(m),
                title: Text(m['name']),
                subtitle: Text(
                  "${formatRupiah(m['price'])} · ${m['category']}\nStok ${stok(m)}",
                ),
                isThreeLine: true,
                onTap: () => buka(DetailMenu(m)),
                trailing: TextButton(
                  onPressed: stok(m) > dalamCart(m['id'])
                      ? () => buka(DetailMenu(m))
                      : null,
                  child: Text(stok(m) == 0 ? 'Habis' : 'Tambah'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const judul = ['BlueBite', 'Menu', 'Riwayat', 'Info'];
    Widget isi;
    if (tab == 0) {
      isi = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TemaTerang( // BARU: kotak biru tetap tema terang
            child: Material( // DIUBAH: Container menjadi Material
              color: biruMuda,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.restaurant, size: 36),
                    SizedBox(height: 10),
                    Text(
                      'Selamat datang di BlueBite',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Favorit dapur kami: Nasi Goreng spesial dengan telur.',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Text(
            'BlueBite • Restoran masakan rumahan\nBuka setiap hari, 10.00–21.00 WIB.',
          ),
        ],
      );
    } else if (tab == 1) {
      isi = halamanMenu();
    } else if (tab == 2) {
      isi = daftarPesanan();
    } else {
      isi = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('BlueBite', style: TextStyle(fontSize: 22)),
          const Text(
            'Masakan rumahan, camilan, minuman, dan dessert.\nSetiap hari • 10.00–21.00 WIB\nPembayaran di aplikasi ini berupa simulasi.',
          ),
          ElevatedButton(
            onPressed: () => buka(const AdminPage()),
            child: const Text('Login admin'),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(judul[tab]),
        actions: [
          const SwitchModeGelap(), // BARU: switch mode gelap
          IconButton(
            tooltip: 'Keranjang',
            onPressed: () => buka(const CartPage()),
            // BARU: badge merah berisi total porsi di keranjang
            icon: Badge(
              isLabelVisible: cart.isNotEmpty,
              backgroundColor: Colors.red,
              label: Text(
                '${cart.fold<int>(0, (sum, p) => sum + (p['quantity'] as int))}',
              ),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
      body: SafeArea(child: isi),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        onTap: (i) => setState(() => tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Info',
          ),
        ],
      ),
    );
  }
}