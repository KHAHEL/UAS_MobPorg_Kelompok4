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