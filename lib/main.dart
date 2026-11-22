import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'admin_page.dart';

const biru = Color(0xFF81D4FA);
const biruMuda = Color(0xFFE1F5FE);
const kategori = ['Main Course', 'Snacks', 'Drinks', 'Dessert'];
const levelPedas = ['Tidak Pedas', 'Sedang', 'Pedas'];
const metodeBayar = ['Tunai', 'QRIS', 'Transfer Bank'];
late Box menus;
late Box orders;
final List<Map<String, dynamic>> cart = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await bukaDatabase();
  runApp(const MyApp());
}

Future<void> bukaDatabase() async {
  menus = await Hive.openBox('menus');
  orders = await Hive.openBox('orders');

  // Data contoh dan alamat foto hanya ditambahkan satu kali.
  // Kalau admin menghapus menu, aplikasi tidak akan memunculkannya lagi sendiri.
  if (!menus.containsKey('_versiMenu')) {
    final awal = [
      [
        'nasi',
        'Nasi Goreng',
        'Nasi goreng spesial + telur',
        25000,
        20,
        kategori[0],
        true,
        'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=640',
      ],
      [
        'mie',
        'Mie Ayam',
        'Mie ayam dengan bakso',
        20000,
        15,
        kategori[0],
        true,
        'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=640',
      ],
      [
        'sate',
        'Sate Ayam',
        '10 tusuk sate dengan bumbu kacang',
        20000,
        12,
        kategori[0],
        true,
        'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=640',
      ],
      [
        'ayam',
        'Ayam Bakar',
        'Ayam bakar dengan nasi hangat',
        28000,
        12,
        kategori[0],
        true,
        'https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=640',
      ],
      [
        'bakso',
        'Bakso Kuah',
        'Bakso sapi dengan kuah hangat',
        18000,
        14,
        kategori[0],
        false,
        'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=640',
      ],
      [
        'kwetiau',
        'Kwetiau Goreng',
        'Kwetiau goreng dengan sayuran',
        22000,
        10,
        kategori[0],
        true,
        'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=640',
      ],
      [
        'tahu',
        'Tahu Crispy',
        'Tahu goreng renyah',
        12000,
        8,
        kategori[1],
        true,
        'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=640',
      ],
      [
        'dimsum',
        'Dimsum Ayam',
        'Empat buah dimsum kukus',
        16000,
        10,
        kategori[1],
        false,
        'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=640',
      ],
      [
        'kentang',
        'Kentang Goreng',
        'Kentang goreng renyah',
        14000,
        12,
        kategori[1],
        false,
        'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=640',
      ],
      [
        'teh',
        'Es Teh Manis',
        'Teh manis dengan es',
        6000,
        15,
        kategori[2],
        false,
        'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=640',
      ],
      [
        'jeruk',
        'Es Jeruk',
        'Jeruk segar dengan es',
        8000,
        12,
        kategori[2],
        false,
        'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=640',
      ],
      [
        'puding',
        'Puding Cokelat',
        'Puding cokelat dingin',
        10000,
        5,
        kategori[3],
        false,
        'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=640',
      ],
    ];
    for (final m in awal) {
      final id = m[0] as String;
      if (!menus.containsKey(id)) {
        await menus.put(id, {
          'id': id,
          'name': m[1],
          'description': m[2],
          'price': m[3],
          'stock': m[4],
          'category': m[5],
          'spicy': m[6],
          'imageUrl': m[7],
        });
      }
    }
    // Menu lama dari database UTS dapat tetap dipakai.
    for (final m in daftarMenu) {
      if (!m.containsKey('imageUrl') || m['imageUrl'] == '') {
        final contoh = awal.where((item) => item[0] == m['id']).toList();
        final url = contoh.isEmpty ? '' : contoh.first[7] as String;
        await menus.put(m['id'], {...m, 'imageUrl': url});
      }
    }
    await menus.put('_versiMenu', 1);
  }
}

