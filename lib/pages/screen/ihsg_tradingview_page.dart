import 'dart:math' as math;
import 'package:cuan_app/components/chart_indicators_legend.dart';
import 'package:cuan_app/components/indicators_modal_sheet.dart';
import 'package:cuan_app/components/sma_settings_modal.dart';
import 'package:cuan_app/components/tv_chart_widget.dart';
import 'package:cuan_app/data/model/active_chart_indicator.dart';
import 'package:cuan_app/data/model/candle_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stocks_provider.dart';
import 'home_page.dart'
    show Ohlc, makeDummyCandles; // reuse model & helper yg udah ada

class IhsgTradingViewPage extends StatefulWidget {
  const IhsgTradingViewPage({super.key});

  @override
  State<IhsgTradingViewPage> createState() => _IhsgTradingViewPageState();
}

class _IhsgTradingViewPageState extends State<IhsgTradingViewPage> {
  bool _isCandle = true;
  final List<ActiveChartIndicator> _activeIndicators = <ActiveChartIndicator>[];
  bool _showSma = false;
  bool _showRsi = false;
  bool _showVolume = false;
  bool _visibleSma = true;
  bool _visibleRsi = true;
  bool _visibleVolume = true;
  bool _showFibonacci = false;
  bool _isDrawingFib = false;
  List<Map<String, dynamic>> _horizontalLines = <Map<String, dynamic>>[];
  bool _isDrawingHorizontalLine = false;
  List<Map<String, dynamic>> _trendlines = <Map<String, dynamic>>[];
  bool _isDrawingTrendline = false;
  List<Map<String, dynamic>> _rectangles = <Map<String, dynamic>>[];
  bool _isDrawingRectangle = false;
  bool _isChartModalOpen = false;
  bool _showDrawingToolbar = false;
  Map<String, dynamic>? _crosshair;
  String? _selectedLegendIndicatorId;
  final Set<String> _favoriteIndicators = <String>{
    'Moving Average',
    'Relative Strength Index',
    'Volume',
  };
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StocksProvider>().fetchTvCandles();
    });
  }

  int get _activeIndicatorsCount => _activeIndicators.length;

  void _startDrawingFibonacci() {
    setState(() {
      _isDrawingHorizontalLine = false;
      _isDrawingTrendline = false;
      _isDrawingRectangle = false;
      _showFibonacci = true;
      _isDrawingFib = true;
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
      _horizontalLines = <Map<String, dynamic>>[];
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
        final bool hasDrawings =
            _showFibonacci ||
            _horizontalLines.isNotEmpty ||
            _trendlines.isNotEmpty ||
            _rectangles.isNotEmpty;

        return _DrawingsBottomSheetWidget(
          isDrawingTrendline: _isDrawingTrendline,
          isDrawingHorizontalLine: _isDrawingHorizontalLine,
          showFibonacci: _showFibonacci,
          isDrawingFib: _isDrawingFib,
          isDrawingRectangle: _isDrawingRectangle,
          showDrawingToolbar: _showDrawingToolbar,
          hasDrawings: hasDrawings,
          onSelectTrendline: () {
            Navigator.of(sheetContext).pop();
            _startDrawingTrendline();
          },
          onSelectHorizontalLine: () {
            Navigator.of(sheetContext).pop();
            _startDrawingHorizontalLine();
          },
          onSelectFibonacci: () {
            Navigator.of(sheetContext).pop();
            _startDrawingFibonacci();
          },
          onSelectRectangle: () {
            Navigator.of(sheetContext).pop();
            _startDrawingRectangle();
          },
          onClearAllDrawings: () {
            Navigator.of(sheetContext).pop();
            _clearAllDrawings();
          },
          onToggleDrawingToolbar: (bool val) {
            setState(() => _showDrawingToolbar = val);
          },
        );
      },
    );
  }

  void _syncLegacyIndicators() {
    final List<ActiveChartIndicator> activeSmas = _activeIndicators
        .where((ActiveChartIndicator i) => i.type == 'sma')
        .toList();
    final List<ActiveChartIndicator> activeRsis = _activeIndicators
        .where((ActiveChartIndicator i) => i.type == 'rsi')
        .toList();
    final List<ActiveChartIndicator> activeVols = _activeIndicators
        .where((ActiveChartIndicator i) => i.type == 'vol')
        .toList();

    _showSma = activeSmas.isNotEmpty;
    _visibleSma = activeSmas.any((ActiveChartIndicator i) => i.isVisible);

    _showRsi = activeRsis.isNotEmpty;
    _visibleRsi = activeRsis.any((ActiveChartIndicator i) => i.isVisible);

    _showVolume = activeVols.isNotEmpty;
    _visibleVolume = activeVols.any((ActiveChartIndicator i) => i.isVisible);
  }

  void _addIndicator(String id) {
    setState(() {
      final int count = _activeIndicators
          .where((ActiveChartIndicator i) => i.type == id)
          .length;
      final String suffix = count > 0 ? ' ${count + 1}' : '';
      if (id == 'sma') {
        const int period = 20;
        _activeIndicators.add(
          ActiveChartIndicator(
            id: 'sma_${DateTime.now().microsecondsSinceEpoch}',
            type: 'sma',
            title: 'SMA $period close$suffix',
            period: period,
          ),
        );
      } else if (id == 'rsi') {
        const int period = 14;
        _activeIndicators.add(
          ActiveChartIndicator(
            id: 'rsi_${DateTime.now().microsecondsSinceEpoch}',
            type: 'rsi',
            title: 'RSI $period close$suffix',
            period: period,
          ),
        );
      } else if (id == 'vol') {
        _activeIndicators.add(
          ActiveChartIndicator(
            id: 'vol_${DateTime.now().microsecondsSinceEpoch}',
            type: 'vol',
            title: 'Vol$suffix',
          ),
        );
      }
      _syncLegacyIndicators();
    });
  }

  void _toggleIndicatorVisibility(String id) {
    setState(() {
      final int idx = _activeIndicators.indexWhere(
        (ActiveChartIndicator i) => i.id == id,
      );
      if (idx != -1) {
        final ActiveChartIndicator item = _activeIndicators[idx];
        _activeIndicators[idx] = item.copyWith(isVisible: !item.isVisible);
      }
      _syncLegacyIndicators();
    });
  }

  void _deleteIndicator(String id) {
    setState(() {
      _activeIndicators.removeWhere((ActiveChartIndicator i) => i.id == id);
      if (_selectedLegendIndicatorId == id) {
        _selectedLegendIndicatorId = null;
      }
      _syncLegacyIndicators();
    });
  }

  void _showIndicatorsBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return IndicatorsModalSheet(
          showSma: _showSma,
          showRsi: _showRsi,
          showVolume: _showVolume,
          showFibonacci: _showFibonacci,
          favoriteIndicators: _favoriteIndicators,
          onAddIndicator: (String id) => _addIndicator(id),
          onToggleFavorite: (String name) {
            setState(() {
              if (_favoriteIndicators.contains(name)) {
                _favoriteIndicators.remove(name);
              } else {
                _favoriteIndicators.add(name);
              }
            });
          },
          onToggleSma: (bool val) => setState(() {
            _showSma = val;
            if (val) _visibleSma = true;
          }),
          onToggleRsi: (bool val) => setState(() {
            _showRsi = val;
            if (val) _visibleRsi = true;
          }),
          onToggleVolume: (bool val) => setState(() {
            _showVolume = val;
            if (val) _visibleVolume = true;
          }),
          onToggleFibonacci: (bool val) => setState(() => _showFibonacci = val),
        );
      },
    );
  }

  void _openIndicatorSettings(String id) {
    ActiveChartIndicator? indicator;
    final int idx = _activeIndicators.indexWhere(
      (ActiveChartIndicator i) => i.id == id,
    );
    if (idx != -1) {
      indicator = _activeIndicators[idx];
    } else if (id == 'sma' || id.startsWith('sma')) {
      final int smaIdx = _activeIndicators.indexWhere(
        (ActiveChartIndicator i) => i.type == 'sma',
      );
      if (smaIdx != -1) {
        indicator = _activeIndicators[smaIdx];
      } else {
        indicator = ActiveChartIndicator(
          id: 'sma_${DateTime.now().microsecondsSinceEpoch}',
          type: 'sma',
          title: 'SMA 20 close',
          period: 20,
        );
      }
    }

    if (indicator != null && indicator.type == 'sma') {
      SmaSettingsModal.show(
        context: context,
        indicator: indicator,
        onSave: (ActiveChartIndicator updated) {
          setState(() {
            final int targetIdx = _activeIndicators.indexWhere(
              (ActiveChartIndicator i) => i.id == updated.id,
            );
            if (targetIdx != -1) {
              _activeIndicators[targetIdx] = updated;
            } else {
              _activeIndicators.add(updated);
            }
            _syncLegacyIndicators();
          });
        },
      );
      return;
    }

    final String title = id == 'sma'
        ? 'Moving Average (SMA)'
        : id == 'rsi'
        ? 'Relative Strength Index (RSI)'
        : 'Volume';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetCtx) {
        final bool isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E222D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Customization untuk $title akan dikonfigurasi di langkah berikutnya.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFFD1D4DC)
                        : const Color(0xFF4A4E5A),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
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
            tooltip: _isCandle
                ? 'Ganti ke Area Chart'
                : 'Ganti ke Candle Chart',
            onPressed: () => setState(() => _isCandle = !_isCandle),
          ),
        ],
      ),
      body: Consumer<StocksProvider>(
        builder: (BuildContext context, StocksProvider p, _) {
          final List<Ohlc> rawCandles =
              (p.tvChartPayload?.candles.isNotEmpty == true)
              ? p.tvChartPayload!.candles
              : p.tvCandles
                    .map(
                      (CandleItem c) => Ohlc(
                        time: c.ts,
                        open: c.open ?? c.close ?? 0,
                        high: c.high ?? c.close ?? 0,
                        low: c.low ?? c.close ?? 0,
                        close: c.close ?? 0,
                        volume: (c.volume ?? 0).toDouble(),
                      ),
                    )
                    .toList();
          // (p.ihsgChartPayload?.candles.isNotEmpty == true)
          // ? p.ihsgChartPayload!.candles
          // : p.ihsgCandles
          //       .map(
          //         (CandleItem c) => Ohlc(
          //           time: c.ts,
          //           open: c.open ?? c.close ?? 0,
          //           high: c.high ?? c.close ?? 0,
          //           low: c.low ?? c.close ?? 0,
          //           close: c.close ?? 0,
          //           volume: (c.volume ?? 0).toDouble(),
          //         ),
          //       )
          //       .toList();
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _Legend(
                  crosshair: _crosshair,
                  fallback:
                      liveBar ?? (candles.isNotEmpty ? candles.last : null),
                ),
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
                          children: ['1D', '1W', '1M']
                              .map(
                                (String r) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(r),
                                    selected: p.tvResolution == r,
                                    onSelected: (_) => p.setTvResolution(r),
                                  ),
                                ),
                              )
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
                                  : (isDark
                                        ? const Color(0xFFD8D8D8)
                                        : const Color(0xFF373737)),
                            ),
                          ),
                          if (_activeIndicatorsCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
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
                      isActive:
                          _showDrawingToolbar ||
                          _isDrawingHorizontalLine ||
                          _isDrawingTrendline ||
                          _isDrawingRectangle ||
                          _isDrawingFib,
                      activeColor: const Color(0xFF00A3A8),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 17,
                        color:
                            (_showDrawingToolbar ||
                                _isDrawingHorizontalLine ||
                                _isDrawingTrendline ||
                                _isDrawingRectangle ||
                                _isDrawingFib)
                            ? const Color(0xFF00A3A8)
                            : (isDark
                                  ? const Color(0xFFD8D8D8)
                                  : const Color(0xFF373737)),
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
                      symbol: 'IHSG',
                      timeframe: p.tvResolution,
                      candles: candles,
                      payload: p.tvChartPayload,
                      isCandle: _isCandle,
                      activeIndicators: List<ActiveChartIndicator>.from(
                        _activeIndicators,
                      ),
                      showSma: _showSma && _visibleSma,
                      showRsi: _showRsi && _visibleRsi,
                      showVolume: _showVolume && _visibleVolume,
                      showFibonacci: _showFibonacci,
                      isDrawingFib: _isDrawingFib,
                      onFibDrawn: () {
                        if (mounted && _isDrawingFib) {
                          setState(() => _isDrawingFib = false);
                        }
                      },
                      onFibDeleted: () {
                        if (mounted) {
                          setState(() {
                            _showFibonacci = false;
                            _isDrawingFib = false;
                          });
                        }
                      },
                      horizontalLines: _horizontalLines,
                      isDrawingHorizontalLine: _isDrawingHorizontalLine,
                      onHorizontalLineAdded: (dynamic item) {
                        if (mounted) {
                          setState(() {
                            _isDrawingHorizontalLine = false;
                          });
                        }
                      },
                      onHorizontalLinesChanged:
                          (List<Map<String, dynamic>> updated) {
                            if (mounted) {
                              setState(() {
                                _horizontalLines =
                                    List<Map<String, dynamic>>.from(updated);
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
                      onTrendlinesChanged:
                          (List<Map<String, dynamic>> updated) {
                            if (mounted) {
                              setState(() {
                                _trendlines = List<Map<String, dynamic>>.from(
                                  updated,
                                );
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
                      onRectanglesChanged:
                          (List<Map<String, dynamic>> updated) {
                            if (mounted) {
                              setState(() {
                                _rectangles = List<Map<String, dynamic>>.from(
                                  updated,
                                );
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
                      onChartModalStateChanged: (bool isOpen) =>
                          setState(() => _isChartModalOpen = isOpen),
                    ),

                    // Tap-outside detector saat ada indikator legend yang sedang terseleksi
                    if (!_isChartModalOpen &&
                        _selectedLegendIndicatorId != null)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            setState(() {
                              _selectedLegendIndicatorId = null;
                            });
                          },
                        ),
                      ),

                    // Active Indicators Legend di Pojok Kiri Atas Chart (ala TradingView)
                    if (!_isChartModalOpen)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: ChartIndicatorsLegend(
                          selectedId: _selectedLegendIndicatorId,
                          onSelectionChanged: (String? id) =>
                              setState(() => _selectedLegendIndicatorId = id),
                          activeIndicators: _activeIndicators,
                          onToggleIndicatorVisibility:
                              _toggleIndicatorVisibility,
                          onDeleteIndicator: _deleteIndicator,
                          showSma: _showSma,
                          showRsi: _showRsi,
                          showVolume: _showVolume,
                          visibleSma: _visibleSma,
                          visibleRsi: _visibleRsi,
                          visibleVolume: _visibleVolume,
                          onToggleVisibilitySma: (bool val) =>
                              setState(() => _visibleSma = val),
                          onToggleVisibilityRsi: (bool val) =>
                              setState(() => _visibleRsi = val),
                          onToggleVisibilityVolume: (bool val) =>
                              setState(() => _visibleVolume = val),
                          onDeleteSma: () => setState(() {
                            _showSma = false;
                            _visibleSma = true;
                          }),
                          onDeleteRsi: () => setState(() {
                            _showRsi = false;
                            _visibleRsi = true;
                          }),
                          onDeleteVolume: () => setState(() {
                            _showVolume = false;
                            _visibleVolume = true;
                          }),
                          symbol: 'IHSG',
                          timeframe: p.tvResolution,
                          onOpenSettings: (String id) =>
                              _openIndicatorSettings(id),
                        ),
                      ),

                    // Active Drawing Prompt Banner (Memberikan instruksi saat user sedang menggambar)
                    if (_isDrawingHorizontalLine ||
                        _isDrawingTrendline ||
                        _isDrawingRectangle ||
                        _isDrawingFib)
                      Positioned(
                        top: 10,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFE0E3EB),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.35 : 0.08,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                size: 16,
                                color: isDark
                                    ? const Color(0xFFD8D8D8)
                                    : const Color(0xFF373737),
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
                                    color: isDark
                                        ? const Color(0xFFD8D8D8)
                                        : const Color(0xFF373737),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: isDark
                                        ? const Color(0xFF868993)
                                        : const Color(0xFF787B86),
                                  ),
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
                            onToggleFib: () {
                              if (_isDrawingFib) {
                                setState(() => _isDrawingFib = false);
                              } else {
                                _startDrawingFibonacci();
                              }
                            },
                            isDrawingHLine: _isDrawingHorizontalLine,
                            onToggleHLine: () {
                              if (_isDrawingHorizontalLine) {
                                setState(
                                  () => _isDrawingHorizontalLine = false,
                                );
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
                            hasDrawings:
                                _showFibonacci ||
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
    final Color inactiveBg = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF2F2F4);
    final Color inactiveBorder = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);

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

class _DragHandleWidget extends StatelessWidget {
  final Color color;
  const _DragHandleWidget({this.color = const Color(0xFF787B86)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 2.8,
                  height: 2.8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 2.8),
                Container(
                  width: 2.8,
                  height: 2.8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _FavoriteToolButton extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _FavoriteToolButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color selectedBg = isDark
        ? const Color(0xFF2A2E39)
        : const Color(0xFFE0E3EB);
    final Color selectedBorder = const Color(0xFF2962FF);

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: selectedBorder, width: 1.2)
                  : null,
            ),
            child: icon,
          ),
        ),
      ),
    );
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

    // Neutral Charcoal/Black background matching chart: #1E1E1E in dark mode, pure white in light mode
    final Color toolbarBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color toolbarBorder = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE0E3EB);
    final Color dividerColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE0E3EB);
    final Color defaultIconColor = isDark
        ? const Color(0xFFD8D8D8)
        : const Color(0xFF50535E);
    final Color activeIconColor = const Color(0xFF2962FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: toolbarBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: toolbarBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle grip (TradingView style 6 dots :::)
            _DragHandleWidget(
              color: isDark ? const Color(0xFF636670) : const Color(0xFF9598A1),
            ),
            const SizedBox(width: 4),

            // Rectangle (Box Area)
            _FavoriteToolButton(
              tooltip: 'Rectangle',
              isSelected: isDrawingRectangle,
              onTap: onToggleRectangle,
              icon: _RectVectorIcon(
                color: isDrawingRectangle ? activeIconColor : defaultIconColor,
              ),
            ),
            const SizedBox(width: 2),

            // Trendline
            _FavoriteToolButton(
              tooltip: 'Trendline',
              isSelected: isDrawingTrendline,
              onTap: onToggleTrendline,
              icon: _TrendlineVectorIcon(
                color: isDrawingTrendline ? activeIconColor : defaultIconColor,
              ),
            ),
            const SizedBox(width: 2),

            // Horizontal Line (Support/Resistance)
            _FavoriteToolButton(
              tooltip: 'Horizontal line',
              isSelected: isDrawingHLine,
              onTap: onToggleHLine,
              icon: _HLineVectorIcon(
                color: isDrawingHLine ? activeIconColor : defaultIconColor,
              ),
            ),
            const SizedBox(width: 2),

            // Fibonacci Retracement
            _FavoriteToolButton(
              tooltip: 'Fib retracement',
              isSelected: isDrawingFib,
              onTap: onToggleFib,
              icon: _FibVectorIcon(
                color: isDrawingFib ? activeIconColor : defaultIconColor,
              ),
            ),
            const SizedBox(width: 4),

            // Divider
            Container(width: 1, height: 20, color: dividerColor),
            const SizedBox(width: 2),

            // Clear all annotations
            IconButton(
              tooltip: 'Hapus Semua Garis',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              padding: const EdgeInsets.all(4),
              icon: Icon(
                Icons.delete_sweep_outlined,
                size: 19,
                color: hasDrawings
                    ? Colors.red.shade400
                    : (isDark
                          ? const Color(0xFF636670)
                          : const Color(0xFFBDBDBD)),
              ),
              onPressed: hasDrawings ? onClearAll : null,
            ),

            // Close / Hide toolbar
            IconButton(
              tooltip: 'Tutup Toolbar',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              padding: const EdgeInsets.all(4),
              icon: Icon(
                Icons.close,
                size: 17,
                color: isDark
                    ? const Color(0xFFB2B5BE)
                    : const Color(0xFF616161),
              ),
              onPressed: onClose,
            ),
          ],
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
      child: Text(
        '$k ${v != null ? v.toStringAsFixed(0) : '-'}',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
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

    final Paint ringPaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    const double r = 2.2;
    const Offset p1 = Offset(4.5, 19.5);
    const Offset p2 = Offset(19.5, 4.5);

    // 45 degree diagonal unit step: r / sqrt(2) ≈ 1.56
    const double delta = 1.56;
    const Offset lineStart = Offset(4.5 + delta, 19.5 - delta);
    const Offset lineEnd = Offset(19.5 - delta, 4.5 + delta);

    canvas.drawLine(lineStart, lineEnd, linePaint);
    canvas.drawCircle(p1, r, ringPaint);
    canvas.drawCircle(p2, r, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _TrendlinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HLineVectorIcon extends StatelessWidget {
  final Color color;
  const _HLineVectorIcon({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _HLinePainter(color));
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

    final Paint ringPaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    const double r = 2.2;
    const Offset center = Offset(12.0, 12.0);

    // Left line up to ring perimeter
    canvas.drawLine(const Offset(3.0, 12.0), Offset(12.0 - r, 12.0), linePaint);
    // Right line from ring perimeter
    canvas.drawLine(
      Offset(12.0 + r, 12.0),
      const Offset(21.0, 12.0),
      linePaint,
    );
    // Center hollow anchor ring
    canvas.drawCircle(center, r, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _HLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _FibVectorIcon extends StatelessWidget {
  final Color color;
  const _FibVectorIcon({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _FibPainter(color));
  }
}

class _FibPainter extends CustomPainter {
  final Color color;
  _FibPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint ringPaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    const double r = 2.2;
    const double xLeft = 3.5;
    const double xRight = 20.5;

    // 4 horizontal parallel levels
    // Line 1: plain top line
    canvas.drawLine(
      const Offset(xLeft, 4.5),
      const Offset(xRight, 4.5),
      linePaint,
    );

    // Line 2: line with hollow anchor ring on the right
    const double circle2CenterX = xRight - r; // 18.3
    canvas.drawLine(
      const Offset(xLeft, 9.5),
      const Offset(circle2CenterX - r, 9.5),
      linePaint,
    );
    canvas.drawCircle(const Offset(circle2CenterX, 9.5), r, ringPaint);

    // Line 3: plain middle line
    canvas.drawLine(
      const Offset(xLeft, 14.5),
      const Offset(xRight, 14.5),
      linePaint,
    );

    // Line 4: line with hollow anchor ring on the left
    const double circle4CenterX = xLeft + r; // 5.7
    canvas.drawCircle(const Offset(circle4CenterX, 19.5), r, ringPaint);
    canvas.drawLine(
      const Offset(circle4CenterX + r, 19.5),
      const Offset(xRight, 19.5),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FibPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RectVectorIcon extends StatelessWidget {
  final Color color;
  const _RectVectorIcon({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _RectPainter(color));
  }
}

class _RectPainter extends CustomPainter {
  final Color color;
  _RectPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final Paint ringPaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    const double r = 2.2;
    const double x1 = 5.0;
    const double x2 = 19.0;
    const double y1 = 5.0;
    const double y2 = 19.0;

    // 4 edges connecting the corner rings (without bleeding into ring holes)
    canvas.drawLine(
      const Offset(x1 + r, y1),
      const Offset(x2 - r, y1),
      strokePaint,
    ); // Top
    canvas.drawLine(
      const Offset(x1 + r, y2),
      const Offset(x2 - r, y2),
      strokePaint,
    ); // Bottom
    canvas.drawLine(
      const Offset(x1, y1 + r),
      const Offset(x1, y2 - r),
      strokePaint,
    ); // Left
    canvas.drawLine(
      const Offset(x2, y1 + r),
      const Offset(x2, y2 - r),
      strokePaint,
    ); // Right

    // 4 corner hollow anchor rings
    canvas.drawCircle(const Offset(x1, y1), r, ringPaint); // Top-Left
    canvas.drawCircle(const Offset(x2, y1), r, ringPaint); // Top-Right
    canvas.drawCircle(const Offset(x1, y2), r, ringPaint); // Bottom-Left
    canvas.drawCircle(const Offset(x2, y2), r, ringPaint); // Bottom-Right
  }

  @override
  bool shouldRepaint(covariant _RectPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DrawingsBottomSheetWidget extends StatefulWidget {
  final bool isDrawingTrendline;
  final bool isDrawingHorizontalLine;
  final bool showFibonacci;
  final bool isDrawingFib;
  final bool isDrawingRectangle;
  final bool showDrawingToolbar;
  final bool hasDrawings;
  final VoidCallback onSelectTrendline;
  final VoidCallback onSelectHorizontalLine;
  final VoidCallback onSelectFibonacci;
  final VoidCallback onSelectRectangle;
  final VoidCallback onClearAllDrawings;
  final ValueChanged<bool> onToggleDrawingToolbar;

  const _DrawingsBottomSheetWidget({
    required this.isDrawingTrendline,
    required this.isDrawingHorizontalLine,
    required this.showFibonacci,
    required this.isDrawingFib,
    required this.isDrawingRectangle,
    required this.showDrawingToolbar,
    required this.hasDrawings,
    required this.onSelectTrendline,
    required this.onSelectHorizontalLine,
    required this.onSelectFibonacci,
    required this.onSelectRectangle,
    required this.onClearAllDrawings,
    required this.onToggleDrawingToolbar,
  });

  @override
  State<_DrawingsBottomSheetWidget> createState() =>
      _DrawingsBottomSheetWidgetState();
}

class _DrawingsBottomSheetWidgetState
    extends State<_DrawingsBottomSheetWidget> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  String _searchQuery = '';
  String _selectedFilter = 'Favorites';
  bool _isSearching = false;
  late bool _showDrawingToolbar;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
    _showDrawingToolbar = widget.showDrawingToolbar;

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isSearching) {
        setState(() => _isSearching = true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _stopSearching() {
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Theme palette harmonized with chart background (#121212 in dark mode)
    final Color sheetBg = isDark ? const Color(0xFF121212) : Colors.white;
    final Color cardBg = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF0F3FA);
    final Color cardBorder = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE0E3EB);
    final Color searchBg = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF0F3FA);
    final Color textColor = isDark ? Colors.white : const Color(0xFF131722);
    final Color subtitleColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF9598A1);
    final Color closeBtnBg = isDark
        ? const Color(0xFF242426)
        : const Color(0xFFF0F3FA);
    final Color iconColor = isDark ? Colors.white : const Color(0xFF131722);
    const Color starColor = Color(0xFFF7A600); // TradingView Amber Star

    final List<_DrawingToolItem> allTools = [
      _DrawingToolItem(
        id: 'trendline',
        title: 'Trendline',
        category: 'TREND TOOLS',
        iconBuilder: (Color c) => _TrendlineVectorIcon(color: c),
        isFavorite: true,
        isSelected: widget.isDrawingTrendline,
        onSelect: widget.onSelectTrendline,
      ),
      _DrawingToolItem(
        id: 'horizontal_line',
        title: 'Horizontal line',
        category: 'TREND TOOLS',
        iconBuilder: (Color c) => _HLineVectorIcon(color: c),
        isFavorite: true,
        isSelected: widget.isDrawingHorizontalLine,
        onSelect: widget.onSelectHorizontalLine,
      ),
      _DrawingToolItem(
        id: 'fib_retracement',
        title: 'Fib retracement',
        category: 'GANN AND FIBONACCI',
        iconBuilder: (Color c) => _FibVectorIcon(color: c),
        isFavorite: true,
        isSelected: widget.isDrawingFib,
        onSelect: widget.onSelectFibonacci,
      ),
      _DrawingToolItem(
        id: 'rectangle',
        title: 'Rectangle',
        category: 'GEOMETRIC SHAPES',
        iconBuilder: (Color c) => _RectVectorIcon(color: c),
        isFavorite: true,
        isSelected: widget.isDrawingRectangle,
        onSelect: widget.onSelectRectangle,
      ),
    ];

    List<_DrawingToolItem> filtered = allTools;
    if (_searchQuery.isNotEmpty) {
      filtered = allTools
          .where(
            (t) =>
                t.title.toLowerCase().contains(_searchQuery) ||
                t.category.toLowerCase().contains(_searchQuery),
          )
          .toList();
    } else if (_selectedFilter == 'Favorites') {
      filtered = allTools.where((t) => t.isFavorite).toList();
    } else if (_selectedFilter == 'Trend tools') {
      filtered = allTools.where((t) => t.category == 'TREND TOOLS').toList();
    } else if (_selectedFilter == 'Gann and...') {
      filtered = allTools
          .where((t) => t.category == 'GANN AND FIBONACCI')
          .toList();
    } else if (_selectedFilter == 'Shapes') {
      filtered = allTools
          .where((t) => t.category == 'GEOMETRIC SHAPES')
          .toList();
    }

    final Map<String, List<_DrawingToolItem>> grouped = {};
    for (final item in filtered) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // When searching or typing, maintain fullscreen height (94%) so it NEVER shrinks
    final double targetHeight = (_isSearching || _searchQuery.isNotEmpty)
        ? screenHeight * 0.94
        : screenHeight * 0.75;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: targetHeight,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE0E3EB),
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
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Pill Handle (only when not in fullscreen search mode)
              if (!_isSearching && _searchQuery.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3E3E42)
                            : const Color(0xFFD1D4DC),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 12),

              // Title & Close/Back Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSearching || _searchQuery.isNotEmpty
                          ? 'Search drawings'
                          : 'Drawings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (_isSearching || _searchQuery.isNotEmpty) {
                          _stopSearching();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: closeBtnBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isSearching || _searchQuery.isNotEmpty
                              ? Icons.arrow_back
                              : Icons.close,
                          size: 18,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: searchBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF131722))
                                : cardBorder,
                            width: _focusNode.hasFocus ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 18, color: subtitleColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                cursorColor: isDark
                                    ? Colors.white
                                    : const Color(0xFF131722),
                                onTap: () {
                                  if (!_isSearching) {
                                    setState(() => _isSearching = true);
                                  }
                                },
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val.trim().toLowerCase();
                                    _isSearching = true;
                                  });
                                },
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: textColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search',
                                  hintStyle: TextStyle(
                                    fontSize: 13.5,
                                    color: subtitleColor,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: subtitleColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_isSearching || _searchQuery.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: _stopSearching,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF131722),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Category Filter Pills (Horizontal scroll) - visible when not searching text
              if (_searchQuery.isEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children:
                        [
                          'Favorites',
                          'Tools',
                          'Trend tools',
                          'Gann and...',
                          'Shapes',
                        ].map((filter) {
                          final bool isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() => _selectedFilter = filter);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                            ? const Color(0xFF2B2B2B)
                                            : const Color(0xFFE0E3EB))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? textColor
                                        : subtitleColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                Divider(height: 1, color: cardBorder),
              ],

              // Scrollable Area: Tool Cards grouped by Category
              // Using Expanded guarantees the view fills all vertical space and never shrinks!
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (grouped.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 36,
                                  color: subtitleColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tidak ada drawing tool yang cocok dengan "$_searchQuery"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
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
                                    return _buildToolCard(
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

              // Bottom Footer: Show favorites on Chart + Hapus Garis (only when not searching)
              if (!_isSearching && _searchQuery.isEmpty) ...[
                Divider(height: 1, color: cardBorder),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
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
                      if (widget.hasDrawings) ...[
                        TextButton.icon(
                          onPressed: widget.onClearAllDrawings,
                          icon: Icon(
                            Icons.delete_sweep_outlined,
                            size: 16,
                            color: Colors.red.shade400,
                          ),
                          label: Text(
                            'Hapus Garis',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Switch(
                        value: _showDrawingToolbar,
                        activeColor: const Color(0xFF2962FF),
                        activeTrackColor: const Color(
                          0xFF2962FF,
                        ).withValues(alpha: 0.35),
                        inactiveThumbColor: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFFD1D4DC),
                        inactiveTrackColor: isDark
                            ? const Color(0xFF2B2B2B)
                            : const Color(0xFFE0E3EB),
                        onChanged: (val) {
                          setState(() => _showDrawingToolbar = val);
                          widget.onToggleDrawingToolbar(val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard({
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
              tool.iconBuilder(
                tool.isSelected ? const Color(0xFF2962FF) : iconColor,
              ),
              // Tool Name
              Text(
                tool.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: tool.isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: tool.isSelected ? const Color(0xFF2962FF) : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
