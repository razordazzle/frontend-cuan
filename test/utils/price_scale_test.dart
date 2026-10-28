import 'package:cuan_app/utils/price_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('priceTickSize', () {
    test('batas harga: 200 masih 1 poin, setelahnya 2 poin', () {
      expect(priceTickSize(1), 1);
      expect(priceTickSize(199), 1);
      expect(priceTickSize(200), 1);
      expect(priceTickSize(201), 2);
      expect(priceTickSize(500), 2);
      expect(priceTickSize(501), 5);
      expect(priceTickSize(2000), 5);
      expect(priceTickSize(2001), 10);
      expect(priceTickSize(5000), 10);
      expect(priceTickSize(5001), 25);
      expect(priceTickSize(9800), 25);
    });
  });

  group('priceAxisInterval', () {
    bool isClean(double v, double tick) =>
        v == v.roundToDouble() && v % tick == 0;

    test('rentang sempit tidak menghasilkan pecahan (kasus intraday)', () {
      // rentang 4 dengan 8 label dulu -> interval 0,5
      expect(priceAxisInterval(4510, 4514), 10); // tik 10 -> minimal 10
      expect(priceAxisInterval(9800, 9804), 25); // tik 25
      expect(priceAxisInterval(150, 154), 1); // tik 1
      expect(priceAxisInterval(350, 354), 2); // tik 2
      expect(priceAxisInterval(1500, 1504), 5); // tik 5
    });

    test('interval selalu bulat dan kelipatan tik, di semua kombinasi rentang', () {
      for (final price in [3, 120, 200, 350, 500, 800, 1999, 2400, 4999, 6500, 12000]) {
        for (final range in [0.0, 1, 2, 4, 7, 15, 40, 120, 480, 2500]) {
          final min = price.toDouble();
          final max = min + range;
          final tick = priceTickSize(max);
          final i = priceAxisInterval(min, max);
          expect(isClean(i, tick), isTrue,
              reason: 'harga $min..$max -> interval $i (tik $tick)');
        }
      }
    });

    test('rentang lebar tetap rapi (sekitar 8 garis, bukan ratusan)', () {
      final i = priceAxisInterval(1000, 2000); // rough 125 -> 250? kelipatan 5
      expect(i, inInclusiveRange(125, 250));
      expect((2000 - 1000) / i, lessThanOrEqualTo(10));
    });

    test('contoh dari tim: harga <=200 pakai 1 poin, 200-500 pakai 2 poin', () {
      expect(priceAxisInterval(100, 108), 1);
      expect(priceAxisInterval(300, 308), 2);
    });
  });
}
