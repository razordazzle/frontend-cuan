// import 'package:cuan_app/config/app_routes.dart';
// import 'package:cuan_app/providers/stock_detail_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';

// class KeyStatisticsPage extends StatefulWidget {
//   const KeyStatisticsPage({super.key, required this.ticker});
//   final String ticker;

//   @override
//   State<KeyStatisticsPage> createState() => _KeyStatisticsPageState();
// }

// class _KeyStatisticsPageState extends State<KeyStatisticsPage> {
//   // ---------- kecil-kecil helper ----------
//   String _n(num? v, {int decimals = 0}) {
//     if (v == null) return '-';
//     final f = NumberFormat.decimalPattern();
//     return (decimals == 0)
//         ? f.format(v)
//         : NumberFormat.decimalPattern().format(
//             num.parse(v.toStringAsFixed(decimals)),
//           );
//   }

//   String _p(num? v) => v == null ? '-' : '${v.toStringAsFixed(2)}%';

//   // String _d(DateTime? d) =>
//   String _d(dynamic v) {
//     if (v == null) return '-';
//     DateTime? dt;
//     if (v is DateTime) {
//       dt = v;
//     } else if (v is String) {
//       dt = DateTime.tryParse(v); // works for 'YYYY-MM-DD' / ISO8601
//     }
//     if (dt == null) return v.toString(); // fallback tampilkan apa adanya
//     return DateFormat('dd MMM yyyy').format(dt);
//   }

//   TableRow _head(BuildContext context, List<String> cells) {
//     final cs = Theme.of(context).colorScheme;
//     final t = Theme.of(context).textTheme;
//     return TableRow(
//       decoration: BoxDecoration(color: cs.surfaceVariant.withOpacity(.25)),
//       children: [
//         for (final e in cells)
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 10),
//             child: Center(
//               child: Text(
//                 e,
//                 style: t.labelMedium?.copyWith(
//                   fontWeight: FontWeight.w700,
//                   color: cs.onSurface.withOpacity(.85),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   TableRow _row(BuildContext context, List<String> cells) {
//     final cs = Theme.of(context).colorScheme;
//     final t = Theme.of(context).textTheme;
//     return TableRow(
//       decoration: BoxDecoration(
//         border: Border(bottom: BorderSide(color: cs.outline.withOpacity(.12))),
//       ),
//       children: [
//         for (final e in cells)
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 10),
//             child: Center(
//               child: Text(
//                 e,
//                 style: t.bodyMedium?.copyWith(
//                   color: cs.onSurface.withOpacity(.85),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _sectionTitle(BuildContext context, String s) {
//     final cs = Theme.of(context).colorScheme;
//     final t = Theme.of(context).textTheme;
//     return Padding(
//       padding: const EdgeInsets.only(top: 16, bottom: 8),
//       child: Text(
//         s,
//         style: t.titleMedium?.copyWith(
//           fontWeight: FontWeight.w800,
//           color: cs.onSurface,
//         ),
//       ),
//     );
//   }

//   Widget _kvBox(BuildContext context, List<List<String>> kv) {
//     final cs = Theme.of(context).colorScheme;
//     final t = Theme.of(context).textTheme;
//     return Card(
//       elevation: 0,
//       color: cs.surface,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         children: kv
//             .map(
//               (e) => Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 14,
//                   vertical: 10,
//                 ),
//                 decoration: BoxDecoration(
//                   border: Border(
//                     bottom: BorderSide(color: cs.outline.withOpacity(.08)),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(child: Text(e.first, style: t.bodyMedium)),
//                     Text(
//                       e.last,
//                       style: t.bodyMedium?.copyWith(
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             )
//             .toList(),
//       ),
//     );
//   }

//   num? _m(Map? m, String k) {
//     if (m == null) return null;
//     final v = m[k];
//     if (v is num) return v;
//     if (v is String) return num.tryParse(v);
//     return null;
//   }

//   num? _mx(Map? m, List<String> keys) {
//     if (m == null) return null;
//     for (final k in keys) {
//       final v = m[k];
//       if (v is num) return v;
//       if (v is String) {
//         final n = num.tryParse(v);
//         if (n != null) return n;
//       }
//     }
//     return null;
//   }

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<StockDetailProvider>().loadAll(widget.ticker);
//     });
//   }

