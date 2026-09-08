import 'package:cuan_app/data/model/market_item.dart';
import 'package:cuan_app/data/model/stock_list_item.dart';
import 'package:cuan_app/pages/screen/market_search_page.dart';
import 'package:cuan_app/providers/market_provider.dart';
import 'package:cuan_app/providers/stocks_provider.dart';
import 'package:flutter/material.dart';
import 'package:cuan_app/pages/screen/stock_detail_page.dart';
import 'package:provider/provider.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  int _segIndex = 0; // 0=Gainers, 1=Losers, 2=Top Volume

  // ===== Dummy data saham (samakan dengan HomePage agar konsisten) =====

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // context.read<MarketProvider>().loadAll(limit: 50);
      final p = context.read<MarketProvider>();
      await p.loadAll(limit: 50);
      // const wsBaseUrl = 'ws://10.0.2.2:8000';

      // // subscribe semua ticker yang tampil (gabung 3 list supaya update tetap jalan walau pindah tab)
      // final symbols = <String>{
      //   ...p.gainers.map((e) => e.ticker),
      //   ...p.losers.map((e) => e.ticker),
      //   ...p.volume.map((e) => e.ticker),
      // }.toList();

      // await p.startLivePrices(wsBaseUrl: wsBaseUrl, symbols: symbols);

      if (mounted) _syncWsSymbols(p);
    });
  }

  @override
  void dispose() {
    context.read<MarketProvider>().stopLivePrices();
    super.dispose();
  }

  void _syncWsSymbols(MarketProvider p) {
    // const wsBaseUrl = 'ws://10.0.2.2:8000';
    // final symbols = <String>{
    //   ...p.gainers.map((e) => e.ticker),
    //   ...p.losers.map((e) => e.ticker),
    //   ...p.volume.map((e) => e.ticker),
    // }.toList();
    // p.startLivePrices(wsBaseUrl: wsBaseUrl, symbols: symbols);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        title: Text(
          'List Saham',
          style: t.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: cs.onSurface),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: cs.onSurface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketSearchPage()),
              );
            },
          ),
          const SizedBox(width: 8), // Jarak margin kanan
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Divider(
            height: 1,
            thickness: 1,
            color: cs.outline.withValues(alpha: .12),
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // ===== Segmented top (sesuai prototype) =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Segmented3(
                labels: const ['Top Gainers', 'Top Losers', 'Top Volume'],
                index: _segIndex,
                onChanged: (i) {
                  setState(() => _segIndex = i);
                  _syncWsSymbols(context.read<MarketProvider>());
                },
              ),
            ),

            const SizedBox(height: 8),

            // ===== Header kolom =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nama',
                      style: t.textTheme.labelMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: .6),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _calcPriceWidth(context),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Harga',
                        style: t.textTheme.labelMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: .6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outline.withValues(alpha: .12)),

            // ===== List saham =====
            Expanded(
              // child: Consumer<MarketProvider>(
              child: Consumer<StocksProvider>(
                builder: (_, p, __) {
                  List<StockListItem> current() {
                    // if (_segIndex == 0) return p.gainers;
                    // if (_segIndex == 1) return p.losers;
                    // return p.volume;
                    if (_segIndex == 0) return p.topGainers ?? [];
                    if (_segIndex == 1) return p.topLosers ?? [];
                    return p.topVolume ?? [];
                  }

                  // Cek loading status dari masing-masing list
                  bool isLoading = _segIndex == 0
                      ? p.loadingGainers
                      : (_segIndex == 1 ? p.loadingLosers : p.loadingVolume);

                  if (isLoading && current().isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // if (p.loading && current().isEmpty) {
                  //   return const Center(child: CircularProgressIndicator());
                  // }
                  // if (p.error != null && current().isEmpty) {
                  //   return Center(
                  //     child: Column(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         Text(
                  //           p.error!,
                  //           style: TextStyle(
                  //             color: Theme.of(context).colorScheme.error,
                  //           ),
                  //         ),
                  //         const SizedBox(height: 8),
                  //         OutlinedButton(
                  //           onPressed: () => context
                  //               .read<MarketProvider>()
                  //               .loadAll(limit: 50),
                  //           child: const Text('Coba lagi'),
                  //         ),
                  //       ],
                  //     ),
                  //   );
                  // }

                  return RefreshIndicator(
                    // onRefresh: () => context.read<MarketProvider>().refreshOne(
                    //   _segIndex == 0
                    //       ? 'gainers'
                    //       : _segIndex == 1
                    //       ? 'losers'
                    //       : 'volume',
                    //   limit: 50,
                    // ),
                    onRefresh: () async {
                      final p = context.read<MarketProvider>();
                      await p.refreshOne(
                        _segIndex == 0
                            ? 'gainers'
                            : _segIndex == 1
                            ? 'losers'
                            : 'volume',
                        limit: 50,
                      );
                      _syncWsSymbols(p);
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: current().length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: .06),
                      ),
                      itemBuilder: (context, i) {
                        final s = current()[i];
                        final up = (s.changePoint ?? 0) >= 0;
                        final color = up
                            ? const Color(0xFF21C07A)
                            : Colors.red.shade600;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant,
                            backgroundImage:
                                (s.logoUrl != null && s.logoUrl!.isNotEmpty)
                                ? NetworkImage(s.logoUrl!)
                                : null,
                            child: (s.logoUrl == null || s.logoUrl!.isEmpty)
                                ? Text(
                                    s.ticker.substring(0, 1),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                s.ticker,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.companyName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: .7),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          trailing: SizedBox(
                            width: _calcPriceWidth(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  s.lastPrice?.toStringAsFixed(0) ?? '-',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        up
                                            ? Icons.arrow_drop_up
                                            : Icons.arrow_drop_down,
                                        color: color,
                                        size: 20,
                                      ),
                                      Text(
                                        _fmtDelta(s.changePoint, s.changePct),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: color,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StockDetailPage(
                                  ticker: s.ticker,
                                  company: s.companyName,
                                  price: (s.lastPrice ?? 0).toInt(),
                                  change: (s.changePoint ?? 0).toInt(),
                                  changePct: s.changePct ?? 0,
                                  logoUrl: s.logoUrl,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
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
/* ===================== Widgets & utils ===================== */

class _Segmented3 extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const _Segmented3({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    Widget item(String text, int i) {
      final on = i == index;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onChanged(i),
          child: Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on
                  ? cs.primary.withValues(alpha: .12)
                  : cs.surfaceVariant.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: on
                    ? cs.primary.withValues(alpha: .35)
                    : cs.outline.withValues(alpha: .20),
              ),
            ),
            child: Text(
              text,
              style: t.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: on ? cs.primary : cs.onSurface.withValues(alpha: .75),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        item(labels[0], 0),
        const SizedBox(width: 8),
        item(labels[1], 1),
        const SizedBox(width: 8),
        item(labels[2], 2),
      ],
    );
  }
}

double _calcPriceWidth(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w <= 340) return 86;
  if (w <= 380) return 96;
  return 110;
}
