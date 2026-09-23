import 'dart:async';
import 'dart:math' as math;
import 'package:cuan_app/config/app_config.dart';
import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/data/model/broker_summary_row.dart';
import 'package:cuan_app/data/model/candle_item.dart';
import 'package:cuan_app/data/services/stocks_service.dart';
import 'package:cuan_app/pages/screen/stock_tradingview_page.dart';
import 'package:cuan_app/providers/stock_detail_provider.dart';
import 'package:cuan_app/providers/stocks_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StockDetailPage extends StatefulWidget {
  final String ticker;
  final String company;
  final int price;
  final int change;
  final double changePct;
  final String? logoUrl;

  const StockDetailPage({
    super.key,
    required this.ticker,
    required this.company,
    required this.price,
    required this.change,
    required this.changePct,
    this.logoUrl,
  });

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  // final _ranges = const ['1M', '3M', '6M', '1Y', '10M', '30M', '1H', '1D'];
  final _ranges = const ['1m', '5m', '15m', '30m', '1H', '1D', '1W', '1M'];
  int _rangeIndex = 5;

  bool _isCandle = true;
  // final Set<String> _overlaySet = {'MA', 'EMA', 'BOLL'};
  // final Set<String> _subSet = {'VOL', 'RSI', 'MACD'};
  String? _overlay = 'MA'; // default seperti prototype
  String? _sub = 'VOL';

  final GlobalKey<_BrokerTabState> _brokerTabKey = GlobalKey<_BrokerTabState>();
  late StockDetailProvider _detailProvider;

  @override
  void initState() {
    super.initState();
    // trigger load SEKALI setelah widget mounted
    _detailProvider = context.read<StockDetailProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initialInterval = _intervalForLabel(_ranges[_rangeIndex]);
      final initialLimit = _limitForLabel(_ranges[_rangeIndex]);

      context.read<StockDetailProvider>().loadAll(
        widget.ticker,
        candleInterval: initialInterval,
        candleLimit: initialLimit,
      );

      final wsBaseUrl = AppConfig.wsBaseUrl;
      context.read<StockDetailProvider>().startLive(
        wsBaseUrl: wsBaseUrl,
        symbol: widget.ticker,
      );
      context.read<StocksProvider>().fetchWatchlist();
    });
  }

  @override
  void dispose() {
    _detailProvider.stopLive();
    super.dispose();
  }

  String _intervalForLabel(String label) {
    switch (label) {
      case '1m':
        return '1m';
      case '5m':
        return '5m';
      case '15m':
        return '15m';
      case '30m':
        return '30m';
      case '1H':
        return '1h';
      case '1D':
        return '1d';
      case '1W':
        return '1w'; // FIX: candle per JAM, bukan per minggu
      case '1M':
        return '1M'; // FIX: candle per HARI, bukan per bulan
      default:
        return '1d';
    }
  }

  int _limitForLabel(String label) {
    switch (label) {
      case '1m':
        return 195; // sliding window, sama pola kayak IHSG 1D
      case '5m':
        return 100;
      case '15m':
        return 60;
      case '30m':
        return 48;
      case '1H':
        return 48;
      case '1D':
        return 500; // intraday hari ini
      case '1W':
        return 102; // ~40 jam bursa = 1 minggu terakhir
      // case '1W':
      //   return 52; // ~40 jam bursa = 1 minggu terakhir
      case '1M':
        return 24; // ~22 hari kerja bursa = 1 bulan terakhir
      default:
        return 200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Consumer<StockDetailProvider>(
        builder: (_, p, __) {
          final d = p.detail;

          // status naik/turun berdasarkan last vs prevClose (fallback ke prop yang dibawa)
          final last = p.liveLast ?? d?.lastPrice;
          final prev = d?.prevClose; // prevClose dari REST saja, stabil
          final chg = p.liveChangePoint ?? ((last ?? 0) - (prev ?? 0));
          final pct =
              p.liveChangePct ?? _safeChangePct(last, prev) ?? widget.changePct;

          final isUp = chg >= 0;
          // final isUp = (last != null && prev != null)
          //     ? (last - prev) >= 0
          //     : widget.change >= 0;
          final open = d?.openPrice;
          final high = d?.highPrice;
          final low = d?.lowPrice;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 64,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: cs.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: cs.onSurface),
                  onPressed: () {},
                ),
                Consumer<StocksProvider>(
                  builder: (_, sp, __) {
                    final inWatch = (sp.watchlist ?? const []).any(
                      (it) =>
                          it.ticker.toUpperCase() ==
                          widget.ticker.toUpperCase(),
                    );
                    return IconButton(
                      tooltip: inWatch
                          ? 'Hapus dari Watchlist'
                          : 'Tambah ke Watchlist',
                      icon: Icon(
                        inWatch ? Icons.star : Icons.star_border,
                        color: inWatch ? const Color(0xFFFFC107) : cs.onSurface,
                      ),
                      onPressed: () async {
                        try {
                          await context.read<StocksProvider>().toggleWatchlist(
                            widget.ticker,
                            nowInWatchlist: inWatch,
                          );
                          // opsional: snackbar
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  inWatch
                                      ? 'Dihapus dari Watchlist'
                                      : 'Ditambahkan ke Watchlist',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(8),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outline.withOpacity(.12),
                ),
              ),
            ),

            body: p.loading && d == null
                ? const Center(child: CircularProgressIndicator())
                : NestedScrollView(
                    headerSliverBuilder: (context, _) => [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: _StockHeader(
                                ticker: widget.ticker,
                                company: d?.companyName ?? widget.company,
                                price: (last ?? widget.price.toDouble())
                                    .toInt(),
                                // change: ((last ?? 0) - (prev ?? 0)).toInt(),
                                // changePct:
                                //     _safeChangePct(last, prev) ??
                                //     widget.changePct,
                                change: chg.toInt(),
                                changePct: pct,
                                logoUrl: widget.logoUrl,
                              ),
                            ),

                            // === segmented range (tetap) ===
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _SegmentRow(
                                items: _ranges,
                                selectedIndex: _rangeIndex,
                                onSelected: (i) {
                                  setState(() => _rangeIndex = i);
                                  final interval = _intervalForLabel(
                                    _ranges[i],
                                  );
                                  final limit = _limitForLabel(_ranges[i]);
                                  context
                                      .read<StockDetailProvider>()
                                      .fetchCandles(interval, limit: limit);
                                },
                              ),
                            ),
                            // === CHART (pakai pilihan indikatornya) ===
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Builder(
                                builder: (context) {
                                  if (p.candles.isNotEmpty) {
                                    return _CandleChartCard(
                                      ticker: widget.ticker,
                                      candles: p.candles,
                                      isUp: isUp,
                                      isCandle: _isCandle,
                                      currentRange: _ranges[_rangeIndex],
                                      onToggleChartType: () {
                                        setState(() {
                                          _isCandle = !_isCandle;
                                        });
                                      },
                                      showVol: _sub == 'VOL',
                                      showRSI: _sub == 'RSI',
                                      showMACD: _sub == 'MACD',
                                      showMA: _overlay == 'MA',
                                      showEMA: _overlay == 'EMA',
                                      showBOLL: _overlay == 'BOLL',
                                    );
                                  }

                                  // kalau candle belum ada:
                                  if (p.loading) {
                                    return Card(
                                      elevation: 0,
                                      color: cs.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const SizedBox(
                                        height: 220,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    );
                                  }

                                  return Card(
                                    elevation: 0,
                                    color: cs.surface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const SizedBox(
                                      height: 220,
                                      child: Center(
                                        child: Text('Belum ada data chart'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: _IndicatorToolbar(
                                overlaySelected: _overlay,
                                subSelected: _sub,
                                onOverlaySelect: (s) => setState(() {
                                  _overlay = (_overlay == s) ? null : s;
                                }),
                                onSubSelect: (s) => setState(() {
                                  _sub = (_sub == s) ? null : s;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: 12)),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabBarHeader(
                          TabBar(
                            onTap: (i) async {
                              final controller = DefaultTabController.of(
                                context,
                              );

                              if (i == 1) {
                                // TAB 1 → tetap buka halaman Key Stats terpisah
                                final keep = controller?.index ?? 0;
                                Future.microtask(
                                  () => controller?.animateTo(keep),
                                );

                                final res = await Navigator.pushNamed(
                                  context,
                                  AppRoutes.keyStats,
                                  arguments: {'ticker': widget.ticker},
                                );

                                if (res is int) {
                                  controller?.animateTo(res);
                                  final currentInterval = _intervalForLabel(
                                    _ranges[_rangeIndex],
                                  );
                                  final currentLimit = _limitForLabel(
                                    _ranges[_rangeIndex],
                                  );
                                  // 👇 Panggil ulang datanya biar nggak kosongan! 👇
                                  context.read<StockDetailProvider>().loadAll(
                                    widget.ticker,
                                    candleInterval: currentInterval,
                                    candleLimit: currentLimit,
                                  );

                                  context.read<StockDetailProvider>().startLive(
                                    wsBaseUrl: AppConfig.wsBaseUrl,
                                    symbol: widget.ticker,
                                  );
                                }
                              }

                              // i == 0 dan i == 2: biarkan TabBarView jalan normal
                              // _SummaryFromCandles (0) dan _BrokerTab (2)
                            },
                            isScrollable: false,
                            tabs: const [
                              Tab(text: 'Ringkasan'),
                              Tab(text: 'Key Statistics'),
                              Tab(text: 'Informasi Broker'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    body: TabBarView(
                      children: [
                        _SummaryTab(
                          provider: p,
                          prevClose: prev,
                          open: open,
                          high: high,
                          low: low,
                        ),
                        const SizedBox.shrink(),
                        // _BrokerTab(key: _brokerTabKey),
                        const _BrokerTab(), // ✅ tanpa key
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

double? _safeChangePct(double? last, double? prev) {
  if (last == null || prev == null || prev == 0) return null;
  return (last - prev) / prev * 100.0;
}

/* ===================== RINGKASAN DARI CANDLES ===================== */
class _SummaryFromCandles extends StatelessWidget {
  final List<CandleItem> candles;
  final double? prevClose;
  final double? fallbackOpen;
  final double? fallbackHigh;
  final double? fallbackLow;
  const _SummaryFromCandles({
    required this.candles,
    this.prevClose,
    this.fallbackOpen,
    this.fallbackHigh,
    this.fallbackLow,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final c = candles.isNotEmpty ? candles.last : null;

    final open = fallbackOpen ?? c?.open;
    final high = fallbackHigh ?? c?.high;
    final low = fallbackLow ?? c?.low;
    String n(num? v) => v == null ? '-' : v.toStringAsFixed(0);

    Widget row(String k, String v, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: t.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(.7),
              ),
            ),
          ),
          Text(
            v,
            style: t.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          row('Open', n(open)),
          Divider(height: 1, color: cs.outline.withOpacity(.12)),
          row('High', n(high), color: const Color(0xFF21C07A)),
          Divider(height: 1, color: cs.outline.withOpacity(.12)),
          row('Low', n(low), color: Colors.red),
          Divider(height: 1, color: cs.outline.withOpacity(.12)),
          row('Prev Closing', n(prevClose)),
        ],
      ),
    );
  }
}

/* ---------- HEADER EMITEN ---------- */

class _StockHeader extends StatelessWidget {
  final String ticker, company;
  final int price, change;
  final double changePct;
  final String? logoUrl;
  const _StockHeader({
    required this.ticker,
    required this.company,
    required this.price,
    required this.change,
    required this.changePct,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final up = change >= 0;
    const upColor = Color(0xFF21C07A);

    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: cs.surfaceVariant,
          backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
          onBackgroundImageError: hasLogo
              ? (err, stack) => debugPrint('Gagal load logo')
              : null,
          child: !hasLogo
              ? Text(
                  ticker.substring(0, 1),
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticker,
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              Text(
                company,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(.6),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$price',
              style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: up ? upColor : Colors.red.shade600,
                ),
                Text(
                  '${up ? '+' : ''}$change (${changePct.toStringAsFixed(2)}%)',
                  style: t.labelSmall?.copyWith(
                    color: up ? upColor : Colors.red.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/* ---------- Chart, Segmented, Tabs ---------- */

class _SegmentRow extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const _SegmentRow({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Row(
      children: List.generate(items.length, (i) {
        final on = i == selectedIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelected(i),
              child: Container(
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on
                      ? cs.primary.withOpacity(.12)
                      : cs.surfaceVariant.withOpacity(.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: on
                        ? cs.primary.withOpacity(.3)
                        : cs.outline.withOpacity(.15),
                  ),
                ),
                child: Text(
                  items[i],
                  style: t.labelMedium?.copyWith(
                    color: on ? cs.primary : cs.onSurface.withOpacity(.75),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/* ===================== BROKER TAB ===================== */
class _BrokerTab extends StatefulWidget {
  const _BrokerTab({Key? key}) : super(key: key);
  @override
  State<_BrokerTab> createState() => _BrokerTabState();
}

class _BrokerTabState extends State<_BrokerTab> {
  // 0=Broker Summary, 1=Informasi Broker
  // int _mode = 1;
  // int _mode = 0;
  // 0=Semua, 1=Asing, 2=Domestik
  int _investor = 0;
  bool _net = true;

  DateTime? _tradeDate; // null => latest by server
  DateTime? _resolvedDate; // 👈 BARU: tanggal aktual dari response backend
  String _ticker = '';

  Future<List<BrokerSummaryRow>>? _futureRows;
  Map<String, String> _brokerCat = const {}; // CODE -> category

  // brand color (konsisten dgn halaman lain)
  static const _localColor = Color(0xFFFFC107);
  static const _foreignColor = Color(0xFFD32F2F);
  static const _bumnColor = Color(0xFF00BCD4);

  // void collapseToInfo() {
  //   if (_mode != 1) setState(() => _mode = 1);
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // _ticker = (args?['ticker'] as String?) ?? '';
    // _futureRows ??= _load();
    // _warmBrokerCategories(); // fire & forget (untuk pewarnaan buyer)
    // ambil dari parent StockDetailPage
    final parent = context.findAncestorWidgetOfExactType<StockDetailPage>();

    if (_ticker.isEmpty) {
      _ticker = parent?.ticker ?? ''; // ✅ assign langsung, tanpa ??=
    }
    _futureRows ??= _load();
    _warmBrokerCategories(); // pewarnaan broker
  }

  Future<void> _warmBrokerCategories() async {
    try {
      final svc = context.read<StocksService>();
      // batas server 500
      final list = await svc.listBrokers(limit: 500);
      // final mapped = {
      //   for (final e in list)
      //     (e['code'] as String).toUpperCase(): (e['category'] as String? ?? ''),
      // };
      final mapped = {
        for (final e in list)
          (e['code'] as String).toUpperCase(): ((e['category'] as String? ?? '')
              .toLowerCase()),
      };
      if (mounted) setState(() => _brokerCat = mapped);
    } catch (_) {
      // diam-diam saja; pewarnaan fallback ke hijau angka
    }
  }

  Future<List<BrokerSummaryRow>> _load() async {
    final svc = context.read<StocksService>();
    final investor = switch (_investor) {
      1 => 'foreign',
      2 => 'local',
      _ => 'all',
    };
    final rows = await svc.fetchBrokerSummary(
      _ticker,
      tradeDate:
          _tradeDate, // null = backend yg resolve (coba hari ini dulu, else mundur)
      investor: investor,
      net: _net,
      limit: 300,
    );

    // 👇 simpan tanggal ASLI yang dipakai backend, biar label selalu sinkron
    if (mounted) {
      setState(() {
        _resolvedDate = rows.isNotEmpty ? rows.first.tradeDate : _tradeDate;
      });
    }
    return rows;
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() {
      _futureRows = f;
    });
    await f;
  }

  DateTime get _effectiveDate =>
      // _tradeDate ?? DateTime.now().subtract(const Duration(days: 1));
      _resolvedDate ?? _tradeDate ?? DateTime.now();

  String get _rangeLabel {
    final d = _effectiveDate;
    final s = DateFormat('dd MMM yy').format(d);
    return '$s - $s';
  }

  Color _buyerColor(String code, ColorScheme cs) {
    switch (_brokerCat[code.toUpperCase()]) {
      case 'local':
        return _localColor;
      case 'foreign':
        return _foreignColor;
      case 'bumn':
        return _bumnColor;
      default:
        return Colors.greenAccent;
    }
  }

  Color _sellerColor(String code, ColorScheme cs) {
    switch (_brokerCat[code.toUpperCase()]) {
      case 'local':
        return _localColor;
      case 'foreign':
        return _foreignColor;
      case 'bumn':
        return _bumnColor;
      default:
        return Colors.redAccent;
    }
  }

  String _fmtNum(num? v) {
    if (v == null) return '-';
    return NumberFormat.compactCurrency(decimalDigits: 0, symbol: '').format(v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    Widget netToggle() {
      return InkWell(
        onTap: () {
          setState(() => _net = !_net);
          _refresh();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _net
                ? cs.primary.withOpacity(.12)
                : cs.surfaceVariant.withOpacity(.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _net
                  ? cs.primary.withOpacity(.30)
                  : cs.outline.withOpacity(.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _net ? Icons.toggle_on : Icons.toggle_off,
                size: 20,
                color: _net ? cs.primary : cs.onSurface.withOpacity(.5),
              ),
              const SizedBox(width: 4),
              Text(
                'Net',
                style: t.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _net ? cs.primary : cs.onSurface.withOpacity(.75),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget investorDropdown() {
      const labels = {0: 'Semua Investor', 1: 'Asing', 2: 'Lokal'};
      return PopupMenuButton<int>(
        initialValue: _investor,
        onSelected: (v) {
          setState(() => _investor = v);
          _refresh();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 0, child: Text('Semua Investor')),
          PopupMenuItem(value: 1, child: Text('Asing')),
          PopupMenuItem(value: 2, child: Text('Lokal')),
        ],
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outline.withOpacity(.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labels[_investor] ?? 'Semua Investor',
                style: t.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(.85),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: cs.onSurface.withOpacity(.6),
              ),
            ],
          ),
        ),
      );
    }

    Widget datePill() => OutlinedButton.icon(
      onPressed: () async {
        final today = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _tradeDate ?? today.subtract(const Duration(days: 1)),
          firstDate: DateTime(today.year - 5),
          lastDate: today,
        );
        if (picked != null) {
          setState(() => _tradeDate = picked);
          _refresh();
        }
      },
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(_rangeLabel, style: t.labelMedium),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    return FutureBuilder<List<BrokerSummaryRow>>(
      future: _futureRows,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final error = snap.hasError;
        final rows = snap.data ?? const <BrokerSummaryRow>[];

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ===== Baris: "Broker Summary" (teks statis) di kiri, "Lihat Daftar Broker" + tanggal di kanan =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Broker Summary',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.daftarBroker),
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.zero, // 👈 BARU — hilangkan padding default
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Lihat Daftar Broker',
                    style: TextStyle(color: cs.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                investorDropdown(),
                const SizedBox(width: 8),
                // netToggle(),
                Expanded(child: datePill()),
              ],
            ),
            const SizedBox(height: 8),
            // datePill(),
            // netToggle(),
            Align(
              alignment: Alignment.centerRight,
              child:
                  netToggle(), // 👈 dibungkus Align, biar ukurannya sekecil kontennya
            ),
            const SizedBox(height: 12),

            _summaryCard(
              context,
              rows,
              loading: loading,
              error: error,
              onRetry: _refresh,
            ),
          ],
        );
      },
    );
  }

  // ---------- Cards ----------

  Widget _summaryCard(
    BuildContext context,
    List<BrokerSummaryRow> rows, {
    required bool loading,
    required bool error,
    required Future<void> Function() onRetry,
  }) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final baseHead = t.labelLarge ?? t.bodyMedium ?? const TextStyle();
    final head = baseHead.copyWith(fontWeight: FontWeight.w700);

    const wCode = 46.0; // Lebar untuk kode (CC, AK)
    const wNum = 64.0; // Lebar untuk angka (1.37M, 5.03K)
    const gap = 16.0; // Jarak pembatas antara Buyer dan Seller
    const padH = 14.0; // Padding horizontal kiri-kanan

    // Total lebar konten = 364 (sangat pas untuk mayoritas layar HP modern)
    const totalWidth = (wCode * 2) + (wNum * 4) + gap + (padH * 2);

    Widget contentColumn() {
      if (loading) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: SizedBox(
            width: totalWidth - (padH * 2), // Sesuaikan lebar skeleton
            child: Column(
              children: List.generate(
                5,
                (i) => Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      if (error) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
          child: SizedBox(
            width:
                MediaQuery.of(context).size.width - 60, // Biar tetep di tengah
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 40),
                const SizedBox(height: 8),
                Text('Gagal memuat data', style: t.titleMedium),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        );
      }

      final top = rows.take(5).toList(); // Batasi 5 baris saja untuk ringkasan
      if (top.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('Tidak ada data')),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER TABEL ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: padH, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: wCode,
                  child: Center(
                    child: Text(_net ? 'Net Buy' : 'Buyer', style: head),
                  ), // 👈 diubah
                ),
                SizedBox(
                  width: wNum,
                  child: Center(
                    child: Text(_net ? 'Net Lot' : 'B.Lot', style: head),
                  ), // 👈 diubah
                ),
                SizedBox(
                  width: wNum,
                  child: Center(child: Text('B.Avg', style: head)), // tetap
                ),

                const SizedBox(width: gap),

                SizedBox(
                  width: wCode,
                  child: Center(
                    child: Text(_net ? 'Net Sell' : 'Seller', style: head),
                  ), // 👈 diubah
                ),
                SizedBox(
                  width: wNum,
                  child: Center(
                    child: Text(_net ? 'Net Lot' : 'S.Lot', style: head),
                  ), // 👈 diubah
                ),
                SizedBox(
                  width: wNum,
                  child: Center(child: Text('S.Avg', style: head)), // tetap
                ),
              ],
            ),
          ),

          // --- DIVIDER ATAS ---
          Container(
            height: 1,
            width: totalWidth,
            color: cs.outline.withOpacity(.12),
          ),

          // --- BODY ROWS ---
          ...top.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;

            final buyerNumStyle = t.bodyMedium?.copyWith(
              color: Colors.greenAccent,
              fontWeight: FontWeight.w700,
            );
            final sellerNumStyle = t.bodyMedium?.copyWith(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: padH,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // SISI BUYER
                      SizedBox(
                        width: wCode,
                        child: Center(
                          // Dibungkus Center
                          child: Text(
                            r.buyerCode,
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: _buyerColor(r.buyerCode, cs),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: wNum,
                        child: Center(
                          // Angka B.Lot fix warna HIJAU
                          child: Text(_fmtNum(r.bLot), style: buyerNumStyle),
                        ),
                      ),
                      SizedBox(
                        width: wNum,
                        child: Center(
                          // Angka B.Avg fix warna HIJAU
                          child: Text(_fmtNum(r.bAvg), style: buyerNumStyle),
                        ),
                      ),

                      const SizedBox(width: gap),

                      // SISI SELLER
                      SizedBox(
                        width: wCode,
                        child: Center(
                          // Dibungkus Center
                          child: Text(
                            r.sellerCode,
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: _sellerColor(r.sellerCode, cs),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: wNum,
                        child: Center(
                          // Angka S.Lot fix warna MERAH
                          child: Text(_fmtNum(r.sLot), style: sellerNumStyle),
                        ),
                      ),
                      SizedBox(
                        width: wNum,
                        child: Center(
                          // Angka S.Avg fix warna MERAH
                          child: Text(_fmtNum(r.sAvg), style: sellerNumStyle),
                        ),
                      ),
                    ],
                  ),
                ),
                // --- DIVIDER BAWAH ---
                if (i != top.length - 1)
                  Container(
                    height: 1,
                    width: totalWidth,
                    color: cs.outline.withOpacity(.06),
                  ),
              ],
            );
          }).toList(),
        ],
      );
    }

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // BUNGKUS TABEL DENGAN HORIZONTAL SCROLL
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics:
                const BouncingScrollPhysics(), // Scroll halus gaya iOS/Android
            child: contentColumn(),
          ),

          // TOMBOL EXPAND TETAP DI TENGAH (Di luar area scroll)
          if (!loading && !error && rows.isNotEmpty) ...[
            Divider(height: 1, color: cs.outline.withOpacity(.12)),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
              child: IconButton(
                onPressed: () {
                  final parent = context
                      .findAncestorWidgetOfExactType<StockDetailPage>();
                  Navigator.pushNamed(
                    context,
                    AppRoutes.brokerInfo,
                    arguments: {
                      'ticker': _ticker,
                      'companyName': parent?.company ?? '',
                      'logoUrl': parent?.logoUrl ?? '',
                      'price': parent?.price,
                      'change': parent?.change,
                      'changePct': parent?.changePct,
                      'tradeDate':
                          _resolvedDate ??
                          _tradeDate, // 👈 pakai hasil fix sebelumnya juga
                      'investor': _investor,
                      'net': _net,
                    },
                  );
                },
                icon: Icon(Icons.expand_more, color: cs.primary),
                tooltip: 'Lihat broker summary lengkap',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* ---------- Pinned TabBar (Sliver header) ---------- */

class _TabBarHeader extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _TabBarHeader(this._tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant _TabBarHeader oldDelegate) => false;
}

class _CandleChartCard extends StatefulWidget {
  final String ticker;
  final List<CandleItem> candles;
  final bool isUp;
  final bool isCandle;
  final VoidCallback onToggleChartType;
  final bool showVol;
  final bool showMA;
  final bool showEMA;
  final bool showBOLL; // NEW
  final bool showRSI; // NEW
  final bool showMACD;
  final String currentRange;

  const _CandleChartCard({
    required this.ticker,
    required this.candles,
    required this.isUp,
    required this.isCandle,
    required this.onToggleChartType,
    required this.currentRange,
    this.showVol = false,
    this.showMA = false,
    this.showEMA = false,
    this.showBOLL = false,
    this.showRSI = false,
    this.showMACD = false,
  });

  @override
  State<_CandleChartCard> createState() => _CandleChartCardState();
}

class _CandleChartCardState extends State<_CandleChartCard> {
  late final TrackballBehavior _trackball;
  late final ZoomPanBehavior _zoomPan;
  int? _selectedIndex;
  bool _boxOnRight = false;
  Timer? _resetTimer;
  List<CandleItem> _lastRaw = [];
  bool _lastIsIntraday = false;
  @override
  void initState() {
    super.initState();
    _trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.longPress,
      lineType: TrackballLineType.vertical,
      lineColor: Colors.grey.withOpacity(.6),
      lineWidth: 1,
      tooltipSettings: const InteractiveTooltip(enable: false),
      markerSettings: const TrackballMarkerSettings(
        markerVisibility: TrackballVisibilityMode.visible,
        height: 10,
        width: 10,
        borderWidth: 2,
        color: Colors.white,
      ),
    );
    _zoomPan = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _selectedIndex = null);
    });
  }

  String _fmtVolume(num? v) {
    if (v == null) return '-';
    final val = v.toDouble();
    if (val >= 1e9) return '${(val / 1e9).toStringAsFixed(2)}B';
    if (val >= 1e6) return '${(val / 1e6).toStringAsFixed(2)}M';
    if (val >= 1e3) return '${(val / 1e3).toStringAsFixed(2)}K';
    return val.toStringAsFixed(0);
  }

  String _fmtNum(num? v) => v == null ? '-' : v.toStringAsFixed(0);

  double _niceInterval(double rawRange, {int targetTicks = 8}) {
    if (rawRange <= 0) return 1;
    final rough = rawRange / targetTicks;
    final mag = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
    final norm = rough / mag; // 1..10
    double niceMul;
    if (norm <= 1) {
      niceMul = 1;
    } else if (norm <= 2) {
      niceMul = 2;
    } else if (norm <= 2.5) {
      niceMul = 2.5;
    } else if (norm <= 5) {
      niceMul = 5;
    } else {
      niceMul = 10;
    }
    return niceMul * mag;
  }

  List<double> _ema(List<double> values, int period) {
    if (values.length < period) return [];
    final k = 2 / (period + 1);
    final out = <double>[];
    double prev = values.take(period).reduce((a, b) => a + b) / period;
    out.add(prev);
    for (int i = period; i < values.length; i++) {
      prev = values[i] * k + prev * (1 - k);
      out.add(prev);
    }
    return out;
  }

  /// Balikin (min, max) dari MACD line + signal + histogram, buat nentuin skala axis.
  (double, double) _macdRange(List<CandleItem> raw) {
    final closes = raw.map((c) => (c.close ?? 0).toDouble()).toList();
    if (closes.length < 35) return (-1, 1); // data kurang, kasih default aman

    final ema12 = _ema(closes, 12);
    final ema26 = _ema(closes, 26);
    final offset =
        ema12.length - ema26.length; // ema12 lebih panjang, samain panjangnya
    final macdLine = <double>[];
    for (int i = 0; i < ema26.length; i++) {
      macdLine.add(ema12[i + offset] - ema26[i]);
    }
    final signal = _ema(macdLine, 9);
    final sigOffset = macdLine.length - signal.length;
    final hist = <double>[];
    for (int i = 0; i < signal.length; i++) {
      hist.add(macdLine[i + sigOffset] - signal[i]);
    }

    final all = [...macdLine, ...signal, ...hist];
    if (all.isEmpty) return (-1, 1);
    return (
      all.reduce((a, b) => a < b ? a : b),
      all.reduce((a, b) => a > b ? a : b),
    );
  }

  double? _lastRsi(List<CandleItem> raw, {int period = 14}) {
    final closes = raw.map((c) => (c.close ?? 0).toDouble()).toList();
    if (closes.length < period + 1) return null;

    double gain = 0, loss = 0;
    for (int i = 1; i <= period; i++) {
      final diff = closes[i] - closes[i - 1];
      if (diff > 0) {
        gain += diff;
      } else {
        loss -= diff;
      }
    }
    gain /= period;
    loss /= period;

    for (int i = period + 1; i < closes.length; i++) {
      final diff = closes[i] - closes[i - 1];
      if (diff > 0) {
        gain = (gain * (period - 1) + diff) / period;
        loss = (loss * (period - 1)) / period;
      } else {
        loss = (loss * (period - 1) - diff) / period;
        gain = (gain * (period - 1)) / period;
      }
    }

    if (loss == 0) return 100;
    final rs = gain / loss;
    return 100 - (100 / (1 + rs));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const upColor = Color(0xFF21C07A);
    final downColor = Colors.red.shade600;
    final gridColor = cs.outline.withOpacity(.15);
    final chartColor = widget.isUp ? upColor : downColor;

    DateTime _fixTime(DateTime dt) {
      final u = dt.toUtc();
      return DateTime(u.year, u.month, u.day, u.hour, u.minute);
    }

    // 1) Saring data yang valid
    List<CandleItem> raw = widget.candles
        .where(
          (c) =>
              c.open != null &&
              c.high != null &&
              c.low != null &&
              c.close != null,
        )
        .toList();

    if (raw.isEmpty) return const SizedBox(height: 220);

    // ==============================================================
    // 2) KUNCI X-AXIS BERDASARKAN RANGE TERPILIH
    // ==============================================================
    final range = widget.currentRange;
    // final isIntraday = (range == '1D' || range.endsWith('m') || range == '1H');
    final isIntraday = (range.endsWith('m') || range == '1H');

    DateTime xMin = _fixTime(raw.first.ts);
    DateTime xMax = _fixTime(raw.last.ts);
    DateTime? visibleMin;
    DateTime? visibleMax;

    if (!xMax.isAfter(xMin)) {
      xMax = xMin.add(const Duration(hours: 1));
    }

    visibleMax = xMax;

    if (isIntraday) {
      final latest = _fixTime(raw.last.ts);
      raw = raw.where((c) {
        final t = _fixTime(c.ts);
        return t.year == latest.year &&
            t.month == latest.month &&
            t.day == latest.day;
      }).toList();

      if (raw.isNotEmpty) {
        xMin = _fixTime(raw.first.ts);
        xMax = _fixTime(raw.last.ts);
        if (!xMax.isAfter(xMin)) xMax = xMin.add(const Duration(minutes: 5));

        visibleMin = null;
        visibleMax = null;

        // const framePoints = 40;
        // visibleMin = raw.length > framePoints
        //     ? _fixTime(raw[raw.length - framePoints].ts)
        //     : xMin;
        // visibleMax = xMax;
      }
    } else if (range == '1W') {
      // 👇 GANTI: frame awal nampilin 52 candle TERAKHIR
      // data yang di-fetch tetap penuh (~104 candle / 2 tahun), sisanya diakses lewat geser
      const framePoints = 52;
      visibleMin = raw.length > framePoints
          ? _fixTime(raw[raw.length - framePoints].ts)
          : xMin;
    } else if (range == '1M') {
      // 👇 GANTI: frame awal nampilin 12 candle TERAKHIR
      const framePoints = 12;
      visibleMin = raw.length > framePoints
          ? _fixTime(raw[raw.length - framePoints].ts)
          : xMin;
    } else {
      // Historical harian
      visibleMin = xMax.subtract(const Duration(days: 90));
    }

    if (visibleMin != null && visibleMin.isBefore(xMin)) {
      visibleMin = xMin;
    }

    // ==============================================================
    // 3) HITUNG INTERVAL & Y-AXIS
    // ==============================================================
    double rawMin = double.infinity, rawMax = -double.infinity;

    final (macdMin, macdMax) = widget.showMACD ? _macdRange(raw) : (0.0, 1.0);
    final double? lastRsiValue = widget.showRSI ? _lastRsi(raw) : null;

    double maxVol = 0;

    for (final d in raw) {
      if (d.low! < rawMin) rawMin = d.low!.toDouble();
      if (d.high! > rawMax) rawMax = d.high!.toDouble();
      if ((d.volume ?? 0) > maxVol) maxVol = (d.volume ?? 0).toDouble();
    }
    // double yInterval = 100.0;
    double yInterval = _niceInterval(rawMax - rawMin);

    double minY = (rawMin / yInterval).floor() * yInterval;
    double maxY = (rawMax / yInterval).ceil() * yInterval;

    if (maxY <= minY) maxY = minY + yInterval;

    if (widget.showVol || widget.showRSI || widget.showMACD) {
      final priceSpan = maxY - minY;
      minY = minY - (priceSpan * 0.45); // sisakan ruang kosong di bawah
    }

    _lastRaw = raw;
    _lastIsIntraday = isIntraday;

    final double? _visibleMinIndex = visibleMin != null
        ? raw
              .indexWhere((c) => !_fixTime(c.ts).isBefore(visibleMin!))
              .toDouble()
              .clamp(0, raw.length - 1)
        : null;
    final double _visibleMaxIndex = (raw.length - 1).toDouble();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cs.surface,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          widget.isCandle
                              ? Icons.show_chart
                              : Icons.candlestick_chart,
                          color: cs.onSurface.withOpacity(.6),
                          size: 20,
                        ),
                        onPressed: widget.onToggleChartType,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.open_in_full,
                          color: cs.onSurface.withOpacity(.6),
                          size: 18,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StockTradingViewPage(ticker: widget.ticker),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // === CHART UTAMA ===
                SizedBox(
                  // height: widget.showVol ? 280 : 200,
                  height: (widget.showVol || widget.showRSI || widget.showMACD)
                      ? 280
                      : 200,
                  child: SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    backgroundColor: Colors.transparent,
                    primaryXAxis: NumericAxis(
                      isVisible: false,
                      rangePadding: ChartRangePadding.none,
                      // minimum: isIntraday ? xMin : null,
                      // maximum: isIntraday ? xMax : null,
                      minimum: 0, // 👈 BARU: batas mutlak kiri
                      maximum: (raw.length - 1).toDouble(),
                      initialVisibleMinimum: _visibleMinIndex,
                      initialVisibleMaximum: _visibleMaxIndex,
                    ),
                    primaryYAxis: NumericAxis(
                      axisLabelFormatter: (AxisLabelRenderDetails details) {
                        // sembunyikan label di zona volume (area kosong bawah)
                        if ((widget.showVol ||
                                widget.showRSI ||
                                widget.showMACD) &&
                            details.value < rawMin) {
                          return ChartAxisLabel(
                            '',
                            const TextStyle(color: Colors.transparent),
                          );
                        }
                        return ChartAxisLabel(details.text, details.textStyle);
                      },
                      opposedPosition: true,
                      axisLine: const AxisLine(width: 0),
                      majorTickLines: const MajorTickLines(width: 0),
                      majorGridLines: MajorGridLines(
                        color: gridColor,
                        width: 1,
                      ),
                      labelStyle: const TextStyle(fontSize: 10),

                      // 👇 FIX: Lepas kuncian untuk Historical agar bisa Auto-Scale 👇
                      // rangePadding: isIntraday
                      //     ? ChartRangePadding.none
                      //     : ChartRangePadding.auto,
                      // minimum: isIntraday ? minY : null,
                      // maximum: isIntraday ? maxY : null,
                      // interval: yInterval,
                      rangePadding: ChartRangePadding
                          .none, // <- selalu none, bukan kondisional
                      minimum: minY, // <- selalu pakai minY
                      maximum: maxY, // <- selalu pakai maxY
                      interval: yInterval,
                      plotOffset: 0,
                    ),
                    axes: <ChartAxis>[
                      NumericAxis(
                        name: 'indi',
                        opposedPosition: true,
                        // isVisible: false,
                        isVisible: widget.showRSI,
                        labelPosition: ChartDataLabelPosition.inside,
                        // 👇 BARU: RSI (0-100 fix) didorong ke area bawah, proporsional kayak volume
                        minimum: widget.showRSI
                            ? 0
                            : widget.showMACD
                            ? macdMin - (macdMax - macdMin) * 0.1
                            : null,
                        maximum: widget.showRSI
                            ? 320
                            : widget.showMACD
                            ? macdMin +
                                  (macdMax - macdMin) *
                                      4 // 👈 kuncinya: stretch 4x biar data cuma "makan" 25% bawah
                            : null,
                        interval: widget.showRSI ? 20 : null,
                        labelStyle: const TextStyle(fontSize: 10),
                        axisLine: const AxisLine(width: 0),
                        majorTickLines: const MajorTickLines(width: 0),
                        majorGridLines: const MajorGridLines(
                          width: 0,
                        ), // 👈 BARU: matiin grid sendiri (biar gak dobel sama grid harga)
                        axisLabelFormatter: (AxisLabelRenderDetails details) {
                          // 👇 BARU: buat RSI, sembunyikan angka di atas 100 (itu cuma zona "padding" biar RSI kecil di layar)
                          if (widget.showRSI && details.value > 100) {
                            return ChartAxisLabel(
                              '',
                              const TextStyle(color: Colors.transparent),
                            );
                          }
                          if (widget.showMACD) {
                            return ChartAxisLabel(
                              details.value.toStringAsFixed(0),
                              details.textStyle,
                            );
                          }
                          return ChartAxisLabel(
                            details.text,
                            details.textStyle,
                          );
                        },
                        rangePadding: ChartRangePadding.none,
                        plotBands: widget.showRSI
                            ? <PlotBand>[
                                PlotBand(
                                  isVisible: true,
                                  start: 80,
                                  end: 100,
                                  color: downColor.withOpacity(
                                    0.08,
                                  ), // merah tipis, zona overbought
                                ),
                                PlotBand(
                                  isVisible: true,
                                  start: 0,
                                  end: 20,
                                  color: upColor.withOpacity(
                                    0.08,
                                  ), // hijau tipis, zona oversold
                                ),
                              ]
                            : <PlotBand>[],
                      ),
                      NumericAxis(
                        name: 'volAxis',
                        isVisible: false,
                        minimum: 0,
                        // dikali 4 supaya bar volume cuma "mengisi" ~25% tinggi bawah chart
                        maximum: maxVol > 0 ? maxVol * 3.2 : 1,
                        rangePadding: ChartRangePadding.none,
                      ),
                      NumericAxis(
                        name: 'volXAxis',
                        isVisible: false,
                        minimum: 0,
                        maximum: (raw.length - 1).toDouble(),
                        rangePadding: ChartRangePadding.none,
                        initialVisibleMinimum: _visibleMinIndex, // 👈 BARU
                        initialVisibleMaximum: _visibleMaxIndex,
                      ),
                    ],
                    trackballBehavior: _trackball,
                    zoomPanBehavior: _zoomPan,
                    series: <CartesianSeries<dynamic, num>>[
                      //VOLUME
                      if (widget.showVol)
                        ColumnSeries<CandleItem, num>(
                          name: 'volume',
                          dataSource: raw,
                          xValueMapper: (d, i) => i,
                          yValueMapper: (d, _) =>
                              (d.volume ?? 0).toDouble().abs(),
                          xAxisName: 'volXAxis',
                          yAxisName: 'volAxis',
                          width: 0.7,
                          spacing: 0,
                          enableTooltip: false,
                          pointColorMapper: (d, _) {
                            final cl = (d.close ?? 0), op = (d.open ?? cl);
                            return cl >= op
                                ? upColor.withOpacity(.35)
                                : downColor.withOpacity(.35);
                          },
                        ),
                      if (widget.isCandle)
                        CandleSeries<CandleItem, num>(
                          enableTooltip: true,
                          name: 'price',
                          dataSource: raw,
                          xValueMapper: (d, i) => i,
                          lowValueMapper: (d, _) => d.low,
                          highValueMapper: (d, _) => d.high,
                          openValueMapper: (d, _) => d.open,
                          closeValueMapper: (d, _) => d.close,
                          width: 0.7,
                          spacing: 0,
                          bullColor: upColor,
                          bearColor: downColor,
                          enableSolidCandles: true,
                          animationDuration: 450,
                        )
                      else
                        AreaSeries<CandleItem, num>(
                          enableTooltip: true,
                          name: 'price',
                          dataSource: raw,
                          xValueMapper: (d, i) => i,
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
                    indicators: <TechnicalIndicator<dynamic, num>>[
                      if (widget.showMA)
                        SmaIndicator<dynamic, num>(
                          seriesName: 'price',
                          period: 14,
                        ),
                      if (widget.showEMA)
                        EmaIndicator<dynamic, num>(
                          seriesName: 'price',
                          period: 14,
                        ),
                      if (widget.showBOLL)
                        BollingerBandIndicator<dynamic, num>(
                          seriesName: 'price',
                          period: 20,
                          standardDeviation: 2,
                          animationDuration: 450,
                        ),
                      if (widget.showRSI)
                        RsiIndicator<dynamic, num>(
                          seriesName: 'price',
                          period: 14,
                          yAxisName: 'indi',
                          overbought:
                              80, // 👈 BARU: eksplisit, garis atas (merah)
                          oversold:
                              20, // 👈 BARU: eksplisit, garis bawah (hijau)
                          showZones: true,
                        ),
                      if (widget.showMACD)
                        MacdIndicator<dynamic, num>(
                          seriesName: 'price',
                          shortPeriod: 12,
                          longPeriod: 26,
                          period: 9,
                          yAxisName: 'indi',
                        ),
                    ],
                    onTrackballPositionChanging: (args) {
                      final info = args.chartPointInfo;
                      debugPrint(
                        'TRACKBALL => seriesIndex=${info?.seriesIndex} '
                        'seriesName=${info?.series?.name} '
                        'dataPointIndex=${info?.dataPointIndex} '
                        'raw.length=${raw.length}',
                      );

                      if (info?.series?.name != 'price') return;

                      final i = info?.dataPointIndex;
                      if (i != null && i >= 0 && i < raw.length) {
                        debugPrint('  -> setState _selectedIndex = $i');
                        setState(() {
                          _selectedIndex = i;
                          // kalau candle di paruh KIRI data → box tampil di KANAN, dan sebaliknya
                          // _boxOnRight = i < (raw.length / 2);
                          final visMin = _visibleMinIndex ?? 0;
                          final mid = (visMin + _visibleMaxIndex) / 2;
                          _boxOnRight = i < mid;
                        });
                        _scheduleReset();
                      } else {
                        debugPrint('  -> SKIP (i out of range or null)');
                      }
                    },
                  ),
                ),

                // === CHART VOLUME DI BAWAH ===
              ],
            ),
          ),
          // 👇 BOX INFO OHLCV MANUAL (pengganti builder trackball)
          if (_selectedIndex != null &&
              _selectedIndex! >= 0 &&
              _selectedIndex! < _lastRaw.length)
            Positioned(
              top: 8,
              left: _boxOnRight ? null : 12,
              right: _boxOnRight ? 12 : null,
              child: IgnorePointer(
                child: Builder(
                  builder: (context) {
                    final cur = _lastRaw[_selectedIndex!];
                    final dateLabel = _lastIsIntraday
                        ? DateFormat(
                            'dd MMM yyyy, HH:mm',
                          ).format(cur.ts.toUtc())
                        : DateFormat('dd MMM yyyy').format(cur.ts.toUtc());

                    Widget row(String k, String v, {Color? color}) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
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
                            _fmtNum(cur.high),
                            color: const Color(0xFF21C07A),
                          ),
                          row(
                            'Low',
                            _fmtNum(cur.low),
                            color: Colors.red.shade300,
                          ),
                          row('Open', _fmtNum(cur.open)),
                          row('Close', _fmtNum(cur.close)),
                          row('Volume', _fmtVolume(cur.volume)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          if (widget.showRSI)
            const Positioned(
              left: 18,
              bottom: 100, // sesuaikan biar pas di pojok kiri-atas panel RSI
              child: IgnorePointer(
                child: Text(
                  'RSI (14)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),

          //for future
          // if (widget.showRSI && lastRsiValue != null)
          //   Positioned(
          //     right: 4,
          //     bottom: 20, // sesuaikan juga biar sejajar posisi ujung garis
          //     child: IgnorePointer(
          //       child: Container(
          //         padding: const EdgeInsets.symmetric(
          //           horizontal: 5,
          //           vertical: 2,
          //         ),
          //         decoration: BoxDecoration(
          //           color: Colors.blueAccent,
          //           borderRadius: BorderRadius.circular(4),
          //         ),
          //         child: Text(
          //           lastRsiValue.toStringAsFixed(1),
          //           style: const TextStyle(
          //             fontSize: 10,
          //             fontWeight: FontWeight.w700,
          //             color: Colors.white,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}

class _IndicatorBox extends StatelessWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelect;
  const _IndicatorBox({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(.25)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((e) {
          final on = selected == e;
          return _Pill(label: e, selected: on, onTap: () => onSelect(e));
        }).toList(),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  static const _minH = 32.0; // dari 36
  static const _minW = 62.0; // sedikit lebih sempit
  static const _iconW = 14.0;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(minWidth: _minW, minHeight: _minH),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? cs.primary.withOpacity(.30)
                : cs.outline.withOpacity(.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ruang ikon SELALU ada -> lebar stabil
            SizedBox(
              width: _iconW,
              child: Opacity(
                opacity: selected ? 1 : 0,
                child: Icon(Icons.check, size: _iconW, color: cs.primary),
              ),
            ),
            const SizedBox(width: 4), // spacer SELALU ada
            Text(
              label,
              style: t.labelMedium?.copyWith(
                // ganti dari labelLarge
                fontWeight: FontWeight.w700,
                color: selected ? cs.primary : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorToolbar extends StatelessWidget {
  final String? overlaySelected;
  final String? subSelected;
  final ValueChanged<String> onOverlaySelect;
  final ValueChanged<String> onSubSelect;

  const _IndicatorToolbar({
    required this.overlaySelected,
    required this.subSelected,
    required this.onOverlaySelect,
    required this.onSubSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(.25)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // kiri: overlay
            _Pill(
              label: 'MA',
              selected: overlaySelected == 'MA',
              onTap: () => onOverlaySelect('MA'),
            ),
            const SizedBox(width: 8),
            _Pill(
              label: 'EMA',
              selected: overlaySelected == 'EMA',
              onTap: () => onOverlaySelect('EMA'),
            ),
            const SizedBox(width: 8),
            _Pill(
              label: 'BOLL',
              selected: overlaySelected == 'BOLL',
              onTap: () => onOverlaySelect('BOLL'),
            ),

            const SizedBox(width: 12),
            const _VDivider(), // | pemisah
            const SizedBox(width: 12),

            // kanan: sub chart
            _Pill(
              label: 'VOL',
              selected: subSelected == 'VOL',
              onTap: () => onSubSelect('VOL'),
            ),
            const SizedBox(width: 8),
            _Pill(
              label: 'RSI',
              selected: subSelected == 'RSI',
              onTap: () => onSubSelect('RSI'),
            ),
            const SizedBox(width: 8),
            _Pill(
              label: 'MACD',
              selected: subSelected == 'MACD',
              onTap: () => onSubSelect('MACD'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  final double height;
  const _VDivider({super.key, this.height = 18});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.outline.withOpacity(.25);
    return SizedBox(
      height: height,
      child: Center(
        child: Container(width: 1, height: height, color: c),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final StockDetailProvider provider;
  final double? prevClose, open, high, low;

  const _SummaryTab({
    required this.provider,
    this.prevClose,
    this.open,
    this.high,
    this.low,
  });

  @override
  Widget build(BuildContext context) {
    // final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        /// === Existing candle summary ===
        _SummaryFromCandles(
          candles: provider.candles,
          prevClose: prevClose,
          fallbackOpen: open,
          fallbackHigh: high,
          fallbackLow: low,
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}
