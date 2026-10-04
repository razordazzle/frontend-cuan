import 'dart:math' as math;
import 'package:cuan_app/components/chart_indicators_legend.dart';
import 'package:cuan_app/components/drawing_tools.dart';
import 'package:cuan_app/components/indicator_settings_sheet.dart';
import 'package:cuan_app/components/indicators_modal_sheet.dart';
import 'package:cuan_app/components/tv_chart_widget.dart';
import 'package:cuan_app/controllers/chart_drawings_controller.dart';
import 'package:cuan_app/controllers/chart_indicators_controller.dart';
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
  final ChartIndicatorsController _indicators = ChartIndicatorsController();
  final ChartDrawingsController _drawings = ChartDrawingsController();
  late final Listenable _chartState = Listenable.merge(<Listenable>[
    _indicators,
    _drawings,
  ]);
  bool _isCandle = true;
  bool _isChartModalOpen = false;
  Map<String, dynamic>? _crosshair;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StocksProvider>().fetchTvCandles();
    });
  }

  @override
  void dispose() {
    _indicators.dispose();
    _drawings.dispose();
    super.dispose();
  }

  void _showIndicatorsBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IndicatorsModalSheet(
        favoriteIndicators: _indicators.favorites,
        onAddIndicator: _indicators.add,
        onToggleFavorite: _indicators.toggleFavorite,
      ),
    );
  }

  void _openIndicatorSettings(String id) {
    final ActiveChartIndicator? indicator = _indicators.findById(id);
    if (indicator == null) return;
    showIndicatorSettingsSheet(
      context: context,
      indicator: indicator,
      onSave: _indicators.update,
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
      body: ListenableBuilder(
        listenable: _chartState,
        builder: (BuildContext context, _) => Consumer<StocksProvider>(
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
                        isActive: _indicators.count > 0,
                        activeColor: const Color(0xFF00A3A8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'fx',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: _indicators.count > 0
                                    ? const Color(0xFF00A3A8)
                                    : (isDark
                                          ? const Color(0xFFD8D8D8)
                                          : const Color(0xFF373737)),
                              ),
                            ),
                            if (_indicators.count > 0) ...[
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
                                  '${_indicators.count}',
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
                        onTap: () => DrawingToolsSheet.show(
                          context: context,
                          controller: _drawings,
                        ),
                        isActive: _drawings.isToolbarActive,
                        activeColor: const Color(0xFF00A3A8),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 17,
                          color: _drawings.isToolbarActive
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
                        activeIndicators: _indicators.indicators,
                        showFibonacci: _drawings.showFibonacci,
                        isDrawingFib: _drawings.isDrawing(
                          ChartDrawingTool.fibonacci,
                        ),
                        onFibDrawn: () =>
                            _drawings.finishDrawing(ChartDrawingTool.fibonacci),
                        onFibDeleted: _drawings.deleteFibonacci,
                        horizontalLines: _drawings.horizontalLines,
                        isDrawingHorizontalLine: _drawings.isDrawing(
                          ChartDrawingTool.horizontalLine,
                        ),
                        onHorizontalLineAdded: (_) => _drawings.finishDrawing(
                          ChartDrawingTool.horizontalLine,
                        ),
                        onHorizontalLinesChanged: _drawings.setHorizontalLines,
                        trendlines: _drawings.trendlines,
                        isDrawingTrendline: _drawings.isDrawing(
                          ChartDrawingTool.trendline,
                        ),
                        onTrendlineAdded: (_) =>
                            _drawings.finishDrawing(ChartDrawingTool.trendline),
                        onTrendlinesChanged: _drawings.setTrendlines,
                        rectangles: _drawings.rectangles,
                        isDrawingRectangle: _drawings.isDrawing(
                          ChartDrawingTool.rectangle,
                        ),
                        onRectangleAdded: (_) =>
                            _drawings.finishDrawing(ChartDrawingTool.rectangle),
                        onRectanglesChanged: _drawings.setRectangles,
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
                        onIndicatorValues: (IndicatorPlotValues values) =>
                            _indicators.plotValues.value = values,
                      ),

                      // Tap-outside detector saat ada indikator legend yang sedang terseleksi
                      if (!_isChartModalOpen && _indicators.selectedId != null)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _indicators.select(null),
                          ),
                        ),

                      // Active Indicators Legend di Pojok Kiri Atas Chart (ala TradingView)
                      if (!_isChartModalOpen)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: ChartIndicatorsLegend(
                            selectedId: _indicators.selectedId,
                            onSelectionChanged: _indicators.select,
                            activeIndicators: _indicators.indicators,
                            onToggleIndicatorVisibility:
                                _indicators.toggleVisibility,
                            onDeleteIndicator: _indicators.remove,
                            symbol: 'IHSG',
                            timeframe: p.tvResolution,
                            onOpenSettings: _openIndicatorSettings,
                            plotValues: _indicators.plotValues,
                          ),
                        ),

                      // Active Drawing Prompt Banner (Memberikan instruksi saat user sedang menggambar)
                      if (_drawings.isDrawingAny)
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
                                    switch (_drawings.activeTool) {
                                      ChartDrawingTool.horizontalLine =>
                                        'Ketuk chart untuk menaruh garis Support/Resistance',
                                      ChartDrawingTool.trendline =>
                                        'Ketuk titik 1 lalu titik 2 untuk menarik Trendline',
                                      ChartDrawingTool.rectangle =>
                                        'Ketuk sudut 1 lalu sudut 2 untuk membuat Box Area',
                                      ChartDrawingTool.fibonacci || null =>
                                        'Tarik dari titik asal ke puncak untuk Fibonacci',
                                    },
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
                                  onTap: _drawings.stopDrawing,
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

                      // Floating Drawing Toolbar (favorit, bisa digeser lewat drag handle)
                      if (_drawings.isToolbarVisible)
                        Positioned.fill(
                          child: FloatingDrawingToolbar(controller: _drawings),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
