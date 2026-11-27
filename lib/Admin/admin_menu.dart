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
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue.shade800,
            backgroundColor: biruMuda,
            side: BorderSide(color: Colors.blue.shade600, width: 1.5),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => editMenu(),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Tambah menu'),
        ),
        const SizedBox(height: 16),
        for (final m in daftarMenu)
          TemaTerang( // BARU: kotak biru tetap tema terang
            child: Card(
              color: biruMuda,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    fotoMenu(m, ukuran: 60),
                    const SizedBox(height: 8),
                    Text(m['name'], style: _title),
                    Text("${formatRupiah(m['price'])} · ${m['category']}"),
                    Text("Stok ${stok(m)} · ${labelStok(stok(m))}"),
                  ])),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade800,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.blue.shade600, width: 1.5),
                        minimumSize: const Size(118, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => editMenu(m),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit / stok'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.red.shade500, width: 1.5),
                        minimumSize: const Size(118, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => hapusMenu(m),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                    ),
                  ]),
                ]),
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
          const SizedBox(height: 12),
          TextFormField(
            initialValue: deskripsi,
            decoration: const InputDecoration(labelText: 'Deskripsi'),
            onChanged: (s) => deskripsi = s,
          ),
          const SizedBox(height: 12),
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