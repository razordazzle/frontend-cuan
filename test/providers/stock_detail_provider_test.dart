import 'dart:async';

import 'package:cuan_app/data/model/chart_payload.dart';
import 'package:cuan_app/data/model/chart_timeframe.dart';
import 'package:cuan_app/data/services/stocks_service.dart';
import 'package:cuan_app/pages/screen/home_page.dart' show Ohlc;
import 'package:cuan_app/providers/stock_detail_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Service palsu: setiap request chart dicatat & dijawab manual lewat [respond].
class _FakeStocks implements StocksService {
  final List<String> requests = <String>[];
  final Map<String, Completer<ChartPayload>> _pending =
      <String, Completer<ChartPayload>>{};

  void respond(String interval) =>
      _pending.remove(interval)!.complete(_payloadFor(interval));

  @override
  Future<ChartPayload> getStockChartWithIndicators({
    required String ticker,
    required String interval,
    required int limit,
  }) {
    requests.add('$ticker:$interval');
    return (_pending[interval] = Completer<ChartPayload>()).future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ChartPayload _payloadFor(String interval) => ChartPayload(
  candles: <Ohlc>[
    Ohlc(
      time: DateTime.utc(2026, 10, 27),
      open: 1,
      high: 1,
      low: 1,
      close: interval.length.toDouble(),
      volume: 1,
    ),
  ],
);

void main() {
  late _FakeStocks api;
  late StockDetailProvider provider;

  setUp(() {
    api = _FakeStocks();
    provider = StockDetailProvider(api);
  });

  tearDown(() => provider.dispose());

  test('kembali ke timeframe yang sudah dibuka tidak request ulang', () async {
    final Future<void> daily = provider.fetchTvCandles('BBRI');
    api.respond('1d');
    await daily;
    final ChartPayload? dailyPayload = provider.tvChartPayload;

    final Future<void> minute = provider.setTvTimeframe(
      'BBRI',
      ChartTimeframe.minute15,
    );
    api.respond('15m');
    await minute;
    await provider.setTvTimeframe('BBRI', ChartTimeframe.day1);

    expect(api.requests, <String>['BBRI:1d', 'BBRI:15m']);
    expect(provider.tvChartPayload, same(dailyPayload));
    expect(provider.loadingTv, isFalse);
  });

  test(
    'respons timeframe lama tidak menimpa timeframe yang sedang dipilih',
    () async {
      final Future<void> daily = provider.fetchTvCandles('BBRI');
      final Future<void> minute = provider.setTvTimeframe(
        'BBRI',
        ChartTimeframe.minute15,
      );
      api.respond('15m');
      await minute;
      final ChartPayload? minutePayload = provider.tvChartPayload;
      api.respond('1d'); // datang terlambat
      await daily;

      expect(provider.tvTimeframe, ChartTimeframe.minute15);
      expect(provider.tvChartPayload, same(minutePayload));

      // Respons yang terlambat tetap masuk cache.
      await provider.setTvTimeframe('BBRI', ChartTimeframe.day1);
      expect(api.requests, <String>['BBRI:1d', 'BBRI:15m']);
    },
  );

  test('buka emiten lain tidak menampilkan chart emiten sebelumnya', () async {
    final Future<void> bbri = provider.fetchTvCandles('BBRI');
    api.respond('1d');
    await bbri;

    final Future<void> bbca = provider.fetchTvCandles('BBCA');
    expect(provider.tvChartPayload, isNull);
    expect(provider.loadingTv, isTrue);
    api.respond('1d');
    await bbca;

    expect(api.requests, <String>['BBRI:1d', 'BBCA:1d']);
    expect(provider.tvChartPayload, isNotNull);
  });
}
