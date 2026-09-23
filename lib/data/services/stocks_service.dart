import 'package:cuan_app/data/core/api_client.dart';
import 'package:cuan_app/data/core/auth_interceptor.dart';
import 'package:cuan_app/data/model/broker_summary_row.dart';
import 'package:cuan_app/data/model/candle_item.dart';
import 'package:cuan_app/data/model/dividend_item.dart';
import 'package:cuan_app/data/model/key_stats_latest.dart';
import 'package:cuan_app/data/model/ratio_item.dart';
import 'package:cuan_app/data/model/stock_detail.dart';
import 'package:cuan_app/data/model/stock_list_item.dart';
import 'package:cuan_app/data/model/chart_payload.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class StocksService {
  final Dio _dio;
  StocksService(AuthInterceptor interceptor)
    : _dio = ApiClient.instance(interceptor);

  dynamic _extractData(Response res) {
    if (res.data is Map<String, dynamic> && res.data.containsKey('data')) {
      return res.data['data'];
    }
    return res.data; // Balikin apa adanya kalau tidak dibungkus
  }
  // Future<List<StockListItem>> listStocks({String? filter, int limit = 10}) async {
  //   final res = await _dio.get('/stocks', queryParameters: {
  //     if (filter != null) 'filter': filter,
  //     'limit': limit,
  //   });
  //   final list = (res.data as List).map((e) => StockListItem.fromJson(e)).toList();
  //   return list;
  //   // filter=watchlist memerlukan Bearer token (interceptor akan mengirim otomatis)
  // }

  /// List stocks dengan filter. Tanpa filter -> default A–Z dari server.
  Future<List<StockListItem>> list({
    String? filter, // watchlist|az|top_gainers|top_losers|top_volume
    int limit = 10,
    // bool useLiveSource = false,
  }) async {
    final qp = <String, dynamic>{
      if (filter != null) 'filter': filter,
      'limit': limit,
      // if (useLiveSource) 'source': 'live',
    };
    final res = await _dio.get('/stocks', queryParameters: qp);

    // Gunakan helper di sini
    final rawData = _extractData(res);
    return (rawData as List)
        .map((e) => StockListItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // final list = (res.data as List)
    //     .map((e) => StockListItem.fromJson(e as Map<String, dynamic>))
    //     .toList();
    // return list;
  }

  // (opsional) detail
  Future<Map<String, dynamic>> detailRaw(String ticker) async {
    final res = await _dio.get('/stocks/$ticker');
    return res.data as Map<String, dynamic>;
  }

  Future<StockDetail> getDetail(String ticker) async {
    final res = await _dio.get('/stocks/$ticker');
    final rawData = _extractData(res);
    return StockDetail.fromJson(rawData);
  }

  // Future<List<CandleItem>> getCandles(
  //   String ticker, {
  //   String interval = '1d',
  //   int limit = 300,
  // }) async {
  //   final r = await _dio.get(
  //     '/stocks/$ticker/candles',
  //     queryParameters: {'interval': interval, 'limit': limit},
  //   );
  //   return (r.data as List).map((e) => CandleItem.fromJson(e)).toList();
  // }

  Future<List<CandleItem>> getCandles(
    String ticker, {
    String interval = '1d',
    int limit = 300,
  }) async {
    try {
      final res = await _dio.get(
        '/stocks/$ticker/candles',
        queryParameters: {'interval': interval, 'limit': limit},
      );
      final rawData = _extractData(res);
      return (rawData as List).map((e) => CandleItem.fromJson(e)).toList();
    } on DioException catch (e) {
      // kalau backend balikin 404 (ticker tidak ada), anggap saja tidak ada data
      if (e.response?.statusCode == 404) return <CandleItem>[];
      rethrow;
    }
  }

  Future<KeyStatsLatest> getKeyStatsLatest(
    String ticker, {
    String basis = 'TTM',
  }) async {
    final res = await _dio.get(
      '/stocks/$ticker/key-stats',
      queryParameters: {'basis': basis},
    );
    final rawData = _extractData(res);
    return KeyStatsLatest.fromJson(rawData);
  }

  // Future<List<dynamic>> getEarningsMatrix(String ticker) async {
  //   final res = await _dio.get('/stocks/$ticker/earnings-matrix');
  //   // API mereturn { "ticker": "...", "data": [ ... ] }
  //   return res.data['data'] as List<dynamic>;
  // }
  Future<List<dynamic>> getEarningsMatrix(String ticker) async {
    final res = await _dio.get('/stocks/$ticker/earnings-matrix');
    final rawData = _extractData(res);
    return (rawData as List?) ?? const [];
  }

  Future<List<DividendItem>> getDividends(
    String ticker, {
    int years = 6,
  }) async {
    final res = await _dio.get(
      '/stocks/$ticker/dividends',
      queryParameters: {'years': years},
    );
    final rawData = _extractData(res);
    return (rawData as List).map((e) => DividendItem.fromJson(e)).toList();
  }

  Future<List<RatioItem>> getRatios(
    String ticker, {
    String period = 'Q',
    int limit = 24,
  }) async {
    final res = await _dio.get(
      '/stocks/$ticker/ratios',
      queryParameters: {'period': period, 'limit': limit},
    );
    final rawData = _extractData(res);
    return (rawData as List).map((e) => RatioItem.fromJson(e)).toList();
  }

  Future<List<BrokerSummaryRow>> fetchBrokerSummary(
    String ticker, {
    DateTime? tradeDate,
    String investor = 'all', // 'all' | 'foreign' | 'local'
    bool net = false,
    int limit = 300,
  }) async {
    try {
      final qp = <String, dynamic>{
        'limit': limit,
        if (investor.isNotEmpty && investor != 'all') 'investor': investor,
        if (net)
          'net':
              true, // 👈 BARU — cukup kirim kalau true, biar query string bersih
        if (tradeDate != null)
          // 'trade_date': DateFormat('yyyy-MM-dd').format(tradeDate),
          'tradeDate': DateFormat('yyyy-MM-dd').format(tradeDate),
      };

      final res = await _dio.get(
        '/stocks/$ticker/broker-summary', // <<— di sini bedanya
        queryParameters: qp,
      );

      final rawData = _extractData(res);
      final data = (rawData as List? ?? const []);
      return data.map((e) => BrokerSummaryRow.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        // jangan crash, tapi balikan list kosong
        return <BrokerSummaryRow>[];
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listBrokers({
    String? category, // 'local' | 'foreign' | 'bumn'
    String? q,
    int limit = 500,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/brokers',
      queryParameters: {
        if (category != null) 'category': category,
        if (q != null && q.isNotEmpty) 'q': q,
        'limit': limit,
        'offset': offset,
      },
    );
    final rawData = _extractData(res);
    return (rawData as List).cast<Map<String, dynamic>>();
  }

  // Future<Map<String, LivePrice>> fetchLivePrices(List<String> tickers) async {
  //   if (tickers.isEmpty) return {};
  //   try {
  //     final res = await _dio.get(
  //       '/stocks/live-prices',
  //       queryParameters: {
  //         'symbols': tickers.join(','), //"BBCA, TLKM, ASII"
  //       },
  //     );
  //     final rawData = _extractData(res);
  //     final data = rawData as Map<String, dynamic>;
  //     final map = <String, LivePrice>{};
  //     data.forEach((key, value) {
  //       map[key.toUpperCase()] = LivePrice.fromJson(
  //         value as Map<String, dynamic>,
  //       );
  //     });

  //     return map;
  //   } on DioException catch (e) {
  //     // kalau rate limited GOAPI → jangan jatuhkan UI
  //     if (e.response?.statusCode == 429) {
  //       // bisa juga kasih log / snackBar nanti lewat layer lain
  //       return <
  //         String,
  //         LivePrice
  //       >{}; // balik map kosong, harga lama di UI tetap bisa dipakai
  //     }
  //     rethrow;
  //   }
  // }

  Future<List<CandleItem>> getIhsgCandles({
    String interval = '1d',
    int limit = 60,
  }) async {
    final res = await _dio.get(
      '/stocks/index/ihsg/candles',
      queryParameters: {'interval': interval, 'limit': limit},
    );
    final rawData = _extractData(res);
    return (rawData as List).map((e) => CandleItem.fromJson(e)).toList();
  }

  Future<ChartPayload> getIhsgChartWithIndicators({
    String interval = '1d',
    int limit = 60,
  }) async {
    final Response<dynamic> res = await _dio.get<dynamic>(
      '/stocks/index/ihsg/chart-with-indicators',
      queryParameters: <String, dynamic>{'interval': interval, 'limit': limit},
    );
    final dynamic rawData = _extractData(res);
    return ChartPayload.fromJson(rawData as Map<String, dynamic>);
  }

  Future<List<CandleItem>> getIndexCandles({
    required String symbol,
    String interval = '1d',
    int limit = 60,
  }) async {
    final res = await _dio.get(
      '/stocks/index-candles',
      queryParameters: {'symbol': symbol, 'interval': interval, 'limit': limit},
    );
    final rawData = _extractData(res);
    return (rawData as List).map((e) => CandleItem.fromJson(e)).toList();
  }

  // Future<YahooFundamentals> getYahooFundamentals(String ticker) async {
  //   final res = await _dio.get('/stocks/yahoo/$ticker/fundamentals');
  //   final rawData = _extractData(res);
  //   return YahooFundamentals.fromJson(rawData as Map<String, dynamic>);
  // }
  Future<ChartPayload> getStockChartWithIndicators({
    required String ticker,
    required String interval,
    required int limit,
  }) async {
    final res = await _dio.get(
      '/stocks/$ticker/chart-with-indicators',
      queryParameters: {'interval': interval, 'limit': limit},
    );
    return ChartPayload.fromJson(res.data);
  }
}
