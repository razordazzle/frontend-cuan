import 'package:cuan_app/utils/number_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EPS dipotong ke 2 desimal, tidak dibulatkan ke atas', () {
    expect(truncateDecimals(400.9166, 2), 400.91); // dulu tampil 400.92
    expect(truncateDecimals(377.5733, 2), 377.57);
    expect(truncateDecimals(471.4536, 2), 471.45);
    expect(truncateDecimals(-6.3489, 2), -6.34); // negatif ke arah nol
    expect(truncateDecimals(0.29, 2), 0.29); // tahan error float
    expect(truncateDecimals(12, 2), 12);
  });
}
