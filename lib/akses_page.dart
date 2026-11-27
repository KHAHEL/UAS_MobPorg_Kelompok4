part of 'main.dart';

class AksesPage extends StatefulWidget {
  const AksesPage({super.key});
  @override
  State<AksesPage> createState() => _AksesPageState();
}

class _AksesPageState extends State<AksesPage> {
  final form = GlobalKey<FormState>();
  final phone = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  final address = TextEditingController();
  bool daftar = false, sibuk = false;
  String info = '';

  @override
  void dispose() {
    for (final c in [phone, password, name, address]) {
      c.dispose();
    }
    super.dispose();
  }

  String nomor() {
    final angka = phone.text.replaceAll(RegExp(r'[\s()+-]'), '');
    return angka.startsWith('62') ? '0${angka.substring(2)}' : angka;
  }

  Future<void> masuk() async {
    if (sibuk || !form.currentState!.validate()) return;
    setState(() { sibuk = true; info = ''; });
    try {
      final id = nomor();
      final lama = pelangganBox.get(id);
      if (daftar && lama != null) throw StateError('Nomor ini sudah terdaftar.');
      if (!daftar && lama == null) throw StateError('Nomor atau kata sandi salah.');
      final salt = daftar
          ? List<int>.generate(16, (_) => Random.secure().nextInt(256))
          : base64Decode(lama['salt']);
      final kunci = await Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 120000, bits: 256)
          .deriveKey(secretKey: SecretKey(utf8.encode(password.text)), nonce: salt);
      final hash = base64Encode(await kunci.extractBytes());
      if (!daftar && hash != lama['hash']) throw StateError('Nomor atau kata sandi salah.');
      final profil = daftar
          ? {'name': name.text.trim(), 'address': address.text.trim(), 'phone': id}
          : {'name': lama['name'], 'address': lama['address'], 'phone': id};
      if (daftar) await pelangganBox.put(id, {...profil, 'salt': base64Encode(salt), 'hash': hash});
      if (!mounted) return;
      pelangganAktif = Map<String, dynamic>.from(profil);
      cart.clear();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RestoranPage()));
    } catch (e) {
      if (mounted) setState(() => info = e is StateError ? e.message : 'Gagal membuka akun. Coba lagi.');
    } finally {
      if (mounted) setState(() => sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BlueBite'), actions: const [SwitchModeGelap()]),
      body: _PageList(children: [
        Text(daftar ? 'Daftar pelanggan' : 'Masuk sebagai pelanggan', style: _heading),
        const SizedBox(height: 20),
        Form(key: form, child: Column(children: [
          if (daftar) ...[
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nama pemesan'),
                validator: (s) => (s ?? '').trim().isEmpty ? 'Isi nama pemesan.' : null),
            const SizedBox(height: 12),
            TextFormField(controller: address, decoration: const InputDecoration(labelText: 'Alamat'),
                validator: (s) => (s ?? '').trim().isEmpty ? 'Isi alamat.' : null),
            const SizedBox(height: 12),
          ],
          TextFormField(key: const ValueKey('phone'), controller: phone, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor telepon'),
              validator: (_) => RegExp(r'^0[0-9]{8,13}$').hasMatch(nomor()) ? null : 'Isi nomor telepon yang valid.'),
          const SizedBox(height: 12),
          TextFormField(key: const ValueKey('password'), controller: password, obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata sandi'),
              validator: (s) => (s ?? '').length < 6 ? 'Gunakan minimal 6 karakter.' : null),
        ])),
        if (info.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(info)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: sibuk ? null : masuk, child: Text(daftar ? 'Daftar dan masuk' : 'Masuk')),
        TextButton(onPressed: sibuk ? null : () => setState(() { daftar = !daftar; info = ''; }),
            child: Text(daftar ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar')),
        const Divider(),
        OutlinedButton.icon(onPressed: sibuk ? null : () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminPage())),
            icon: const Icon(Icons.admin_panel_settings_outlined), label: const Text('Masuk sebagai admin')),
      ]),
    );
  }
}
