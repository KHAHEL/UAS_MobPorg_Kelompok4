part of '../main.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedMethod = 'QRIS';
  bool sibuk = false;
  Future<void> bayar() async {
    if (sibuk) return;
    setState(() => sibuk = true);
    try {
      await simpanPesanan(selectedMethod);
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
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final item in cart) barisItem(item),
            Text(
              'Total ${formatRupiah(totalPrice)}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            const Text('Metode pembayaran'),
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