List<Map> get daftarMenu => menus.values.whereType<Map>().toList();
String formatRupiah(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final posFromEnd = s.length - i;
    buffer.write(s[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
  }
  return 'Rp$buffer';
}

// Stok tersedia = stok yang disediakan admin - porsi pada pesanan aktif.
// Satu catatan pesanan cukup untuk mengurangi stok atau mengembalikannya saat batal.
int terjual(String id) {
  int jumlah = 0;
  for (final order in orders.values) {
    if (order['orderStatus'] == 'Cancelled') continue;
    for (final item in order['items']) {
      if (item['id'] == id) jumlah += item['quantity'] as int;
    }
  }
  return jumlah;
}

int stok(Map menu) => (menu['stock'] as int) - terjual(menu['id']);
int dalamCart(String id) {
  int jumlah = 0;
  for (final item in cart) {
    if (item['id'] == id) jumlah += item['quantity'] as int;
  }
  return jumlah;
}

int get totalPrice => cart.fold(
  0,
  (sum, p) => sum + (p['quantity'] as int) * (p['price'] as int),
);

void tambahKeranjang(Map menu, String level, int jumlah) {
  if (jumlah < 1 || dalamCart(menu['id']) + jumlah > stok(menu)) return;
  // Menu yang sama dengan pilihan pedas yang berbeda tetap punya baris sendiri.
  for (final item in cart) {
    if (item['id'] == menu['id'] && item['level'] == level) {
      item['quantity'] += jumlah;
      return;
    }
  }
  cart.add({
    'id': menu['id'],
    'name': menu['name'],
    'price': menu['price'],
    'level': level,
    'quantity': jumlah,
  });
}

String? cekKeranjang() {
  if (cart.isEmpty) return 'Keranjang masih kosong.';
  for (final item in cart) {
    final m = menus.get(item['id']);
    if (m == null ||
        m['price'] != item['price'] ||
        m['name'] != item['name'] ||
        (m['spicy'] == false && item['level'] != '')) {
      return 'Menu ${item['name']} berubah. Hapus dari keranjang dan pilih kembali.';
    }
    if (dalamCart(item['id']) > stok(m))
      return 'Stok ${item['name']} tersisa ${stok(m)}. Sesuaikan jumlah di keranjang.';
  }
  return null;
}

Future<void> simpanPesanan(String metode) async {
  final masalah = cekKeranjang();
  if (masalah != null) throw StateError(masalah);
  final waktu = DateTime.now();
  final id = 'BB-${waktu.microsecondsSinceEpoch}';
  // Simpan salinan nama dan harga agar nota lama tetap sama setelah menu diedit.
  await orders.put(id, {
    'orderId': id,
    'orderDate': waktu.toIso8601String(),
    'items': [for (final item in cart) Map.of(item)],
    'totalPrice': totalPrice,
    'paymentMethod': metode,
    'paymentStatus': 'Lunas (simulasi)',
    'orderStatus': 'Processing',
  });
  cart.clear();
}

void pesan(BuildContext context, String teks) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(teks)));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BlueBite',
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: biru,
          selectionHandleColor: biru,
        ),
        colorScheme: const ColorScheme.light(
          primary: biru,
          secondary: biru,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          error: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: biru,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: biru,
            foregroundColor: Colors.black,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: biruMuda,
          contentTextStyle: TextStyle(color: Colors.black),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          backgroundColor: biruMuda,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const RestoranPage(),
    );
  }
}

