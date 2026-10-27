import 'package:cuan_app/controllers/chart_payload_cache.dart';
import 'package:cuan_app/data/model/chart_payload.dart';
import 'package:cuan_app/data/model/chart_timeframe.dart';
import 'package:cuan_app/pages/screen/home_page.dart' show Ohlc;
import 'package:flutter_test/flutter_test.dart';

ChartPayload _payload({int bars = 1}) => ChartPayload(
  candles: List<Ohlc>.generate(
    bars,
    (int i) => Ohlc(
      time: DateTime.utc(2026, 10, 27, 9, i),
      open: 1,
      high: 1,
      low: 1,
      close: 1,
      volume: 1,
    ),
  ),
);

void main() {
  late DateTime now;
  late ChartPayloadCache cache;

  setUp(() {
    now = DateTime.utc(2026, 10, 27, 9);
    cache = ChartPayloadCache(clock: () => now);
  });

  test('payload tersimpan per timeframe', () {
    final ChartPayload daily = _payload();
    final ChartPayload minute = _payload();
    cache
      ..put('BBRI', ChartTimeframe.day1, daily)
      ..put('BBRI', ChartTimeframe.minute15, minute);

    expect(cache.get('BBRI', ChartTimeframe.day1), same(daily));
    expect(cache.get('BBRI', ChartTimeframe.minute15), same(minute));
    expect(cache.get('BBRI', ChartTimeframe.hour1), isNull);
  });

  test('intraday kedaluwarsa setelah 60 detik, harian setelah 10 menit', () {
    cache
      ..put('BBRI', ChartTimeframe.minute1, _payload())
      ..put('BBRI', ChartTimeframe.day1, _payload());

    now = now.add(const Duration(seconds: 59));
    expect(cache.get('BBRI', ChartTimeframe.minute1), isNotNull);
    now = now.add(const Duration(seconds: 1));
    expect(cache.get('BBRI', ChartTimeframe.minute1), isNull);
    expect(cache.get('BBRI', ChartTimeframe.day1), isNotNull);

    now = now.add(const Duration(minutes: 9));
    expect(cache.get('BBRI', ChartTimeframe.day1), isNull);
  });

  test('ganti simbol mengosongkan cache simbol sebelumnya', () {
    cache
      ..put('BBRI', ChartTimeframe.day1, _payload())
      ..put('BBCA', ChartTimeframe.day1, _payload());

    expect(cache.get('BBRI', ChartTimeframe.day1), isNull);
    expect(cache.get('BBCA', ChartTimeframe.day1), isNotNull);
  });

  test('payload kosong tidak disimpan', () {
    cache.put('BBRI', ChartTimeframe.day1, _payload(bars: 0));
    expect(cache.get('BBRI', ChartTimeframe.day1), isNull);
  });
}
