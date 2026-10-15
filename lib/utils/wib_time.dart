/// Waktu dari backend selalu UTC (lihat database.py di backend). Sebagian endpoint mengirim
/// tanpa penanda zona (mis. "2026-10-14T03:00:00"); kalau di-`DateTime.parse` begitu saja,
/// Dart menganggapnya waktu lokal HP sehingga jam yang tampil bisa geser 7 jam.
DateTime parseServerTime(String value) {
  final hasZone = value.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(value);
  return DateTime.parse(hasZone ? value : '${value}Z');
}

/// Ubah ke WIB (UTC+7) untuk ditampilkan, tidak tergantung zona waktu HP.
DateTime toWib(DateTime t) => t.toUtc().add(const Duration(hours: 7));
