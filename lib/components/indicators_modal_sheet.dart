import 'package:flutter/material.dart';

/// Definisi data untuk setiap indikator teknikal
class IndicatorItem {
  final String id;
  final String name;
  final String category;
  final String description;
  final bool isSupported;

  const IndicatorItem({
    required this.id,
    required this.name,
    this.category = 'Indicators',
    required this.description,
    this.isSupported = true,
  });
}

/// Modal Sheet Indikator ala TradingView Mobile
class IndicatorsModalSheet extends StatefulWidget {
  final bool showSma;
  final bool showRsi;
  final bool showVolume;
  final bool showFibonacci;
  final Set<String> favoriteIndicators;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<bool> onToggleSma;
  final ValueChanged<bool> onToggleRsi;
  final ValueChanged<bool> onToggleVolume;
  final ValueChanged<bool> onToggleFibonacci;

  const IndicatorsModalSheet({
    super.key,
    required this.showSma,
    required this.showRsi,
    required this.showVolume,
    required this.showFibonacci,
    required this.favoriteIndicators,
    required this.onToggleFavorite,
    required this.onToggleSma,
    required this.onToggleRsi,
    required this.onToggleVolume,
    required this.onToggleFibonacci,
  });

  @override
  State<IndicatorsModalSheet> createState() => _IndicatorsModalSheetState();
}

enum _IndicatorScreen { root, technicals, favorites }

class _IndicatorsModalSheetState extends State<IndicatorsModalSheet> {
  _IndicatorScreen _currentScreen = _IndicatorScreen.root;
  final TextEditingController _rootSearchCtrl = TextEditingController();
  final TextEditingController _techSearchCtrl = TextEditingController();
  final TextEditingController _favSearchCtrl = TextEditingController();

  // 8 Indikator: 3 yang sudah berfungsi + 5 yang menyusul sesuai instruksi user
  static const List<IndicatorItem> _allIndicators = <IndicatorItem>[
    IndicatorItem(
      id: 'atr',
      name: 'Average True Range (ATR)',
      description: 'Indikator volatilitas pasar yang mengukur rentang rata-rata pergerakan harga saham.',
      isSupported: false,
    ),
    IndicatorItem(
      id: 'bb',
      name: 'Bollinger Bands',
      description: 'Pita volatilitas atas dan bawah di sekitar moving average harga untuk melihat deviasi standar.',
      isSupported: false,
    ),
    IndicatorItem(
      id: 'ema',
      name: 'Exponential Moving Average (EMA)',
      description: 'Rata-rata pergerakan harga dengan pembobotan lebih besar pada pergerakan data harga terbaru.',
      isSupported: false,
    ),
    IndicatorItem(
      id: 'macd',
      name: 'MACD (Moving Average Convergence Divergence)',
      description: 'Indikator momentum trend-following yang membandingkan pergerakan dua moving average.',
      isSupported: false,
    ),
    IndicatorItem(
      id: 'sma',
      name: 'Moving Average (SMA)',
      description: 'Rata-rata pergerakan harga sederhana selama 20 periode terakhir.',
      isSupported: true,
    ),
    IndicatorItem(
      id: 'rsi',
      name: 'Relative Strength Index (RSI)',
      description: 'Oscillator momentum untuk mengidentifikasi kondisi Overbought (>70) dan Oversold (<30).',
      isSupported: true,
    ),
    IndicatorItem(
      id: 'stoch',
      name: 'Stochastic Oscillator',
      description: 'Oscillator momentum yang membandingkan harga penutupan dengan rentang harga dalam periode tertentu.',
      isSupported: false,
    ),
    IndicatorItem(
      id: 'vol',
      name: 'Volume',
      description: 'Volume perdagangan kumulatif yang menunjukkan aktivitas transaksi pasar dan likuiditas.',
      isSupported: true,
    ),
  ];

  // Local active flags mirroring props
  late bool _smaActive;
  late bool _rsiActive;
  late bool _volumeActive;
  late bool _fibActive;
  late Set<String> _favs;

  @override
  void initState() {
    super.initState();
    _smaActive = widget.showSma;
    _rsiActive = widget.showRsi;
    _volumeActive = widget.showVolume;
    _fibActive = widget.showFibonacci;
    _favs = Set<String>.from(widget.favoriteIndicators);
  }

  bool _isIndicatorActive(String id) {
    switch (id) {
      case 'sma':
        return _smaActive;
      case 'rsi':
        return _rsiActive;
      case 'vol':
        return _volumeActive;
      case 'fib':
        return _fibActive;
      default:
        return false;
    }
  }

