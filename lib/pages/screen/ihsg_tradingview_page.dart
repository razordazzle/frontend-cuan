import 'dart:math' as math;
import 'package:cuan_app/components/tv_chart_widget.dart';
import 'package:cuan_app/data/model/candle_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stocks_provider.dart';
import 'home_page.dart' show Ohlc; // reuse model & helper yg udah ada

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
  bool _showDrawingToolbar = false;
  Map<String, dynamic>? _crosshair;

  int get _activeIndicatorsCount =>
      (_showSma ? 1 : 0) + (_showRsi ? 1 : 0) + (_showVolume ? 1 : 0);

  void _toggleFibonacci() {
    setState(() {
      _isDrawingHorizontalLine = false;
      _isDrawingTrendline = false;
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
      _isDrawingHorizontalLine = true;
    });
  }

  void _startDrawingTrendline() {
    setState(() {
      _isDrawingFib = false;
      _isDrawingHorizontalLine = false;
      _isDrawingTrendline = true;
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
    });
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
          final List<Ohlc> candles = p.ihsgChartPayload?.candles ??
              p.ihsgCandles
                  .map((CandleItem c) => Ohlc(
                        time: c.ts,
                        open: c.open ?? c.close ?? 0,
                        high: c.high ?? c.close ?? 0,
                        low: c.low ?? c.close ?? 0,
                        close: c.close ?? 0,
                        volume: (c.volume ?? 0).toDouble(),
                      ))
                  .toList();

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
                      tooltip: 'Alat Gambar (Drawing Tools)',
                      onTap: () {
                        setState(() {
                          _showDrawingToolbar = !_showDrawingToolbar;
                          if (!_showDrawingToolbar) {
                            _isDrawingHorizontalLine = false;
                            _isDrawingTrendline = false;
                            _isDrawingFib = false;
                          }
                        });
                      },
                      isActive: _showDrawingToolbar,
                      activeColor: const Color(0xFF00A3A8),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 17,
                        color: _showDrawingToolbar
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
                    if (_isDrawingHorizontalLine || _isDrawingTrendline || _isDrawingFib)
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
                                        : const Color(0xFFFFB300),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isDrawingHorizontalLine
                                      ? 'Ketuk chart untuk menaruh garis Support/Resistance'
                                      : _isDrawingTrendline
                                          ? 'Ketuk titik 1 lalu titik 2 untuk menarik Trendline'
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
                            hasDrawings: _showFibonacci ||
                                _horizontalLines.isNotEmpty ||
                                _trendlines.isNotEmpty,
                            onClearAll: _clearAllDrawings,
                            onClose: () {
                              setState(() {
                                _showDrawingToolbar = false;
                                _isDrawingHorizontalLine = false;
                                _isDrawingTrendline = false;
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
    required this.hasDrawings,
    required this.onClearAll,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Same background color as chart (#121212 in dark mode, white in light mode)
    final Color toolbarBg = isDark ? const Color(0xFF121212) : Colors.white;
    final Color toolbarBorder = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final Color dividerColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: toolbarBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: toolbarBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
          const SizedBox(width: 6),
          _ToolButton(
            icon: Icons.horizontal_rule,
            label: 'S/R',
            color: const Color(0xFF00E5FF),
            isSelected: isDrawingHLine,
            onTap: onToggleHLine,
          ),
          const SizedBox(width: 6),
          _ToolButton(
            icon: Icons.trending_up,
            label: 'TL',
            color: const Color(0xFF00A3A8),
            isSelected: isDrawingTrendline,
            onTap: onToggleTrendline,
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 22,
            color: dividerColor,
          ),
          const SizedBox(width: 4),
          // Clear all annotations
          IconButton(
            tooltip: 'Hapus Semua Garis',
            icon: Icon(
              Icons.delete_sweep_outlined,
              size: 20,
              color: hasDrawings ? Colors.red.shade400 : (isDark ? const Color(0xFF555555) : const Color(0xFFBDBDBD)),
            ),
            onPressed: hasDrawings ? onClearAll : null,
          ),
          // Close toolbar
          IconButton(
            tooltip: 'Tutup Toolbar',
            icon: Icon(
              Icons.close,
              size: 18,
              color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF616161),
            ),
            onPressed: onClose,
          ),
        ],
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
    final Color unselectedBorder = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final Color unselectedContent = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF616161);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : unselectedBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : unselectedContent),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? color : unselectedContent,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
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