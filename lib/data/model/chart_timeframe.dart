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
/// Tanpa tick/detik/range (data & audiensnya untuk scalper/pro trader). 3m, 2h, 4h,
/// 3M, 6M & 1Y tidak tersedia langsung di Invezgo; backend menggabungkannya dari candle
/// yang lebih kecil. Riwayat Invezgo ±2 tahun, jadi 3M/6M/1Y hanya beberapa batang.
enum ChartTimeframe {
  minute1(
    label: '1m',
    title: '1 minute',
    group: ChartTimeframeGroup.minutes,
    apiInterval: '1m',
    limit: 300,
  ),
  minute3(
    label: '3m',
    title: '3 minutes',
    group: ChartTimeframeGroup.minutes,
    apiInterval: '3m',
    limit: 300,
  ),
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
  hour2(
    label: '2h',
    title: '2 hours',
    group: ChartTimeframeGroup.hours,
    apiInterval: '2h',
    limit: 200,
  ),
  hour4(
    label: '4h',
    title: '4 hours',
    group: ChartTimeframeGroup.hours,
    apiInterval: '4h',
    limit: 150,
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
  ),
  month3(
    label: '3M',
    title: '3 months',
    group: ChartTimeframeGroup.days,
    apiInterval: '3M',
    limit: 12,
  ),
  month6(
    label: '6M',
    title: '6 months',
    group: ChartTimeframeGroup.days,
    apiInterval: '6M',
    limit: 6,
  ),
  year1(
    label: '1Y',
    title: '1 year',
    group: ChartTimeframeGroup.days,
    apiInterval: '1Y',
    limit: 3,
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
