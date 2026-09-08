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
  DateTime? _tradeDate; // null = latest (server akan ambil tanggal terbaru)
  String _investor = 'all'; // all | foreign | local

  Future<List<BrokerSummaryRow>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // fallback aman kalau tidak ada argumen
    ticker = (args?['ticker'] as String?) ?? '';

    // kick first load
    _future ??= _load();
  }

  Future<List<BrokerSummaryRow>> _load() {
    final svc = context.read<StocksService>();
    return svc.fetchBrokerSummary(
      ticker,
      tradeDate: _tradeDate,
      investor: _investor,
      limit: 300,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  String _fmtNum(num? v) {
    if (v == null) return '-';
    return NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: '', // IDR tanpa simbol
    ).format(v);
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
        body: FutureBuilder<List<BrokerSummaryRow>>(
          future: _future,
          builder: (ctx, snap) {
            // ——— Loading skeleton
            if (snap.connectionState == ConnectionState.waiting) {
              return const _TableSkeleton();
            }

            // ——— Error state
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                ),
              );
            }

            final rows = snap.data ?? const <BrokerSummaryRow>[];

            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ——— TabBar "Ringkasan / Key Statistics / Informasi Broker"
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
                            if (i == 0) {
                              Navigator.pop(context, 0);
                            } else if (i == 1) {
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

                  // ——— Filter bar (investor + tanggal) juga dipinning
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
                                    : DateFormat(
                                        'dd MMM yyyy',
                                      ).format(_tradeDate!),
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

                  // ——— Tabel
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
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 20 + 56),
                        child: _BrokerSummaryTable(rows: rows, format: _fmtNum),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // tombol “minimize”
        bottomNavigationBar: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Center(
              child: IconButton(
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

class _BrokerSummaryTable extends StatelessWidget {
  final List<BrokerSummaryRow> rows;
  final String Function(num?) format;
  const _BrokerSummaryTable({
    super.key,
    required this.rows,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    const wCode = 48.0; // lebar kolom kode broker
    const wNum = 72.0; // lebar kolom angka compact
    const pad = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    final headStyle = t.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    final buyerStyle = t.bodyMedium?.copyWith(
      color: Colors.greenAccent.shade200.withOpacity(.9),
      fontWeight: FontWeight.w700,
    );
    final sellerStyle = t.bodyMedium?.copyWith(
      color: Colors.redAccent.shade200.withOpacity(.95),
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
                // ===== Header =====
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

                // ===== Body (Column, bukan ListView) =====
                for (int i = 0; i < rows.length; i++) ...[
                  Container(
                    color: i.isEven
                        ? cs.surface
                        : cs.surfaceVariant.withOpacity(.06),
                    padding: pad,
                    child: Row(
                      children: [
                        // buyer code
                        SizedBox(
                          width: wCode,
                          child: Text(rows[i].buyerCode, style: buyerStyle),
                        ),

                        // B.Val/Lot/Avg
                        SizedBox(
                          width: wNum,
                          child: Center(
                            child: Text(
                              format(rows[i].bVal),
                              style: buyerStyle,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: wNum,
                          child: Center(
                            child: Text(
                              format(rows[i].bLot),
                              style: buyerStyle,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: wNum,
                          child: Center(
                            child: Text(
                              format(rows[i].bAvg),
                              style: buyerStyle,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // seller code
                        SizedBox(
                          width: wCode,
                          child: Center(
                            child: Text(rows[i].sellerCode, style: sellerStyle),
                          ),
                        ),

                        // S.Val
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