import 'package:cuan_app/pages/screen/home_page.dart' show Ohlc;

class IndicatorValue {
  final int time;
  final double value;

  const IndicatorValue({
    required this.time,
    required this.value,
  });

  factory IndicatorValue.fromJson(Map<String, dynamic> json) => IndicatorValue(
        time: (json['time'] as num?)?.toInt() ?? 0,
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'time': time,
        'value': value,
      };
}

class ChartPayload {
  final List<Ohlc> candles;
  final Map<String, List<IndicatorValue>> indicators;

  const ChartPayload({
    required this.candles,
    required this.indicators,
  });

  factory ChartPayload.fromJson(Map<String, dynamic> json) {
    final List<dynamic> candlesJson =
        (json['candles'] as List<dynamic>?) ?? const <dynamic>[];
    final Map<String, dynamic> indicatorsJson =
        (json['indicators'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};

    final List<Ohlc> candles = candlesJson.map((dynamic e) {
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
    }).toList();

    final Map<String, List<IndicatorValue>> indicators =
        <String, List<IndicatorValue>>{};

    indicatorsJson.forEach((String key, dynamic value) {
      if (value is List) {
        indicators[key] = value
            .where((dynamic e) =>
                e is Map<String, dynamic> && e['value'] != null)
            .map((dynamic e) =>
                IndicatorValue.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    });

    return ChartPayload(candles: candles, indicators: indicators);
  }
}
