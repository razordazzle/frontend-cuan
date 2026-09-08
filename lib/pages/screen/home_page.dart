import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:cuan_app/components/tv_chart_widget.dart';
import 'package:cuan_app/config/app_config.dart';
import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/data/model/stock_list_item.dart';
import 'package:cuan_app/pages/screen/global_search_page.dart';
import 'package:cuan_app/pages/screen/ihsg_tradingview_page.dart';
import 'package:cuan_app/pages/screen/stock_detail_page.dart';
import 'package:cuan_app/providers/stocks_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late StocksProvider _stocksProvider;
  bool _isCandle = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stocksProvider = context.read<StocksProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = _stocksProvider;
      await Future.wait([
        p.fetchWatchlist(),
        p.fetchGainers(),
        p.fetchLosers(),
        p.fetchVolume(),
        p.fetchIndexCandles(),
      ]);

      if (!mounted) return;

      // kumpulin symbols dari semua tab (biar 1 WS doang)
      final syms = <String>{};

      for (final s in (p.watchlist ?? const <StockListItem>[]))
        syms.add(s.ticker);
      for (final s in (p.topGainers ?? const <StockListItem>[]))
        syms.add(s.ticker);
      for (final s in (p.topLosers ?? const <StockListItem>[]))
        syms.add(s.ticker);
      for (final s in (p.topVolume ?? const <StockListItem>[]))
        syms.add(s.ticker);

      // ganti sesuai environment kamu
      // - Android emulator: ws://10.0.2.2:8000
      // - iOS simulator: ws://127.0.0.1:8000
      // - device fisik: ws://IP-LAN-KOMPUTER:8000
      // const wsBaseUrl = 'ws://10.0.2.2:8000';
      final wsBaseUrl = AppConfig.baseUrl.replaceFirst('http', 'ws');

      p.startLivePrices(wsBaseUrl: wsBaseUrl, symbols: syms.toList());
      p.startIhsgLive(wsBaseUrl: wsBaseUrl);
    });
  }

  String _deltaText(List<Ohlc> candles) {
    if (candles.isEmpty) return '-- (--%)';

    final p = context.read<StocksProvider>();
    final is1D = p.indexInterval == '1D';

    double d;
    double pct;

    if (is1D) {
      // FIX Bug A: jangan percaya WS kalau nilainya persis 0 (kemungkinan besar belum dihitung backend)
      final wsValid =
          p.ihsgChangePoint != null &&
          p.ihsgChangePct != null &&
          p.ihsgChangePoint != 0.0;

      if (wsValid) {
        return _fmtIhsgDelta(p);
      }

      final now = DateTime.now();

      // FIX Bug B: ambil SEMUA candle hari ini, bukan cuma candle terakhir
      final todayCandles = candles
          .where(
            (c) =>
                c.time.year == now.year &&
                c.time.month == now.month &&
                c.time.day == now.day,
          )
          .toList();

      if (todayCandles.isEmpty) return '-- (--%)';

      // Open = candle PERTAMA hari ini (jam 09:00), bukan candle terakhir
      final openHariIni = todayCandles.first.open;
      final closeHariIni = todayCandles.last.close;

      d = closeHariIni - openHariIni;
      pct = openHariIni == 0 ? 0 : (d / openHariIni) * 100;
    } else {
      final prev = candles.first.close;
      final last = candles.last.close;

      d = last - prev;
      pct = prev == 0 ? 0 : (d / prev) * 100;
    }

    final s0 = '${d >= 0 ? '+' : ''}${d.toStringAsFixed(2)}';
    final s1 = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%';
    return '$s0  ($s1)';
  }

  String _fmtIhsgDelta(StocksProvider p) {
    final chg = p.ihsgChangePoint;
    final pct = p.ihsgChangePct;

    if (chg == null || pct == null) return '-- (--%)';

    final s0 = '${chg >= 0 ? '+' : ''}${chg.toStringAsFixed(0)}';
    final s1 = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%';
    return '$s0  ($s1)';
  }

  Future<void> _restartWs() async {
    final p = context.read<StocksProvider>();

    // p.stopLivePrices();
    await p.stopLivePrices();

    final syms = <String>{};
    for (final s in (p.watchlist ?? const <StockListItem>[]))
      syms.add(s.ticker);
    for (final s in (p.topGainers ?? const <StockListItem>[]))
      syms.add(s.ticker);
    for (final s in (p.topLosers ?? const <StockListItem>[]))
      syms.add(s.ticker);
    for (final s in (p.topVolume ?? const <StockListItem>[]))
      syms.add(s.ticker);

    // const wsBaseUrl = 'ws://10.0.2.2:8000';
    final wsBaseUrl = AppConfig.baseUrl.replaceFirst('http', 'ws');
    p.startLivePrices(wsBaseUrl: wsBaseUrl, symbols: syms.toList());
  }

  @override
  void dispose() {
    // context.read<StocksProvider>().stopIhsgLive();
    // context.read<StocksProvider>().stopLivePrices();
    _stocksProvider.stopIhsgLive();
    _stocksProvider.stopLivePrices();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    const upColor = Color(0xFF21C07A);
    final downColor = Colors.red.shade600;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 64,
          titleSpacing: 16,
          centerTitle: false,
          title: Text(
            'Cuan Apps',
            style: t.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: cs.onSurface),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GlobalSearchPage(
                      defaultTypes: 'stock|journal|playlist',
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: cs.onSurface),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
            IconButton(
              icon: Icon(Icons.notifications_none, color: cs.onSurface),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),

        // 👇 PERMINTAAN 2: UBAH JADI NESTED SCROLL VIEW BIAR BISA DI-SCROLL FULL
        body: SafeArea(
          bottom: false,
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Consumer<StocksProvider>(
                      builder: (context, p, _) {
                        final loading = p.loadingIndex;
                        final error = p.errIndex;
                        final data = p.ihsgCandles;

                        final useDummy =
                            data.isEmpty && !loading && error == null;

                        final candles = useDummy
                            ? makeDummyCandles(60)
                            : data
                                  .map(
                                    (c) => Ohlc(
                                      time: c.ts,
                                      open: c.open ?? c.close ?? 0,
                                      high: c.high ?? c.close ?? 0,
                                      low: c.low ?? c.close ?? 0,
                                      close: c.close ?? 0,
                                      volume: (c.volume ?? 0).toDouble(),
                                    ),
                                  )
                                  .toList();

                        if (candles.isNotEmpty && p.ihsgLast != null) {
                          final lastCandle = candles.last;
                          final livePrice = p.ihsgLast!;
                          candles[candles.length - 1] = Ohlc(
                            time: lastCandle.time,
                            open: lastCandle.open,
                            high: math.max(lastCandle.high, livePrice),
                            low: math.min(lastCandle.low, livePrice),
                            close: livePrice,
                            volume: lastCandle.volume,
                          );
                        }

                        final hasData = candles.isNotEmpty;

                        final isUp = () {
                          if (!hasData) return true;
                          if (p.indexInterval == '1D') {
                            if (p.ihsgChangePoint != null) {
                              return p.ihsgChangePoint! >= 0;
                            }

                            // Samakan dengan logika Delta 1D: Cek apakah data hari ini
                            final now = DateTime.now();
                            final todayCandles = candles
                                .where(
                                  (c) =>
                                      c.time.year == now.year &&
                                      c.time.month == now.month &&
                                      c.time.day == now.day,
                                )
                                .toList();

                            if (todayCandles.isNotEmpty) {
                              return todayCandles.last.close >=
                                  todayCandles.first.open;
                            }
                            return true;
                          }
                          return candles.last.close >= candles.first.close;
                        }();

                        final baselinePrice = hasData
                            ? candles.first.open
                            : null;

                        return Card(
                          color: cs.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'CHART IHSG',
                                      style: t.textTheme.labelLarge?.copyWith(
                                        color: cs.onSurface.withOpacity(.8),
                                        letterSpacing: .5,
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        Icons.open_in_full,
                                        color: cs.onSurface.withOpacity(.6),
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          _openTradingViewPage(context),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        _isCandle
                                            ? Icons.show_chart
                                            : Icons.candlestick_chart,
                                        color: cs.onSurface.withOpacity(.6),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isCandle = !_isCandle;
                                        });
                                      },
                                    ),
                                    const Spacer(),
                                    if (loading && !hasData)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else if (error != null && !hasData)
                                      Icon(
                                        Icons.error_outline,
                                        color: cs.error,
                                        size: 18,
                                      )
                                    else if (hasData)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            (p.ihsgLast ?? candles.last.close)
                                                .toStringAsFixed(0),
                                            style: t.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: isUp
                                                      ? upColor
                                                      : downColor,
                                                ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isUp
                                                    ? Icons.arrow_drop_up
                                                    : Icons.arrow_drop_down,
                                                color: isUp
                                                    ? upColor
                                                    : downColor,
                                              ),
                                              Text(
                                                (p.indexInterval == '1D')
                                                    ? (p.ihsgChangePoint != null
                                                          ? _fmtIhsgDelta(p)
                                                          : _deltaText(candles))
                                                    : _deltaText(candles),
                                                style: t.textTheme.labelSmall
                                                    ?.copyWith(
                                                      color: isUp
                                                          ? upColor
                                                          : downColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _chip(context, p, '1D', '1D'),
                                      const SizedBox(width: 6),
                                      _chip(context, p, '1W', '1W'),
                                      const SizedBox(width: 6),
                                      _chip(context, p, '1M', '1M'),
                                      const SizedBox(width: 6),
                                      _chip(context, p, '3M', '3M'),
                                      const SizedBox(width: 6),
                                      _chip(context, p, 'YTD', 'YTD'),
                                      const SizedBox(width: 6),
                                      _chip(context, p, '1Y', '1Y'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (error != null && !hasData)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                    ),
                                    child: Text(
                                      error,
                                      style: t.textTheme.bodySmall?.copyWith(
                                        color: cs.error,
                                      ),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: () => _openTradingViewPage(context),
                                  child: _IhsgCandleChart(
                                    candles: candles,
                                    upColor: upColor,
                                    downColor: downColor,
                                    gridColor: cs.outline.withOpacity(.15),
                                    isUp: isUp,
                                    baselinePrice: baselinePrice,
                                    isCandle: _isCandle,
                                    currentRange: p.indexInterval,
                                    prevClose:
                                        (p.ihsgLast != null &&
                                            p.ihsgChangePoint != null)
                                        ? (p.ihsgLast! - p.ihsgChangePoint!)
                                        : null,
                                  ),
                                ),
                                // else
                                //   GestureDetector(
                                //     onTap: () => _openTradingViewPage(context),
                                //     child: SizedBox(
                                //       height: 140,
                                //       child: TvChartWidget(
                                //         candles: candles,
                                //         isCandle: _isCandle,
                                //         upColor: upColor,
                                //         downColor: downColor,
                                //         gridColor: cs.outline.withOpacity(.15),
                                //         interactive: false,
                                //       ),
                                //     ),
                                //   ),

                                // _IhsgCandleChart(
                                //     candles: candles,
                                //     upColor: upColor,
                                //     downColor: downColor,
                                //     gridColor: cs.outline.withOpacity(.15),
                                //     isUp: isUp,
                                //     baselinePrice: baselinePrice,
                                //     isCandle: _isCandle,
                                //     currentRange: p.indexInterval,
                                //     prevClose:
                                //         (p.ihsgLast != null &&
                                //             p.ihsgChangePoint != null)
                                //         ? (p.ihsgLast! - p.ihsgChangePoint!)
                                //         : null,
                                //   ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      isScrollable: false,
                      labelPadding: EdgeInsets.zero,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorColor: cs.primary,
                      indicatorWeight: 2,
                      labelColor: cs.onSurface,
                      unselectedLabelColor: cs.onSurface.withValues(alpha: .6),
                      labelStyle: t.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: const [
                        Tab(text: 'WatchList'),
                        Tab(text: 'Top Gainers'),
                        Tab(text: 'Top Losers'),
                        Tab(text: 'Top Volume'),
                      ],
                    ),
                    cs.surface, // Warna background tab bar saat terscroll
                  ),
                ),
              ];
            },
            body: Consumer<StocksProvider>(
              builder: (_, p, __) => TabBarView(
                children: [
                  _TabList(
                    loading: p.loadingWatch,
                    error: p.errWatch,
                    data: p.watchlist,
                    onRefresh: () async {
                      await p.fetchWatchlist(force: true);
                      await _restartWs();
                    },
                  ),
                  _TabList(
                    loading: p.loadingGainers,
                    error: p.errGainers,
                    data: p.topGainers,
                    onRefresh: () => p.fetchGainers(force: true),
                  ),
                  _TabList(
                    loading: p.loadingLosers,
                    error: p.errLosers,
                    data: p.topLosers,
                    onRefresh: () => p.fetchLosers(force: true),
                  ),
                  _TabList(
                    loading: p.loadingVolume,
                    error: p.errVolume,
                    data: p.topVolume,
                    onRefresh: () => p.fetchVolume(force: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, StocksProvider p, String v, String label) {
    final cs = Theme.of(context).colorScheme;
    final selected = p.indexInterval == v;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => p.setIndexInterval(v),
      selectedColor: cs.primary.withOpacity(.15),
      labelStyle: TextStyle(
        color: selected ? cs.primary : cs.onSurface.withOpacity(.7),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  void _openTradingViewPage(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const IhsgTradingViewPage()));
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this._color);

  final TabBar _tabBar;
  final Color _color;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _color, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
/* ===================== List saham ===================== */

class _TabList extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<StockListItem>? data;
  final Future<void> Function() onRefresh;
  const _TabList({
    required this.loading,
    required this.error,
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final items = data ?? const <StockListItem>[];

    // Header kolom
    Widget header() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Nama',
              style: t.labelMedium?.copyWith(
                color: cs.onSurface.withOpacity(.6),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Harga',
                style: t.labelMedium?.copyWith(
                  color: cs.onSurface.withOpacity(.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Cell status (loading / error / empty)
    Widget statusCell() {
      if (loading && items.isEmpty) {
        return const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (error != null) {
        return SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!, style: TextStyle(color: cs.error)),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: onRefresh,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        );
      }
      if (items.isEmpty) {
        return const SizedBox(
          height: 120,
          child: Center(child: Text('Data kosong')),
        );
      }
      return const SizedBox.shrink();
    }

    // Builder row data
    Widget row(StockListItem s) {
      // 👇 1. Tarik data harga terakhir dan harga penutupan kemarin
      final double price = s.lastPrice ?? 0.0;
      final double prev = s.prevClose ?? 0.0;

      double chg = s.changePoint ?? 0.0;
      double pct = s.changePct ?? 0.0;

      // 👇 2. HITUNG MANUAL jika chg dari API masih 0 tapi harga valid
      if ((chg == 0 || pct == 0) && prev > 0 && price > 0) {
        chg = price - prev;
        pct = (chg / prev) * 100.0;
      }

      // 👇 3. Gunakan 'chg' hasil hitungan untuk nentuin warna hijau/merah
      final pos = chg >= 0;
      final color = pos ? const Color(0xFF21C07A) : Colors.red.shade600;

      final url = (s.logoUrl ?? '').trim();
      final hasImg = url.isNotEmpty;

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: cs.surfaceVariant,
          backgroundImage: hasImg ? NetworkImage(url) : null,
          onBackgroundImageError: hasImg
              ? (error, stackTrace) {
                  // ignore: avoid_print
                  print('ERROR LOAD LOGO ${s.ticker}: $error');
                }
              : null,
          child: !hasImg
              ? Text(
                  s.ticker.substring(0, 1),
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                )
              : null,
        ),
        title: Row(
          children: [
            Text(
              s.ticker,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(.7),
                ),
              ),
            ),
          ],
        ),
        trailing: SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price > 0 ? price.toStringAsFixed(0) : '-',
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pos ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: color,
                    size: 20,
                  ),
                  Text(
                    // 👇 4. Masukkan 'chg' dan 'pct' hasil hitungan manual tadi
                    _fmtDelta(chg, pct),
                    style: t.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StockDetailPage(
                ticker: s.ticker,
                company: s.companyName,
                price: price.toInt(),
                // 👇 5. Oper 'chg' dan 'pct' ini ke StockDetailPage biar di sana juga hijau/merah
                change: chg.toInt(),
                changePct: pct,
                logoUrl: s.logoUrl,
              ),
            ),
          );
          if (context.mounted) {
            context.read<StocksProvider>().fetchWatchlist(force: true);
          }
        },
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 1 /* header */ + (items.isEmpty ? 1 : items.length),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          if (i == 0) return header();
          if (items.isEmpty) return statusCell();
          return row(items[i - 1]);
        },
      ),
    );
  }

  String _fmtDelta(double? pt, double? pct) {
    final p0 = pt == null
        ? '-'
        : (pt >= 0 ? '+${pt.toStringAsFixed(0)}' : pt.toStringAsFixed(0));
    final p1 = pct == null
        ? '-'
        : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%';
    return '$p0  ($p1)';
  }
}

