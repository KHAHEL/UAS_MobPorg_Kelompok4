import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart' show Pbkdf2, Hmac, SecretKey;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

part 'akses_page.dart';
part 'Pemesanan/jadwal.dart';
part 'Pemesanan/promo_api.dart';
part 'Admin/admin_page.dart';
part 'Admin/admin_dashboard.dart';
part 'Admin/admin_menu.dart';
part 'Admin/admin_pesanan.dart';
part 'Pemesanan/restoran_page.dart';
part 'Pemesanan/menu_page.dart';
part 'Pemesanan/keranjang_page.dart';
part 'Pemesanan/payment_page.dart';

const biru = Color(0xFF81D4FA);
final ValueNotifier<bool> modeGelap = ValueNotifier(false);
const biruMuda = Color(0xFFE1F5FE);
const kategori = ['Main Course', 'Snacks', 'Drinks', 'Dessert'];
const levelPedas = ['Tidak Pedas', 'Sedang', 'Pedas'];
const metodeBayar = ['Tunai', 'QRIS', 'Transfer Bank'];
late Box pelangganBox;
Map<String, dynamic>? pelangganAktif;
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
  pelangganBox = await Hive.openBox('pelanggan');
  menus = await Hive.openBox('menus');
  orders = await Hive.openBox('orders');

  // Data contoh
  // Kalau admin menghapus menu, aplikasi tidak akan memunculkannya lagi
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

Future<void> simpanPesanan(String metode, {String? bank, String kodePromo = '', int diskon = 0, DateTime? waktuAmbil}) async {
  final profil = pelangganAktif;
  if (profil == null) throw StateError('Masuk sebagai pelanggan untuk memesan.');
  final masalah = cekKeranjang();
  if (masalah != null) throw StateError(masalah);
  if (waktuAmbil != null) {
    final masalah = masalahJadwal(waktuAmbil, sekarangWib());
    if (masalah != null) throw StateError(masalah);
  }
  final waktu = DateTime.now();
  final id = 'BB-${waktu.microsecondsSinceEpoch}';
  // Simpan salinan nama dan harga agar nota lama tetap sama setelah menu diedit.
  await orders.put(id, {
    'orderId': id,
    'customer': {for (final key in ['name', 'phone', 'address']) key: profil[key]},
    if (metode == 'Transfer Bank') 'bank': bank,
    'orderDate': waktu.toIso8601String(),
    'items': [for (final item in cart) Map.of(item)],
    'subtotal': totalPrice,
    'promoCode': kodePromo,
    'discount': diskon,
    'totalPrice': totalPrice - diskon,
    'pickupDate': waktuAmbil == null ? null : teksIsoWib(waktuAmbil),
    'pickupMode': waktuAmbil == null ? 'asap' : 'scheduled',
    'paymentMethod': metode,
    'paymentStatus': metode == 'Tunai' ? 'Bayar saat ambil' : 'Simulasi pembayaran',
    'orderStatus': 'New',
    'pickupTime': waktuAmbil == null ? 'Ambil secepatnya' : teksAmbil(waktuAmbil),
  });
  cart.clear();
}

void pesan(BuildContext context, String teks) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(teks)));
}

// Tema terang dipisah supaya bisa dipakai ulang oleh kotak biru
class _PageList extends StatelessWidget {
  const _PageList({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: children,
          ),
        ),
      ),
    );
  }
}

const _heading = TextStyle(fontSize: 22, fontWeight: FontWeight.bold);
const _title = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);

final _inputTheme = InputDecorationTheme(
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);

final ThemeData temaTerang = ThemeData(
  useMaterial3: false,
  inputDecorationTheme: _inputTheme,
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
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
);

// Pembungkus yang memaksa isinya memakai tema terang (untuk kotak biru)
class TemaTerang extends StatelessWidget {
  final Widget child;
  const TemaTerang({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: temaTerang,
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        child: child,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: modeGelap,
      builder: (context, gelap, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BlueBite',
          themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
          theme: temaTerang,
          darkTheme: ThemeData(
            useMaterial3: false,
            inputDecorationTheme: _inputTheme,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: const ColorScheme.dark(
              primary: biru,
              secondary: biru,
              onPrimary: Colors.black,
              onSecondary: Colors.black,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: biru,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: biru),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                backgroundColor: biru,
                foregroundColor: Colors.black,
              ),
            ),
            // Snackbar dan footer sama persis dengan mode terang
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
          home: const AksesPage(),
        );
      },
    );
  }
}

