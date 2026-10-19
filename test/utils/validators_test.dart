import 'package:cuan_app/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.isValidPhoneID', () {
    test('format nomor HP Indonesia yang umum diterima', () {
      for (final n in [
        '0812345678910',
        '081234567890',
        '812345678',
        '62812345678',
        '+62 812-3456-7890',
      ]) {
        expect(Validators.isValidPhoneID(n), isTrue, reason: n);
      }
    });

    test('nomor yang bukan HP Indonesia ditolak', () {
      for (final n in [
        '181234567891', // laporan tim: dulu lolos jadi +62181…
        '0212345678', // telepon rumah (bukan 08)
        '0812345', // terlalu pendek
        '08123456789012345', // terlalu panjang
        'abc',
      ]) {
        expect(Validators.isValidPhoneID(n), isFalse, reason: n);
      }
    });
  });
}
