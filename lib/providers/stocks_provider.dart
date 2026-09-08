import 'package:cuan_app/data/model/candle_item.dart';
import 'package:cuan_app/data/model/stock_list_item.dart';
import 'package:cuan_app/data/model/chart_payload.dart';
import 'package:cuan_app/pages/screen/home_page.dart' show Ohlc;
import 'package:cuan_app/data/services/auth_service.dart';
import 'package:cuan_app/data/services/stocks_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cuan_app/data/services/live_prices_ws.dart';

class StocksProvider extends ChangeNotifier {
  final StocksService _svc;
  final AuthService _auth;
  StocksProvider(this._svc, this._auth);

  LivePricesWS? _ws;
  StreamSubscription? _wsSub;
  bool _wsRunning = false;
  // List<StockListItem> _items = [];
  // bool _loading = false;
  // String? _error;

  // List<StockListItem> get items => _items;
  // bool get loading => _loading;
  // String? get error => _error;

  // Future<void> fetch({String? filter, int limit = 10}) async {
  //   _loading = true; _error = null; notifyListeners();
  //   try {
  //     _items = await _svc.listStocks(filter: filter, limit: limit);
  //   } catch (e) {
  //     _error = e.toString();
  //   } finally {
  //     _loading = false; notifyListeners();
  //   }
  // }
  // state tiap tab
  bool loadingWatch = false,
      loadingGainers = false,
      loadingLosers = false,
      loadingVolume = false;
  String? errWatch, errGainers, errLosers, errVolume;

  List<StockListItem>? watchlist;
  List<StockListItem>? topGainers;
  List<StockListItem>? topLosers;
  List<StockListItem>? topVolume;

  // ====== IHSG / INDEX CANDLES UNTUK HOME_PAGE ======
  bool loadingIndex = false;
  String? errIndex;
  List<CandleItem> ihsgCandles = [];
  ChartPayload? ihsgChartPayload;

  // ========== HELPER: overlay harga live dari GOAPI ==========
  // Future<List<StockListItem>> _applyLivePrices(List<StockListItem> list) async {
  //   if (list.isEmpty) return list;

  //   final tickers = list.map((e) => e.ticker).toList();
  //   try {
  //     final liveMap = await _svc.fetchLivePrices(tickers);

  //     return list.map((s) {
  //       final lp = liveMap[s.ticker.toUpperCase()];
  //       if (lp == null)
  //         return s; // kalau harga live nggak ada, pakai versi lama

  //       return s.copyWith(
  //         lastPrice: lp.last,
  //         changePoint: lp.changePoint,
  //         changePct: lp.changePct,
  //       );
  //     }).toList();
  //   } catch (e) {
  //     // kalau GOAPI error, balikin list apa adanya
  //     return list;
  //   }
  // }

  // ==================== TABS LIST ====================
  // Future<void> fetchWatchlist({bool force = false}) async {
  //   if (watchlist != null && !force) return;
  //   loadingWatch = true;
  //   errWatch = null;
  //   notifyListeners();
  //   try {
  //     // list dari DB (filter=watchlist), bukan dari GOAPI
  //     watchlist = await _svc.list(
  //       filter: 'watchlist',
  //       limit: 50,
  //       useLiveSource: false,
  //     );
  //     // overlay harga live dari GOAPI
  //     watchlist = await _applyLivePrices(watchlist!);
  //   } catch (e) {
  //     errWatch = 'Gagal memuat watchlist';
  //   } finally {
  //     loadingWatch = false;
  //     notifyListeners();
  //   }
  // }

  // Future<void> fetchGainers({bool force = false}) async {
  //   if (topGainers != null && !force) return;
  //   loadingGainers = true;
  //   errGainers = null;
  //   notifyListeners();
  //   try {
  //     topGainers = await _svc.list(
  //       filter: 'top_gainers',
  //       limit: 50,
  //       useLiveSource: false,
  //     );
  //     topGainers = await _applyLivePrices(topGainers!);
  //   } catch (e) {
  //     errGainers = 'Gagal memuat top gainers';
  //   } finally {
  //     loadingGainers = false;
  //     notifyListeners();
  //   }
  // }

