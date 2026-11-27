part of '../main.dart';

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

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool masuk = false;
  int tab = 0;
  String filterPesanan = 'New';
  String user = '', sandi = '', salah = '';

  Timer? pengingat;

  @override
  void initState() {
    super.initState();
    pengingat = Timer.periodic(const Duration(seconds: 30), (_) {
      if (masuk && tab == 2 && filterPesanan == 'Ready') setState(() {});
    });
  }

  @override
  void dispose() {
    pengingat?.cancel();
    super.dispose();
  }

  Future<void> ubahStatus(Map order, String baru) async {
    if (baru == 'Completed' && order['paymentMethod'] == 'Tunai' &&
        !await konfirmasi(context, 'Terima pembayaran tunai?',
            'Pastikan uang ${formatRupiah(order['totalPrice'])} sudah diterima dan makanan sudah diserahkan.')) return;
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
    return _PageList(
      children: [
        const Icon(Icons.restaurant_menu, size: 40),
        const SizedBox(height: 12),
        const Center(child: Text('BlueBite', style: _heading)),
        const SizedBox(height: 24),
        TextField(
          decoration: const InputDecoration(labelText: 'Username'),
          onChanged: (s) => user = s,
        ),
        const SizedBox(height: 14),
        TextField(
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          onChanged: (s) => sandi = s,
        ),
        const SizedBox(height: 16),
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
    const tabs = ['Dashboard', 'Menu', 'Pesanan'];
    Widget isi;
    if (!masuk) {
      isi = login();
    } else if (tab == 0) {
      isi = halamanDashboard();
    } else if (tab == 1) {
      isi = halamanMenuAdmin();
    } else {
      isi = halamanPesananAdmin();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(masuk ? tabs[tab] : 'Login admin'),
        actions: [
          const SwitchModeGelap(),
          if (masuk)
            IconButton(tooltip: 'Masuk sebagai pelanggan', icon: const Icon(Icons.person_outline),
                onPressed: () => Navigator.pop(context)),
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
        ],
      ),
    );
  }
}