//   String _pSmart(num? v) {
//     if (v == null) return '-';
//     final vv = (v >= 0 && v <= 1) ? v * 100 : v;
//     return '${vv.toStringAsFixed(2)}%';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final p = context.watch<StockDetailProvider>();

//     final latest = p.latest; // Per, Pbv, Roe, Der, eps_ttm
//     final divs = p.dividends; // List<DividendItem>
//     final ratios = p.ratios; // List<RatioItem> (Q/Y)

//     // final y = p.yahoo;
//     return DefaultTabController(
//       length: 3,
//       initialIndex: 1, // Key Statistics aktif
//       child: Scaffold(
//         appBar: AppBar(
//           leading: const BackButton(),
//           title: Text(widget.ticker.isEmpty ? 'Key Statistics' : widget.ticker),
//           centerTitle: false,
//           bottom: PreferredSize(
//             preferredSize: const Size.fromHeight(44),
//             child: Container(
//               alignment: Alignment.centerLeft,
//               decoration: BoxDecoration(
//                 border: Border(
//                   bottom: BorderSide(color: cs.outline.withOpacity(.15)),
//                 ),
//               ),
//               child: TabBar(
//                 onTap: (i) {
//                   if (i == 0) Navigator.pop(context, 0); // Ringkasan
//                   if (i == 2) {
//                     Navigator.pushNamed(
//                       context,
//                       AppRoutes.brokerInfo,
//                       arguments: {'ticker': widget.ticker},
//                     );
//                   }
//                 },
//                 indicatorColor: cs.primary,
//                 indicatorWeight: 2,
//                 labelColor: cs.onSurface,
//                 unselectedLabelColor: cs.onSurface.withOpacity(.6),
//                 tabs: const [
//                   Tab(text: 'Ringkasan'),
//                   Tab(text: 'Key Statistics'),
//                   Tab(text: 'Informasi Broker'),
//                 ],
//               ),
//             ),
//           ),
//         ),

