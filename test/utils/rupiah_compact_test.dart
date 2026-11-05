import 'package:flutter_test/flutter_test.dart';
import 'package:cuan_app/utils/rupiah_compact.dart';

void main() {
  test('miliar & triliun', () {
    expect(formatRupiahCompact(206535361000), 'Rp 206,5 M');
    expect(formatRupiahCompact(54470119600), 'Rp 54,5 M');
    expect(formatRupiahCompact(2500000000000), 'Rp 2,5 T');
    expect(formatRupiahCompact(3000000000), 'Rp 3 M');
  });

  test('juta, ribu, kecil', () {
    expect(formatRupiahCompact(450000000), 'Rp 450 Jt');
    expect(formatRupiahCompact(12500), 'Rp 12,5 Rb');
    expect(formatRupiahCompact(500), 'Rp 500');
  });

  test('tanda', () {
    expect(formatRupiahCompact(54470119600, withSign: true), '+Rp 54,5 M');
    expect(formatRupiahCompact(-206535361000, withSign: true), '-Rp 206,5 M');
    expect(formatRupiahCompact(-206535361000), '-Rp 206,5 M');
    expect(formatRupiahCompact(0, withSign: true), 'Rp 0');
    expect(formatRupiahCompact(null), '-');
  });

  test('pembulatan ke satuan di atasnya', () {
    expect(formatRupiahCompact(999990000000), 'Rp 1 T');
  });
}