  // Future<void> fetchLosers({bool force = false}) async {
  //   if (topLosers != null && !force) return;
  //   loadingLosers = true;
  //   errLosers = null;
  //   notifyListeners();
  //   try {
  //     topLosers = await _svc.list(
  //       filter: 'top_losers',
  //       limit: 50,
  //       useLiveSource: false,
  //     );
  //     topLosers = await _applyLivePrices(topLosers!);
  //   } catch (e) {
  //     errLosers = 'Gagal memuat top losers';
  //   } finally {
  //     loadingLosers = false;
  //     notifyListeners();
  //   }
  // }

  // Future<void> fetchVolume({bool force = false}) async {
  //   if (topVolume != null && !force) return;
  //   loadingVolume = true;
  //   errVolume = null;
  //   notifyListeners();
  //   try {
  //     topVolume = await _svc.list(
  //       filter: 'top_volume',
  //       limit: 50,
  //       useLiveSource: false,
  //     );
  //     topVolume = await _applyLivePrices(topVolume!);
  //   } catch (e) {
  //     errVolume = 'Gagal memuat top volume';
  //   } finally {
  //     loadingVolume = false;
  //     notifyListeners();
  //   }
  // }

  // ========== HELPER: overlay harga live dari API Detail ==========
  Future<List<StockListItem>> _applyLivePrices(List<StockListItem> list) async {
    if (list.isEmpty) return list;

    // Bikin copy list agar urutannya tidak berantakan
    final newList = List<StockListItem>.from(list);

    // Gunakan Future.wait agar request API berjalan PARALEL (bersamaan).
    await Future.wait(
      newList.asMap().entries.map((entry) async {
        final index = entry.key;
        final item = entry.value;

        try {
          // Panggil endpoint /stocks/BBCA yang ngasih harga update via detailRaw
          final detail = await _svc.detailRaw(item.ticker);

          final lastPrice =
              (detail['last_price'] as num?)?.toDouble() ?? item.lastPrice;
          final prevClose =
              (detail['prev_close'] as num?)?.toDouble() ?? item.prevClose;

          double chg = 0.0;
          double pct = 0.0;

          // Hitung change & percentage secara manual
          if (lastPrice != null && prevClose != null && prevClose > 0) {
            chg = lastPrice - prevClose;
            pct = (chg / prevClose) * 100.0;
          }

          // Timpa data lama dengan data baru yang fresh!
          newList[index] = item.copyWith(
            lastPrice: lastPrice,
            prevClose: prevClose,
            changePoint: chg,
            changePct: pct,
          );
        } catch (e) {
          // Kalau API error/timeout, abaikan dan biarkan pakai harga lama dari DB
          debugPrint('Gagal overlay harga untuk ${item.ticker}');
        }
      }),
    );

    return newList;
  }

  //LAMA
  // Future<void> fetchWatchlist({bool force = false}) async {
  //   if (watchlist != null && !force) return;
  //   loadingWatch = true; errWatch = null; notifyListeners();
  //   try {
  //     // Backend sekarang langsung balikin list yang sudah ada harganya!
  //     watchlist = await _svc.list(filter: 'watchlist', limit: 50);
  //   } catch (e) {
  //     errWatch = 'Gagal memuat watchlist';
  //   } finally {
  //     loadingWatch = false; notifyListeners();
  //   }
  // }
  //BARU
  Future<void> fetchWatchlist({bool force = false}) async {
    if (watchlist != null && !force) return;
    loadingWatch = true;
    errWatch = null;
    notifyListeners();
    try {
      // // 1. Ambil list dari database lokal dulu (harganya mungkin telat)
      // var dataDB = await _svc.list(filter: 'watchlist', limit: 50);

      // // 2. TIMPA harganya dengan data paling update dari endpoint /stocks/{ticker}
      // watchlist = await _applyLivePrices(dataDB);
      // Cukup ambil dari DB lokal — harga live biar WS yang isi
      watchlist = await _svc.list(filter: 'watchlist', limit: 50);
    } catch (e) {
      errWatch = 'Gagal memuat watchlist';
    } finally {
      loadingWatch = false;
      notifyListeners();
    }
  }

  Future<void> fetchGainers({bool force = false}) async {
    if (topGainers != null && !force) return;
    loadingGainers = true;
    errGainers = null;
    notifyListeners();
    try {
      topGainers = await _svc.list(filter: 'top_gainers', limit: 50);
    } catch (e) {
      errGainers = 'Gagal memuat top gainers';
    } finally {
      loadingGainers = false;
      notifyListeners();
    }
  }

