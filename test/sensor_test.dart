import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/models/user_model.dart';
import 'package:notes/screens/sensor_screen.dart';
import 'package:notes/services/sensor_math.dart';
import 'package:notes/theme/app_theme.dart';

void main() {
  group('terdeteksiGuncangan', () {
    test('diam di meja (sekitar 1 g) tidak terhitung', () {
      expect(terdeteksiGuncangan(const Vektor(0, 0, 1)), isFalse);
    });

    test('di bawah ambang tidak terhitung', () {
      expect(terdeteksiGuncangan(const Vektor(1.9, 0, 0), ambang: 2), isFalse);
    });

    test('tepat di ambang belum terhitung', () {
      expect(terdeteksiGuncangan(const Vektor(2, 0, 0), ambang: 2), isFalse);
    });

    test('di atas ambang terhitung', () {
      expect(terdeteksiGuncangan(const Vektor(2.1, 0, 0), ambang: 2), isTrue);
    });

    test('besar vektor memakai Pythagoras tiga sumbu', () {
      expect(besarVektor(const Vektor(3, 4, 0)), closeTo(5, 1e-9));
    });
  });

  group('PendeteksiGuncangan', () {
    const kuat = Vektor(3, 0, 0);
    const diam = Vektor(0, 0, 1);

    test('satu guncangan berlangsung beberapa pembacaan hanya dihitung sekali', () {
      final p = PendeteksiGuncangan(ambang: 2, jedaMs: 800);
      final hitung = [0, 100, 200, 300].where((t) => p.masukkan(kuat, t)).length;
      expect(hitung, 1);
    });

    test('guncangan setelah jeda dihitung lagi', () {
      final p = PendeteksiGuncangan(ambang: 2, jedaMs: 800);
      expect(p.masukkan(kuat, 0), isTrue);
      expect(p.masukkan(diam, 900), isFalse);
      expect(p.masukkan(kuat, 1000), isTrue);
    });

    test('reset membuat guncangan berikutnya dihitung sebagai kejadian baru', () {
      final p = PendeteksiGuncangan(ambang: 2, jedaMs: 800);
      expect(p.masukkan(kuat, 0), isTrue);
      p.reset();
      expect(p.masukkan(kuat, 100), isTrue);
    });
  });

  group('arahKompas dan mataAngin', () {
    test('mataAngin(0) bernilai U dan mataAngin(90) bernilai T', () {
      expect(mataAngin(0), 'U');
      expect(mataAngin(90), 'T');
    });

    test('sudut negatif dan lebih dari 360 tetap valid', () {
      expect(mataAngin(-90), 'B');
      expect(mataAngin(450), 'T');
    });

    test('arahKompas selalu di rentang 0 sampai 360', () {
      final d = arahKompas(10, -3);
      expect(d, greaterThanOrEqualTo(0));
      expect(d, lessThan(360));
    });
  });

  group('SensorScreen', () {
    final user = UserModel.fromJson(const {
      'name': 'tekno',
      'avatar': '-',
      'password': 'tekno1234',
      'created_at': '26-11-2026',
      'updated_at': '26-11-2026',
      'user_id': '1',
    });

    testWidgets('tetap tampil dan memakai fallback saat sensor tidak tersedia', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: SensorScreen(user: user)),
      );
      await tester.pump();

      expect(find.text('Guncangan & Kompas'), findsOneWidget);
      expect(find.text('Penghitung Guncangan'), findsOneWidget);
      expect(find.text('Kompas'), findsOneWidget);
      expect(find.text('Giroskop'), findsOneWidget);
    });

    testWidgets('tombol reset mengembalikan hitungan guncangan ke nol', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: SensorScreen(user: user)),
      );
      await tester.pump();

      await tester.tap(find.text('Reset hitungan'));
      await tester.pump();

      expect(find.text('0'), findsOneWidget);
    });
  });
}
