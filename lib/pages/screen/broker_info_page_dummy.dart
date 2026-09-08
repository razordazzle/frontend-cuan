import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/data/model/broker_summary_row.dart';
import 'package:cuan_app/data/services/stocks_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BrokerInfoPage extends StatefulWidget {
  const BrokerInfoPage({super.key});

  @override
  State<BrokerInfoPage> createState() => _BrokerInfoPageState();
}

class _BrokerInfoPageState extends State<BrokerInfoPage> {
  late final String ticker;
  DateTime? _tradeDate;
  String _investor = 'all';
  Future<_BrokerPageData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    ticker = (args?['ticker'] as String?) ?? '';
    _future ??= _load();
  }

  Future<_BrokerPageData> _load() async {
    final svc = context.read<StocksService>();

    final effectiveDate = _tradeDate ?? DateTime.now();
    // 1) panggil service satu-satu, biar type aman
    final rows = await svc.fetchBrokerSummary(
      ticker,
      tradeDate: effectiveDate,
      investor: _investor, // 'all' | 'foreign' | 'local'
      limit: 300,
    );
    print('broker rows length = ${rows.length}'); // <<< cek di log

    final detailMap = await svc.detailRaw(ticker);

    final brokers = await svc.listBrokers(limit: 500);

    // 2) bangun map kode broker -> kategori
    final catMap = <String, String>{};
    for (final e in brokers) {
      final code = e['code'] as String?;
      final cat = e['category'] as String?;
      if (code != null && cat != null) {
        catMap[code.toUpperCase()] = cat;
      }
    }

    return _BrokerPageData(rows, detailMap, catMap);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  String _fmtNum(num? v) {
    if (v == null) return '-';
    return NumberFormat.compactCurrency(decimalDigits: 0, symbol: '').format(v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 3,
      initialIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const BackButtonIcon(),
            onPressed: () => Navigator.pop(context, 2),
          ),
          title: Text(
            ticker.isEmpty ? 'Informasi Broker' : 'Informasi Broker • $ticker',
          ),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Divider(height: 1, color: cs.outline.withOpacity(.12)),
          ),
        ),
        body: FutureBuilder<_BrokerPageData>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _TableSkeleton();
            }

            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Gagal memuat data broker',
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${snap.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              );
            }

            final data = snap.data!;
            final rows = data.rows;
            final detail = data.detail;
            final brokerCat = data.brokerCategory;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _StockHeader(
                      logoUrl: detail['logoUrl'] ?? detail['logo'] ?? '',
                      name: detail['name'] ?? detail['company_name'] ?? ticker,
                      ticker: ticker,
                      price: (detail['last'] ?? detail['last_price'] ?? 0)
                          .toDouble(),
                      change: detail['change'] ?? 0,
                      pct: detail['change_pct'] ?? detail['chg_pct'] ?? 0,
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedHeader(
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          border: Border(
                            bottom: BorderSide(
                              color: cs.outline.withOpacity(.15),
                            ),
                          ),
                        ),
                        child: TabBar(
                          onTap: (i) {
                            if (i == 0)
                              Navigator.pop(context, 0);
                            else if (i == 1) {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.keyStats,
                                arguments: {'ticker': ticker},
                              );
                            }
                          },
                          indicatorColor: cs.primary,
                          indicatorWeight: 2,
                          labelColor: cs.onSurface,
                          unselectedLabelColor: cs.onSurface.withOpacity(.6),
                          labelStyle: t.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          tabs: const [
                            Tab(text: 'Ringkasan'),
                            Tab(text: 'Key Statistics'),
                            Tab(text: 'Informasi Broker'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedHeader(
                      height: 60,
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  _pill(
                                    context,
                                    'Semua',
                                    'all',
                                    _investor == 'all',
                                    () {
                                      setState(() => _investor = 'all');
                                      _refresh();
                                    },
                                  ),
                                  _pill(
                                    context,
                                    'Asing',
                                    'foreign',
                                    _investor == 'foreign',
                                    () {
                                      setState(() => _investor = 'foreign');
                                      _refresh();
                                    },
                                  ),
                                  _pill(
                                    context,
                                    'Lokal',
                                    'local',
                                    _investor == 'local',
                                    () {
                                      setState(() => _investor = 'local');
                                      _refresh();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                _tradeDate == null
                                    ? 'Terbaru'
                                    : '${DateFormat('dd MMM yy').format(_tradeDate!)}'
                                          ' - '
                                          '${DateFormat('dd MMM yy').format(_tradeDate!)}',
                              ),
                              onPressed: () async {
                                final today = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _tradeDate ?? today,
                                  firstDate: DateTime(today.year - 5),
                                  lastDate: today,
                                );
                                if (picked != null) {
                                  setState(() => _tradeDate = picked);
                                  _refresh();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (rows.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('Tidak ada data', style: t.bodyMedium),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 76),
                        child: _BrokerSummaryTable(
                          rows: rows,
                          format: _fmtNum,
                          brokerCategory: brokerCat,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        // ====== TOMBOL MINIMIZE ======
        bottomNavigationBar: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Center(
              child: IconButton(
                // pakai expand_more (chevron ke bawah) sesuai contohmu
                icon: Icon(Icons.expand_more, color: cs.primary),
                tooltip: 'Minimize',
                onPressed: () => Navigator.pop(context, 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(
    BuildContext context,
    String label,
    String key,
    bool selected,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return ChoiceChip(
      label: Text(
        label,
        style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? cs.outline : cs.outline.withOpacity(.35),
        ),
      ),
      backgroundColor: Colors.transparent,
      selectedColor: cs.surfaceVariant.withOpacity(.25),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }
}

class _BrokerPageData {
  final List<BrokerSummaryRow> rows;
  final Map<String, dynamic> detail;
  final Map<String, String> brokerCategory;
  _BrokerPageData(this.rows, this.detail, this.brokerCategory);
}

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _PinnedHeader({required this.height, required this.child});
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(covariant _PinnedHeader oldDelegate) => false;
}

class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      itemCount: 10,
      itemBuilder: (_, i) => Container(
        height: 56,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _StockHeader extends StatelessWidget {
  final String logoUrl;
  final String name;
  final String ticker;
  final double? price;
  final num? change;
  final num? pct;
  const _StockHeader({
    required this.logoUrl,
    required this.name,
    required this.ticker,
    this.price,
    this.change,
    this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isUp = (change ?? 0) >= 0;

    Widget _avatarChild() {
      if (logoUrl.isEmpty) {
        return Text(ticker.substring(0, 2).toUpperCase());
      }
      return ClipOval(
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          width: 36,
          height: 36,
          errorBuilder: (_, __, ___) {
            // fallback kalau 404 / gagal load
            return Container(
              color: cs.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Text(
                ticker.substring(0, 2).toUpperCase(),
                style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.surfaceContainerHighest,
            // backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
            // child: _avatarChild(),
            child: logoUrl.isEmpty
                ? Text(
                    ticker.substring(0, 2).toUpperCase(),
                    style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  )
                : ClipOval(
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: cs.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Text(
                            ticker.substring(0, 2).toUpperCase(),
                            style: t.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticker,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  name,
                  style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${NumberFormat('#,###').format(price ?? 0)}',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '${isUp ? '▲' : '▼'} ${NumberFormat('#,###').format(change ?? 0)} (${pct?.toStringAsFixed(2)}%)',
                style: t.labelMedium?.copyWith(
                  color: isUp ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _localColor = Color(0xFFFFC107);
const _foreignColor = Color(0xFFD32F2F);
const _bumnColor = Color(0xFF00BCD4);

class _BrokerSummaryTable extends StatelessWidget {
  final List<BrokerSummaryRow> rows;
  final String Function(num?) format;
  final Map<String, String> brokerCategory;
  const _BrokerSummaryTable({
    super.key,
    required this.rows,
    required this.format,
    required this.brokerCategory,
  });

  Color _buyerColor(String code, ColorScheme cs) {
    final cat = brokerCategory[code.toUpperCase()];
    switch (cat) {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    const wCode = 48.0;
    const wNum = 72.0;
    const pad = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    final headStyle = t.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    final buyerNumStyle = t.bodyMedium?.copyWith(
      color: Colors.greenAccent,
      fontWeight: FontWeight.w700,
    );
    final sellerStyle = t.bodyMedium?.copyWith(
      color: Colors.redAccent,
      fontWeight: FontWeight.w700,
    );

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Scrollbar(
        thumbVisibility: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: wCode,
                        child: Text('Buyer', style: headStyle),
                      ),
                      SizedBox(
                        width: wNum,
                        child: Center(child: Text('B.Val', style: headStyle)),
                      ),
                      SizedBox(
                        width: wNum,
                        child: Center(child: Text('B.Lot', style: headStyle)),
                      ),
                      SizedBox(
                        width: wNum,
                        child: Center(child: Text('B.Avg', style: headStyle)),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: wCode,
                        child: Center(child: Text('Seller', style: headStyle)),
                      ),
                      SizedBox(
                        width: wNum,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('S.Val', style: headStyle),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: cs.outline.withOpacity(.12)),
                for (int i = 0; i < rows.length; i++) ...[
                  Container(
                    color: i.isEven
                        ? cs.surface
                        : cs.surfaceVariant.withOpacity(.06),
                    padding: pad,
                    child: Row(
                      children: [
                        SizedBox(
                          width: wCode,
                          child: Text(
                            rows[i].buyerCode,
                            style: t.bodyMedium?.copyWith(
                              color: _buyerColor(rows[i].buyerCode, cs),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: wNum,
                          child: Center(
                            child: Text(
                              format(rows[i].bVal),
                              style: buyerNumStyle,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: wNum,
                          child: Center(
                            child: Text(
                              format(rows[i].bLot),
                              style: buyerNumStyle,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: wNum,
                          child: Center(
                            child: Text(
                              format(rows[i].bAvg),
                              style: buyerNumStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: wCode,
                          child: Center(
                            child: Text(rows[i].sellerCode, style: sellerStyle),
                          ),
                        ),
                        SizedBox(
                          width: wNum,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              format(rows[i].sVal),
                              style: sellerStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != rows.length - 1)
                    Divider(height: 1, color: cs.outline.withOpacity(.06)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
