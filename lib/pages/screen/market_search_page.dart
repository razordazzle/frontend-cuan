import 'package:cuan_app/data/model/stock_list_item.dart';
import 'package:cuan_app/data/services/stocks_service.dart';
import 'package:cuan_app/pages/screen/stock_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MarketSearchPage extends StatefulWidget {
  const MarketSearchPage({super.key});

  @override
  State<MarketSearchPage> createState() => _MarketSearchPageState();
}

class _MarketSearchPageState extends State<MarketSearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<StockListItem> _allStocks = [];
  List<StockListItem> _filteredStocks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Dengarkan setiap ketikan di keyboard
    _searchCtrl.addListener(_onSearchChanged);

    // Tarik data setelah UI selesai di-render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllStocks();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAllStocks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Ambil service (Pastikan StocksService sudah terdaftar di MultiProvider main.dart)
      final service = context.read<StocksService>();

      // Ambil data A-Z dengan limit besar agar semua saham masuk
      final data = await service.list(filter: 'az', limit: 1000);

      setState(() {
        _allStocks = data;
        _filteredStocks = data; // Tampilan awal menampilkan semua
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.trim().toLowerCase();

    // Kalau kotak search kosong, kembalikan ke list penuh
    if (query.isEmpty) {
      setState(() {
        _filteredStocks = _allStocks;
      });
      return;
    }

    // Filter secara lokal di memori (Sangat Cepat!)
    setState(() {
      _filteredStocks = _allStocks.where((s) {
        final tickerMatch = s.ticker.toLowerCase().contains(query);
        final nameMatch = s.companyName.toLowerCase().contains(query);
        return tickerMatch || nameMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          autofocus: true, // Otomatis pop-up keyboard saat halaman dibuka
          decoration: InputDecoration(
            hintText: 'Cari saham (misal: BBCA)...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: .5)),
          ),
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          // Tampilkan tombol "X" (Clear) hanya kalau ada teks
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: cs.onSurface),
              onPressed: () {
                _searchCtrl.clear();
              },
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: cs.outline.withValues(alpha: .12),
          ),
        ),
      ),
      body: _buildBody(cs, t),
    );
  }

  Widget _buildBody(ColorScheme cs, TextTheme t) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gagal memuat daftar saham',
              style: TextStyle(color: cs.error, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(_error!, style: TextStyle(color: cs.error, fontSize: 12)),
          ],
        ),
      );
    }

    if (_filteredStocks.isEmpty) {
      return Center(
        child: Text(
          'Saham tidak ditemukan 😢',
          style: t.bodyLarge?.copyWith(
            color: cs.onSurface.withValues(alpha: .6),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredStocks.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: cs.outline.withValues(alpha: .06)),
      itemBuilder: (context, i) {
        final s = _filteredStocks[i];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: cs.surfaceVariant,
            backgroundImage: (s.logoUrl != null && s.logoUrl!.isNotEmpty)
                ? NetworkImage(s.logoUrl!)
                : null,
            child: (s.logoUrl == null || s.logoUrl!.isEmpty)
                ? Text(
                    s.ticker.substring(0, 1),
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          title: Text(
            s.ticker,
            style: t.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          subtitle: Text(
            s.companyName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: .7),
            ),
          ),
          onTap: () {
            // Sembunyikan keyboard sebelum pindah halaman
            FocusScope.of(context).unfocus();

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
    );
  }
}
