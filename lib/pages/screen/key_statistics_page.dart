import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/providers/stock_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class KeyStatisticsPage extends StatefulWidget {
  const KeyStatisticsPage({super.key, required this.ticker});
  final String ticker;

  @override
  State<KeyStatisticsPage> createState() => _KeyStatisticsPageState();
}

class _KeyStatisticsPageState extends State<KeyStatisticsPage> {
  // ---------- kecil-kecil helper ----------
  String _n(num? v, {int decimals = 0}) {
    if (v == null) return '-';

    // Gunakan formatter currency dengan symbol kosong.
    // Ini secara paksa dan ketat akan menampilkan angka di belakang koma
    // sesuai jumlah 'decimals' yang kita minta!
    return NumberFormat.currency(
      symbol: '',
      decimalDigits: decimals,
    ).format(v).trim();
  }

  String _p(num? v) => v == null ? '-' : '${v.toStringAsFixed(2)}%';

  // Helper untuk menghitung nilai Standalone (Q saat ini dikurangi Q sebelumnya)
  num? _calcStandalone(dynamic current, dynamic prev) {
    if (current == null) return null;
    if (prev == null)
      return current
          as num; // Kalau Q sebelumnya bolong, tampilkan angka aslinya saja
    return (current as num) - (prev as num);
  }

  String _d(dynamic v) {
    if (v == null) return '-';
    DateTime? dt;
    if (v is DateTime) {
      dt = v;
    } else if (v is String) {
      dt = DateTime.tryParse(v); // works for 'YYYY-MM-DD' / ISO8601
    }
    if (dt == null) return v.toString(); // fallback tampilkan apa adanya
    return DateFormat('dd MMM yyyy').format(dt);
  }