/* ===================== Model & Chart ===================== */

class Ohlc {
  final DateTime time;
  final double open, high, low, close, volume;
  Ohlc({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

/// Dummy generator: bikin 60 candle harian
List<Ohlc> makeDummyCandles(int n) {
  final now = DateTime.now();
  final rnd = math.Random(4);
  double prev = 6900;
  return List.generate(n, (i) {
    final day = now.subtract(Duration(days: n - 1 - i));
    final drift = (rnd.nextDouble() - 0.45) * 30; // sedikit tren
    final o = prev;
    final h = o + rnd.nextDouble() * 40 + 5;
    final l = o - rnd.nextDouble() * 40 - 5;
    final c = (l + h) / 2 + drift;
    prev = c;
    final v = 1000000 + rnd.nextInt(800000);
    return Ohlc(
      time: day,
      open: o,
      high: h,
      low: l,
      close: c,
      volume: v.toDouble(),
    );
  });
}

class _IhsgCandleChart extends StatefulWidget {
  final List<Ohlc> candles;
  final Color upColor; // hijau utk bullish
  final Color downColor; // merah utk bearish
  final Color gridColor;
  final bool isUp;
  final double? baselinePrice;
  final bool isCandle;
  final String currentRange;
  final double? prevClose;
  const _IhsgCandleChart({
    required this.candles,
    required this.upColor,
    required this.downColor,
    required this.gridColor,
    required this.isUp,
    this.baselinePrice,
    required this.isCandle,
    required this.currentRange,
    this.prevClose,
  });

  @override
  State<_IhsgCandleChart> createState() => _IhsgCandleChartState();
}

class _IhsgCandleChartState extends State<_IhsgCandleChart> {
  // late TrackballBehavior _trackball;
  // late TooltipBehavior _tooltip;
  TrackballBehavior _trackball = TrackballBehavior(enable: true);
  TooltipBehavior _tooltip = TooltipBehavior(enable: true);
  Ohlc? _selected;
  Timer? _resetTimer;
  int? _selectedIndex;
  bool _boxOnRight = false;

  @override
  void initState() {
    super.initState();
    _tooltip = TooltipBehavior(
      enable: true,
      shared: true,
      color: Colors.black87,
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      // header: '', // Biar nggak ada header ganda
      // format: 'point.x : point.y', // Ini yang bakal munculin kotak harga
    );

    // _trackball = TrackballBehavior(
    //   enable: true,
    //   // activationMode: ActivationMode.longPress,
    //   activationMode: ActivationMode.singleTap,
    //   tooltipDisplayMode:
    //       TrackballDisplayMode.groupAllPoints, // Biar muncul kotak detail
    //   lineType: TrackballLineType.vertical,
    //   lineColor: widget.gridColor.withOpacity(.6),
    //   lineWidth: 1,
    //   markerSettings: const TrackballMarkerSettings(
    //     markerVisibility: TrackballVisibilityMode.visible,
    //     height: 10,
    //     width: 10,
    //     borderWidth: 2,
    //     color: Colors.white,
    //   ), // 👇 TAMBAHKAN INI BIAR MUNCUL KOTAK DETAIL 👇
    //   tooltipSettings: const InteractiveTooltip(
    //     enable: true,
    //     // format: 'point.x : point.y', // Format tulisan di dalam kotak
    //     color: Colors.black87, // Warna background kotak
    //   ),
    _trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      lineType: TrackballLineType.vertical,
      lineColor: widget.gridColor.withOpacity(.8),
      lineWidth: 1,
      // MATIKAN tooltip bawaan trackball biar ga bentrok sama TooltipBehavior
      tooltipSettings: const InteractiveTooltip(enable: false),
      markerSettings: const TrackballMarkerSettings(
        markerVisibility: TrackballVisibilityMode.visible,
        height: 10,
        width: 10,
        borderWidth: 2,
        color: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel(); // <- TAMBAHKAN INI
    super.dispose();
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _selected = null);
      }
    });
  }

