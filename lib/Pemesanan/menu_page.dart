part of '../main.dart';

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
      appBar: AppBar(
        title: const Text('Detail menu'),
        actions: const [SwitchModeGelap()],
      ),
      body: _PageList(
        children: [
          fotoMenu(m, ukuran: 180, lebar: double.infinity),
          const SizedBox(height: 18),
          Text(m['category']),
          const SizedBox(height: 4),
          Text(
            m['name'],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(m['description']),
          Text(
            "${formatRupiah(m['price'])} · Stok ${stok(m)}",
            style: _title,
          ),
          const SizedBox(height: 18),
          if (m['spicy']) const Text('Level pedas', style: _title),
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
              const Expanded(child: Text('Jumlah', style: _title)),
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
          const SizedBox(height: 12),
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