//         body: p.loading && latest == null
//             ? const Center(child: CircularProgressIndicator())
//             : RefreshIndicator(
//                 onRefresh: () => p.loadAll(widget.ticker),
//                 child: ListView(
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   padding: EdgeInsets.fromLTRB(
//                     16,
//                     12,
//                     16,
//                     16 + MediaQuery.of(context).padding.bottom,
//                   ),
//                   children: [
//                     // ===== SUMMARY (dari /key-stats latest) =====
//                     _sectionTitle(context, 'Overview'),
//                     _kvBox(context, [
//                       ['EPS (TTM)', _n(latest?.epsTtm, decimals: 2)],
//                       ['PER', _n(latest?.per, decimals: 2)],
//                       ['PBVR', _n(latest?.pbv, decimals: 2)],
//                       ['ROE', _p(latest?.roe)],
//                       ['DER', _n(latest?.der, decimals: 2)],
//                     ]),

//                     // ===== RATIOS HISTORY (kalau ada) =====
//                     if (ratios.isNotEmpty) ...[
//                       _sectionTitle(context, 'Ratios (History)'),
//                       Card(
//                         elevation: 0,
//                         color: cs.surface,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Table(
//                           columnWidths: const {0: FlexColumnWidth(1.4)},
//                           defaultVerticalAlignment:
//                               TableCellVerticalAlignment.middle,
//                           children: [
//                             _head(context, [
//                               'Period End',
//                               'PER',
//                               'PBVR',
//                               'ROE',
//                               'DER',
//                             ]),
//                             for (final r in ratios)
//                               _row(context, [
//                                 _d(r.periodEnd),
//                                 _n(r.per, decimals: 2),
//                                 _n(r.pbvr, decimals: 2),
//                                 _p(r.roe),
//                                 _n(r.der, decimals: 2),
//                               ]),
//                           ],
//                         ),
//                       ),
//                     ],

//                     // ===== DIVIDENDS =====
//                     _sectionTitle(context, 'Dividends (last years)'),
//                     Card(
//                       elevation: 0,
//                       color: cs.surface,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Table(
//                         columnWidths: const {
//                           0: FlexColumnWidth(1),
//                           1: FlexColumnWidth(1),
//                           2: FlexColumnWidth(1),
//                           3: FlexColumnWidth(1),
//                         },
//                         children: [
//                           _head(context, [
//                             'Year',
//                             'IDR',
//                             'Ex Date',
//                             'Pay Date',
//                           ]),
//                           if (divs.isEmpty)
//                             _row(context, ['-', '-', '-', '-'])
//                           else
//                             for (final d in divs.take(6))
//                               _row(context, [
//                                 d.year?.toString() ?? '-',
//                                 _n(d.amountIdr, decimals: 0),
//                                 _d(d.exDate),
//                                 _d(d.payDate),
//                               ]),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 12),
//                     Text(
//                       'Basis data: EPS TTM & Latest Ratios',
//                       style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                         color: cs.onSurface.withOpacity(.7),
//                       ),
//                     ),

//                     // ===== PLACEHOLDERS (menunggu API) =====
//                     if (p.loadingYahoo) ...[
//                       const SizedBox(height: 12),
//                       const Center(child: CircularProgressIndicator()),
//                     ],
//                     if (!p.loadingYahoo && p.errYahoo != null) ...[
//                       const SizedBox(height: 8),
//                       Text(
//                         p.errYahoo!,
//                         style: Theme.of(
//                           context,
//                         ).textTheme.bodySmall?.copyWith(color: cs.error),
//                       ),
//                     ],
//                     _sectionTitle(context, 'Fundamental'),
//                     _kvBox(context, [
//                       ['Most Recent Quarter', y?.mostRecentQuarter ?? '-'],
//                       ['Market Cap', _n(_m(y?.fundamental, 'marketCap'))],
//                       [
//                         'Shares Outstanding',
//                         _n(_m(y?.fundamental, 'sharesOutstanding')),
//                       ],
//                       ['Revenue (latest)', _n(_m(y?.earnings, 'totalRevenue'))],
//                       ['Net Income (latest)', _n(_m(y?.earnings, 'netIncome'))],
//                       [
//                         'Operating Margin',
//                         _pSmart(_m(y?.profitability, 'operatingMargins')),
//                       ],
//                       [
//                         'Profit Margin',
//                         _pSmart(_m(y?.profitability, 'profitMargins')),
//                       ],
//                       ['ROE', _pSmart(_m(y?.profitability, 'returnOnEquity'))],
//                       [
//                         'Current Ratio',
//                         _n(_m(y?.liquidity, 'currentRatio'), decimals: 2),
//                       ],
//                       [
//                         'Quick Ratio',
//                         _n(_m(y?.liquidity, 'quickRatio'), decimals: 2),
//                       ],
//                       ['Ex Dividend Date', _d(y?.dividend['exDividendDate'])],
//                     ]),
//                     _sectionTitle(context, 'Earnings'),
//                     _kvBox(context, [
//                       [
//                         'Dividend Per Share (DPS)',
//                         _n(_m(y?.dividend, 'dividendRate'), decimals: 2),
//                       ],
//                       [
//                         'Earning Per Share (EPS)',
//                         _n(_m(y?.eps, 'trailingEps'), decimals: 2),
//                       ],
//                       [
//                         'Revenue Per Share (RPS)',
//                         _n(
//                           _mx(y?.valuation, ['revenuePerShare', 'revPerShare']),
//                           decimals: 2,
//                         ),
//                       ],
//                       [
//                         'Book Value Per Share (BVPS)',
//                         _n(
//                           _mx(y?.valuation, ['bookValue', 'bookValuePerShare']),
//                           decimals: 2,
//                         ),
//                       ],
//                       [
//                         'Cash Flow Per Share (CFPS)',
//                         _n(
//                           _mx(y?.valuation, [
//                             'cashFlowPerShare',
//                             'operatingCashFlowPerShare',
//                           ]),
//                           decimals: 2,
//                         ),
//                       ],
//                       [
//                         'Cash Equiv Per Share (CEPS)',
//                         _n(
//                           _mx(y?.liquidity, ['totalCashPerShare']),
//                           decimals: 2,
//                         ),
//                       ],
//                       [
//                         'Net Asset Per Share (NAVPS)',
//                         _n(
//                           _mx(y?.valuation, [
//                             'navPerShare',
//                             'netAssetValuePerShare',
//                           ]),
//                           decimals: 2,
//                         ),
//                       ],
//                     ]),

//                     _sectionTitle(context, 'Valuation'),
//                     _kvBox(context, [
//                       [
//                         'Dividend Yield',
//                         _pSmart(_m(y?.dividend, 'dividendYield')),
//                       ],
//                       [
//                         'Price Earning Ratio (PER)',
//                         _n(
//                           _mx(y?.valuation, ['trailingPE', 'peRatio']),
//                           decimals: 2,
//                         ),
//                       ],
//                       [
//                         'Price Sales Ratio (PSR)',
//                         _n(
//                           _mx(y?.valuation, [
//                             'priceToSalesTrailing12Months',
//                             'psRatio',
//                           ]),
//                           decimals: 2,
//                         ),
//                       ],
//                       [
//                         'Price Book Value Ratio (PBVR)',
//                         _n(
//                           _mx(y?.valuation, ['priceToBook', 'pbRatio']),
//                           decimals: 2,
//                         ),
//                       ],
//                       [
//                         'Price Cash Flow Ratio (PCFR)',
//                         _n(
//                           _mx(y?.valuation, ['priceToCashflow', 'pcfRatio']),
//                           decimals: 2,
//                         ),
//                       ],
//                     ]),

//                     _sectionTitle(context, 'Profitability'),
//                     _kvBox(context, [
//                       [
//                         'Dividend Payout Ratio (DPR)',
//                         _pSmart(_m(y?.dividend, 'payoutRatio')),
//                       ],
//                       [
//                         'Gross Profit Margin (GPM)',
//                         _pSmart(
//                           _mx(y?.profitability, [
//                             'grossMargins',
//                             'grossMargin',
//                           ]),
//                         ),
//                       ],
//                       [
//                         'Operating Profit Margin (OPM)',
//                         _pSmart(
//                           _mx(y?.profitability, [
//                             'operatingMargins',
//                             'operatingMargin',
//                           ]),
//                         ),
//                       ],
//                       [
//                         'Net Profit Margin (NPM)',
//                         _pSmart(
//                           _mx(y?.profitability, ['profitMargins', 'netMargin']),
//                         ),
//                       ],
//                       [
//                         'EBIT Margin (EBITM)',
//                         _pSmart(
//                           _mx(y?.profitability, ['ebitMargins', 'ebitMargin']),
//                         ),
//                       ],
//                       [
//                         'Return On Equity (ROE)',
//                         _pSmart(
//                           _mx(y?.profitability, ['returnOnEquity', 'roe']),
//                         ),
//                       ],
//                       [
//                         'Return On Assets (ROA)',
//                         _pSmart(
//                           _mx(y?.profitability, ['returnOnAssets', 'roa']),
//                         ),
//                       ],
//                     ]),

//                     _sectionTitle(context, 'Liquidity'),
//                     _kvBox(context, [
//                       [
//                         'Debt Equity Ratio (DER)',
//                         _n(
//                           _mx(y?.liquidity, ['debtToEquity', 'deRatio']),
//                           decimals: 2,
//                         ),
//                       ],
//                       [
//                         'Cash Ratio (CR)',
//                         _n(_mx(y?.liquidity, ['cashRatio']), decimals: 2),
//                       ],
//                       [
//                         'Quick Ratio (QR)',
//                         _n(_mx(y?.liquidity, ['quickRatio']), decimals: 2),
//                       ],
//                       [
//                         'Current Ratio (CRR)',
//                         _n(_mx(y?.liquidity, ['currentRatio']), decimals: 2),
//                       ],
//                     ]),
//                     _sectionTitle(context, 'Per-Share Metrics'),
//                     _kvBox(context, [
//                       [
//                         'Dividend Per Share (DPS)',
//                         _n(_m(y?.dividend, 'dividendRate'), decimals: 2),
//                       ],
//                       [
//                         'Earning Per Share (EPS)',
//                         _n(p.latest?.epsTtm, decimals: 2),
//                       ],
//                       [
//                         'Book Value Per Share (BVPS)',
//                         _n(
//                           _mx(y?.valuation, ['bookValue', 'bookValuePerShare']),
//                           decimals: 2,
//                         ),
//                       ],
//                       [
//                         'Revenue Per Share (RPS)',
//                         _n(
//                           _mx(y?.valuation, ['revenuePerShare', 'revPerShare']),
//                           decimals: 2,
//                         ),
//                       ],
//                     ]),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }
// }
