part of '../main.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedMethod = 'QRIS';
  String bank = 'BCA';
  bool sibuk = false;
  String inputPromo = '';
  String promoAktif = '';
  String infoPromo = '';
  int diskon = 0;
  void pakaiPromo() {
    final kode = inputPromo.trim().toUpperCase();
    setState(() {
      promoAktif = kode == 'HEMAT5K' ? kode : '';
      diskon = promoAktif.isEmpty ? 0 : min(5000, totalPrice);
      infoPromo = promoAktif.isEmpty ? 'Kode promo tidak tersedia.' : 'Promo berhasil dipakai.';
    });
  }

  bool terjadwal = false;
  DateTime? tanggal; // BARU: tanggal pengambilan hasil Date Picker
  TimeOfDay? jam; // BARU: jam pengambilan hasil Time Picker

  // BARU: Date Picker untuk memilih tanggal pengambilan (maksimal 3 hari ke depan)
  Future<void> pilihTanggal() async {
    final sekarang = sekarangWib();
    final hasil = await showDatePicker(
      context: context,
      initialDate: tanggal != null && !DateUtils.dateOnly(tanggal!).isBefore(DateUtils.dateOnly(sekarang)) ? tanggal! : sekarang,
      firstDate: sekarang,
      lastDate: sekarang.add(const Duration(days: 3)),
    );
    if (hasil != null) setState(() => tanggal = hasil);
  }

  // BARU: Time Picker untuk memilih jam pengambilan
  Future<void> pilihJam() async {
    final hasil = await showTimePicker(
      context: context,
      initialTime: jam ?? TimeOfDay.fromDateTime(sekarangWib()),
    );
    if (hasil != null) setState(() => jam = hasil);
  }

  Future<void> bayar() async {
    if (sibuk) return;
    DateTime? waktuAmbil;
    if (terjadwal) {
      if (tanggal == null || jam == null) {
        pesan(context, 'Pilih tanggal dan jam pengambilan.');
        return;
      }
      waktuAmbil = DateTime.utc(tanggal!.year, tanggal!.month, tanggal!.day, jam!.hour, jam!.minute);
      final masalah = masalahJadwal(waktuAmbil, sekarangWib());
      if (masalah != null) {
        pesan(context, masalah);
        return;
      }
    }
    setState(() => sibuk = true);
    try {
      await simpanPesanan(selectedMethod, bank: bank,
          waktuAmbil: waktuAmbil, kodePromo: promoAktif, diskon: diskon);
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
        appBar: AppBar(
          title: const Text('Checkout'),
          actions: const [SwitchModeGelap()],
        ),
        body: _PageList(
          children: [
            const Text('Ringkasan pesanan', style: _heading),
            const SizedBox(height: 8),
            if (pelangganAktif != null) ListTile(
                contentPadding: EdgeInsets.zero, leading: const Icon(Icons.person_outline),
                title: Text(pelangganAktif!['name']),
                subtitle: Text("${pelangganAktif!['phone']}\n${pelangganAktif!['address']}")),
            for (final item in cart) barisItem(item),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Kode promo', style: _title),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(
                enabled: !sibuk,
                decoration: const InputDecoration(hintText: 'Masukkan kode'),
                onChanged: (nilai) => setState(() {
                  inputPromo = nilai;
                  promoAktif = '';
                  diskon = 0;
                  infoPromo = '';
                }),
              )),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: sibuk || inputPromo.trim().isEmpty ? null : pakaiPromo,
                child: const Text('Pakai'),
              ),
            ]),
            if (infoPromo.isNotEmpty) Text(infoPromo),
            const SizedBox(height: 16),
            const Text('Metode pembayaran (simulasi)', style: _title),
            for (final m in metodeBayar)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: m == selectedMethod ? Colors.blue : Colors.grey),
                ),
                child: Column(children: [
                  RadioListTile<String>(
                    title: Text(m),
                    subtitle: m == 'Transfer Bank' ? const Text('a/n Sanjiro Mikael Khenji') : null,
                    controlAffinity: ListTileControlAffinity.trailing,
                    value: m, groupValue: selectedMethod,
                    onChanged: sibuk ? null : (nilai) => setState(() => selectedMethod = nilai!),
                  ),
                  if (m == 'Transfer Bank' && m == selectedMethod)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Pilih bank'),
                        value: bank, isExpanded: true,
                        items: [for (final b in ['BCA', 'Mandiri', 'BRI', 'BNI', 'BTN', 'SeaBank'])
                          DropdownMenuItem(value: b, child: Text(b))],
                        onChanged: sibuk ? null : (b) => setState(() => bank = b!),
                      ),
                    ),
                ]),
              ),
            const SizedBox(height: 8),
            if (selectedMethod == 'QRIS') ...[
              Image.asset('assets/pembayaran/kodok.png', height: 144, semanticLabel: 'Gambar kodok untuk simulasi QRIS'),
              const Center(child: Text('QRIS simulasi · gambar contoh')),
            ],
            const SizedBox(height: 12),
            // BARU: pilihan jadwal pengambilan (Date Picker dan Time Picker)
            const Text('Pengambilan pesanan', style: _title),
            for (final pilihJadwal in [false, true])
              RadioListTile<bool>(
                value: pilihJadwal,
                groupValue: terjadwal,
                title: Text(pilihJadwal ? 'Jadwalkan pengambilan' : 'Ambil secepatnya'),
                subtitle: Text(pilihJadwal ? 'Maksimal 3 hari ke depan, 10.00–21.00 WIB' : 'Saat makanan siap dalam jam buka kedai'),
                onChanged: sibuk ? null : (v) => setState(() => terjadwal = v!),
              ),
            if (terjadwal)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: sibuk ? null : pilihTanggal,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        tanggal == null
                            ? 'Pilih tanggal'
                            : '${tanggal!.day.toString().padLeft(2, '0')}/${tanggal!.month.toString().padLeft(2, '0')}/${tanggal!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: sibuk ? null : pilihJam,
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(jam == null ? 'Pilih jam' : '${duaDigit(jam!.hour)}:${duaDigit(jam!.minute)} WIB'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            const _EstimasiPerjalanan(),
            const Divider(),
            Text('Subtotal: ${formatRupiah(totalPrice)}'),
            if (promoAktif.isNotEmpty) Text('Diskon promo: −${formatRupiah(diskon)}'),
            Text('Total bayar: ${formatRupiah(totalPrice - diskon)}', style: _title),
            const SizedBox(height: 12),
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
// Kartu ini mengurus permintaan jaringan sendiri agar checkout tetap bisa dipakai.
class _EstimasiPerjalanan extends StatefulWidget {
  const _EstimasiPerjalanan();
  @override
  State<_EstimasiPerjalanan> createState() => _EstimasiPerjalananState();
}

class _EstimasiPerjalananState extends State<_EstimasiPerjalanan> {
  static const fore = 'Fore Elang Laut PIK';
  static final cache = <String, List<Map>>{};
  static DateTime terakhirCari = DateTime.fromMillisecondsSinceEpoch(0);
  String asal = '';
  List<Map> pilihan = [];
  String hasil = '';
  bool memuat = false;

  @override
  void initState() {
    super.initState();
    final alamat = pelangganAktif?['address']?.toString() ?? '';
    // Untuk alamat rumah, pelanggan dapat mengetik patokan umum terdekat.
    if (alamat.toLowerCase().contains('fore') && alamat.toLowerCase().contains('elang laut')) asal = fore;
  }

  Future<List<Map>> cariTempat(String kata) async {
    final key = kata.trim().toLowerCase();
    if (cache.containsKey(key)) return cache[key]!;
    final jeda = 1100 - DateTime.now().difference(terakhirCari).inMilliseconds;
    if (jeda > 0) await Future<void>.delayed(Duration(milliseconds: jeda));
    terakhirCari = DateTime.now();
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': kata, 'format': 'jsonv2', 'limit': '3', 'countrycodes': 'id',
      'viewbox': '106.55,-6.05,107.05,-6.45', 'bounded': '1',
    });
    final res = await http.get(uri, headers: {'User-Agent': 'BlueBitePickupStudentDemo/1.0'}).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw StateError('Pencarian lokasi sedang tidak tersedia.');
    final daftar = (jsonDecode(res.body) as List).cast<Map>();
    cache[key] = daftar;
    return daftar;
  }

  Future<void> hitungRute(Map dari) async {
    // Nama ruas jalan yang tercatat di peta. Nomor bangunan belum terverifikasi.
    final jalan = await cariTempat('Jalan Utama Sakti VI, Wijaya Kusuma, Jakarta Barat');
    if (jalan.isEmpty) throw StateError('Ruas jalan BlueBite belum ditemukan di peta.');
    final ke = jalan.first;
    final titik = "${dari['lon']},${dari['lat']};${ke['lon']},${ke['lat']}";
    final uri = Uri.https('router.project-osrm.org', '/route/v1/driving/$titik', {'overview': 'false'});
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw StateError('Rute berkendara tidak tersedia.');
    final data = jsonDecode(res.body);
    if (data['code'] != 'Ok' || data['routes'].isEmpty) throw StateError('Rute tidak ditemukan.');
    final rute = data['routes'][0];
    final km = (rute['distance'] / 1000).toStringAsFixed(1).replaceAll('.', ',');
    final menit = (rute['duration'] / 60).ceil();
    if (mounted) setState(() => hasil = "${dari['display_name']}\nSekitar $menit menit · $km km berkendara");
  }

  Future<void> cek({Map? tempat}) async {
    if (memuat || asal.trim().isEmpty) return;
    setState(() { memuat = true; hasil = ''; pilihan = []; });
    try {
      if (tempat != null) {
        await hitungRute(tempat);
      } else if (asal.trim().toLowerCase() == fore.toLowerCase()) {
        // Titik cabang dari peta resmi Fore Coffee.
        await hitungRute({'display_name': fore, 'lat': -6.123475346, 'lon': 106.7404688});
      } else {
        final daftar = await cariTempat(asal.trim());
        if (mounted) setState(() {
          pilihan = daftar;
          hasil = daftar.isEmpty ? 'Tempat tidak ditemukan. Coba nama patokan lain.' : 'Pilih titik keberangkatan yang sesuai.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => hasil = e is StateError ? e.message : 'Gagal memuat estimasi. Periksa koneksi atau lanjutkan pesanan.');
    } finally {
      if (mounted) setState(() => memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: biru)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.directions_car, color: Colors.blue),
              title: Text('Estimasi ke kedai', style: _title),
              subtitle: Text('BlueBite · Jl. Jelambar Utama Sakti VI No. 20, Wijaya Kusuma, Jakarta Barat')),
          TextFormField(initialValue: asal, enabled: !memuat,
              decoration: const InputDecoration(labelText: 'Patokan umum keberangkatan', hintText: 'Misal: Fore Elang Laut PIK'),
              onChanged: (v) => setState(() { asal = v; hasil = ''; pilihan = []; })),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: memuat || asal.trim().isEmpty ? null : () => cek(),
              icon: const Icon(Icons.route_outlined), label: Text(memuat ? 'Mencari…' : 'Cek estimasi')),
          if (hasil.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(hasil)),
          for (final p in pilihan) TextButton(onPressed: () => cek(tempat: p), child: Text(p['display_name'])),
          const Text('Perkiraan sampai ruas jalan kedai, tanpa lalu lintas langsung.\n© OpenStreetMap contributors · OSRM', style: TextStyle(fontSize: 12)),
        ],
      )),
    );
  }
}
