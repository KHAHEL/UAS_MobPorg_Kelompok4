part of 'main.dart';

String labelStok(int sisa) {
  if (sisa == 0) return 'Habis';
  if (sisa <= 5) return 'Stok rendah';
  return 'Tersedia';
}

Future<bool> konfirmasi(BuildContext context, String judul, String isi) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(judul),
          content: Text(isi),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Kembali'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, lanjutkan'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> simpanStatus(String id, String baru) async {
  final order = Map.of(orders.get(id) as Map);
  final lama = order['orderStatus'];
  final boleh =
      (lama == 'Processing' && ['Ready', 'Cancelled'].contains(baru)) ||
      (lama == 'Ready' && ['Completed', 'Cancelled'].contains(baru));
  if (!boleh) return;
  order['orderStatus'] = baru;
  if (baru == 'Cancelled') order['paymentStatus'] = 'Dibatalkan (simulasi)';
  // Stok dihitung dari order aktif. Membuka ulang order batal tidak mengubah stok.
  await orders.put(id, order);
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool masuk = false;
  int tab = 0;
  String user = '', sandi = '', salah = '';

  Future<void> ubahStatus(Map order, String baru) async {
    if (baru == 'Cancelled' &&
        !await konfirmasi(
          context,
          'Batalkan pesanan?',
          'Stok item akan dikembalikan.',
        ))
      return;
    try {
      await simpanStatus(order['orderId'], baru);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) pesan(context, 'Status gagal disimpan.');
    }
  }

  Future<void> editMenu([Map? m]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormMenu(m)),
    );
    if (mounted) setState(() {});
  }

  Future<void> hapusMenu(Map m) async {
    if (!await konfirmasi(
      context,
      'Hapus menu?',
      "Hapus ${m['name']} dari daftar menu?",
    ))
      return;
    try {
      await menus.delete(m['id']);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) pesan(context, 'Menu gagal dihapus.');
    }
  }

  Widget login() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'Username'),
          onChanged: (s) => user = s,
        ),
        TextField(
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          onChanged: (s) => sandi = s,
        ),
        if (salah.isNotEmpty) Text(salah),
        ElevatedButton(
          onPressed: () => setState(() {
            masuk = user.trim() == 'admin' && sandi == 'admin123';
            if (!masuk) salah = 'Username atau password salah.';
          }),
          child: const Text('Masuk'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['Dashboard', 'Menu', 'Pesanan', 'Transaksi'];
    Widget isi;
    if (!masuk) {
      isi = login();
    } else if (tab == 0) {
      final habis = daftarMenu.where((m) => stok(m) == 0).length;
      isi = ListView(
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
    } else if (tab == 1) {
      isi = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () => editMenu(),
            child: const Text('Tambah menu'),
          ),
          for (final m in daftarMenu)
            Card(
              color: biruMuda,
              elevation: 0,
              child: Column(
                children: [
                  ListTile(
                    leading: fotoMenu(m, ukuran: 52),
                    title: Text(m['name']),
                    subtitle: Text(
                      "${formatRupiah(m['price'])} · ${m['category']}\nStok ${stok(m)} · ${labelStok(stok(m))}",
                    ),
                  ),
                  Wrap(
                    children: [
                      TextButton(
                        onPressed: () => editMenu(m),
                        child: const Text('Edit / stok'),
                      ),
                      TextButton(
                        onPressed: () => hapusMenu(m),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      isi = daftarPesanan(
        ubahStatus: tab == 2 ? ubahStatus : null,
        transaksi: tab == 3,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(masuk ? tabs[tab] : 'Login admin'),
        actions: [
          if (masuk)
            IconButton(
              tooltip: 'Keluar admin',
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      body: SafeArea(child: isi),
      bottomNavigationBar: !masuk
          ? null
          : BottomNavigationBar(
              currentIndex: tab,
              onTap: (i) => setState(() => tab = i),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu),
                  label: 'Menu',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long),
                  label: 'Pesanan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payments_outlined),
                  label: 'Transaksi',
                ),
              ],
            ),
    );
  }
}

class FormMenu extends StatefulWidget {
  final Map? menu;
  const FormMenu(this.menu, {super.key});
  @override
  State<FormMenu> createState() => _FormMenuState();
}

class _FormMenuState extends State<FormMenu> {
  late String nama, deskripsi, harga, jumlah, foto;
  String? jenis;
  bool pedas = false, sibuk = false;
  String masalah = '';
  @override
  void initState() {
    super.initState();
    final m = widget.menu;
    nama = m?['name'] ?? '';
    deskripsi = m?['description'] ?? '';
    foto = m?['imageUrl'] ?? '';
    harga = m?['price']?.toString() ?? '';
    jumlah = m == null ? '0' : stok(m).toString();
    jenis = m?['category'];
    pedas = m?['spicy'] ?? false;
  }

  Future<void> simpan() async {
    if (sibuk) return;
    final nilai = int.tryParse(harga.trim());
    final sisa = int.tryParse(jumlah.trim());
    if (nama.trim().isEmpty ||
        nilai == null ||
        nilai <= 0 ||
        sisa == null ||
        sisa < 0 ||
        jenis == null) {
      setState(
        () => masalah =
            'Isi nama dan kategori. Harga harus positif dan stok minimal 0 (bilangan bulat).',
      );
      return;
    }
    setState(() => sibuk = true);
    final id =
        widget.menu?['id'] ?? 'M-${DateTime.now().microsecondsSinceEpoch}';
    try {
      await menus.put(id, {
        'id': id,
        'name': nama.trim(),
        'description': deskripsi.trim(),
        'category': jenis,
        'price': nilai,
        'stock': sisa + terjual(id),
        'spicy': pedas,
        'imageUrl': foto.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        setState(() {
          sibuk = false;
          masalah = 'Menu gagal disimpan.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menu == null ? 'Tambah menu' : 'Edit menu dan stok'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            initialValue: nama,
            decoration: const InputDecoration(labelText: 'Nama menu'),
            onChanged: (s) => nama = s,
          ),
          TextFormField(
            initialValue: deskripsi,
            decoration: const InputDecoration(labelText: 'Deskripsi'),
            onChanged: (s) => deskripsi = s,
          ),
          TextFormField(
            initialValue: foto,
            decoration: const InputDecoration(
              labelText: 'Link foto (opsional)',
            ),
            onChanged: (s) => foto = s,
          ),
          DropdownButton<String>(
            hint: const Text('Pilih kategori'),
            isExpanded: true,
            value: jenis,
            items: [
              for (final k in kategori)
                DropdownMenuItem(value: k, child: Text(k)),
            ],
            onChanged: (s) => setState(() => jenis = s),
          ),
          TextFormField(
            initialValue: harga,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Harga (Rp)'),
            onChanged: (s) => harga = s,
          ),
          TextFormField(
            initialValue: jumlah,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Stok tersedia'),
            onChanged: (s) => jumlah = s,
          ),
          CheckboxListTile(
            value: pedas,
            title: const Text('Bisa pilih level pedas'),
            onChanged: (s) => setState(() => pedas = s!),
          ),
          if (masalah.isNotEmpty) Text(masalah),
          ElevatedButton(
            onPressed: sibuk ? null : simpan,
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
