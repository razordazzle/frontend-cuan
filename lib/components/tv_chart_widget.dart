import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../pages/screen/home_page.dart' show Ohlc, makeDummyCandles; 
import '../data/model/chart_payload.dart';
import '../data/model/active_chart_indicator.dart';
import '../utils/css_color.dart';
import 'web_message_listener.dart';

const bool _kShowDebugReloadButton = false;

/// Jumlah desimal harga di chart (sama dengan PRICE_PRECISION di tv_chart.html).
const int kChartPricePrecision = 3;

/// Nilai OHLC bar di posisi crosshair. Null per field kalau series tidak punya
/// nilai itu (mis. mode area hanya punya close/value).
@immutable
class CrosshairBar {
  final double? open;
  final double? high;
  final double? low;
  final double? close;

  const CrosshairBar({this.open, this.high, this.low, this.close});

  factory CrosshairBar.fromJson(Map<String, dynamic> json) => CrosshairBar(
    open: (json['open'] as num?)?.toDouble(),
    high: (json['high'] as num?)?.toDouble(),
    low: (json['low'] as num?)?.toDouble(),
    close: (json['close'] as num?)?.toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrosshairBar &&
          open == other.open &&
          high == other.high &&
          low == other.low &&
          close == other.close;

  @override
  int get hashCode => Object.hash(open, high, low, close);
}

class TvChartWidget extends StatefulWidget {
  final List<Ohlc> candles;
  final ChartPayload? payload;
  final bool isCandle;
  final List<ActiveChartIndicator> activeIndicators;
  final bool showFibonacci;
  final bool isDrawingFib;
  final VoidCallback? onFibDrawn;
  final VoidCallback? onFibDeleted;
  final List<dynamic> horizontalLines;
  final bool isDrawingHorizontalLine;
  final ValueChanged<dynamic>? onHorizontalLineAdded;
  final ValueChanged<List<Map<String, dynamic>>>? onHorizontalLinesChanged;
  final List<Map<String, dynamic>> trendlines;
  final bool isDrawingTrendline;
  final ValueChanged<Map<String, dynamic>>? onTrendlineAdded;
  final ValueChanged<List<Map<String, dynamic>>>? onTrendlinesChanged;
  final List<Map<String, dynamic>> rectangles;
  final bool isDrawingRectangle;
  final ValueChanged<Map<String, dynamic>>? onRectangleAdded;
  final ValueChanged<List<Map<String, dynamic>>>? onRectanglesChanged;
  final String symbol;
  final String timeframe;
  final Color upColor;
  final Color downColor;
  final Color gridColor;
  final Color? crosshairColor;
  final Ohlc? liveBar; // bar terakhir yg lagi jalan (dari WS)
  final bool interactive; // false di home (preview doang)
  final ValueChanged<CrosshairBar?>? onCrosshairMove;
  final ValueChanged<bool>? onChartModalStateChanged;
  final ValueChanged<IndicatorPlotValues>? onIndicatorValues;

  const TvChartWidget({
    super.key,
    this.symbol = 'IHSG',
    this.timeframe = '1D',
    required this.candles,
    this.payload,
    required this.isCandle,
    required this.activeIndicators,
    this.showFibonacci = false,
    this.isDrawingFib = false,
    this.onFibDrawn,
    this.onFibDeleted,
    this.horizontalLines = const <dynamic>[],
    this.isDrawingHorizontalLine = false,
    this.onHorizontalLineAdded,
    this.onHorizontalLinesChanged,
    this.trendlines = const <Map<String, dynamic>>[],
    this.isDrawingTrendline = false,
    this.onTrendlineAdded,
    this.onTrendlinesChanged,
    this.rectangles = const <Map<String, dynamic>>[],
    this.isDrawingRectangle = false,
    this.onRectangleAdded,
    this.onRectanglesChanged,
    required this.upColor,
    required this.downColor,
    required this.gridColor,
    this.crosshairColor,
    this.liveBar,
    this.interactive = true,
    this.onCrosshairMove,
    this.onChartModalStateChanged,
    this.onIndicatorValues,
  });

  static String? _cachedHtml;
  static Future<void> preload({bool force = false}) async {
    try {
      if (force) {
        rootBundle.evict('assets/charts/tv_chart.html');
      }
      _cachedHtml = await rootBundle.loadString('assets/charts/tv_chart.html');
    } catch (_) {}
  }

