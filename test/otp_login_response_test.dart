import 'package:cuan_app/data/response/otp_login_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OtpLoginResponse.fromJson', () {
    test('membaca token, batas waktu, dan nomor tersamar', () {
      final res = OtpLoginResponse.fromJson({
        'otp_required': true,
        'otp_token': 'tiket-otp',
        'expires_in': 900,
        'phone': '+62****890',
      });

      expect(res.otpToken, 'tiket-otp');
      expect(res.expiresIn, 900);
      expect(res.phone, '+62****890');
    });

    test('nomor boleh null (akun tanpa nomor)', () {
      final res = OtpLoginResponse.fromJson({
        'otp_required': true,
        'otp_token': 'tiket-otp',
        'expires_in': 900,
        'phone': null,
      });

      expect(res.phone, isNull);
    });
  });
}
