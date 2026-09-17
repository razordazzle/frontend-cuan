import 'dart:math' as math;
import 'package:cuan_app/components/tv_chart_widget.dart';
import 'package:cuan_app/data/model/candle_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stocks_provider.dart';
import 'home_page.dart' show Ohlc, makeDummyCandles; // reuse model & helper yg udah ada

class IhsgTradingViewPage extends StatefulWidget {
  const IhsgTradingViewPage({super.key});

  @override
  State<IhsgTradingViewPage> createState() => _IhsgTradingViewPageState();
}

class _IhsgTradingViewPageState extends State<IhsgTradingViewPage> {
  bool _isCandle = true;
  bool _showSma = false;
  bool _showRsi = false;
  bool _showVolume = false;
  bool _showFibonacci = false;
  bool _isDrawingFib = false;
  List<double> _horizontalLines = <double>[];
  bool _isDrawingHorizontalLine = false;
  List<Map<String, dynamic>> _trendlines = <Map<String, dynamic>>[];
  bool _isDrawingTrendline = false;
  List<Map<String, dynamic>> _rectangles = <Map<String, dynamic>>[];
  bool _isDrawingRectangle = false;
  bool _showDrawingToolbar = false;
  Map<String, dynamic>? _crosshair;

  int get _activeIndicatorsCount =>
      (_showSma ? 1 : 0) + (_showRsi ? 1 : 0) + (_showVolume ? 1 : 0);

  void _toggleFibonacci() {
    setState(() {
      _isDrawingHorizontalLine = false;
      _isDrawingTrendline = false;
      _isDrawingRectangle = false;
      if (_showFibonacci) {
        _showFibonacci = false;
        _isDrawingFib = false;
      } else {
        _showFibonacci = true;
        _isDrawingFib = true;
      }
    });
  }

  void _startDrawingHorizontalLine() {
    setState(() {
      _isDrawingFib = false;
      _isDrawingTrendline = false;
      _isDrawingRectangle = false;
      _isDrawingHorizontalLine = true;
    });
  }

  void _startDrawingTrendline() {
    setState(() {
      _isDrawingFib = false;
      _isDrawingHorizontalLine = false;
      _isDrawingRectangle = false;
      _isDrawingTrendline = true;
    });
  }

  void _startDrawingRectangle() {
    setState(() {
      _isDrawingFib = false;
      _isDrawingHorizontalLine = false;
      _isDrawingTrendline = false;
      _isDrawingRectangle = true;
    });
  }

  void _clearAllDrawings() {
    setState(() {
      _showFibonacci = false;
      _isDrawingFib = false;
      _horizontalLines = <double>[];
      _isDrawingHorizontalLine = false;
      _trendlines = <Map<String, dynamic>>[];
      _isDrawingTrendline = false;
      _rectangles = <Map<String, dynamic>>[];
      _isDrawingRectangle = false;
    });
  }

  void _showDrawingsBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final ThemeData theme = Theme.of(sheetContext);
        final bool isDark = theme.brightness == Brightness.dark;

        // TradingView Mobile theme palette
        final Color sheetBg = isDark ? const Color(0xFF1E222D) : Colors.white;
        final Color cardBg = isDark ? const Color(0xFF2A2E39) : const Color(0xFFF0F3FA);
        final Color cardBorder = isDark ? const Color(0xFF363A45) : const Color(0xFFE0E3EB);
        final Color searchBg = isDark ? const Color(0xFF2A2E39) : const Color(0xFFF0F3FA);
        final Color textColor = isDark ? Colors.white : const Color(0xFF131722);
        final Color subtitleColor = isDark ? const Color(0xFF787B86) : const Color(0xFF9598A1);
        final Color closeBtnBg = isDark ? const Color(0xFF2A2E39) : const Color(0xFFF0F3FA);
        final Color iconColor = isDark ? Colors.white : const Color(0xFF131722);
        const Color starColor = Color(0xFFF7A600); // TradingView Amber Star

