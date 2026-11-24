part of '../main.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedMethod = 'QRIS';
  bool sibuk = false;
  DateTime? tanggal; // BARU: tanggal pengambilan hasil Date Picker
  TimeOfDay? jam; // BARU: jam pengambilan hasil Time Picker

  // BARU: Date Picker untuk memilih tanggal pengambilan (maksimal 30 hari ke depan)
  Future<void> pilihTanggal() async {
    final sekarang = DateTime.now();
    final hasil = await showDatePicker(
      context: context,
      initialDate: tanggal ?? sekarang,
      firstDate: sekarang,
      lastDate: sekarang.add(const Duration(days: 30)),
    );
    if (hasil != null) setState(() => tanggal = hasil);
  }

  // BARU: Time Picker untuk memilih jam pengambilan
  Future<void> pilihJam() async {
    final hasil = await showTimePicker(
      context: context,
      initialTime: jam ?? TimeOfDay.now(),
    );
    if (hasil != null) setState(() => jam = hasil);
  }

  // BARU: menggabungkan tanggal dan jam menjadi satu teks jadwal
  String? susunJadwal() {
    final bagian = <String>[];
    if (tanggal != null) {
      final d = tanggal!;
      bagian.add(
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
      );
    }
    if (jam != null) bagian.add(jam!.format(context));
    return bagian.isEmpty ? null : bagian.join(' ');
  }

  Future<void> bayar() async {
    if (sibuk) return;
    final jadwal = susunJadwal(); // dihitung sebelum proses async
    setState(() => sibuk = true);
    try {
      await simpanPesanan(selectedMethod, jadwal: jadwal); // DIUBAH
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
            for (final item in cart) barisItem(item),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Total ${formatRupiah(totalPrice)}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            const Text('Metode pembayaran', style: _title),
            for (final m in metodeBayar)
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(m),
                value: m,
                groupValue: selectedMethod,
                onChanged: sibuk
                    ? null
                    : (s) => setState(() => selectedMethod = s!),
              ),
            const SizedBox(height: 8),
            // BARU: pilihan jadwal pengambilan (Date Picker dan Time Picker)
            const Text('Jadwal pengambilan (opsional)', style: _title),
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
                    label: Text(jam == null ? 'Pilih jam' : jam!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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