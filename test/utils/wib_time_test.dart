import 'package:cuan_app/utils/wib_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('waktu server tanpa zona dibaca sebagai UTC', () {
    final t = parseServerTime('2026-10-14T03:00:00');
    expect(t.isUtc, isTrue);
    expect(t.hour, 3);
  });

  test('waktu server dengan Z / offset tetap dihormati', () {
    expect(parseServerTime('2026-10-14T03:00:00Z').toUtc().hour, 3);
    expect(parseServerTime('2026-10-14T10:00:00+07:00').toUtc().hour, 3);
  });

  test('toWib menambah 7 jam, termasuk ganti tanggal lewat tengah malam', () {
    final wib = toWib(parseServerTime('2026-10-14T18:30:00'));
    expect(wib.day, 15);
    expect(wib.hour, 1);
    expect(wib.minute, 30);
  });
}