        String searchQuery = '';
        String selectedFilter = 'Favorites';
        final TextEditingController searchController = TextEditingController();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final List<_DrawingToolItem> allTools = [
              _DrawingToolItem(
                id: 'trendline',
                title: 'Trendline',
                category: 'TREND TOOLS',
                iconBuilder: (Color c) => _TrendlineVectorIcon(color: c),
                isFavorite: true,
                isSelected: _isDrawingTrendline,
                onSelect: () {
                  Navigator.of(sheetContext).pop();
                  _startDrawingTrendline();
                },
              ),
              _DrawingToolItem(
                id: 'horizontal_line',
                title: 'Horizontal line',
                category: 'TREND TOOLS',
                iconBuilder: (Color c) => _HLineVectorIcon(color: c),
                isFavorite: true,
                isSelected: _isDrawingHorizontalLine,
                onSelect: () {
                  Navigator.of(sheetContext).pop();
                  _startDrawingHorizontalLine();
                },
              ),
              _DrawingToolItem(
                id: 'fib_retracement',
                title: 'Fib retracement',
                category: 'GANN AND FIBONACCI',
                iconBuilder: (Color c) => _FibVectorIcon(color: c),
                isFavorite: true,
                isSelected: _showFibonacci || _isDrawingFib,
                onSelect: () {
                  Navigator.of(sheetContext).pop();
                  _toggleFibonacci();
                },
              ),
              _DrawingToolItem(
                id: 'rectangle',
                title: 'Rectangle',
                category: 'GEOMETRIC SHAPES',
                iconBuilder: (Color c) => _RectVectorIcon(color: c),
                isFavorite: true,
                isSelected: _isDrawingRectangle,
                onSelect: () {
                  Navigator.of(sheetContext).pop();
                  _startDrawingRectangle();
                },
              ),
            ];

            List<_DrawingToolItem> filtered = allTools;
            if (searchQuery.isNotEmpty) {
              filtered = allTools
                  .where((t) =>
                      t.title.toLowerCase().contains(searchQuery) ||
                      t.category.toLowerCase().contains(searchQuery))
                  .toList();
            } else if (selectedFilter == 'Favorites') {
              filtered = allTools.where((t) => t.isFavorite).toList();
            } else if (selectedFilter == 'Trend tools') {
              filtered = allTools.where((t) => t.category == 'TREND TOOLS').toList();
            } else if (selectedFilter == 'Gann and...') {
              filtered = allTools.where((t) => t.category == 'GANN AND FIBONACCI').toList();
            } else if (selectedFilter == 'Shapes') {
              filtered = allTools.where((t) => t.category == 'GEOMETRIC SHAPES').toList();
            }

            final Map<String, List<_DrawingToolItem>> grouped = {};
            for (final item in filtered) {
              grouped.putIfAbsent(item.category, () => []).add(item);
            }

