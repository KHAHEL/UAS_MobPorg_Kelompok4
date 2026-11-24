part of '../main.dart';

String labelStok(int sisa) {
  if (sisa == 0) return 'Habis';
  if (sisa <= 5) return 'Stok rendah';
  return 'Tersedia';
}

extension AdminMenu on _AdminPageState {
  Widget halamanMenuAdmin() {
    return _PageList(
      children: [
        ElevatedButton(
          onPressed: () => editMenu(),
          child: const Text('Tambah menu'),
        ),
        const SizedBox(height: 16),
        for (final m in daftarMenu)
          TemaTerang( // BARU: kotak biru tetap tema terang
            child: Card(
              color: biruMuda,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          ),
      ],
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
  int versiForm = 0; // dinaikkan agar TextFormField dibangun ulang
  bool mencari = false; // status loading saat memanggil API

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

  // Mengambil data makanan dari TheMealDB berdasarkan kata kunci nama
  Future<void> cariDariApi() async {
    final kata = nama.trim();
    if (kata.isEmpty) {
      setState(() => masalah = 'Isi nama menu dulu sebagai kata kunci.');
      return;
    }
    setState(() {
      mencari = true;
      masalah = '';
    });
    try {
      final uri = Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/search.php?s=${Uri.encodeComponent(kata)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Status ${res.statusCode}');
      final data = jsonDecode(res.body);
      final hasil = data['meals'];
      if (hasil == null || hasil.isEmpty) {
        setState(
              () => masalah =
          'Tidak ada hasil. Coba kata kunci bahasa Inggris, misalnya "chicken".',
        );
      } else {
        final m = hasil[0];
        setState(() {
          foto = m['strMealThumb'] ?? foto;
          deskripsi = '${m['strCategory']} - ${m['strArea']}';
          versiForm++; // paksa field terisi ulang dengan nilai baru
        });
      }
    } catch (_) {
      setState(
            () => masalah = 'Gagal mengambil data. Periksa koneksi internet.',
      );
    } finally {
      if (mounted) setState(() => mencari = false);
    }
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
        actions: const [SwitchModeGelap()], // BARU: switch mode gelap
      ),
      body: _PageList(
        children: [
          const SizedBox(height: 12),
          TextFormField(
            initialValue: nama,
            decoration: const InputDecoration(labelText: 'Nama menu'),
            onChanged: (s) => nama = s,
          ),
          OutlinedButton(
            onPressed: mencari ? null : cariDariApi,
            child: Text(mencari ? 'Mencari...' : 'Cari dari API'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('deskripsi$versiForm'),
            initialValue: deskripsi,
            decoration: const InputDecoration(labelText: 'Deskripsi'),
            onChanged: (s) => deskripsi = s,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('foto$versiForm'),
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
          const SizedBox(height: 12),
          TextFormField(
            initialValue: harga,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Harga (Rp)'),
            onChanged: (s) => harga = s,
          ),
          const SizedBox(height: 12),
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