  Future<void> fetchLosers({bool force = false}) async {
    if (topLosers != null && !force) return;
    loadingLosers = true;
    errLosers = null;
    notifyListeners();
    try {
      topLosers = await _svc.list(filter: 'top_losers', limit: 50);
    } catch (e) {
      errLosers = 'Gagal memuat top losers';
    } finally {
      loadingLosers = false;
      notifyListeners();
    }
  }

  Future<void> fetchVolume({bool force = false}) async {
    if (topVolume != null && !force) return;
    loadingVolume = true;
    errVolume = null;
    notifyListeners();
    try {
      topVolume = await _svc.list(filter: 'top_volume', limit: 50);
    } catch (e) {
      errVolume = 'Gagal memuat top volume';
    } finally {
      loadingVolume = false;
      notifyListeners();
    }
  }

  String indexInterval = '1D'; // '1d' | '1w' | '1M'

  Future<void> setIndexInterval(String v) async {
    if (indexInterval == v) return;
    indexInterval = v;
    await fetchIndexCandles(force: true);
    notifyListeners();
  }

  /// Candles IHSG untuk chart di HomePage.
  /// Ganti 'IHSG' kalau ticker index di backend kamu beda (mis: '^JKSE').
  // Future<void> fetchIndexCandles({bool force = false}) async {
  //   if (ihsgCandles.isNotEmpty && !force) return;

  //   loadingIndex = true;
  //   errIndex = null;
  //   notifyListeners();

  //   try {
  //     ihsgCandles = await _svc.getIndexCandles(
  //       symbol: 'COMPOSITE', // IHSG
  //       interval: indexInterval,
  //       // limit: indexInterval == '1d' ? 60 : 120,
  //       limit: indexInterval == '1m' ? 390 : (indexInterval == '1d' ? 60 : 120),
  //     );
  //   } catch (e) {
  //     errIndex = 'Gagal memuat chart IHSG';
  //   } finally {
  //     loadingIndex = false;
  //     notifyListeners();
  //   }
  // }
  /// Candles IHSG untuk chart di HomePage.
  Future<void> fetchIndexCandles({bool force = false}) async {
    if (ihsgCandles.isNotEmpty && !force) return;

    loadingIndex = true;
    errIndex = null;
    notifyListeners();

    try {
      // Tentukan interval dan limit berdasarkan tab yang dipilih user
      String apiInterval = '1d';
      int apiLimit = 60;

      switch (indexInterval) {
        case '1D': // Hari Ini (Intraday)
          apiInterval = '1m'; // 1 Menit
          apiLimit = 390; // ~390 menit (Jam 09:00 - 16:00)
          // apiLimit = 185; // ~390 menit (Jam 09:00 - 16:00)
          break;
        // case '1D': // Hari Ini (Intraday)
        //   // apiInterval = '1m'; // 1 Menit
        //   apiInterval = '5m'; // 5 Menit
        //   apiLimit = 80;     // ~390 menit (Jam 09:00 - 16:00)
        //   break;
        case '1W': // 1 Minggu
          apiInterval = '1h'; // 1 Jam
          apiLimit = 40; // ~40 jam bursa dlm seminggu
          break;
        case '1M': // 1 Bulan
          apiInterval = '1d'; // Harian
          apiLimit = 22; // ~22 hari kerja bursa
          break;
        case '3M': // 3 Bulan
          apiInterval = '1d';
          apiLimit = 65;
          break;
        case 'YTD': // Year to Date (Dari 1 Januari)
          apiInterval = '1d';
          apiLimit = 260; // Angka aman maksimal hari setahun
          break;
        case '1Y': // 1 Tahun Terakhir
          apiInterval = '1w'; // Mingguan biar grafik gak terlalu padat
          apiLimit = 52; // 52 minggu dlm setahun
          break;
      }

      // Panggil endpoint baru yang sudah punya indikator
      ihsgChartPayload = await _svc.getIhsgChartWithIndicators(
        interval: apiInterval,
        limit: apiLimit,
      );
      
      // Tetap isi ihsgCandles agar widget lama tidak rusak
      ihsgCandles = ihsgChartPayload!.candles.map((Ohlc e) => CandleItem(
        ts: e.time,
        open: e.open,
        high: e.high,
        low: e.low,
        close: e.close,
        volume: e.volume.toInt(),
      )).toList();
    } catch (e) {
      errIndex = 'Gagal memuat chart IHSG: $e';
    } finally {
      loadingIndex = false;
      notifyListeners();
    }
  }

