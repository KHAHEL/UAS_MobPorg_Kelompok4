import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'Admin/admin_page.dart';
part 'Admin/admin_dashboard.dart';
part 'Admin/admin_menu.dart';
part 'Admin/admin_pesanan.dart';
part 'Pemesanan/restoran_page.dart';
part 'Pemesanan/menu_page.dart';
part 'Pemesanan/keranjang_page.dart';
part 'Pemesanan/payment_page.dart';

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