            final bool hasDrawings = _showFibonacci ||
                _horizontalLines.isNotEmpty ||
                _trendlines.isNotEmpty ||
                _rectangles.isNotEmpty;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF363A45) : const Color(0xFFE0E3EB),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Drag Pill Handle
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 4),
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF50535E) : const Color(0xFFD1D4DC),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // Title & Close Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Drawings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(sheetContext).pop(),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: closeBtnBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, size: 18, color: iconColor),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: searchBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 18, color: subtitleColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                onChanged: (val) => setSheetState(() => searchQuery = val.trim().toLowerCase()),
                                style: TextStyle(fontSize: 13.5, color: textColor),
                                decoration: InputDecoration(
                                  hintText: 'Search',
                                  hintStyle: TextStyle(fontSize: 13.5, color: subtitleColor),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  searchController.clear();
                                  setSheetState(() => searchQuery = '');
                                },
                                child: Icon(Icons.clear, size: 16, color: subtitleColor),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Category Filter Pills (Horizontal scroll)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          'Favorites',
                          'Tools',
                          'Trend tools',
                          'Gann and...',
                          'Shapes',
                        ].map((filter) {
                          final bool isSelected = selectedFilter == filter && searchQuery.isEmpty;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                searchController.clear();
                                setSheetState(() {
                                  searchQuery = '';
                                  selectedFilter = filter;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF2A2E39) : const Color(0xFFE0E3EB))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? textColor : subtitleColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    Divider(height: 1, color: cardBorder),

                    // Scrollable Area: Tool Cards grouped by Category
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (grouped.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'Tidak ada drawing tool yang ditemukan',
                                    style: TextStyle(color: subtitleColor, fontSize: 13),
                                  ),
                                ),
                              )
                            else
                              ...grouped.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: entry.value.map((tool) {
                                          return _buildTvToolCard(
                                            tool: tool,
                                            cardBg: cardBg,
                                            cardBorder: cardBorder,
                                            textColor: textColor,
                                            iconColor: iconColor,
                                            starColor: starColor,
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),

                    Divider(height: 1, color: cardBorder),

                    // Bottom Footer: Show favorites on Chart + Hapus Garis
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: subtitleColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Show favorites on Chart',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (hasDrawings) ...[
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _clearAllDrawings();
                              },
                              icon: Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.red.shade400),
                              label: Text(
                                'Hapus Garis',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Switch(
                            value: _showDrawingToolbar,
                            activeThumbColor: const Color(0xFF2962FF),
                            activeTrackColor: const Color(0xFF2962FF).withValues(alpha: 0.35),
                            inactiveThumbColor: isDark ? const Color(0xFF787B86) : const Color(0xFFD1D4DC),
                            inactiveTrackColor: isDark ? const Color(0xFF2A2E39) : const Color(0xFFE0E3EB),
                            onChanged: (val) {
                              setState(() => _showDrawingToolbar = val);
                              setSheetState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTvToolCard({
    required _DrawingToolItem tool,
    required Color cardBg,
    required Color cardBorder,
    required Color textColor,
    required Color iconColor,
    required Color starColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tool.onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 104,
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tool.isSelected ? const Color(0xFF2962FF) : cardBorder,
              width: tool.isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Star on top right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    tool.isFavorite ? Icons.star : Icons.star_border,
                    size: 13,
                    color: tool.isFavorite ? starColor : Colors.transparent,
                  ),
                ],
              ),
              // Vector Tool Icon
              tool.iconBuilder(tool.isSelected ? const Color(0xFF2962FF) : iconColor),
              // Tool Name
              Text(
                tool.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: tool.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: tool.isSelected ? const Color(0xFF2962FF) : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIndicatorsBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final ThemeData theme = Theme.of(sheetContext);
        final ColorScheme cs = theme.colorScheme;
        final bool isDark = theme.brightness == Brightness.dark;

        // Same color as chart background (#121212 in dark mode, white in light mode)
        final Color sheetBg = isDark ? const Color(0xFF121212) : Colors.white;
        final Color borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
        final Color handleColor = isDark ? const Color(0xFF3E3E42) : const Color(0xFFD1D1D6);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                top: 12,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetContext).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: handleColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A3A8).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'fx',
                              style: TextStyle(
                                color: Color(0xFF00A3A8),
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Indikator Teknikal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 12),

                  // SMA Item
                  _buildIndicatorItem(
                    title: 'SMA (Simple Moving Average)',
                    subtitle: 'Periode 20 • Tren Harga Rata-Rata',
                    color: const Color(0xFF2962FF),
                    value: _showSma,
                    onChanged: (bool val) {
                      setState(() => _showSma = val);
                      setSheetState(() {});
                    },
                    cs: cs,
                    theme: theme,
                  ),
                  const SizedBox(height: 10),

                  // RSI Item
                  _buildIndicatorItem(
                    title: 'RSI (Relative Strength Index)',
                    subtitle: 'Periode 14 • Momentum Overbought / Oversold',
                    color: const Color(0xFFE91E63),
                    value: _showRsi,
                    onChanged: (bool val) {
                      setState(() => _showRsi = val);
                      setSheetState(() {});
                    },
                    cs: cs,
                    theme: theme,
                  ),
                  const SizedBox(height: 10),

                  // Volume Item
                  _buildIndicatorItem(
                    title: 'Volume',
                    subtitle: 'Volume Bar Perdagangan',
                    color: const Color(0xFF00B0FF),
                    value: _showVolume,
                    onChanged: (bool val) {
                      setState(() => _showVolume = val);
                      setSheetState(() {});
                    },
                    cs: cs,
                    theme: theme,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIndicatorItem({
    required String title,
    required String subtitle,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme cs,
    required ThemeData theme,
  }) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Color itemBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F8);
    final Color itemBorder = isDark ? const Color(0xFF2A2A2D) : const Color(0xFFE5E5EA);

    return Container(
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.1) : itemBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.6) : itemBorder,
          width: value ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.35),
            inactiveThumbColor: isDark ? const Color(0xFF8E8E93) : const Color(0xFFE5E5EA),
            inactiveTrackColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD1D1D6),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme cs = t.colorScheme;
    final bool isDark = t.brightness == Brightness.dark;
    const Color upColor = Color(0xFF21C07A);
    final Color downColor = Colors.red.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IHSG'),
        actions: [
          IconButton(
            icon: Icon(_isCandle ? Icons.show_chart : Icons.candlestick_chart),
            tooltip: _isCandle ? 'Ganti ke Area Chart' : 'Ganti ke Candle Chart',
            onPressed: () => setState(() => _isCandle = !_isCandle),
          ),
        ],
      ),
      body: Consumer<StocksProvider>(
        builder: (BuildContext context, StocksProvider p, _) {
          final List<Ohlc> rawCandles = (p.ihsgChartPayload?.candles.isNotEmpty == true)
              ? p.ihsgChartPayload!.candles
              : p.ihsgCandles
                  .map((CandleItem c) => Ohlc(
                        time: c.ts,
                        open: c.open ?? c.close ?? 0,
                        high: c.high ?? c.close ?? 0,
                        low: c.low ?? c.close ?? 0,
                        close: c.close ?? 0,
                        volume: (c.volume ?? 0).toDouble(),
                      ))
                  .toList();
          final List<Ohlc> candles = rawCandles.isNotEmpty
              ? rawCandles
              : makeDummyCandles(60);

          final Ohlc? liveBar = (candles.isNotEmpty && p.ihsgLast != null)
              ? Ohlc(
                  time: candles.last.time,
                  open: candles.last.open,
                  high: math.max(candles.last.high, p.ihsgLast!),
                  low: math.min(candles.last.low, p.ihsgLast!),
                  close: p.ihsgLast!,
                  volume: candles.last.volume,
                )
              : null;

          return Column(
            children: [
              // Legend OHLCV live, update pas jari geser di chart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _Legend(crosshair: _crosshair, fallback: liveBar ?? (candles.isNotEmpty ? candles.last : null)),
              ),
              // Clean Top Bar: Timeframe (Kiri) + Action Buttons [fx] & [✏️] (Kanan)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Timeframe pills (sekarang sangat rapi dan pas di layar)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['1D', '1W', '1M', '3M', 'YTD', '1Y']
                              .map((String r) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(r),
                                      selected: p.indexInterval == r,
                                      onSelected: (_) => p.setIndexInterval(r),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Pembatas visual
                    Container(
                      width: 1,
                      height: 22,
                      color: cs.outline.withValues(alpha: 0.25),
                    ),
                    const SizedBox(width: 8),
                    // Tombol Indikator Teknikal (fx) dengan badge counter
                    _ActionButton(
                      tooltip: 'Indikator Teknikal',
                      onTap: () => _showIndicatorsBottomSheet(context),
                      isActive: _activeIndicatorsCount > 0,
                      activeColor: const Color(0xFF00A3A8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'fx',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: _activeIndicatorsCount > 0
                                  ? const Color(0xFF00A3A8)
                                  : (isDark ? const Color(0xFFD8D8D8) : const Color(0xFF373737)),
                            ),
                          ),
                          if (_activeIndicatorsCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00A3A8),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_activeIndicatorsCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Tombol Drawing Toolbar (✏️)
                    _ActionButton(
                      tooltip: 'Alat Gambar (Drawings)',
                      onTap: () => _showDrawingsBottomSheet(context),
                      isActive: _showDrawingToolbar ||
                          _isDrawingHorizontalLine ||
                          _isDrawingTrendline ||
                          _isDrawingRectangle ||
                          _isDrawingFib,
                      activeColor: const Color(0xFF00A3A8),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 17,
                        color: (_showDrawingToolbar ||
                                _isDrawingHorizontalLine ||
                                _isDrawingTrendline ||
                                _isDrawingRectangle ||
                                _isDrawingFib)
                            ? const Color(0xFF00A3A8)
                            : (isDark ? const Color(0xFFD8D8D8) : const Color(0xFF373737)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  children: [
                    TvChartWidget(
                      candles: candles,
                      payload: p.ihsgChartPayload,
                      isCandle: _isCandle,
                      showSma: _showSma,
                      showRsi: _showRsi,
                      showVolume: _showVolume,
                      showFibonacci: _showFibonacci,
                      isDrawingFib: _isDrawingFib,
                      onFibDrawn: () {
                        if (mounted && _isDrawingFib) {
                          setState(() => _isDrawingFib = false);
                        }
                      },
                      horizontalLines: _horizontalLines,
                      isDrawingHorizontalLine: _isDrawingHorizontalLine,
                      onHorizontalLineAdded: (double price) {
                        if (mounted) {
                          setState(() {
                            _isDrawingHorizontalLine = false;
                          });
                        }
                      },
                      onHorizontalLinesChanged: (List<double> updated) {
                        if (mounted) {
                          setState(() {
                            _horizontalLines = List<double>.from(updated);
                            _isDrawingHorizontalLine = false;
                          });
                        }
                      },
                      trendlines: _trendlines,
                      isDrawingTrendline: _isDrawingTrendline,
                      onTrendlineAdded: (Map<String, dynamic> line) {
                        if (mounted) {
                          setState(() {
                            _isDrawingTrendline = false;
                          });
                        }
                      },
                      onTrendlinesChanged: (List<Map<String, dynamic>> updated) {
                        if (mounted) {
                          setState(() {
                            _trendlines = List<Map<String, dynamic>>.from(updated);
                            _isDrawingTrendline = false;
                          });
                        }
                      },
                      rectangles: _rectangles,
                      isDrawingRectangle: _isDrawingRectangle,
                      onRectangleAdded: (Map<String, dynamic> rect) {
                        if (mounted) {
                          setState(() {
                            _isDrawingRectangle = false;
                          });
                        }
                      },
                      onRectanglesChanged: (List<Map<String, dynamic>> updated) {
                        if (mounted) {
                          setState(() {
                            _rectangles = List<Map<String, dynamic>>.from(updated);
                            _isDrawingRectangle = false;
                          });
                        }
                      },
                      upColor: upColor,
                      downColor: downColor,
                      gridColor: cs.outline.withValues(alpha: .15),
                      crosshairColor: t.brightness == Brightness.dark
                          ? const Color(0xFFD1D4DC)
                          : const Color(0xFF4A4E5A),
                      liveBar: liveBar,
                      interactive: true,
                      onCrosshairMove: (Map<String, dynamic>? v) =>
                          setState(() => _crosshair = v),
                    ),

                    // Active Drawing Prompt Banner (Memberikan instruksi saat user sedang menggambar)
                    if (_isDrawingHorizontalLine || _isDrawingTrendline || _isDrawingRectangle || _isDrawingFib)
                      Positioned(
                        top: 10,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isDrawingHorizontalLine
                                  ? const Color(0xFF00E5FF)
                                  : _isDrawingTrendline
                                      ? const Color(0xFF00A3A8)
                                      : _isDrawingRectangle
                                          ? const Color(0xFFAB47BC)
                                          : const Color(0xFFFFB300),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                size: 16,
                                color: _isDrawingHorizontalLine
                                    ? const Color(0xFF00E5FF)
                                    : _isDrawingTrendline
                                        ? const Color(0xFF00A3A8)
                                        : _isDrawingRectangle
                                            ? const Color(0xFFAB47BC)
                                            : const Color(0xFFFFB300),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isDrawingHorizontalLine
                                      ? 'Ketuk chart untuk menaruh garis Support/Resistance'
                                      : _isDrawingTrendline
                                          ? 'Ketuk titik 1 lalu titik 2 untuk menarik Trendline'
                                          : _isDrawingRectangle
                                              ? 'Ketuk sudut 1 lalu sudut 2 untuk membuat Box Area'
                                              : 'Tarik dari titik asal ke puncak untuk Fibonacci',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isDrawingHorizontalLine = false;
                                    _isDrawingTrendline = false;
                                    _isDrawingRectangle = false;
                                    _isDrawingFib = false;
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.close, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Floating Drawing Toolbar (Muncul saat tombol ✏️ diaktifkan)
                    if (_showDrawingToolbar)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: _DrawingToolbar(
                            showFib: _showFibonacci,
                            isDrawingFib: _isDrawingFib,
                            onToggleFib: _toggleFibonacci,
                            isDrawingHLine: _isDrawingHorizontalLine,
                            onToggleHLine: () {
                              if (_isDrawingHorizontalLine) {
                                setState(() => _isDrawingHorizontalLine = false);
                              } else {
                                _startDrawingHorizontalLine();
                              }
                            },
                            isDrawingTrendline: _isDrawingTrendline,
                            onToggleTrendline: () {
                              if (_isDrawingTrendline) {
                                setState(() => _isDrawingTrendline = false);
                              } else {
                                _startDrawingTrendline();
                              }
                            },
                            isDrawingRectangle: _isDrawingRectangle,
                            onToggleRectangle: () {
                              if (_isDrawingRectangle) {
                                setState(() => _isDrawingRectangle = false);
                              } else {
                                _startDrawingRectangle();
                              }
                            },
                            hasDrawings: _showFibonacci ||
                                _horizontalLines.isNotEmpty ||
                                _trendlines.isNotEmpty ||
                                _rectangles.isNotEmpty,
                            onClearAll: _clearAllDrawings,
                            onClose: () {
                              setState(() {
                                _showDrawingToolbar = false;
                                _isDrawingHorizontalLine = false;
                                _isDrawingTrendline = false;
                                _isDrawingRectangle = false;
                                _isDrawingFib = false;
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;
  final Widget child;
  final String? tooltip;

  const _ActionButton({
    required this.onTap,
    required this.isActive,
    required this.activeColor,
    required this.child,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color inactiveBg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F4);
    final Color inactiveBorder = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    Widget btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.15) : inactiveBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? activeColor : inactiveBorder,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

class _DrawingToolbar extends StatelessWidget {
  final bool showFib;
  final bool isDrawingFib;
  final VoidCallback onToggleFib;
  final bool isDrawingHLine;
  final VoidCallback onToggleHLine;
  final bool isDrawingTrendline;
  final VoidCallback onToggleTrendline;
  final bool isDrawingRectangle;
  final VoidCallback onToggleRectangle;
  final bool hasDrawings;
  final VoidCallback onClearAll;
  final VoidCallback onClose;

  const _DrawingToolbar({
    required this.showFib,
    required this.isDrawingFib,
    required this.onToggleFib,
    required this.isDrawingHLine,
    required this.onToggleHLine,
    required this.isDrawingTrendline,
    required this.onToggleTrendline,
    required this.isDrawingRectangle,
    required this.onToggleRectangle,
    required this.hasDrawings,
    required this.onClearAll,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // TradingView Charcoal background: #1E222D in dark mode, pure white in light mode
    final Color toolbarBg = isDark ? const Color(0xFF1E222D) : Colors.white;
    final Color toolbarBorder = isDark ? const Color(0xFF363A45) : const Color(0xFFE0E3EB);
    final Color dividerColor = isDark ? const Color(0xFF363A45) : const Color(0xFFE0E3EB);

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: toolbarBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: toolbarBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolButton(
              icon: Icons.architecture,
              label: 'FIB',
              color: const Color(0xFFFFB300),
              isSelected: showFib || isDrawingFib,
              onTap: onToggleFib,
            ),
            const SizedBox(width: 5),
            _ToolButton(
              icon: Icons.horizontal_rule,
              label: 'S/R',
              color: const Color(0xFF00E5FF),
              isSelected: isDrawingHLine,
              onTap: onToggleHLine,
            ),
            const SizedBox(width: 5),
            _ToolButton(
              icon: Icons.trending_up,
              label: 'TL',
              color: const Color(0xFF00A3A8),
              isSelected: isDrawingTrendline,
              onTap: onToggleTrendline,
            ),
            const SizedBox(width: 5),
            _ToolButton(
              icon: Icons.crop_square_rounded,
              label: 'BOX',
              color: const Color(0xFFAB47BC),
              isSelected: isDrawingRectangle,
              onTap: onToggleRectangle,
            ),
            const SizedBox(width: 6),
            Container(
              width: 1,
              height: 20,
              color: dividerColor,
            ),
            const SizedBox(width: 2),
            // Clear all annotations
            IconButton(
              tooltip: 'Hapus Semua Garis',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(4),
              icon: Icon(
                Icons.delete_sweep_outlined,
                size: 19,
                color: hasDrawings ? Colors.red.shade400 : (isDark ? const Color(0xFF787B86) : const Color(0xFFBDBDBD)),
              ),
              onPressed: hasDrawings ? onClearAll : null,
            ),
            // Close toolbar
            IconButton(
              tooltip: 'Tutup Toolbar',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(4),
              icon: Icon(
                Icons.close,
                size: 17,
                color: isDark ? const Color(0xFFB2B5BE) : const Color(0xFF616161),
              ),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color unselectedBorder = isDark ? const Color(0xFF363A45) : const Color(0xFFE0E3EB);
    final Color unselectedBg = isDark ? const Color(0xFF2A2E39) : const Color(0xFFF0F3FA);
    final Color unselectedContent = isDark ? const Color(0xFFB2B5BE) : const Color(0xFF50535E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.18) : unselectedBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : unselectedBorder,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: isSelected ? color : unselectedContent),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? color : unselectedContent,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Map<String, dynamic>? crosshair;
  final Ohlc? fallback;
  const _Legend({required this.crosshair, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final num? o = crosshair?['open'] as num? ?? fallback?.open;
    final num? h = crosshair?['high'] as num? ?? fallback?.high;
    final num? l = crosshair?['low'] as num? ?? fallback?.low;
    final num? c = crosshair?['close'] as num? ?? fallback?.close;
    if (o == null) return const SizedBox.shrink();

    Widget kv(String k, num? v) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text('$k ${v != null ? v.toStringAsFixed(0) : '-'}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        );

    return Row(children: [kv('O', o), kv('H', h), kv('L', l), kv('C', c)]);
  }
}

class _DrawingToolItem {
  final String id;
  final String title;
  final String category;
  final Widget Function(Color color) iconBuilder;
  final bool isFavorite;
  final bool isSelected;
  final VoidCallback onSelect;

  const _DrawingToolItem({
    required this.id,
    required this.title,
    required this.category,
    required this.iconBuilder,
    required this.isFavorite,
    required this.isSelected,
    required this.onSelect,
  });
}

// Vector Custom Icons inspired by TradingView Mobile
class _TrendlineVectorIcon extends StatelessWidget {
  final Color color;
  const _TrendlineVectorIcon({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _TrendlinePainter(color),
    );
  }
}

class _TrendlinePainter extends CustomPainter {
  final Color color;
  _TrendlinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final Paint dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const Offset p1 = Offset(4, 19);
    const Offset p2 = Offset(20, 5);

    canvas.drawLine(p1, p2, linePaint);
    canvas.drawCircle(p1, 2.4, dotPaint);
    canvas.drawCircle(p2, 2.4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TrendlinePainter oldDelegate) => oldDelegate.color != color;
}

class _HLineVectorIcon extends StatelessWidget {
  final Color color;
  const _HLineVectorIcon({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _HLinePainter(color),
    );
  }
}

class _HLinePainter extends CustomPainter {
  final Color color;
  _HLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final Paint dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const Offset p1 = Offset(3, 12);
    const Offset p2 = Offset(21, 12);
    const Offset center = Offset(12, 12);

    canvas.drawLine(p1, p2, linePaint);
    canvas.drawCircle(center, 2.4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _HLinePainter oldDelegate) => oldDelegate.color != color;
}

class _FibVectorIcon extends StatelessWidget {
  final Color color;
  const _FibVectorIcon({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _FibPainter(color),
    );
  }
}

class _FibPainter extends CustomPainter {
  final Color color;
  _FibPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Paint dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 3 horizontal level lines
    canvas.drawLine(const Offset(6, 6), const Offset(21, 6), linePaint);
    canvas.drawLine(const Offset(6, 12), const Offset(21, 12), linePaint);
    canvas.drawLine(const Offset(6, 18), const Offset(21, 18), linePaint);

    // Anchor points
    canvas.drawCircle(const Offset(6, 6), 2.0, dotPaint);
    canvas.drawCircle(const Offset(6, 18), 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _FibPainter oldDelegate) => oldDelegate.color != color;
}

class _RectVectorIcon extends StatelessWidget {
  final Color color;
  const _RectVectorIcon({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _RectPainter(color),
    );
  }
}

class _RectPainter extends CustomPainter {
  final Color color;
  _RectPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final Paint fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final RRect rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 5, 18, 14),
      const Radius.circular(3),
    );

    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _RectPainter oldDelegate) => oldDelegate.color != color;
}