  TableRow _head(BuildContext context, List<String> cells) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return TableRow(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.5),
      ),
      children: [
        for (int i = 0; i < cells.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Align(
              alignment: i == 0 ? Alignment.centerLeft : Alignment.center,
              child: Text(
                cells[i],
                textAlign: i == 0 ? TextAlign.left : TextAlign.center,
                style: t.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(.85),
                ),
              ),
            ),
          ),
      ],
    );
  }

  TableRow _row(
    BuildContext context,
    List<String> cells, {
    bool isBold = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outline.withOpacity(.08))),
      ),
      children: [
        for (int i = 0; i < cells.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Align(
              alignment: i == 0 ? Alignment.centerLeft : Alignment.center,
              child: Text(
                cells[i],
                textAlign: i == 0 ? TextAlign.left : TextAlign.center,
                style: t.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(.85),
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String s) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        s,
        style: t.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _kvBox(BuildContext context, List<List<String>> kv) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: kv.asMap().entries.map((entry) {
          final isLast = entry.key == kv.length - 1;
          final e = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(color: cs.outline.withOpacity(.08)),
                    ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.first,
                    style: t.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                Text(
                  e.last,
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  double? _safeChangePct(double? last, double? prev) {
    if (last == null || prev == null || prev == 0) return null;
    return (last - prev) / prev * 100.0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockDetailProvider>().loadAll(widget.ticker);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = context.watch<StockDetailProvider>();

    final latest = p.latest; // Per, Pbv, Roe, Der, eps_ttm
    final divs = p.dividends; // List<DividendItem>
    // final ratios = p.ratios; // List<RatioItem> (Bisa dipake nanti buat tabel EPS/Ratios)

    return DefaultTabController(
      length: 3,
      initialIndex: 1, // Key Statistics aktif
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const BackButtonIcon(),
            onPressed: () =>
                Navigator.pop(context, 0), // Kembalikan nilai 0 (Tab Ringkasan)
          ),
          title: Text(widget.ticker.isEmpty ? 'Key Statistics' : widget.ticker),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: cs.outline.withOpacity(.15)),
                ),
              ),
              child: TabBar(
                onTap: (i) {
                  if (i == 0) Navigator.pop(context, 0); // Ringkasan
                  if (i == 2) {
                    final d = p.detail;
                    final last = p.liveLast ?? d?.lastPrice;
                    final prev = d?.prevClose;
                    final chg =
                        p.liveChangePoint ?? ((last ?? 0) - (prev ?? 0));
                    final pct = p.liveChangePct ?? _safeChangePct(last, prev);

                    Navigator.pushNamed(
                      context,
                      AppRoutes.brokerInfo,
                      arguments: {
                        'ticker': widget.ticker,
                        'companyName': d?.companyName ?? '',
                        'logoUrl':
                            d?.logoUrl ??
                            '', // 👈 cek nama field asli di StockDetail model kamu
                        'price': last,
                        'change': chg,
                        'changePct': pct,
                      },
                    );
                  }
                },
                indicatorColor: cs.primary,
                indicatorWeight: 2,
                labelColor: cs.onSurface,
                unselectedLabelColor: cs.onSurface.withOpacity(.6),
                tabs: const [
                  Tab(text: 'Ringkasan'),
                  Tab(text: 'Key Statistics'),
                  Tab(text: 'Informasi Broker'),
                ],
              ),
            ),
          ),
        ),
        body: p.loading && latest == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => p.loadAll(widget.ticker),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  children: [
                    // ===== EARNINGS PER SHARE (Tabel Kompleks) =====
                    _sectionTitle(context, 'Earnings Per Share'),
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: cs.surfaceContainerLowest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: cs.outline.withOpacity(0.1)),
                      ),
                      child: Builder(
                        builder: (context) {
                          // Pastikan data matrix ada (biasanya 4 tahun)
                          // final m = p.earningsMatrix;
                          // if (m.isEmpty) {
                          //   return const Padding(
                          //     padding: EdgeInsets.all(16.0),
                          //     child: Center(child: Text("Data belum tersedia")),
                          //   );
                          // }
                          final rawMatrix = p.earningsMatrix;
                          if (rawMatrix.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: Text("Data belum tersedia")),
                            );
                          }

                          // FIX: Dibalik (reversed) agar tahun terbaru ada di kiri!
                          final m = rawMatrix.reversed.toList();

                          // Ambil daftar tahun dari data (contoh: 2022, 2023, 2024, 2025)
                          final years = m
                              .map((e) => e['year'].toString())
                              .toList();

                          // Bikin lebar kolom dinamis:
                          // Kolom pertama (Period) lebarnya 90, sisanya (Tahun) lebarnya 75
                          Map<int, TableColumnWidth> colWidths = {
                            0: const FixedColumnWidth(90),
                          };
                          for (int i = 0; i < years.length; i++) {
                            colWidths[i + 1] = const FixedColumnWidth(75);
                          }

                          // Bungkus dengan ScrollView Horizontal
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Table(
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              columnWidths: colWidths,
                              children: [
                                _head(context, [
                                  'Period',
                                  ...years.map((y) => '$y\n(Rp)'),
                                ]),
                                _row(context, [
                                  'Q1 (Mar)',
                                  ...m.map((e) => _n(e['q1'], decimals: 2)),
                                ]),
                                _row(context, [
                                  'Q2 (Jun)',
                                  ...m.map(
                                    (e) => _n(
                                      _calcStandalone(e['q2'], e['q1']),
                                      decimals: 2,
                                    ),
                                  ),
                                ]),
                                _row(context, [
                                  'Q3 (Sep)',
                                  ...m.map(
                                    (e) => _n(
                                      _calcStandalone(e['q3'], e['q2']),
                                      decimals: 2,
                                    ),
                                  ),
                                ]),
                                _row(context, [
                                  'Q4 (Dec)',
                                  // Jika e['q4'] null, otomatis pakai e['fy']. Jika masih null, pakai e['full_year']
                                  ...m.map(
                                    (e) => _n(
                                      _calcStandalone(
                                        e['q4'] ?? e['eps'] ?? e['fy'],
                                        e['q3'],
                                      ),
                                      decimals: 2,
                                    ),
                                  ),
                                ]),
                                _row(context, [
                                  'EPS (Annual)',
                                  ...m.map((e) => _n(e['eps'], decimals: 2)),
                                ], isBold: true),
                                _row(context, [
                                  'DPS',
                                  ...m.map((e) => _n(e['dps'])),
                                ], isBold: true),
                                _row(context, [
                                  'DPR',
                                  ...m.map((e) => _p(e['dpr'])),
                                ], isBold: true),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // ===== DIVIDEND =====
                    _sectionTitle(context, 'Dividend'),
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: cs.surfaceContainerLowest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: cs.outline.withOpacity(0.1)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(1.2),
                            3: FlexColumnWidth(1.2),
                          },
                          children: [
                            _head(context, [
                              'Year',
                              'IDR',
                              'Ex Date',
                              'Pay Date',
                            ]),
                            if (divs.isEmpty)
                              _row(context, ['-', '-', '-', '-'])
                            else
                              for (final d in divs.take(6))
                                _row(context, [
                                  d.year?.toString() ?? '-',
                                  _n(d.amountIdr, decimals: 0),
                                  _d(d.exDate),
                                  _d(d.payDate),
                                ]),
                          ],
                        ),
                      ),
                    ),

                    // ===== MOST RECENT QUARTER =====
                    _sectionTitle(
                      context,
                      'Most Recent Quarter : 31 May 2025',
                    ), // Update manual atau via API nanti
                    _kvBox(context, [
                      ['Financial Year End', latest?.financialYearEnd ?? '-'],
                      ['Issued Shares', _n(latest?.issuedShares)],
                    ]),

                    // ===== FUNDAMENTAL =====
                    _sectionTitle(context, 'Fundamental'),
                    _kvBox(context, [
                      ['Sales', _n(latest?.sales)],
                      ['Assets', _n(latest?.assets)],
                      ['Liability', _n(latest?.liability)],
                      ['Equity', _n(latest?.equity)],
                      ['Operating Cash Flow', _n(latest?.operatingCashFlow)],
                      ['Net Cash Flow', _n(latest?.netCashFlow)],
                      ['Cap.Ex', _n(latest?.capEx)],
                      ['Op.Exp', _n(latest?.opExp)],
                      ['Operating Profit', _n(latest?.operatingProfit)],
                      ['Net Profit', _n(latest?.netProfit)],
                    ]),

                    // ===== EARNINGS =====
                    _sectionTitle(context, 'Earnings'),
                    _kvBox(context, [
                      ['Dividend Per Share (DPS)', _n(latest?.dps)],
                      [
                        'Earning Per Share (EPS)',
                        _n(latest?.epsTtm, decimals: 2),
                      ],
                      ['Revenue Per Share (RPS)', _n(latest?.rps, decimals: 2)],
                      [
                        'Book Value Per Share (BVPS)',
                        _n(latest?.bvps, decimals: 2),
                      ],
                    ]),

                    // ===== VALUATION =====
                    _sectionTitle(context, 'Valuation'),
                    _kvBox(context, [
                      ['Dividend Yield', _p(latest?.dividendYield)],
                      [
                        'Price Earning Ratio (PER)',
                        _n(latest?.per, decimals: 2),
                      ],
                      ['Price Sales Ratio (PSR)', _n(latest?.psr, decimals: 2)],
                      [
                        'Price Book Value Ratio (PBVR)',
                        _n(latest?.pbv, decimals: 2),
                      ],
                      [
                        'Price Cash Flow Ratio (PCFR)',
                        _n(latest?.pcfr, decimals: 2),
                      ],
                    ]),

                    // ===== PROFITABILITY =====
                    _sectionTitle(context, 'Profitability'),
                    _kvBox(context, [
                      ['Dividend Payout Ratio (DPR)', _p(latest?.dpr)],
                      ['Gross Profit Margin (GPM)', _p(latest?.gpm)],
                      ['Operating Profit Margin (OPM)', _p(latest?.opm)],
                      ['Net Profit Margin (NPM)', _p(latest?.npm)],
                      ['EBITM', _p(latest?.ebitm)],
                      ['Return On Equity (ROE)', _p(latest?.roe)],
                      ['Return On Assets (ROA)', _p(latest?.roa)],
                    ]),

                    // ===== LIQUIDITY =====
                    _sectionTitle(context, 'Liquidity'),
                    _kvBox(context, [
                      ['Debt Equity Ratio (DER)', _n(latest?.der, decimals: 2)],
                      ['Cash Ratio (CR)', _p(latest?.cashRatio)],
                      ['Quick Ratio (QR)', _p(latest?.quickRatio)],
                      ['Current Ratio (CRR)', _p(latest?.currentRatio)],
                    ]),
                  ],
                ),
              ),
      ),
    );
  }
}
