class CandleItem {
  final DateTime ts;
  final double? open, high, low, close;
  final int? volume;

  CandleItem({
    required this.ts,
    this.open,
    this.high,
    this.low,
    this.close,
    this.volume,
  });

  factory CandleItem.fromJson(Map<String, dynamic> j) => CandleItem(
    ts: DateTime.parse(j['ts'] as String),
    open: (j['open'] as num?)?.toDouble(),
    high: (j['high'] as num?)?.toDouble(),
    low: (j['low'] as num?)?.toDouble(),
    close: (j['close'] as num?)?.toDouble(),
    volume: j['volume'] as int?,
  );
}