  // ==================== WATCHLIST OPERATIONS ====================
  Future<void> addToWatchlist(String ticker) async {
    await _auth.addWatchlist(ticker);
    await fetchWatchlist(force: true);
  }

  Future<void> removeFromWatchlist(String ticker) async {
    await _auth.deleteWatchlist(ticker);
    // optimistik: hapus lokal jika ada
    watchlist = (watchlist ?? [])..removeWhere((e) => e.ticker == ticker);
    notifyListeners();
  }

  Future<void> toggleWatchlist(
    String ticker, {
    required bool nowInWatchlist,
  }) async {
    try {
      if (nowInWatchlist) {
        await removeFromWatchlist(ticker);
      } else {
        await addToWatchlist(ticker);
      }
    } catch (e) {
      // tampilkan snackbar/toast dari UI kalau perlu
      rethrow;
    }
  }

  bool _patchListBySymbol(List<StockListItem>? list, Map<String, dynamic> row) {
    if (list == null || list.isEmpty) return false;

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
      logoUrl: (logo != null && logo.isNotEmpty) ? logo : null,
    );

    return true;
  }

  void startLivePrices({
    required String wsBaseUrl,
    required List<String> symbols,
  }) {
    if (_wsRunning) return;

    final syms = symbols
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (syms.isEmpty) return;

    _wsRunning = true;
    final uri = Uri.parse('$wsBaseUrl/ws/prices?symbols=${syms.join(",")}');

    _ws = LivePricesWS()..connect(uri);

    _wsSub = _ws!.stream.listen((msg) {
      final type = msg['type'];

      if (type == 'error') {
        // ignore: avoid_print
        print('WS ERROR: ${msg['message']}');
        return;
      }
      if (type != 'tick') return;
      // if (msg['type'] != 'tick') return;

      final data = msg['data'];
      if (data is! Map) return;

      bool changed = false;

      for (final entry in data.entries) {
        final v = entry.value;
        if (v is! Map) continue;

        final row = Map<String, dynamic>.from(v);

        // changed = _patchListBySymbol(watchlist, row) || changed;
        // changed = _patchListBySymbol(topGainers, row) || changed;
        // changed = _patchListBySymbol(topLosers, row) || changed;
        // changed = _patchListBySymbol(topVolume, row) || changed;
        row['symbol'] = entry.key;

        changed = _patchListBySymbol(watchlist, row) || changed;
        changed = _patchListBySymbol(topGainers, row) || changed;
        changed = _patchListBySymbol(topLosers, row) || changed;
        changed = _patchListBySymbol(topVolume, row) || changed;
      }

      if (changed) notifyListeners();
    });
  }

  // void stopLivePrices() {
  //   _wsRunning = false;
  //   _wsSub?.cancel();
  //   _wsSub = null;
  //   _ws?.close();
  //   _ws = null;
  // }
  Future<void> stopLivePrices() async {
    _wsRunning = false;
    await _wsSub?.cancel();
    _wsSub = null;
    _ws?.close();
    _ws = null;
  }

  @override
  void dispose() {
    stopLivePrices();
    stopIhsgLive();
    super.dispose();
  }

  double? ihsgLast;
  double? ihsgChangePoint;
  double? ihsgChangePct;
  DateTime? ihsgTs;

  LivePricesWS? _ihsgWs;
  StreamSubscription? _ihsgSub;

  void startIhsgLive({required String wsBaseUrl}) {
    if (_ihsgWs != null) return;

    final uri = Uri.parse('$wsBaseUrl/ws/ihsg');
    _ihsgWs = LivePricesWS()..connect(uri);

    _ihsgSub = _ihsgWs!.stream.listen((msg) {
      if (msg['type'] != 'ihsg_tick') return;
      final data = msg['data'];
      if (data is! Map) return;

      final row = Map<String, dynamic>.from(data);

      ihsgLast = (row['last'] as num?)?.toDouble();
      ihsgChangePoint = (row['change_point'] as num?)?.toDouble();
      ihsgChangePct = (row['change_pct'] as num?)?.toDouble();

      // kalau backend ngirim 'date' atau 'ts'
      final d = row['date']?.toString();
      if (d != null) {
        // contoh: '2026-01-05'
        ihsgTs = DateTime.tryParse(d);
      }

      notifyListeners();
    });
  }

  void stopIhsgLive() {
    _ihsgSub?.cancel();
    _ihsgSub = null;
    _ihsgWs?.close();
    _ihsgWs = null;
  }
}