// Switch mode gelap yang bisa dipasang di AppBar halaman mana pun
class SwitchModeGelap extends StatelessWidget {
  const SwitchModeGelap({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder membuat switch memperbarui dirinya sendiri
    return ValueListenableBuilder<bool>(
      valueListenable: modeGelap,
      builder: (context, gelap, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(gelap ? Icons.dark_mode : Icons.light_mode, size: 20),
            Switch(
              value: gelap,
              activeTrackColor: Colors.black54,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.black26,
              onChanged: (v) => modeGelap.value = v,
            ),
          ],
        );
      },
    );
  }
}

const _fotoAwal = {
  'nasi': 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=640',
  'mie': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=640',
  'sate': 'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=640',
  'ayam': 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=640',
  'bakso': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=640',
  'kwetiau': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=640',
  'tahu': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=640',
  'dimsum': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=640',
  'kentang': 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=640',
  'teh': 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=640',
  'jeruk': 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=640',
  'puding': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=640',
};

Widget fotoMenu(Map menu, {double ukuran = 64, double? lebar}) {
  final id = menu['id'];
  final simpan = menu['imageUrl']?.toString().trim() ?? '';
  // Pakai URL tersimpan; kalau kosong, pakai URL bawaan menu awal
  final url = simpan.isNotEmpty ? simpan : (_fotoAwal[id] ?? '');
  // Ikon cadangan jika tidak ada foto atau gagal dimuat
  final ikon = Container(
    color: biru,
    child: const Icon(Icons.restaurant, size: 32),
  );
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      width: lebar ?? ukuran,
      height: ukuran,
      child: url.isEmpty
          ? ikon
          : Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ikon,
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
  String? filter,
}) {
  final terlihat = orders.values.where((o) {
    if (ubahStatus != null) return filter == null || o['orderStatus'] == filter;
    return pelangganAktif != null && o['customer']?['phone'] == pelangganAktif!['phone'];
  }).toList().reversed.toList();
  if (ubahStatus != null && ['New', 'Processing', 'Ready'].contains(filter)) {
    terlihat.sort((a, b) {
      final jadwal = urutanAmbil(a).compareTo(urutanAmbil(b));
      return jadwal != 0 ? jadwal : a['orderDate'].compareTo(b['orderDate']);
    });
  }
  if (terlihat.isEmpty) return const Center(child: Text('Belum ada pesanan.'));
  return _PageList(
    children: [
      for (final o in terlihat)
        TemaTerang(
          child: Card(
            color: biruMuda,
            elevation: 0,
            child: ExpansionTile(
              textColor: Colors.black,
              iconColor: Colors.black,
              title: Text(o['customer']?['name'] ?? 'Pemesan belum tercatat', style: _title),
              subtitle: Text(
                [
                  if (ubahStatus != null && terlambatDiambil(o)) '⚠ Lewat jadwal ambil',
                  if (ubahStatus != null) (o['items'] as List).map((i) => "${i['quantity']}× ${i['name']}").join(', '),
                  if (ubahStatus != null) "Ambil: ${(o['pickupTime'] ?? '').isEmpty ? 'Belum ditentukan' : o['pickupTime']}",
                  "Dipesan: ${o['orderDate'].toString().substring(0, 16).replaceFirst('T', ' ')}",
                  "${o['orderId']} · ${labelStatus[o['orderStatus']] ?? o['orderStatus']}",
                  "Total: ${formatRupiah(o['totalPrice'])}",
                ].join('\n'),
              ),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                if (o['customer'] != null)
                  ListTile(leading: const Icon(Icons.person_outline),
                      title: Text(o['customer']['phone']), subtitle: Text(o['customer']['address'])),
                if (o['bank'] != null) Text("Bank: ${o['bank']}"),
                if ((o['discount'] ?? 0) > 0) ...[
                  Text("Subtotal: ${formatRupiah(o['subtotal'])}"),
                  Text("Promo ${o['promoCode']}: −${formatRupiah(o['discount'])}"),
                ],
                for (final item in o['items']) barisItem(item),
                Text("${o['paymentMethod']} · ${statusBayarTampil(o)}"),
                if ((o['pickupTime'] ?? '') != '')
                  Text('Pengambilan: ${o['pickupTime']}'),
                if (ubahStatus != null &&
                    !transaksi &&
                    statusBerikut.containsKey(o['orderStatus']))
                  Wrap(
                    children: [
                      TextButton(
                        onPressed: () => ubahStatus(
                          o,
                          statusBerikut[o['orderStatus']]!,
                        ),
                        child: Text(tombolStatus[o['orderStatus']]!),
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
        ),
    ],
  );
}