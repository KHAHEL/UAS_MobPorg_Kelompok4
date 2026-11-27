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
  bool mengecek = false;

  Future<void> pakaiPromo() async {
    final kode = inputPromo.trim().toUpperCase();
    if (kode.isEmpty || mengecek || sibuk) return;
    setState(() => mengecek = true);
    try {
      final hasil = await cekPromo(kode, totalPrice);
      if (!mounted) return;
      setState(() {
        promoAktif = kode;
        diskon = hasil;
        infoPromo = 'Promo berhasil dipakai.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        promoAktif = '';
        diskon = 0;
        infoPromo = e is StateError ? e.message : 'API promo tidak terhubung. Coba lagi atau lanjut tanpa promo.';
      });
    } finally {
      if (mounted) setState(() => mengecek = false);
    }
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
    if (sibuk || mengecek) return;
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
      // Periksa lagi agar diskon yang disimpan masih berlaku.
      if (promoAktif.isNotEmpty) {
        try {
          final terbaru = await cekPromo(promoAktif, totalPrice);
          if (terbaru != diskon) throw StateError('Diskon berubah. Tekan Pakai untuk mengecek lagi.');
        } catch (e) {
          if (!mounted) return;
          setState(() {
            promoAktif = '';
            diskon = 0;
            infoPromo = e is StateError ? e.message : 'Gagal mengecek promo. Coba lagi atau lanjut tanpa promo.';
            sibuk = false;
          });
          return;
        }
      }
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
                enabled: !sibuk && !mengecek,
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
                onPressed: sibuk || mengecek || inputPromo.trim().isEmpty ? null : pakaiPromo,
                child: Text(mengecek ? 'Cek…' : 'Pakai'),
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
              Image.asset('assets/kodok.png', height: 144, semanticLabel: 'Gambar kodok untuk simulasi QRIS'),
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
            const Divider(),
            Text('Subtotal: ${formatRupiah(totalPrice)}'),
            if (promoAktif.isNotEmpty) Text('Diskon promo: −${formatRupiah(diskon)}'),
            Text('Total bayar: ${formatRupiah(totalPrice - diskon)}', style: _title),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: sibuk || mengecek ? null : bayar,
              child: const Text('Konfirmasi pesanan'),
            ),
          ],
        ),
      ),
    );
  }
}