Widget fotoMenu(Map menu, {double ukuran = 64}) {
  final url = menu['imageUrl']?.toString() ?? '';
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      width: ukuran,
      height: ukuran,
      child: url.isEmpty
          ? Container(
              color: biru,
              child: const Icon(Icons.restaurant, size: 32),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: biru,
                child: const Icon(Icons.restaurant, size: 32),
              ),
            ),
    ),
  );
}

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
          Card(
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
          Container(
            color: biruMuda,
            padding: const EdgeInsets.all(20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.restaurant, size: 36),
                SizedBox(height: 10),
                Text(
                  'Selamat datang di BlueBite',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Favorit dapur kami: Nasi Goreng spesial dengan telur.'),
              ],
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
          IconButton(
            tooltip: 'Keranjang',
            onPressed: () => buka(const CartPage()),
            icon: const Icon(Icons.shopping_cart_outlined),
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

class DetailMenu extends StatefulWidget {
  final Map menu;
  const DetailMenu(this.menu, {super.key});
  @override
  State<DetailMenu> createState() => _DetailMenuState();
}

class _DetailMenuState extends State<DetailMenu> {
  int jumlah = 1;
  String level = 'Sedang';
  @override
  Widget build(BuildContext context) {
    final m = widget.menu;
    final sisa = stok(m) - dalamCart(m['id']);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail menu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            m['name'],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(m['description']),
          Text(
            "${m['category']} · ${formatRupiah(m['price'])} · Stok ${stok(m)}",
          ),
          if (m['spicy'])
            DropdownButton<String>(
              isExpanded: true,
              value: level,
              items: [
                for (final l in levelPedas)
                  DropdownMenuItem(value: l, child: Text(l)),
              ],
              onChanged: (s) => setState(() => level = s!),
            ),
          Row(
            children: [
              const Text('Jumlah'),
              IconButton(
                tooltip: 'Kurangi',
                onPressed: jumlah > 1 ? () => setState(() => jumlah--) : null,
                icon: const Icon(Icons.remove),
              ),
              Text('$jumlah'),
              IconButton(
                tooltip: 'Tambah jumlah',
                onPressed: jumlah < sisa
                    ? () => setState(() => jumlah++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: sisa < jumlah
                ? null
                : () {
                    tambahKeranjang(m, m['spicy'] ? level : '', jumlah);
                    pesan(context, "${m['name']} masuk keranjang");
                    Navigator.pop(context);
                  },
            child: const Text('Masukkan ke keranjang'),
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  void ubahJumlah(Map item, int delta) {
    setState(() {
      item['quantity'] += delta;
      if (item['quantity'] <= 0) cart.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final masalah = cekKeranjang();
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final item in cart)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                barisItem(item),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Kurangi',
                      icon: const Icon(Icons.remove),
                      onPressed: () => ubahJumlah(item, -1),
                    ),
                    Text("${item['quantity']}"),
                    IconButton(
                      tooltip: 'Tambah jumlah',
                      icon: const Icon(Icons.add),
                      onPressed:
                          menus.containsKey(item['id']) &&
                              dalamCart(item['id']) <
                                  stok(menus.get(item['id']))
                          ? () => ubahJumlah(item, 1)
                          : null,
                    ),
                    IconButton(
                      tooltip: 'Hapus item',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => cart.remove(item)),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
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

Widget barisItem(Map item) {
  final nama = item['name'];
  final level = item['level'];
  return ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(level == '' ? nama : '$nama · $level'),
    subtitle: Text(
      "${formatRupiah(item['price'])} × ${item['quantity']} = ${formatRupiah(item['quantity'] * item['price'])}",
    ),
  );
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedMethod = 'QRIS';
  bool sibuk = false;
  Future<void> bayar() async {
    if (sibuk) return;
    setState(() => sibuk = true);
    try {
      await simpanPesanan(selectedMethod);
    } catch (e) {
      if (mounted) {
        setState(() => sibuk = false);
        pesan(
          context,
          e is StateError ? e.message : 'Pesanan gagal disimpan. Coba lagi.',
        );
      }
      return;
    }
    if (!mounted) return;
    pesan(context, 'Pesanan berhasil disimpan. Terima kasih!');
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !sibuk,
      child: Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final item in cart) barisItem(item),
            Text(
              'Total ${formatRupiah(totalPrice)}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            const Text('Metode pembayaran (simulasi)'),
            DropdownButton<String>(
              value: selectedMethod,
              isExpanded: true,
              items: [
                for (final m in metodeBayar)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: sibuk
                  ? null
                  : (s) => setState(() => selectedMethod = s!),
            ),
            ElevatedButton(
              onPressed: sibuk ? null : bayar,
              child: const Text('Konfirmasi pesanan'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget daftarPesanan({
  void Function(Map, String)? ubahStatus,
  bool transaksi = false,
}) {
  if (orders.isEmpty) return const Center(child: Text('Belum ada pesanan.'));
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      for (final o in orders.values.toList().reversed)
        Card(
          color: biruMuda,
          elevation: 0,
          child: ExpansionTile(
            textColor: Colors.black,
            iconColor: Colors.black,
            title: Text(o['orderId']),
            subtitle: Text(
              "${o['orderDate'].toString().substring(0, 16).replaceFirst('T', ' ')}\n${formatRupiah(o['totalPrice'])} · ${o['orderStatus']}",
            ),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              for (final item in o['items']) barisItem(item),
              Text("${o['paymentMethod']} · ${o['paymentStatus']}"),
              if (ubahStatus != null &&
                  !transaksi &&
                  ['Processing', 'Ready'].contains(o['orderStatus']))
                Wrap(
                  children: [
                    TextButton(
                      onPressed: () => ubahStatus(
                        o,
                        o['orderStatus'] == 'Processing'
                            ? 'Ready'
                            : 'Completed',
                      ),
                      child: Text(
                        o['orderStatus'] == 'Processing'
                            ? 'Tandai Ready'
                            : 'Selesaikan',
                      ),
                    ),
                    TextButton(
                      onPressed: () => ubahStatus(o, 'Cancelled'),
                      child: const Text('Batalkan pesanan'),
                    ),
                  ],
                ),
            ],
          ),
        ),
    ],
  );
}
