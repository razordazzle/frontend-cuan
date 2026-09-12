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
  final List<double> _horizontalLines = <double>[];
  bool _isDrawingHorizontalLine = false;
  final List<Map<String, dynamic>> _trendlines = <Map<String, dynamic>>[];
  bool _isDrawingTrendline = false;
  Map<String, dynamic>? _crosshair;

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

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme cs = t.colorScheme;
    const Color upColor = Color(0xFF21C07A);
    final Color downColor = Colors.red.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IHSG'),
        actions: [
          IconButton(
            icon: Icon(_isCandle ? Icons.show_chart : Icons.candlestick_chart),
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
              // Chip resolusi/range & tombol pilihan indikator teknikal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Pilihan interval/timeframe
                      ...['1D', '1W', '1M', '3M', 'YTD', '1Y']
                          .map((String r) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(r),
                                  selected: p.indexInterval == r,
                                  onSelected: (_) => p.setIndexInterval(r),
                                ),
                              )),
                      const SizedBox(width: 6),
                      // Pembatas visual antara timeframe dan indikator
                      Container(
                        width: 1,
                        height: 24,
                        color: cs.outline.withValues(alpha: 0.25),
                      ),
                      const SizedBox(width: 10),
                      // Tombol pilihan indikator teknikal & drawing tools
                      _IndicatorChip(
                        label: 'SMA 20',
                        color: const Color(0xFF2962FF),
                        isSelected: _showSma,
                        onTap: () => setState(() => _showSma = !_showSma),
                      ),
                      const SizedBox(width: 8),
                      _IndicatorChip(
                        label: 'RSI 14',
                        color: const Color(0xFFE91E63),
                        isSelected: _showRsi,
                        onTap: () => setState(() => _showRsi = !_showRsi),
                      ),
                      const SizedBox(width: 8),
                      _IndicatorChip(
                        label: 'VOL',
                        color: const Color(0xFF00B0FF),
                        isSelected: _showVolume,
                        onTap: () => setState(() => _showVolume = !_showVolume),
                      ),
                      const SizedBox(width: 8),
                      _IndicatorChip(
                        label: 'FIB',
                        color: const Color(0xFFFFB300),
                        isSelected: _showFibonacci,
                        onTap: _toggleFibonacci,
                      ),
                      const SizedBox(width: 8),
                      _IndicatorChip(
                        label: 'S/R',
                        color: const Color(0xFF00E5FF),
                        isSelected: _isDrawingHorizontalLine,
                        onTap: () {
                          if (_isDrawingHorizontalLine) {
                            setState(() => _isDrawingHorizontalLine = false);
                          } else {
                            _startDrawingHorizontalLine();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _IndicatorChip(
                        label: 'TL',
                        color: const Color(0xFF7C4DFF),
                        isSelected: _isDrawingTrendline,
                        onTap: () {
                          if (_isDrawingTrendline) {
                            setState(() => _isDrawingTrendline = false);
                          } else {
                            _startDrawingTrendline();
                          }
                        },
                      ),
                    ],
                  ),
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
                            _horizontalLines.add(price);
                            _isDrawingHorizontalLine = false;
                          });
                        }
                      },
                      onHorizontalLinesChanged: (List<double> updated) {
                        if (mounted) {
                          setState(() {
                            _horizontalLines.clear();
                            _horizontalLines.addAll(updated);
                            _isDrawingHorizontalLine = false;
                          });
                        }
                      },
                      trendlines: _trendlines,
                      isDrawingTrendline: _isDrawingTrendline,
                      onTrendlineAdded: (Map<String, dynamic> line) {
                        if (mounted) {
                          setState(() {
                            _trendlines.add(line);
                            _isDrawingTrendline = false;
                          });
                        }
                      },
                      onTrendlinesChanged: (List<Map<String, dynamic>> updated) {
                        if (mounted) {
                          setState(() {
                            _trendlines.clear();
                            _trendlines.addAll(updated);
                            _isDrawingTrendline = false;
                          });
                        }
                      },
                      upColor: upColor,
                      downColor: downColor,
                      gridColor: cs.outline.withValues(alpha: .15),
                      liveBar: liveBar,
                      interactive: true,
                      onCrosshairMove: (Map<String, dynamic>? v) =>
                          setState(() => _crosshair = v),
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

class _IndicatorChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _IndicatorChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : cs.outline.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? color : cs.onSurface.withValues(alpha: 0.7),
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
