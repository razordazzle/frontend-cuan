class LivePrice {
  final String symbol;
  final double? last;
  final double? prevClose;
  final double? changePoint;
  final double? changePct;

  LivePrice({
    required this.symbol,
    this.last,
    this.prevClose,
    this.changePoint,
    this.changePct,
  });

  factory LivePrice.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return LivePrice(
      symbol: (json['symbol'] ?? '').toString().toUpperCase(),
      last: _toDouble(json['last']),
      prevClose: _toDouble(json['prev_close']),
      changePoint: _toDouble(json['change_point']),
      changePct: _toDouble(json['change_pct']),
    );
  }
}
