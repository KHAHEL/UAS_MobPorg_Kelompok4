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
    return _PageList(
      children: [
        TextFormField(
          initialValue: cari,
          decoration: const InputDecoration(
            labelText: 'Cari makanan atau minuman',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (s) => setState(() => cari = s),
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Kategori'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              value: filter,
              items: [
                for (final k in ['Semua', ...kategori])
                  DropdownMenuItem(value: k, child: Text(k)),
              ],
              onChanged: (s) => setState(() => filter = s!),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (hasil.isEmpty) const Center(child: Text('Menu tidak ditemukan.')),
        for (final m in hasil)
          TemaTerang(child: Card(
            color: biruMuda,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => buka(DetailMenu(m)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    fotoMenu(m, ukuran: 82),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['category']),
                        Text(m['name'], style: _title),
                        const SizedBox(height: 6),
                        Text(formatRupiah(m['price']), style: _title),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text('Stok ${stok(m)}'),
                            TextButton(
                              onPressed: stok(m) > dalamCart(m['id'])
                                  ? () => buka(DetailMenu(m)) : null,
                              child: Text(stok(m) == 0 ? 'Habis' : 'Tambah'),
                            ),
                          ],
                        ),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const judul = ['BlueBite', 'Menu', 'Riwayat', 'Info'];
    Widget isi;
    if (tab == 0) {
      final favorit = menus.get('nasi');
      isi = _PageList(
        children: [
          const Text('Selamat datang di BlueBite', style: _heading),
          const SizedBox(height: 6),
          const Text('Restoran masakan rumahan'),
          const SizedBox(height: 20),
          if (favorit is Map) ...[
            TemaTerang(child: Card(
              color: biruMuda,
              margin: EdgeInsets.zero,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: InkWell(
                onTap: () => buka(DetailMenu(favorit)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    fotoMenu(favorit, ukuran: 152, lebar: double.infinity),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Favorit dapur kami'),
                          const SizedBox(height: 4),
                          Text(favorit['name'], style: _heading),
                          const SizedBox(height: 6),
                          Text(formatRupiah(favorit['price']), style: _title),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: () => setState(() => tab = 1),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Lihat menu'),
          ),
          TextButton(
            onPressed: () => buka(const CartPage()),
            child: const Text('Lihat keranjang'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.schedule),
            title: Text('Buka setiap hari'),
            subtitle: Text('10.00–21.00 WIB'),
          ),
        ],
      );
    } else if (tab == 1) {
      isi = halamanMenu();
    } else if (tab == 2) {
      isi = daftarPesanan();
    } else {
      isi = _PageList(
        children: [
          const Text('BlueBite', style: _heading),
          const SizedBox(height: 6),
          const Text('Masakan rumahan, camilan, minuman, dan dessert.'),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.schedule),
            title: Text('Jam buka'),
            subtitle: Text('Setiap hari • 10.00–21.00 WIB'),
          ),
          const ListTile(
            leading: Icon(Icons.payment),
            title: Text('Pembayaran'),
          ),
          const SizedBox(height: 24),
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