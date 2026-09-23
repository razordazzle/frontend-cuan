import 'dart:async';

import 'package:cuan_app/data/model/candle_item.dart';
import 'package:cuan_app/data/model/chart_payload.dart';
import 'package:cuan_app/data/model/dividend_item.dart';
import 'package:cuan_app/data/model/key_stats_latest.dart';
import 'package:cuan_app/data/model/ratio_item.dart';
import 'package:cuan_app/data/model/stock_detail.dart';
import 'package:cuan_app/data/model/yahoo_fundamentals.dart';
import 'package:cuan_app/data/services/live_prices_ws.dart';
import 'package:cuan_app/data/services/stocks_service.dart';
import 'package:cuan_app/pages/screen/home_page.dart';
import 'package:flutter/material.dart';

class StockDetailProvider extends ChangeNotifier {
  final StocksService api;
  StockDetailProvider(this.api);

  bool loading = false;
  String? error;

  StockDetail? detail;
  List<CandleItem> candles = const [];
  KeyStatsLatest? latest;
  List<DividendItem> dividends = const [];
  List<RatioItem> ratios = const [];

  List<dynamic> earningsMatrix = [];

  // State terpisah, JANGAN reuse `candles`/`candleInterval` yang dipakai chart inline
  String tvResolution = '1D';
  ChartPayload? tvChartPayload;
  List<CandleItem> tvCandles = [];
  bool loadingTv = false;
  String? errTv;
  String? _tvTicker;

  Future<void> loadAll(
    String ticker, {
    String candleInterval = '1m',
    int candleLimit = 300,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    // reset live per ticker
    liveLast = null;
    liveChangePoint = null;
    liveChangePct = null;
    liveTs = null;

    try {
      final futures = await Future.wait([
        api.getDetail(ticker), // futures[0] (StockDetail)
        api.getCandles(
          ticker,
          interval: candleInterval,
          limit: candleLimit,
        ), // futures[1] (List<CandleItem>)
        api
            .getKeyStatsLatest(ticker)
            .catchError((_) => null), // futures[2] (KeyStatsLatest?)
        api
            .getDividends(ticker, years: 6)
            .catchError(
              (_) => <DividendItem>[],
            ), // futures[3] (List<DividendItem>)
        api
            .getRatios(ticker, period: 'Q', limit: 16)
            .catchError((_) => <RatioItem>[]), // futures[4] (List<RatioItem>)
        api.getEarningsMatrix(ticker).catchError((_) => []),
      ]);

      detail = futures[0] as StockDetail;
      candles = futures[1] as List<CandleItem>;

      // Karena futures[2] bisa me-return null (jika API error 404),
      // kita cast ke nullable KeyStatsLatest?
      latest = futures[2] as KeyStatsLatest?;

      dividends = futures[3] as List<DividendItem>;
      ratios = futures[4] as List<RatioItem>;
      earningsMatrix = futures[5] as List<dynamic>;
    } catch (e) {
      error = e.toString();
      debugPrint("Error loadAll: $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCandles(String interval, {int limit = 300}) async {
    if (detail == null) return; // Pastikan ticker sudah di-load

    loading = true; // Opsional: kasih animasi loading pas chart ganti
    notifyListeners();

    try {
      // Panggil API lewat service lu
      candles = await api.getCandles(
        detail!.ticker,
        interval: interval,
        limit: limit,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setTvResolution(String ticker, String v) async {
    if (tvResolution == v && _tvTicker == ticker) return;
    tvResolution = v;
    _tvTicker = ticker;
    await fetchTvCandles(ticker, force: true);
    notifyListeners();
  }

  Future<void> fetchTvCandles(String ticker, {bool force = false}) async {
    if (tvCandles.isNotEmpty && !force && _tvTicker == ticker) return;
    loadingTv = true;
    errTv = null;
    _tvTicker = ticker;
    notifyListeners();
    try {
      String apiInterval;
      int apiLimit;
      switch (tvResolution) {
        case '1D':
          apiInterval = '1d';
          apiLimit = 480;
          break;
        case '1W':
          apiInterval = '1w';
          apiLimit = 100;
          break;
        case '1M':
          apiInterval = '1M';
          apiLimit = 24;
          break;
        default:
          apiInterval = '1d';
          apiLimit = 480;
      }
      tvChartPayload = await api.getStockChartWithIndicators(
        ticker: ticker,
        interval: apiInterval,
        limit: apiLimit,
      );
      tvCandles = tvChartPayload!.candles
          .map(
            (Ohlc e) => CandleItem(
              ts: e.time,
              open: e.open,
              high: e.high,
              low: e.low,
              close: e.close,
              volume: e.volume.toInt(),
            ),
          )
          .toList();
    } catch (e) {
      errTv = 'Gagal memuat chart TradingView: $e';
    } finally {
      loadingTv = false;
      notifyListeners();
    }
  }

  // ===================== LIVE WS (1 ticker) =====================
  LivePricesWS? _ws;
  StreamSubscription? _wsSub;
  String? _wsSymbol;

  double? liveLast;
  double? liveChangePoint;
  double? liveChangePct;
  DateTime? liveTs;

  void startLive({required String wsBaseUrl, required String symbol}) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;

    // Jangan dobel koneksi kalau masih symbol yang sama
    if (_ws != null && _wsSymbol == sym) return;

    stopLive(); // tutup koneksi lama bila ada

    _wsSymbol = sym;
    final uri = Uri.parse('$wsBaseUrl/ws/prices?symbols=$sym');

    _ws = LivePricesWS()..connect(uri);

    _wsSub = _ws!.stream.listen((msg) {
      final type = msg['type'];

      if (type == 'error') {
        // ignore: avoid_print
        print('DETAIL WS ERROR: ${msg['message']}');
        return;
      }

      if (type != 'tick') return;

      final data = msg['data'];
      if (data is! Map) return;

      final rowAny = data[sym];
      if (rowAny is! Map) return;

      final row = Map<String, dynamic>.from(rowAny);

      liveLast = (row['last'] as num?)?.toDouble();
      liveChangePoint = (row['change_point'] as num?)?.toDouble();
      liveChangePct = (row['change_pct'] as num?)?.toDouble();

      // optional: kalau backend ngirim date/ts
      final d = row['date']?.toString();
      if (d != null) liveTs = DateTime.tryParse(d);

      // Patch ke model detail biar UI yang pakai detail juga ikut hidup
      if (detail != null && liveLast != null) {
        detail = detail!.copyWith(
          lastPrice: liveLast,
          // kalau kamu punya field changePoint/changePct di StockDetail, isi juga:
          // changePoint: liveChangePoint,
          // changePct: liveChangePct,
        );
      }

      notifyListeners();
    });
  }

  void stopLive() {
    _wsSub?.cancel();
    _wsSub = null;
    _ws?.close();
    _ws = null;
    _wsSymbol = null;
  }

  @override
  void dispose() {
    stopLive();
    super.dispose();
  }
}
