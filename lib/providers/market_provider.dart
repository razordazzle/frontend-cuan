import 'dart:async';

import 'package:cuan_app/data/model/market_item.dart';
import 'package:cuan_app/data/model/stock_list_item.dart';
import 'package:cuan_app/data/services/live_prices_ws.dart';
import 'package:cuan_app/data/services/market_service.dart';
import 'package:cuan_app/data/services/stocks_service.dart';
import 'package:flutter/material.dart';

class MarketProvider extends ChangeNotifier {
  // final MarketService svc;
  final StocksService _svc;
  MarketProvider(this._svc);

  bool loading = false;
  String? error;

  List<StockListItem> gainers = [];
  List<StockListItem> losers = [];
  List<StockListItem> volume = [];

  LivePricesWS? _ws;
  StreamSubscription? _wsSub;
  bool _wsRunning = false;

  String _symbolsKey = ''; // buat deteksi kalau list berubah
  Timer? _notifyDebounce;
  bool _pendingNotify = false;

  Future<void> loadAll({int limit = 20}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final r = await Future.wait([
        _svc.list(filter: 'top_gainers', limit: limit),
        _svc.list(filter: 'top_losers', limit: limit),
        _svc.list(filter: 'top_volume', limit: limit),
        // _svc.list(filter: 'top_gainers', limit: limit, useLiveSource: false),
        // _svc.list(filter: 'top_losers', limit: limit, useLiveSource: false),
        // _svc.list(filter: 'top_volume', limit: limit, useLiveSource: false),
      ]);
      gainers = r[0];
      losers = r[1];
      volume = r[2];
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshOne(String metric, {int limit = 20}) async {
    try {
      final list = await _svc.list(
        filter: metric == 'gainers'
            ? 'top_gainers'
            : metric == 'losers'
            ? 'top_losers'
            : 'top_volume',
        limit: limit,
        // useLiveSource: false,
      );
      if (metric == 'gainers') gainers = list;
      if (metric == 'losers') losers = list;
      if (metric == 'volume') volume = list;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  bool _patchListBySymbol(List<StockListItem> list, Map<String, dynamic> row) {
    if (list.isEmpty) return false;
    final sym = (row['symbol'] ?? '').toString().toUpperCase();
    if (sym.isEmpty) return false;

    final i = list.indexWhere((x) => x.ticker.toUpperCase() == sym);
    if (i < 0) return false;

    final last = (row['last'] as num?)?.toDouble();
    final chg = (row['change_point'] as num?)?.toDouble();
    final pct = (row['change_pct'] as num?)?.toDouble();
    final logo = row['logo_url']?.toString();

    final old = list[i];
    list[i] = old.copyWith(
      lastPrice: last,
      changePoint: chg,
      changePct: pct,
      logoUrl: (logo != null && logo.isNotEmpty) ? logo : old.logoUrl,
    );
    return true;
  }

  void _scheduleNotify() {
    if (_notifyDebounce != null) {
      _pendingNotify = true;
      return;
    }
    // maksimal ~4x/detik
    _notifyDebounce = Timer(const Duration(milliseconds: 250), () {
      _notifyDebounce = null;
      if (_pendingNotify) {
        _pendingNotify = false;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  Future<void> startLivePrices({
    required String wsBaseUrl,
    required List<String> symbols,
  }) async {
    final syms = symbols
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (syms.isEmpty) return;

    // key biar nggak reconnect kalau sama
    final key = syms.join(',');
    if (_wsRunning && key == _symbolsKey) return;

    // kalau sudah jalan tapi symbols beda -> restart
    await stopLivePrices();

    _wsRunning = true;
    _symbolsKey = key;

    final uri = Uri.parse('$wsBaseUrl/ws/prices?symbols=$key');
    _ws = LivePricesWS()..connect(uri);

    _wsSub = _ws!.stream.listen((msg) {
      if (msg['type'] == 'error') return;
      if (msg['type'] != 'tick') return;

      final data = msg['data'];
      if (data is! Map) return;

      bool changed = false;

      for (final entry in data.entries) {
        final v = entry.value;
        if (v is! Map) continue;

        final row = Map<String, dynamic>.from(v);

        // patch ke semua list yang ada di MarketProvider
        // (sesuaikan nama field di provider kamu)
        changed = _patchListBySymbol(gainers, row) || changed;
        changed = _patchListBySymbol(losers, row) || changed;
        changed = _patchListBySymbol(volume, row) || changed;
      }

      // if (changed) notifyListeners();
      if (changed) _scheduleNotify();
    });
  }

  Future<void> stopLivePrices() async {
    _wsRunning = false;
    _symbolsKey = '';
    await _wsSub?.cancel();
    _wsSub = null;
    _ws?.close();
    _ws = null;
    _notifyDebounce?.cancel();
    _notifyDebounce = null;
    _pendingNotify = false;
  }

  @override
  void dispose() {
    stopLivePrices();
    super.dispose();
  }
}
