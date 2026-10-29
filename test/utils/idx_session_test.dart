import 'package:cuan_app/utils/idx_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Waktu WIB (UTC+7) -> UTC, supaya tes menulis jam seperti yang dibaca orang.
DateTime _wib(int y, int m, int d, int h, int min) =>
    DateTime.utc(y, m, d, h, min).subtract(const Duration(hours: 7));

void main() {
  // 26-30 Okt 2026 = Senin-Jumat, 31 Okt = Sabtu, 1 Nov = Minggu
  test('hari bursa: aktif 08:45 sampai sebelum 16:30 WIB', () {
    expect(isIdxSessionActive(_wib(2026, 10, 29, 8, 44)), isFalse);
    expect(isIdxSessionActive(_wib(2026, 10, 29, 8, 45)), isTrue);
    expect(
      isIdxSessionActive(_wib(2026, 10, 29, 12, 30)),
      isTrue,
    ); // istirahat sesi
    expect(isIdxSessionActive(_wib(2026, 10, 29, 14, 34)), isTrue);
    expect(isIdxSessionActive(_wib(2026, 10, 29, 16, 29)), isTrue);
    expect(isIdxSessionActive(_wib(2026, 10, 29, 16, 30)), isFalse);
    expect(isIdxSessionActive(_wib(2026, 10, 29, 23, 0)), isFalse);
    expect(isIdxSessionActive(_wib(2026, 10, 29, 3, 0)), isFalse);
  });

  test('Sabtu dan Minggu tidak aktif', () {
    expect(isIdxSessionActive(_wib(2026, 10, 31, 10, 0)), isFalse);
    expect(isIdxSessionActive(_wib(2026, 11, 1, 10, 0)), isFalse);
    expect(isIdxSessionActive(_wib(2026, 11, 2, 10, 0)), isTrue); // Senin
  });

  test('memakai WIB, bukan zona HP: 07:29 UTC = 14:29 WIB (aktif)', () {
    expect(isIdxSessionActive(DateTime.utc(2026, 10, 29, 7, 29)), isTrue);
    // 01:00 UTC = 08:00 WIB (belum aktif); 09:30 UTC = 16:30 WIB (sudah tidak)
    expect(isIdxSessionActive(DateTime.utc(2026, 10, 29, 1, 0)), isFalse);
    expect(isIdxSessionActive(DateTime.utc(2026, 10, 29, 9, 30)), isFalse);
  });

  test('batas hari mengikuti WIB: Jumat 23:00 UTC sudah Sabtu 06:00 WIB', () {
    expect(isIdxSessionActive(DateTime.utc(2026, 10, 30, 23, 0)), isFalse);
  });
}
