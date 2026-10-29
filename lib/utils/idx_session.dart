import 'package:cuan_app/utils/wib_time.dart';

/// Apakah bursa efek sedang (atau baru saja) berjalan pada [nowUtc]: Senin-Jumat, 08:45-16:30 WIB.
///
/// Dipakai untuk menentukan kapan grafik intraday perlu dimuat ulang otomatis. Batasnya sengaja
/// longgar: dimulai sebelum pra-pembukaan (08:45) dan berakhir setelah sesi pasca-penutupan
/// (16:15), supaya candle penutup ikut terambil. Hari libur nasional tidak diketahui di sini;
/// kalau libur, pembaruan hanya mengambil data lama yang sama dari cache server.
bool isIdxSessionActive(DateTime nowUtc) {
  final wib = toWib(nowUtc);
  if (wib.weekday == DateTime.saturday || wib.weekday == DateTime.sunday) {
    return false;
  }
  final minutes = wib.hour * 60 + wib.minute;
  return minutes >= 8 * 60 + 45 && minutes < 16 * 60 + 30;
}