  @override
  State<TvChartWidget> createState() => _TvChartWidgetState();
}

class _TvChartWidgetState extends State<TvChartWidget> {
  InAppWebViewController? _ctrl;
  List<Map<String, dynamic>>? _lastReceivedHorizLines;
  List<Map<String, dynamic>>? _lastReceivedTrendlines;
  List<Map<String, dynamic>>? _lastReceivedRectangles;

  /// True setelah state awal pernah dikirim ke chart; sebelum itu perubahan cukup
  /// ditunggu karena [_pushAll] selalu mengirim state terbaru.
  bool _isSynced = false;
  bool _isPushing = false;

  /// Tema yang terakhir dikirim ke UI drawing di chart (popover, modal, object tree).
  Brightness? _brightness;

  /// Pengukuran waktu buka chart (debug/profile saja), dimulai saat widget dibuat.
  final Stopwatch _openTimer = Stopwatch()..start();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Brightness brightness = Theme.of(context).brightness;
    if (brightness == _brightness) return;
    _brightness = brightness;
    // Sebelum sinkron, tema ikut dikirim oleh _pushAll.
    if (_isSynced) _run(<String>[_themeModeScript]);
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      TvChartWidget.preload(force: true);
    } else if (TvChartWidget._cachedHtml == null) {
      TvChartWidget.preload();
    }
    listenToWebMessages((String type, dynamic payload) {
      if (!mounted) return;
      if (type == 'onHorizontalLineAdded') {
        widget.onHorizontalLineAdded?.call(payload);
      } else if (type == 'onHorizontalLinesChanged') {
        if (payload is List) {
          final List<Map<String, dynamic>> updated = payload
              .map((dynamic e) {
                if (e is Map) return Map<String, dynamic>.from(e);
                if (e is num) return <String, dynamic>{'price': e.toDouble()};
                return <String, dynamic>{};
              })
              .where((Map<String, dynamic> m) => m.isNotEmpty)
              .toList();
          _lastReceivedHorizLines = List<Map<String, dynamic>>.from(updated);
          widget.onHorizontalLinesChanged?.call(updated);
        }
      } else if (type == 'onFibDeleted') {
        widget.onFibDeleted?.call();
      } else if (type == 'onFibDrawn') {
        if (payload == false) {
          widget.onFibDeleted?.call();
        } else {
          widget.onFibDrawn?.call();
        }
      } else if (type == 'onTrendlineAdded') {
        if (payload is Map) {
          widget.onTrendlineAdded?.call(Map<String, dynamic>.from(payload));
        }
      } else if (type == 'onTrendlinesChanged') {
        if (payload is List) {
          final List<Map<String, dynamic>> updated = payload
              .whereType<Map>()
              .map((Map e) => Map<String, dynamic>.from(e))
              .toList();
          _lastReceivedTrendlines = List<Map<String, dynamic>>.from(updated);
          widget.onTrendlinesChanged?.call(updated);
        }
      } else if (type == 'onRectangleAdded') {
        if (payload is Map) {
          widget.onRectangleAdded?.call(Map<String, dynamic>.from(payload));
        }
      } else if (type == 'onRectanglesChanged') {
        if (payload is List) {
          final List<Map<String, dynamic>> updated = payload
              .whereType<Map>()
              .map((Map e) => Map<String, dynamic>.from(e))
              .toList();
          _lastReceivedRectangles = List<Map<String, dynamic>>.from(updated);
          widget.onRectanglesChanged?.call(updated);
        }
      } else if (type == 'onCrosshair') {
        _emitCrosshair(payload);
      } else if (type == 'onChartModalStateChanged') {
        if (payload is bool) {
          widget.onChartModalStateChanged?.call(payload);
        }
      } else if (type == 'onIndicatorValues') {
        _emitIndicatorValues(payload);
      }
    });
  }

  /// Payload JS: JSON `{ "<id>": { "values": [...], "isGrowing"?: bool } }`.
  void _emitIndicatorValues(Object? payload) {
    final ValueChanged<IndicatorPlotValues>? callback = widget.onIndicatorValues;
    if (callback == null || payload is! String) return;
    final Map<String, dynamic> decoded =
        jsonDecode(payload) as Map<String, dynamic>;
    callback(<String, IndicatorPlotSnapshot>{
      for (final MapEntry<String, dynamic>(:String key, :dynamic value)
          in decoded.entries)
        key: IndicatorPlotSnapshot.fromJson(value as Map<String, dynamic>),
    });
  }

  /// Payload JS: JSON string `{ time, open, high, low, close }`, atau null saat crosshair keluar.
  void _emitCrosshair(Object? payload) {
    final ValueChanged<CrosshairBar?>? callback = widget.onCrosshairMove;
    if (callback == null) return;
    final Object? json = payload is String ? jsonDecode(payload) : payload;
    callback(
      json is Map ? CrosshairBar.fromJson(Map<String, dynamic>.from(json)) : null,
    );
  }

  int _sec(DateTime t) =>
      t.toUtc().add(const Duration(hours: 7)).millisecondsSinceEpoch ~/ 1000;

  Map<String, dynamic> _barJson(Ohlc c) => <String, dynamic>{
    'time': _sec(c.time),
    'open': c.open,
    'high': c.high,
    'low': c.low,
    'close': c.close,
    'volume': c.volume,
  };

  /// Warna crosshair (default mengikuti brightness tema) dalam format CSS.
  String get _crosshairCss {
    final Color crosshair =
        widget.crosshairColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFD1D4DC)
            : const Color(0xFF4A4E5A));
    return crosshair.withValues(alpha: 0.85).toCssRgba();
  }

  /// Argumen warna tema untuk JS: naik/turun dalam hex (JS menambah suffix alpha), grid dalam rgba.
  String get _themeColorArgs =>
      "'${widget.upColor.toCssHex()}', '${widget.downColor.toCssHex()}', '${widget.gridColor.toCssRgba()}'";

  // ===== Script JS per bagian state chart =====

  String get _themeModeScript =>
      "setThemeMode('${_brightness == Brightness.light ? 'light' : 'dark'}');";

  String get _chartInfoScript =>
      "setChartInfo(${jsonEncode(widget.symbol)}, ${jsonEncode(widget.timeframe)});";

  String get _setDataScript {
    final List<Ohlc> payloadCandles = widget.payload?.candles ?? const <Ohlc>[];
    final List<Ohlc> candles = payloadCandles.isNotEmpty
        ? payloadCandles
        : widget.candles.isNotEmpty
        ? widget.candles
        : makeDummyCandles(60);
    return 'setData(${jsonEncode(candles.map(_barJson).toList())});';
  }

  String get _seriesTypeScript =>
      "setSeriesType('${widget.isCandle ? 'candle' : 'area'}');";

  String get _activeIndicatorsScript => 'setActiveIndicators(${jsonEncode(
    widget.activeIndicators.map((ActiveChartIndicator e) => e.toJson()).toList(),
  )});';

  String get _fibonacciScript => 'setFibonacci(${widget.showFibonacci});';
  String get _horizontalLinesScript =>
      'setHorizontalLines(${jsonEncode(widget.horizontalLines)});';
  String get _trendlinesScript =>
      'setTrendlines(${jsonEncode(widget.trendlines)});';
  String get _rectanglesScript =>
      'setRectangles(${jsonEncode(widget.rectangles)});';

  static String _drawingModeScript(String tool, {required bool isDrawing}) =>
      isDrawing ? 'start${tool}Drawing();' : 'cancel${tool}Drawing();';

  /// Log fase buka chart: `TV_CHART_TIMING: <fase> <ms sejak widget dibuat> ms`.
  void _logTiming(String phase, [String detail = '']) {
    if (kReleaseMode) return;
    debugPrint(
      'TV_CHART_TIMING: $phase ${_openTimer.elapsedMilliseconds} ms$detail',
    );
  }

  /// Jalankan beberapa perintah JS dalam satu panggilan bridge.
  Future<void> _run(List<String> scripts) async {
    final InAppWebViewController? ctrl = _ctrl;
    if (ctrl == null || scripts.isEmpty) return;
    await ctrl.evaluateJavascript(source: scripts.join('\n'));
  }

  /// Kirim seluruh state ke chart, sekali per halaman dimuat. Penanda sinkron disimpan
  /// di halaman JS (`window.__cuanChartSynced`), jadi reload WebView otomatis memicu push ulang.
  Future<void> _pushAll() async {
    final InAppWebViewController? ctrl = _ctrl;
    if (ctrl == null || _isPushing) return;
    _isPushing = true;
    try {
      final Object? needsSync = await ctrl.evaluateJavascript(
        source:
            "typeof setActiveIndicators === 'function' && !window.__cuanChartSynced",
      );
      if (needsSync != true || !mounted) return;

      await _run(<String>[
        "initChart($_themeColorArgs, ${widget.interactive}, '$_crosshairCss');",
        _themeModeScript,
        _chartInfoScript,
        _setDataScript,
        _seriesTypeScript,
        _activeIndicatorsScript,
        _fibonacciScript,
        if (widget.isDrawingFib) 'startFibDrawing();',
        _horizontalLinesScript,
        if (widget.isDrawingHorizontalLine) 'startHorizontalLineDrawing();',
        _trendlinesScript,
        if (widget.isDrawingTrendline) 'startTrendlineDrawing();',
        _rectanglesScript,
        if (widget.isDrawingRectangle) 'startRectangleDrawing();',
        'window.__cuanChartSynced = true;',
      ]);
      if (!_isSynced) _logTiming('first_render');
      _isSynced = true;
    } finally {
      _isPushing = false;
    }
  }

  @override
  void didUpdateWidget(covariant TvChartWidget old) {
    super.didUpdateWidget(old);
    if (!_isSynced) return;

    final bool candlesChanged =
        !identical(old.payload, widget.payload) ||
        old.candles.length != widget.candles.length;
    final Ohlc? liveBar = widget.liveBar;
    if (candlesChanged) {
      _logTiming(
        'data_render',
        ' (${widget.payload?.candles.length ?? widget.candles.length} candle)',
      );
    }

    // Hanya bagian yang berubah yang dikirim; urutan sama dengan _pushAll.
    _run(<String>[
      if (old.symbol != widget.symbol || old.timeframe != widget.timeframe)
        _chartInfoScript,
      if (candlesChanged) _setDataScript,
      if (old.isCandle != widget.isCandle) _seriesTypeScript,
      if (!listEquals(old.activeIndicators, widget.activeIndicators))
        _activeIndicatorsScript,
      if (old.upColor != widget.upColor ||
          old.downColor != widget.downColor ||
          old.gridColor != widget.gridColor)
        'applyThemeColors($_themeColorArgs);',
      if (old.crosshairColor != widget.crosshairColor)
        "setCrosshairColor('$_crosshairCss');",
      if (old.showFibonacci != widget.showFibonacci) _fibonacciScript,
      if (old.isDrawingFib != widget.isDrawingFib)
        _drawingModeScript('Fib', isDrawing: widget.isDrawingFib),
      // Perubahan yang berasal dari chart sendiri (_lastReceived*) tidak dikirim balik.
      if (!listEquals(old.horizontalLines, widget.horizontalLines) &&
          !listEquals(widget.horizontalLines, _lastReceivedHorizLines))
        _horizontalLinesScript,
      if (old.isDrawingHorizontalLine != widget.isDrawingHorizontalLine)
        _drawingModeScript(
          'HorizontalLine',
          isDrawing: widget.isDrawingHorizontalLine,
        ),
      if (!listEquals(old.trendlines, widget.trendlines) &&
          !listEquals(widget.trendlines, _lastReceivedTrendlines))
        _trendlinesScript,
      if (old.isDrawingTrendline != widget.isDrawingTrendline)
        _drawingModeScript('Trendline', isDrawing: widget.isDrawingTrendline),
      if (!listEquals(old.rectangles, widget.rectangles) &&
          !listEquals(widget.rectangles, _lastReceivedRectangles))
        _rectanglesScript,
      if (old.isDrawingRectangle != widget.isDrawingRectangle)
        _drawingModeScript('Rectangle', isDrawing: widget.isDrawingRectangle),
      if (liveBar != null && old.liveBar?.close != liveBar.close)
        'updateBar(${jsonEncode(_barJson(liveBar))});',
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final InAppWebView webview = InAppWebView(
      initialData: TvChartWidget._cachedHtml != null
          ? InAppWebViewInitialData(
              data: TvChartWidget._cachedHtml!,
              mimeType: 'text/html',
              encoding: 'utf-8',
              baseUrl: !kIsWeb && Platform.isAndroid
                  ? WebUri('file:///android_asset/flutter_assets/assets/charts/')
                  : null,
            )
          : null,
      initialFile: TvChartWidget._cachedHtml == null ? 'assets/charts/tv_chart.html' : null,
      initialSettings: InAppWebViewSettings(
        transparentBackground: true,
        disableVerticalScroll: false,
        disableHorizontalScroll: false,
        supportZoom: false,
        builtInZoomControls: false,
        displayZoomControls: false,
        useWideViewPort: false,
        cacheMode: CacheMode.LOAD_NO_CACHE,
        clearCache: true,
      ),
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(
          () => EagerGestureRecognizer(),
        ),
      },
      onWebViewCreated: (InAppWebViewController c) {
        _ctrl = c;
        c.addJavaScriptHandler(
          handlerName: 'onCrosshair',
          callback: (List<dynamic> args) {
            _emitCrosshair(args.isNotEmpty ? args[0] : null);
            return null;
          },
        );
        c.addJavaScriptHandler(
          handlerName: 'onFibDeleted',
          callback: (List<dynamic> args) {
            widget.onFibDeleted?.call();
            return null;
          },
        );
        c.addJavaScriptHandler(
          handlerName: 'onFibDrawn',
          callback: (List<dynamic> args) {
            if (args.isNotEmpty && args[0] == false) {
              widget.onFibDeleted?.call();
            } else {
              widget.onFibDrawn?.call();
            }
            return null;
          },
        );
        c.addJavaScriptHandler(
          handlerName: 'onHorizontalLineAdded',
          callback: (List<dynamic> args) {
            if (args.isNotEmpty) {
              widget.onHorizontalLineAdded?.call(args[0]);
            }
            return null;
          },
        );
        c.addJavaScriptHandler(
          handlerName: 'onHorizontalLinesChanged',
          callback: (List<dynamic> args) {
            if (args.isNotEmpty && args[0] is List) {
              final List<dynamic> rawList = args[0] as List<dynamic>;
              final List<Map<String, dynamic>> updated = rawList
                  .map((dynamic e) {
                    if (e is Map) return Map<String, dynamic>.from(e);
                    if (e is num) return <String, dynamic>{'price': e.toDouble()};
                    return <String, dynamic>{};
                  })
                  .where((Map<String, dynamic> m) => m.isNotEmpty)
                  .toList();
              _lastReceivedHorizLines = List<Map<String, dynamic>>.from(updated);
              widget.onHorizontalLinesChanged?.call(updated);
            }
            return null;
          },
        );
        c.addJavaScriptHandler(
          handlerName: 'onTrendlineAdded',
          callback: (List<dynamic> args) {
            if (args.isNotEmpty && args[0] is Map) {
              widget.onTrendlineAdded?.call(Map<String, dynamic>.from(args[0] as Map));
            }
            return null;
          },
        );
        c.addJavaScriptHandler(
          handlerName: 'onTrendlinesChanged',
          callback: (List<dynamic> args) {
            if (args.isNotEmpty && args[0] is List) {
              final List<dynamic> rawList = args[0] as List<dynamic>;
              final List<Map<String, dynamic>> updated = rawList
                  .whereType<Map>()
                  .map((Map e) => Map<String, dynamic>.from(e))
                  .toList();
              _lastReceivedTrendlines = List<Map<String, dynamic>>.from(updated);
              widget.onTrendlinesChanged?.call(updated);
            }
            return null;
          },
        );
        c.addJavaScriptHandler(
          handlerName: 'onRectangleAdded',
          callback: (List<dynamic> args) {
            if (args.isNotEmpty && args[0] is Map) {
              widget.onRectangleAdded?.call(Map<String, dynamic>.from(args[0] as Map));
            }
            return null;
          },
        );
        c.addJavaScriptHandler(
          handlerName: 'onRectanglesChanged',
          callback: (List<dynamic> args) {
            if (args.isNotEmpty && args[0] is List) {
              final List<dynamic> rawList = args[0] as List<dynamic>;
              final List<Map<String, dynamic>> updated = rawList
                  .whereType<Map>()
                  .map((Map e) => Map<String, dynamic>.from(e))
                  .toList();
              widget.onRectanglesChanged?.call(updated);
            }
            return null;
          },
        );
        c.addJavaScriptHandler(
          handlerName: 'onIndicatorValues',
          callback: (List<dynamic> args) {
            if (args.isNotEmpty) _emitIndicatorValues(args[0]);
            return null;
          },
        );
        c.addJavaScriptHandler(
          handlerName: 'onChartModalStateChanged',
          callback: (List<dynamic> args) {
            if (args.isNotEmpty && args[0] is bool) {
              widget.onChartModalStateChanged?.call(args[0] as bool);
            }
            return null;
          },
        );

        // Fallback trigger untuk platform Web & mobile saat halaman siap
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _pushAll();
          }
        });
        Future<void>.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _pushAll();
          }
        });
      },
      onConsoleMessage: (InAppWebViewController controller, ConsoleMessage consoleMessage) {
        debugPrint("TV_CHART_JS: ${consoleMessage.messageLevel}: ${consoleMessage.message}");
      },
      onLoadStart: (InAppWebViewController controller, WebUri? url) {
        debugPrint("TV_CHART_DART: onLoadStart: $url");
      },
      onLoadStop: (InAppWebViewController c, WebUri? url) async {
        if (!kReleaseMode) {
          // performance.now() = ms sejak halaman mulai dimuat (parse HTML + eksekusi script).
          final Object? pageMs = await c.evaluateJavascript(
            source: 'Math.round(performance.now())',
          );
          _logTiming('html_loaded', ' (di WebView: $pageMs ms)');
        }
        await _pushAll();
      },
      onReceivedError: (InAppWebViewController controller, WebResourceRequest request, WebResourceError error) {
        debugPrint("TV_CHART_DART: onReceivedError: ${error.description} for ${request.url}");
      },
      onReceivedHttpError: (InAppWebViewController controller, WebResourceRequest request, WebResourceResponse errorResponse) {
        debugPrint("TV_CHART_DART: onReceivedHttpError: ${errorResponse.statusCode} for ${request.url}");
      },
      shouldOverrideUrlLoading: (InAppWebViewController controller, NavigationAction action) async {
        final String url = action.request.url.toString();
        if (url.contains('tv_chart.html') ||
            url.contains('localhost') ||
            url.contains('127.0.0.1') ||
            url.startsWith('file://') ||
            url.startsWith('about:') ||
            url.startsWith('blob:') ||
            url.startsWith('data:') ||
            url.startsWith('chrome-extension://')) {
          return NavigationActionPolicy.ALLOW;
        }
        return NavigationActionPolicy.CANCEL;
      },
    );

    final Widget chartContent = widget.interactive ? webview : IgnorePointer(child: webview);

    if (!_kShowDebugReloadButton) {
      return chartContent;
    }

    return Stack(
      children: <Widget>[
        chartContent,
        Positioned(
          top: 10,
          right: 10,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _debugReloadChart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xBF000000),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber, width: 1.2),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.refresh_rounded, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "Reload HTML",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void openObjectTree() {
    _ctrl?.evaluateJavascript(
      source: 'if (typeof openObjectTreeModal === "function") openObjectTreeModal();',
    );
  }

  Future<void> _debugReloadChart() async {
    try {
      rootBundle.evict('assets/charts/tv_chart.html');
      final String htmlData = await rootBundle.loadString('assets/charts/tv_chart.html');
      TvChartWidget._cachedHtml = htmlData;
      await InAppWebViewController.clearAllCache();
      WebUri? baseUri;
      if (!kIsWeb && Platform.isAndroid) {
        baseUri = WebUri('file:///android_asset/flutter_assets/assets/charts/');
      }
      await _ctrl?.loadData(
        data: htmlData,
        mimeType: 'text/html',
        encoding: 'utf-8',
        baseUrl: baseUri,
      );
    } catch (e) {
      debugPrint("DEBUG_RELOAD_ERROR: $e");
      await InAppWebViewController.clearAllCache();
      await _ctrl?.reload();
    }
  }
}
