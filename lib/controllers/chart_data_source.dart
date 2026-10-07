import 'package:flutter/foundation.dart';

import '../data/model/chart_payload.dart';
import '../providers/stock_detail_provider.dart';
import '../providers/stocks_provider.dart';

/// Sumber data halaman TradingView: satu-satunya bagian yang beda antara chart saham & IHSG.
/// Listener diteruskan ke provider di belakangnya, jadi halaman cukup mendengarkan sumber ini.
abstract class ChartDataSource<P extends ChangeNotifier> implements Listenable {
  final P provider;

  const ChartDataSource(this.provider);

  String get symbol;
  String get resolution;
  ChartPayload? get payload;

  /// Harga live terakhir dari WebSocket; null kalau belum ada.
  double? get liveLast;

  Future<void> fetchCandles();
  Future<void> setResolution(String resolution);

  @override
  void addListener(VoidCallback listener) => provider.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      provider.removeListener(listener);
}

class StockChartDataSource extends ChartDataSource<StockDetailProvider> {
  final String ticker;

  const StockChartDataSource(super.provider, this.ticker);

  @override
  String get symbol => ticker;

  @override
  String get resolution => provider.tvResolution;

  @override
  ChartPayload? get payload => provider.tvChartPayload;

  @override
  double? get liveLast => provider.liveLast;

  @override
  Future<void> fetchCandles() => provider.fetchTvCandles(ticker);

  @override
  Future<void> setResolution(String resolution) =>
      provider.setTvResolution(ticker, resolution);
}

class IhsgChartDataSource extends ChartDataSource<StocksProvider> {
  const IhsgChartDataSource(super.provider);

  @override
  String get symbol => 'IHSG';

  @override
  String get resolution => provider.tvResolution;

  @override
  ChartPayload? get payload => provider.tvChartPayload;

  @override
  double? get liveLast => provider.ihsgLast;

  @override
  Future<void> fetchCandles() => provider.fetchTvCandles();

  @override
  Future<void> setResolution(String resolution) =>
      provider.setTvResolution(resolution);
}
