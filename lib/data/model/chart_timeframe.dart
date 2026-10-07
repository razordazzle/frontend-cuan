/// Kelompok timeframe di sheet pemilih (sama seperti TradingView).
enum ChartTimeframeGroup {
  minutes('MINUTES'),
  hours('HOURS'),
  days('DAYS');

  const ChartTimeframeGroup(this.title);

  final String title;
}

/// Timeframe (resolusi candle) chart TradingView.
///
/// Sengaja dibatasi ke timeframe yang umum dipakai belajar analisis teknikal saham:
/// tanpa tick/detik/range (data & audiensnya untuk scalper/pro trader) dan tanpa 1m/4h
/// (1m terlalu noisy untuk belajar; sesi bursa IDX ~6,5 jam sehingga bar 4h terpotong).
enum ChartTimeframe {
  minute5(
    label: '5m',
    title: '5 minutes',
    group: ChartTimeframeGroup.minutes,
    apiInterval: '5m',
    limit: 300,
  ),
  minute15(
    label: '15m',
    title: '15 minutes',
    group: ChartTimeframeGroup.minutes,
    apiInterval: '15m',
    limit: 300,
  ),
  minute30(
    label: '30m',
    title: '30 minutes',
    group: ChartTimeframeGroup.minutes,
    apiInterval: '30m',
    limit: 300,
  ),
  hour1(
    label: '1h',
    title: '1 hour',
    group: ChartTimeframeGroup.hours,
    apiInterval: '1h',
    limit: 300,
  ),
  day1(
    label: '1D',
    title: '1 day',
    group: ChartTimeframeGroup.days,
    apiInterval: '1d',
    limit: 480, // ~2 tahun candle harian
  ),
  week1(
    label: '1W',
    title: '1 week',
    group: ChartTimeframeGroup.days,
    apiInterval: '1w',
    limit: 100, // ~2 tahun candle mingguan
  ),
  month1(
    label: '1M',
    title: '1 month',
    group: ChartTimeframeGroup.days,
    apiInterval: '1M',
    limit: 24, // 2 tahun candle bulanan
  );

  const ChartTimeframe({
    required this.label,
    required this.title,
    required this.group,
    required this.apiInterval,
    required this.limit,
  });

  /// Label ringkas di tombol & legend, mis. "15m", "1D".
  final String label;

  /// Nama lengkap di sheet pemilih, mis. "15 minutes".
  final String title;
  final ChartTimeframeGroup group;

  /// Nilai `interval` untuk endpoint chart backend.
  final String apiInterval;

  /// Jumlah candle yang diminta ke backend.
  final int limit;

  static const ChartTimeframe defaultTimeframe = ChartTimeframe.day1;
}
