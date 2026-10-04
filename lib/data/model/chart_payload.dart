import 'package:cuan_app/pages/screen/home_page.dart' show Ohlc;

/// Response `/chart-with-indicators`. Hanya candle yang dipakai; semua indikator
/// dihitung di chart (client) supaya hanya ada satu sumber perhitungan.
class ChartPayload {
  final List<Ohlc> candles;

  const ChartPayload({required this.candles});

  factory ChartPayload.fromJson(Map<String, dynamic> json) {
    final List<dynamic> candlesJson =
        (json['candles'] as List<dynamic>?) ?? const <dynamic>[];

    return ChartPayload(
      candles: candlesJson.map((dynamic e) {
        final Map<String, dynamic> item = e as Map<String, dynamic>;
        final double close = (item['close'] as num?)?.toDouble() ?? 0.0;
        final int timeSec = (item['time'] as num?)?.toInt() ?? 0;

        return Ohlc(
          time: DateTime.fromMillisecondsSinceEpoch(
            timeSec * 1000,
            isUtc: true,
          ),
          open: (item['open'] as num?)?.toDouble() ?? close,
          high: (item['high'] as num?)?.toDouble() ?? close,
          low: (item['low'] as num?)?.toDouble() ?? close,
          close: close,
          volume: (item['volume'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList(),
    );
  }
}