  DateTimeIntervalType _intervalTypeFor(List<Ohlc> candles) {
    if (candles.length < 2) return DateTimeIntervalType.days;
    final diff = candles.last.time.difference(candles.first.time).inDays.abs();

    if (diff > 90) return DateTimeIntervalType.months;
    if (diff >= 2) return DateTimeIntervalType.days;
    return DateTimeIntervalType.days;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final candles = widget.candles;
    final last = candles.isNotEmpty ? candles.last : null;
    final cur = _selected ?? last;
    final xType = _intervalTypeFor(candles);

    final chartColor = widget.isUp ? widget.upColor : widget.downColor;

    List<Ohlc> validCandles = candles
        .where((c) => c.low > 0 && c.high > 0)
        .toList();

    // =======================================================
    // FIX: LOGIKA MENGUNCI WAKTU KHUSUS 1D (INTRADAY HARI INI)
    // =======================================================
    DateTime xMin;
    DateTime xMax;
    final is1D = widget.currentRange == '1D';

    if (is1D && validCandles.isNotEmpty) {
      // 1. Cari tahu tanggal data ter-update (hari ini)
      final latestDate = validCandles.last.time;

      // 2. POTONG (Filter) array validCandles HANYA untuk tanggal tersebut!
      // Buang semua data tanggal 11 Jun, 10 Jun, dll dari memori chart
      validCandles = validCandles
          .where(
            (c) =>
                c.time.year == latestDate.year &&
                c.time.month == latestDate.month &&
                c.time.day == latestDate.day,
          )
          .toList();

      // 3. Kunci sumbu X layar dari jam 09:00 s.d 16:00 persis!
      xMin = DateTime(latestDate.year, latestDate.month, latestDate.day, 9, 0);
      xMax = DateTime(latestDate.year, latestDate.month, latestDate.day, 16, 0);
    } else if (validCandles.isNotEmpty) {
      xMin = validCandles.first.time;
      xMax = validCandles.last.time;
      if (!xMax.isAfter(xMin)) xMax = xMin.add(const Duration(minutes: 5));
    } else {
      xMin = DateTime.now().subtract(const Duration(days: 1));
      xMax = DateTime.now();
    }

    // Hitung Min-Max Y-Axis SETELAH datanya dipotong jadi "Hari Ini" saja
    double rawMin = validCandles.isNotEmpty
        ? validCandles.map((e) => e.low).reduce(math.min)
        : 6000;
    double rawMax = validCandles.isNotEmpty
        ? validCandles.map((e) => e.high).reduce(math.max)
        : 6100;

    final double range = (rawMax - rawMin).abs();

    // padding biar candle paling atas/bawah gak mepet ke tepi chart
    final double padding = range > 0 ? range * 0.15 : (is1D ? 20 : 50);
    double minY = rawMin - padding;
    double maxY = rawMax + padding;

    // hitung "nice interval" grid berdasarkan range asli, bukan fixed
    double _niceInterval(double r) {
      if (r <= 0) return is1D ? 50 : 100;
      final rough = r / 5; // target ~5 garis grid
      final magnitude = math
          .pow(10, (math.log(rough) / math.ln10).floor())
          .toDouble();
      final residual = rough / magnitude;
      double niceResidual;
      if (residual > 5) {
        niceResidual = 10;
      } else if (residual > 2) {
        niceResidual = 5;
      } else if (residual > 1) {
        niceResidual = 2;
      } else {
        niceResidual = 1;
      }
      return niceResidual * magnitude;
    }

    final double yInterval = _niceInterval(maxY - minY);

    minY = (minY / yInterval).floor() * yInterval;
    maxY = (maxY / yInterval).ceil() * yInterval;

    if (maxY == minY) {
      minY -= yInterval;
      maxY += yInterval;
    }
    if (is1D && validCandles.isNotEmpty) {
      final tDate =
          validCandles.last.time; // Ambil tanggal hari ini dari data terakhir
      // Paksa sumbu X mulai jam 09:00 sampai 16:00 persis kayak Stockbit
      xMin = DateTime(tDate.year, tDate.month, tDate.day, 9, 0);
      xMax = DateTime(tDate.year, tDate.month, tDate.day, 16, 0);
    } else if (validCandles.isNotEmpty) {
      xMin = validCandles.first.time;
      xMax = validCandles.last.time;
      if (!xMax.isAfter(xMin)) xMax = xMin.add(const Duration(minutes: 5));
    } else {
      xMin = DateTime.now().subtract(const Duration(days: 1));
      xMax = DateTime.now();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cur != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              // ... (Kodingan Wrap berisi Text tanggal dan O H L C lu biarkan sama) ...
              spacing: 14,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  // xType == DateTimeIntervalType.hours
                  //     ? DateFormat('dd MMM, HH:mm').format(
                  //         cur.time,
                  //       ) // Format jam (intraday)
                  //     : DateFormat(
                  //         'dd MMM yyyy',
                  //       ).format(cur.time), // Format tanggal (harian)
                  is1D
                      ? 'Pukul ${DateFormat('HH:mm').format(_toWib(cur.time))}'
                      : DateFormat('dd MMM yyyy').format(_toWib(cur.time)),
                  style: TextStyle(
                    color: cs.primary, // Biar warnanya nyala pakai warna tema
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                _kv('O', _fmt(cur.open), cs),
                _kv('H', _fmt(cur.high), cs),
                _kv('L', _fmt(cur.low), cs),
                _kv('C', _fmt(cur.close), cs),
              ],
            ),
          ),
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              SfCartesianChart(
                plotAreaBorderWidth: 0,
                // tooltipBehavior: _tooltip,
                backgroundColor: Colors.transparent,
                primaryXAxis: DateTimeCategoryAxis(
                  // ... (kodingan X Axis lu biarkan sama persis) ...
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  dateFormat: xType == DateTimeIntervalType.hours
                      ? DateFormat.Hm()
                      : DateFormat('dd MMM'),
                  labelStyle: const TextStyle(fontSize: 10),
                  interactiveTooltip: InteractiveTooltip(
                    enable: true,
                    color: cs.primary, // Warna background bubble
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    format: xType == DateTimeIntervalType.hours
                        ? 'HH:mm'
                        : 'dd MMM',
                  ),
                ),

                // 👇 UBAH BAGIAN Y AXIS DI SINI 👇
                primaryYAxis: NumericAxis(
                  minimum: minY, // Pakai nilai bulat kelipatan 100
                  maximum: maxY, // Pakai nilai bulat kelipatan 100
                  interval:
                      yInterval, // <--- KUNCI UTAMA: Paksa garis grid muncul per 100 poin!
                  opposedPosition: true,
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(width: 0),
                  majorGridLines: MajorGridLines(
                    color: widget.gridColor,
                    width: 1,
                  ),
                  labelStyle: const TextStyle(fontSize: 10),

                  plotBands: widget.baselinePrice != null
                      ? <PlotBand>[
                          PlotBand(
                            isVisible: true,
                            start: widget.baselinePrice,
                            end: widget.baselinePrice,
                            borderColor: cs.onSurface.withOpacity(0.35),
                            borderWidth: 1.5,
                            dashArray: const <double>[5, 4],
                          ),
                        ]
                      : <PlotBand>[],
                ),
                trackballBehavior: _trackball,
                zoomPanBehavior: ZoomPanBehavior(
                  enablePanning: true,
                  enablePinching: true,
                  zoomMode: ZoomMode.x,
                ),
                series: <CartesianSeries<Ohlc, DateTime>>[
                  if (widget.isCandle)
                    CandleSeries<Ohlc, DateTime>(
                      enableTooltip: true,
                      name: 'IHSG',
                      dataSource: validCandles,
                      xValueMapper: (d, _) => d.time,
                      lowValueMapper: (d, _) => d.low,
                      highValueMapper: (d, _) => d.high,
                      openValueMapper: (d, _) => d.open,
                      closeValueMapper: (d, _) => d.close,
                      bearColor: widget.downColor,
                      bullColor: widget.upColor,
                      enableSolidCandles: true,
                      animationDuration: 450,
                    )
                  else
                    AreaSeries<Ohlc, DateTime>(
                      enableTooltip: true,
                      name: 'IHSG',
                      dataSource: validCandles,
                      xValueMapper: (d, _) => d.time,
                      yValueMapper: (d, _) => d.close,
                      borderColor: chartColor,
                      borderWidth: 2.5,
                      gradient: LinearGradient(
                        colors: [
                          chartColor.withOpacity(0.35),
                          chartColor.withOpacity(0.01),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      animationDuration: 450,
                    ),
                ],
                onTrackballPositionChanging: (args) {
                  final i = args.chartPointInfo?.dataPointIndex;
                  if (i != null && i >= 0 && i < validCandles.length) {
                    setState(() {
                      _selected = validCandles[i];
                      _selectedIndex = i;
                      _boxOnRight = i < (validCandles.length / 2);
                    });
                    _scheduleReset();
                  }
                },
              ),
              if (_selected != null)
                Positioned(
                  top: 8,
                  left: _boxOnRight ? null : 12,
                  right: _boxOnRight ? 12 : null,
                  child: IgnorePointer(
                    child: Builder(
                      builder: (context) {
                        final cur = _selected!;
                        // final dateLabel = xType == DateTimeIntervalType.hours
                        //     ? DateFormat('dd MMM yyyy, HH:mm').format(cur.time)
                        //     : DateFormat('dd MMM yyyy').format(cur.time);
                        final displayTime = _toWib(cur.time);
                        final dateLabel = is1D
                            ? DateFormat('HH:mm').format(displayTime)
                            : DateFormat('dd MMM yyyy').format(displayTime);

                        final refPrice = (is1D && widget.prevClose != null)
                            ? widget.prevClose!
                            : cur.open; // fallback buat range selain 1D atau kalau prevClose belum ada
                        final chg = cur.close - refPrice;
                        final pct = refPrice == 0
                            ? 0.0
                            : (chg / refPrice) * 100;
                        final naik = chg >= 0;
                        final chgColor = naik
                            ? widget.upColor
                            : widget.downColor;
                        Widget row(String k, String v, {Color? color}) =>
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 1.5,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 48,
                                    child: Text(
                                      k,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    v,
                                    style: TextStyle(
                                      color: color ?? Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dateLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              row(
                                'High',
                                _fmt(cur.high),
                                color: widget.upColor,
                              ),
                              row(
                                'Low',
                                _fmt(cur.low),
                                color: Colors.red.shade300,
                              ),
                              row('Open', _fmt(cur.open)),
                              row('Close', _fmt(cur.close)),
                              row('Volume', _fmtVolume(cur.volume)),
                              row(
                                'Chg',
                                '${naik ? '+' : ''}${chg.toStringAsFixed(0)} '
                                    '(${naik ? '+' : ''}${pct.toStringAsFixed(2)}%)',
                                color: chgColor,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          k,
          style: TextStyle(
            color: cs.onSurface.withOpacity(.65),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          v,
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ],
    );
  }

  String _fmt(double x) => x.toStringAsFixed(0);
  String _fmtVolume(num? v) {
    if (v == null) return '-';
    final val = v.toDouble();
    if (val >= 1e9) return '${(val / 1e9).toStringAsFixed(2)}B';
    if (val >= 1e6) return '${(val / 1e6).toStringAsFixed(2)}M';
    if (val >= 1e3) return '${(val / 1e3).toStringAsFixed(2)}K';
    return val.toStringAsFixed(0);
  }

  DateTime _toWib(DateTime t) => t.toUtc().add(const Duration(hours: 7));
}
