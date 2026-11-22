import 'dart:typed_data';
import 'dart:io';
import 'package:bluebite/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory folder;
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('bluebite_test');
    Hive.init(folder.path);
    await bukaDatabase();
    cart.clear();
  });
  tearDown(() async {
    await Hive.close();
    cart.clear();
    await folder.delete(recursive: true);
  });

  test('Varian pedas berbagi stok dan item identik digabung', () {
    final nasi = menus.get('nasi');
    tambahKeranjang(nasi, 'Sedang', 2);
    tambahKeranjang(nasi, 'Sedang', 1);
    tambahKeranjang(nasi, 'Pedas', 17);
    tambahKeranjang(nasi, 'Tidak Pedas', 1);
    expect(cart.length, 2);
    expect(dalamCart('nasi'), 20);
    expect(stok(nasi), 20);
    expect(totalPrice, 500000);
  });

  test(
    'Stok kurang, harga berubah, dan menu terhapus mencegah checkout',
    () async {
      final nasi = Map.of(menus.get('nasi') as Map);
      tambahKeranjang(nasi, 'Sedang', 3);
      await menus.put('nasi', {...nasi, 'stock': 2});
      await expectLater(simpanPesanan('Tunai'), throwsStateError);
      await menus.put('nasi', {...nasi, 'price': 27500});
      await expectLater(simpanPesanan('Tunai'), throwsStateError);
      await menus.delete('nasi');
      await expectLater(simpanPesanan('Tunai'), throwsStateError);
      expect(cart.length, 1);
      expect(orders.length, 0);
    },
  );

  test(
    'Pembayaran, total, stok dan riwayat bertahan setelah Hive dibuka ulang',
    () async {
      tambahKeranjang(menus.get('nasi'), 'Pedas', 2);
      tambahKeranjang(menus.get('mie'), 'Sedang', 1);
      await simpanPesanan('Transfer Bank');
      await expectLater(simpanPesanan('Transfer Bank'), throwsStateError);
      await Hive.close();
      await bukaDatabase();
      expect(orders.length, 1);
      final o = orders.values.single;
      expect(o['totalPrice'], 70000);
      expect(formatRupiah(o['totalPrice']), 'Rp70.000');
      expect(o['paymentMethod'], 'Transfer Bank');
      expect(stok(menus.get('nasi')), 18);
      expect(stok(menus.get('mie')), 14);
      await menus.delete('nasi');
      expect(o['items'].first['name'], 'Nasi Goreng');
      expect(o['items'].first['price'], 25000);
      expect(cart, isEmpty);
    },
  );

  test('Batal dua kali mengembalikan stok hanya sekali', () async {
    tambahKeranjang(menus.get('nasi'), 'Pedas', 3);
    await simpanPesanan('QRIS');
    final id = orders.keys.single;
    expect(stok(menus.get('nasi')), 17);
    await simpanStatus(id, 'Ready');
    await simpanStatus(id, 'Cancelled');
    await simpanStatus(id, 'Cancelled');
    expect(stok(menus.get('nasi')), 20);
    expect(orders.get(id)['paymentStatus'], 'Dibatalkan (simulasi)');
  });

  test('Pesanan selesai tidak dapat dibatalkan', () async {
    tambahKeranjang(menus.get('nasi'), 'Pedas', 1);
    await simpanPesanan('Tunai');
    final id = orders.keys.single;
    await simpanStatus(id, 'Completed');
    expect(orders.get(id)['orderStatus'], 'Processing');
    await simpanStatus(id, 'Ready');
    await simpanStatus(id, 'Completed');
    await simpanStatus(id, 'Cancelled');
    expect(orders.get(id)['orderStatus'], 'Completed');
    expect(stok(menus.get('nasi')), 19);
  });

  test('Menu kosong milik admin tidak diisi lagi setelah restart', () async {
    for (final m in daftarMenu) {
      await menus.delete(m['id']);
    }
    await Hive.close();
    await bukaDatabase();
    expect(daftarMenu, isEmpty);
  });

  group('Antarmuka dengan Hive dalam memori', () {
    setUp(() async {
      await Hive.close();
      await Hive.openBox('menus', bytes: Uint8List(0));
      await Hive.openBox('orders', bytes: Uint8List(0));
      await bukaDatabase();
    });
    testWidgets('Keranjang di layar 320 piksel: batas stok dan hapus item', (
      t,
    ) async {
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      tambahKeranjang(menus.get('nasi'), 'Sedang', 20);
      await t.pumpWidget(const MyApp());
      await t.tap(find.text('Lihat keranjang'));
      await t.pumpAndSettle();
      expect(
        t
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
            .onPressed,
        isNull,
      );
      await t.tap(find.byTooltip('Hapus item'));
      await t.pumpAndSettle();
      expect(find.text('Keranjang masih kosong.'), findsOneWidget);
      expect(
        t
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Checkout'),
            )
            .onPressed,
        isNull,
      );
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'Pembeli mencari, memfilter, mengatur jumlah, dan bayar sekali',
      (t) async {
        Future<void> tap(Finder f) async {
          await t.ensureVisible(f.last);
          await t.tap(f.last);
          await t.pumpAndSettle();
        }

        await t.pumpWidget(const MyApp());
        expect(find.text('Selamat datang di BlueBite'), findsOneWidget);
        await tap(find.text('Lihat keranjang'));
        expect(find.text('Keranjang masih kosong.'), findsOneWidget);
        await t.pageBack();
        await t.pumpAndSettle();
        await tap(find.text('Lihat menu'));
        await t.enterText(find.byType(TextFormField), 'nASi');
        await t.pumpAndSettle();
        expect(find.text('Nasi Goreng'), findsOneWidget);
        expect(find.text('Mie Ayam'), findsNothing);
        await tap(find.text('Semua'));
        await tap(find.text('Drinks'));
        expect(find.text('Menu tidak ditemukan.'), findsOneWidget);
        await tap(find.text('Drinks'));
        await tap(find.text('Semua'));
        await tap(find.text('Tambah'));
        await tap(find.text('Sedang'));
        await tap(find.text('Pedas'));
        await tap(find.byTooltip('Tambah jumlah'));
        await tap(find.text('Masukkan ke keranjang'));
        await tap(find.byTooltip('Keranjang'));
        expect(find.text('Total Rp50.000'), findsOneWidget);
        await tap(find.byTooltip('Tambah jumlah'));
        await tap(find.byTooltip('Kurangi'));
        await tap(find.text('Checkout'));
        await tap(find.text('QRIS'));
        await tap(find.text('Tunai'));
        final tombol = find.text('Konfirmasi pesanan');
        await t.tap(tombol);
        await t.tap(tombol, warnIfMissed: false);
        await t.pumpAndSettle();
        expect(orders.length, 1);
        expect(stok(menus.get('nasi')), 18);
        await tap(find.text('Riwayat').last);
        await tap(find.text(orders.keys.first));
        expect(find.text('Nasi Goreng · Pedas'), findsOneWidget);
        expect(find.text('Tunai · Lunas (simulasi)'), findsOneWidget);
      },
    );

    testWidgets('Admin login, tambah, edit, hapus, dan stok terlihat pembeli', (
      t,
    ) async {
      Future<void> tap(Finder f) async {
        await t.ensureVisible(f.last);
        await t.tap(f.last);
        await t.pumpAndSettle();
      }

      Future<void> login() async {
        await tap(find.text('Login admin'));
        await t.enterText(find.byType(TextField).first, 'admin');
        await tap(find.text('Masuk'));
        expect(find.text('Username atau password salah.'), findsOneWidget);
        await t.enterText(find.byType(TextField).last, 'admin123');
        await tap(find.text('Masuk'));
        expect(find.text('Jumlah pesanan'), findsOneWidget);
        await tap(find.text('Menu'));
      }

      await t.pumpWidget(const MyApp());
      await tap(find.text('Info'));
      await login();
      await tap(find.text('Tambah menu'));
      await tap(find.text('Simpan'));
      expect(find.textContaining('Harga harus positif'), findsOneWidget);
      await t.enterText(find.byType(TextFormField).at(0), 'Air Mineral');
      await tap(find.byType(DropdownButton<String>));
      await tap(find.text('Drinks'));
      await t.enterText(find.byType(TextFormField).at(2), '5000');
      await t.enterText(find.byType(TextFormField).at(3), '4');
      await tap(find.text('Simpan'));
      await t.pumpAndSettle();
      expect(daftarMenu.where((m) => m['name'] == 'Air Mineral').length, 1);
      await t.scrollUntilVisible(
        find.text('Air Mineral'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      Finder card() => find.ancestor(
        of: find.text('Air Mineral'),
        matching: find.byType(Card),
      );
      await tap(
        find.descendant(of: card(), matching: find.text('Edit / stok')),
      );
      await t.enterText(find.byType(TextFormField).at(3), '0');
      await tap(find.text('Simpan'));
      await t.pumpAndSettle();
      await tap(find.byTooltip('Keluar admin'));
      await tap(find.text('Menu'));
      await t.enterText(find.byType(TextFormField), 'Air Mineral');
      await t.pumpAndSettle();
      expect(find.text('Habis'), findsOneWidget);
      expect(
        t
            .widget<TextButton>(find.widgetWithText(TextButton, 'Habis'))
            .onPressed,
        isNull,
      );
      await tap(find.text('Info'));
      await login();
      await t.scrollUntilVisible(
        find.text('Air Mineral'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(find.descendant(of: card(), matching: find.text('Hapus')));
      await tap(find.text('Ya, lanjutkan'));
      await t.pumpAndSettle();
      expect(daftarMenu.any((m) => m['name'] == 'Air Mineral'), isFalse);
      expect(t.takeException(), isNull);
    });
    testWidgets('Admin memproses pesanan, melihat transaksi dan membatalkan', (
      t,
    ) async {
      await t.runAsync(() async {
        tambahKeranjang(menus.get('nasi'), 'Sedang', 1);
        await simpanPesanan('QRIS');
      });
      final id = orders.keys.single as String;
      Future<void> tap(Finder finder) async {
        await t.ensureVisible(finder.last);
        await t.tap(finder.last);
        await t.pumpAndSettle();
      }

      await t.pumpWidget(const MyApp());
      await tap(find.text('Info'));
      await tap(find.text('Login admin'));
      await t.enterText(find.byType(TextField).first, 'admin');
      await t.enterText(find.byType(TextField).last, 'admin123');
      await tap(find.text('Masuk'));
      await tap(find.text('Pesanan'));
      await tap(find.text(id));
      await tap(find.text('Tandai Ready'));
      await t.pumpAndSettle();
      expect(orders.get(id)['orderStatus'], 'Ready');
      await tap(find.text('Batalkan pesanan'));
      await tap(find.text('Ya, lanjutkan'));
      await t.pumpAndSettle();
      expect(stok(menus.get('nasi')), 20);
      await tap(find.text('Transaksi'));
      if (find.text('QRIS · Dibatalkan (simulasi)').evaluate().isEmpty) {
        await tap(find.text(id));
      }
      expect(find.text('QRIS · Dibatalkan (simulasi)'), findsOneWidget);
      expect(find.text('Batalkan pesanan'), findsNothing);
    });
  });
}
