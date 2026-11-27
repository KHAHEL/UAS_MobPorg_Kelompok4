part of '../main.dart';

// 10.0.2.2 mengarah ke laptop dari emulator Android Studio.
const alamatApi = String.fromEnvironment(
  'PROMO_API_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

Future<int> cekPromo(String kode, int subtotal) async {
  final response = await http.post(
    Uri.parse('$alamatApi/promo/check'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'code': kode, 'subtotal': subtotal}),
  ).timeout(const Duration(seconds: 6));

  if (response.statusCode != 200) throw StateError('Server promo sedang bermasalah.');
  final data = jsonDecode(response.body);
  if (data['valid'] != true) throw StateError(data['message']);
  final diskon = data['discount'];
  if (diskon is! int || diskon < 0 || diskon > subtotal) {
    throw StateError('Nilai diskon dari server tidak valid.');
  }
  return diskon;
}