  void _toggleIndicator(IndicatorItem item) {
    if (!item.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Indikator "${item.name}" akan segera hadir.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      switch (item.id) {
        case 'sma':
          _smaActive = !_smaActive;
          widget.onToggleSma(_smaActive);
          break;
        case 'rsi':
          _rsiActive = !_rsiActive;
          widget.onToggleRsi(_rsiActive);
          break;
        case 'vol':
          _volumeActive = !_volumeActive;
          widget.onToggleVolume(_volumeActive);
          break;
        case 'fib':
          _fibActive = !_fibActive;
          widget.onToggleFibonacci(_fibActive);
          break;
      }
    });
  }

  void _toggleFav(String name) {
    setState(() {
      if (_favs.contains(name)) {
        _favs.remove(name);
      } else {
        _favs.add(name);
      }
      widget.onToggleFavorite(name);
    });
  }

  void _showInfoDialog(IndicatorItem item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E222D) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: <Widget>[
              const Icon(Icons.help_outline, color: Color(0xFF2962FF), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            item.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? const Color(0xFFD1D4DC) : const Color(0xFF4A4E5A),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Tutup',
                style: TextStyle(color: Color(0xFF2962FF), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color sheetBg = isDark ? const Color(0xFF000000) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF131722);
    final Color subtextColor = isDark ? const Color(0xFF848E9C) : const Color(0xFF787B86);
    final Color searchBg = isDark ? const Color(0xFF161A25) : const Color(0xFFF0F3FA);
    final Color searchBorder = isDark ? const Color(0xFF2A2E39) : const Color(0xFFE0E3EB);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            // Grab handle indicator
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2E39) : const Color(0xFFD1D4DC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Screen content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildCurrentScreen(
                  isDark: isDark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  searchBg: searchBg,
                  searchBorder: searchBorder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen({
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
    required Color searchBg,
    required Color searchBorder,
  }) {
    switch (_currentScreen) {
      case _IndicatorScreen.root:
        return _buildRootScreen(
          isDark: isDark,
          textColor: textColor,
          subtextColor: subtextColor,
          searchBg: searchBg,
          searchBorder: searchBorder,
        );
      case _IndicatorScreen.technicals:
        return _buildTechnicalsScreen(
          isDark: isDark,
          textColor: textColor,
          subtextColor: subtextColor,
          searchBg: searchBg,
          searchBorder: searchBorder,
        );
      case _IndicatorScreen.favorites:
        return _buildFavoritesScreen(
          isDark: isDark,
          textColor: textColor,
          subtextColor: subtextColor,
          searchBg: searchBg,
          searchBorder: searchBorder,
        );
    }
  }

  // ==========================================
  // SCREEN 1: ROOT ("Indicators") ala Gambar 1
  // ==========================================
  Widget _buildRootScreen({
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
    required Color searchBg,
    required Color searchBorder,
  }) {
    final String query = _rootSearchCtrl.text.trim().toLowerCase();
    final List<IndicatorItem> searchResults = query.isEmpty
        ? const <IndicatorItem>[]
        : _allIndicators
            .where((IndicatorItem item) => item.name.toLowerCase().contains(query))
            .toList();

    return Column(
      key: const ValueKey<String>('screen_root'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Header: "Indicators" + [✕]
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Indicators',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: textColor, size: 24),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
        ),

        // Search Bar (Transparan, bebas dari fill abu-abu tema global)
        _buildSearchBar(
          controller: _rootSearchCtrl,
          searchBg: searchBg,
          searchBorder: searchBorder,
          subtextColor: subtextColor,
          textColor: textColor,
          onChanged: (String _) => setState(() {}),
        ),

        const SizedBox(height: 8),

        // If user is searching on root, show filtered results directly
        if (query.isNotEmpty)
          Expanded(
            child: searchResults.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada indikator yang cocok.',
                      style: TextStyle(color: subtextColor, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (BuildContext ctx, int i) {
                      final IndicatorItem item = searchResults[i];
                      return _buildIndicatorRow(
                        item: item,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        isDark: isDark,
                      );
                    },
                  ),
          )
        else
          Expanded(
            child: ListView(
              children: <Widget>[
                // Section: PERSONAL
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'PERSONAL',
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _buildMenuNavigationItem(
                  icon: Icons.star_border_rounded,
                  title: 'Favorites',
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    setState(() {
                      _favSearchCtrl.clear();
                      _currentScreen = _IndicatorScreen.favorites;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Section: BUILT-IN
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'BUILT-IN',
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _buildMenuNavigationItem(
                  icon: Icons.show_chart_rounded,
                  title: 'Technicals',
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    setState(() {
                      _techSearchCtrl.clear();
                      _currentScreen = _IndicatorScreen.technicals;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==========================================
  // SCREEN 2: TECHNICALS ala Gambar 2 (Tanpa filter pills dummy)
  // ==========================================
  Widget _buildTechnicalsScreen({
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
    required Color searchBg,
    required Color searchBorder,
  }) {
    final String query = _techSearchCtrl.text.trim().toLowerCase();
    final List<IndicatorItem> filtered = _allIndicators.where((IndicatorItem item) {
      final bool matchesQuery = query.isEmpty || item.name.toLowerCase().contains(query);
      return matchesQuery;
    }).toList();

    return Column(
      key: const ValueKey<String>('screen_technicals'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Top Header: [<] Technicals [✕]
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                onPressed: () {
                  setState(() => _currentScreen = _IndicatorScreen.root);
                },
                splashRadius: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Technicals',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: textColor, size: 24),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
        ),

        // Search Bar (Transparan & bersih)
        _buildSearchBar(
          controller: _techSearchCtrl,
          searchBg: searchBg,
          searchBorder: searchBorder,
          subtextColor: subtextColor,
          textColor: textColor,
          onChanged: (String _) => setState(() {}),
        ),

        const SizedBox(height: 10),

        // Indicator List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada indikator yang cocok.',
                    style: TextStyle(color: subtextColor, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (BuildContext ctx, int i) {
                    final IndicatorItem item = filtered[i];
                    return _buildIndicatorRow(
                      item: item,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // SCREEN 3: FAVORITES ala Gambar 3
  // ==========================================
  Widget _buildFavoritesScreen({
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
    required Color searchBg,
    required Color searchBorder,
  }) {
    final String query = _favSearchCtrl.text.trim().toLowerCase();
    final List<IndicatorItem> favItems = _allIndicators.where((IndicatorItem item) {
      final bool isFav = _favs.contains(item.name);
      final bool matchesQuery = query.isEmpty || item.name.toLowerCase().contains(query);
      return isFav && matchesQuery;
    }).toList();

    return Column(
      key: const ValueKey<String>('screen_favorites'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Top Header: [<] Favorites [✕]
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                onPressed: () {
                  setState(() => _currentScreen = _IndicatorScreen.root);
                },
                splashRadius: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Favorites',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: textColor, size: 24),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
        ),

        // Search Bar (Transparan & bersih)
        _buildSearchBar(
          controller: _favSearchCtrl,
          searchBg: searchBg,
          searchBorder: searchBorder,
          subtextColor: subtextColor,
          textColor: textColor,
          onChanged: (String _) => setState(() {}),
        ),

        const SizedBox(height: 12),

        // Favorite List
        Expanded(
          child: favItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.star_outline_rounded, size: 48, color: subtextColor),
                        const SizedBox(height: 12),
                        Text(
                          query.isNotEmpty
                              ? 'Tidak ada indikator favorit yang cocok.'
                              : 'Belum ada indikator favorit.\nTekan ikon bintang (☆) pada menu Technicals untuk menambahkan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: favItems.length,
                  itemBuilder: (BuildContext ctx, int i) {
                    final IndicatorItem item = favItems[i];
                    final bool isActive = _isIndicatorActive(item.id);

                    return InkWell(
                      onTap: () => _toggleIndicator(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: <Widget>[
                            // Star Icon (Filled)
                            GestureDetector(
                              onTap: () => _toggleFav(item.name),
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 14),
                                child: Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            // Indicator Title (WITHOUT LuxAlgo / author name)
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        color: isActive ? const Color(0xFF00A3A8) : textColor,
                                        fontSize: 15,
                                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isActive) ...<Widget>[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00A3A8).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Aktif',
                                        style: TextStyle(
                                          color: Color(0xFF00A3A8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Document / Note Icon on Right (Gambar 3)
                            GestureDetector(
                              onTap: () => _showInfoDialog(item),
                              child: Icon(
                                Icons.article_outlined,
                                color: subtextColor,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildSearchBar({
    required TextEditingController controller,
    required Color searchBg,
    required Color searchBorder,
    required Color subtextColor,
    required Color textColor,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: searchBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: searchBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: <Widget>[
            const SizedBox(width: 12),
            Icon(Icons.search_rounded, color: subtextColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Theme(
                // Override global inputDecorationTheme agar tidak tertutup warna abu-abu
                data: ThemeData(
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: subtextColor, fontSize: 14),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.cancel_rounded, color: subtextColor, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuNavigationItem({
    required IconData icon,
    required String title,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subtextColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorRow({
    required IndicatorItem item,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    final bool isFav = _favs.contains(item.name);
    final bool isActive = _isIndicatorActive(item.id);

    return InkWell(
      onTap: () => _toggleIndicator(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            // Star Toggle Button
            GestureDetector(
              onTap: () => _toggleFav(item.name),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav ? Colors.white : subtextColor,
                  size: 20,
                ),
              ),
            ),
            // Title
            Expanded(
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        color: isActive ? const Color(0xFF00A3A8) : textColor,
                        fontSize: 15,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isActive) ...<Widget>[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A3A8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Aktif',
                        style: TextStyle(
                          color: Color(0xFF00A3A8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Info Icon (?)
            GestureDetector(
              onTap: () => _showInfoDialog(item),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: subtextColor,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
