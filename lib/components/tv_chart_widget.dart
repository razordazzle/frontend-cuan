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
import 'web_message_listener.dart';

const bool _kShowDebugReloadButton = true;

class TvChartWidget extends StatefulWidget {
  final List<Ohlc> candles;
  final ChartPayload? payload;
  final bool isCandle;
  final List<ActiveChartIndicator>? activeIndicators;
  final bool showSma;
  final bool showRsi;
  final bool showVolume;
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
  final ValueChanged<Map<String, dynamic>?>? onCrosshairMove;

  const TvChartWidget({
    super.key,
    this.symbol = 'IHSG',
    this.timeframe = '1D',
    required this.candles,
    this.payload,
    required this.isCandle,
    this.activeIndicators,
    this.showSma = false,
    this.showRsi = false,
    this.showVolume = false,
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
        if (payload is Map) {
          widget.onCrosshairMove?.call(Map<String, dynamic>.from(payload));
        } else if (payload == null) {
          widget.onCrosshairMove?.call(null);
        }
      }
    });
  }

  String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

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

  String _rgba(Color c, double opacity) {
    final int argb = c.toARGB32();
    final int r = (argb >> 16) & 0xFF;
    final int g = (argb >> 8) & 0xFF;
    final int b = argb & 0xFF;
    return 'rgba($r, $g, $b, $opacity)';
  }

  Map<String, dynamic> _volJson(Ohlc c) => <String, dynamic>{
    'time': _sec(c.time),
    'value': c.volume,
    'color': c.close >= c.open
        ? _rgba(widget.upColor, .5)
        : _rgba(widget.downColor, .5),
  };

  Future<void> _pushAll() async {
    if (_ctrl == null) return;
    debugPrint("TV_CHART_DART: _pushAll called, candles=${widget.candles.length}, hasPayload=${widget.payload != null}");

    final Color crosshair = widget.crosshairColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFD1D4DC)
            : const Color(0xFF4A4E5A));

    // Pastikan initChart terpanggil dengan parameter warna tema
    await _ctrl!.evaluateJavascript(
      source:
          "if (typeof initChart === 'function') initChart('${_hex(widget.upColor)}', '${_hex(widget.downColor)}', '${_hex(widget.gridColor)}', ${widget.interactive}, '${_rgba(crosshair, 0.85)}');",
    );
    await _ctrl!.evaluateJavascript(
      source:
          "if (typeof setChartInfo === 'function') setChartInfo('${widget.symbol}', '${widget.timeframe}');",
    );

    if (widget.payload != null && widget.payload!.candles.isNotEmpty) {
      final List<Map<String, dynamic>> candlesJson =
          widget.payload!.candles.map(_barJson).toList();
      final Map<String, List<Map<String, dynamic>>> indicatorsJson =
          <String, List<Map<String, dynamic>>>{};

      widget.payload!.indicators.forEach((String key, List<IndicatorValue> value) {
        indicatorsJson[key] = value.map((IndicatorValue e) => <String, dynamic>{
          'time': e.time + (7 * 3600), // Sinkronkan ke WIB (+7)
          'value': e.value,
        }).toList();
      });

      final String payloadStr = jsonEncode(<String, dynamic>{
        'candles': candlesJson,
        'indicators': indicatorsJson,
      });

      await _ctrl!.evaluateJavascript(
        source: "setDataWithIndicators(${jsonEncode(payloadStr)});",
      );

      final String volsJson = jsonEncode(
        widget.payload!.candles.map(_volJson).toList(),
      );
      await _ctrl!.evaluateJavascript(
        source: "if (window.setVolumeData) setVolumeData(${jsonEncode(volsJson)});",
      );
    } else {
      final List<Ohlc> activeCandles = widget.candles.isNotEmpty
          ? widget.candles
          : makeDummyCandles(60);
      final String candlesJson = jsonEncode(
        activeCandles.map(_barJson).toList(),
      );
      final String volsJson = jsonEncode(
        activeCandles.map(_volJson).toList(),
      );
      await _ctrl!.evaluateJavascript(
        source: "setData(${jsonEncode(candlesJson)}, ${jsonEncode(volsJson)});",
      );
    }

    await _ctrl!.evaluateJavascript(
      source: "setSeriesType('${widget.isCandle ? 'candle' : 'area'}');",
    );

    if (widget.activeIndicators != null) {
      final String indJson = jsonEncode(
        widget.activeIndicators!.map((ActiveChartIndicator e) => e.toJson()).toList(),
      );
      await _ctrl!.evaluateJavascript(
        source: "if (typeof setActiveIndicators === 'function') setActiveIndicators($indJson);",
      );
    } else {
      await _ctrl!.evaluateJavascript(
        source:
            "setIndicators(${widget.showSma}, ${widget.showRsi}, ${widget.showVolume});",
      );
    }

    await _ctrl!.evaluateJavascript(
      source: "setFibonacci(${widget.showFibonacci});",
    );

    if (widget.isDrawingFib) {
      await _ctrl!.evaluateJavascript(
        source: "startFibDrawing();",
      );
    }

    final String horizJson = jsonEncode(widget.horizontalLines);
    await _ctrl!.evaluateJavascript(
      source: "setHorizontalLines($horizJson);",
    );

    if (widget.isDrawingHorizontalLine) {
      await _ctrl!.evaluateJavascript(
        source: "startHorizontalLineDrawing();",
      );
    }

    final String trendJson = jsonEncode(widget.trendlines);
    await _ctrl!.evaluateJavascript(
      source: "setTrendlines($trendJson);",
    );

    if (widget.isDrawingTrendline) {
      await _ctrl!.evaluateJavascript(
        source: "startTrendlineDrawing();",
      );
    }

    final String rectJson = jsonEncode(widget.rectangles);
    await _ctrl!.evaluateJavascript(
      source: "if (typeof setRectangles === 'function') setRectangles($rectJson);",
    );

    if (widget.isDrawingRectangle) {
      await _ctrl!.evaluateJavascript(
        source: "if (typeof startRectangleDrawing === 'function') startRectangleDrawing();",
      );
    }
  }

  @override
  void didUpdateWidget(covariant TvChartWidget old) {
    super.didUpdateWidget(old);
    final bool dataChanged = old.candles.length != widget.candles.length ||
        old.isCandle != widget.isCandle ||
        old.payload != widget.payload;

    final String oldIndJson = old.activeIndicators == null
        ? ''
        : jsonEncode(old.activeIndicators!.map((ActiveChartIndicator e) => e.toJson()).toList());
    final String newIndJson = widget.activeIndicators == null
        ? ''
        : jsonEncode(widget.activeIndicators!.map((ActiveChartIndicator e) => e.toJson()).toList());
    final bool activeIndicatorsChanged = oldIndJson != newIndJson;

    final bool indicatorsChanged = old.showSma != widget.showSma ||
        old.showRsi != widget.showRsi ||
        old.showVolume != widget.showVolume;

    final bool fibChanged = old.showFibonacci != widget.showFibonacci;
    final bool drawFibChanged = old.isDrawingFib != widget.isDrawingFib;

    final bool horizLinesChanged =
        !listEquals(old.horizontalLines, widget.horizontalLines);
    final bool drawHorizChanged =
        old.isDrawingHorizontalLine != widget.isDrawingHorizontalLine;

    final bool trendlinesChanged =
        !listEquals(old.trendlines, widget.trendlines);
    final bool drawTrendlineChanged =
        old.isDrawingTrendline != widget.isDrawingTrendline;

    final bool rectanglesChanged =
        !listEquals(old.rectangles, widget.rectangles);
    final bool drawRectangleChanged =
        old.isDrawingRectangle != widget.isDrawingRectangle;

    final bool crosshairChanged = old.crosshairColor != widget.crosshairColor;
    final bool chartInfoChanged =
        old.symbol != widget.symbol || old.timeframe != widget.timeframe;

    if (dataChanged) {
      _pushAll();
    } else {
      if (chartInfoChanged) {
        _ctrl?.evaluateJavascript(
          source:
              "if (typeof setChartInfo === 'function') setChartInfo('${widget.symbol}', '${widget.timeframe}');",
        );
      }
      if (widget.activeIndicators != null) {
        if (activeIndicatorsChanged) {
          _ctrl?.evaluateJavascript(
            source:
                "if (typeof setActiveIndicators === 'function') setActiveIndicators($newIndJson);",
          );
        }
      } else if (indicatorsChanged) {
        _ctrl?.evaluateJavascript(
          source:
              "setIndicators(${widget.showSma}, ${widget.showRsi}, ${widget.showVolume});",
        );
      }
      if (fibChanged) {
        _ctrl?.evaluateJavascript(
          source: "setFibonacci(${widget.showFibonacci});",
        );
      }
      if (drawFibChanged) {
        if (widget.isDrawingFib) {
          _ctrl?.evaluateJavascript(
            source: "startFibDrawing();",
          );
        } else {
          _ctrl?.evaluateJavascript(
            source: "cancelFibDrawing();",
          );
        }
      }
      if (horizLinesChanged) {
        if (!listEquals(widget.horizontalLines, _lastReceivedHorizLines)) {
          final String horizJson = jsonEncode(widget.horizontalLines);
          _ctrl?.evaluateJavascript(
            source: "setHorizontalLines($horizJson);",
          );
        }
      }
      if (drawHorizChanged) {
        if (widget.isDrawingHorizontalLine) {
          _ctrl?.evaluateJavascript(
            source: "startHorizontalLineDrawing();",
          );
        } else {
          _ctrl?.evaluateJavascript(
            source: "cancelHorizontalLineDrawing();",
          );
        }
      }
      if (trendlinesChanged) {
        if (!listEquals(widget.trendlines, _lastReceivedTrendlines)) {
          final String trendJson = jsonEncode(widget.trendlines);
          _ctrl?.evaluateJavascript(
            source: "setTrendlines($trendJson);",
          );
        }
      }
      if (drawTrendlineChanged) {
        if (widget.isDrawingTrendline) {
          _ctrl?.evaluateJavascript(
            source: "startTrendlineDrawing();",
          );
        } else {
          _ctrl?.evaluateJavascript(
            source: "cancelTrendlineDrawing();",
          );
        }
      }
      if (rectanglesChanged) {
        if (!listEquals(widget.rectangles, _lastReceivedRectangles)) {
          final String rectJson = jsonEncode(widget.rectangles);
          _ctrl?.evaluateJavascript(
            source: "if (typeof setRectangles === 'function') setRectangles($rectJson);",
          );
        }
      }
      if (drawRectangleChanged) {
        if (widget.isDrawingRectangle) {
          _ctrl?.evaluateJavascript(
            source: "if (typeof startRectangleDrawing === 'function') startRectangleDrawing();",
          );
        } else {
          _ctrl?.evaluateJavascript(
            source: "if (typeof cancelRectangleDrawing === 'function') cancelRectangleDrawing();",
          );
        }
      }
      if (crosshairChanged) {
        final Color crosshair = widget.crosshairColor ??
            (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFD1D4DC)
                : const Color(0xFF4A4E5A));
        _ctrl?.evaluateJavascript(
          source:
              "if (typeof setCrosshairColor === 'function') setCrosshairColor('${_rgba(crosshair, 0.85)}');",
        );
      }
      if (widget.liveBar != null &&
          (old.liveBar?.close != widget.liveBar?.close)) {
        final String bar = jsonEncode(_barJson(widget.liveBar!));
        final String vol = jsonEncode(_volJson(widget.liveBar!));
        _ctrl?.evaluateJavascript(
          source: "updateBar(${jsonEncode(bar)}, ${jsonEncode(vol)});",
        );
      }
    }
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
            final String? raw = args.isNotEmpty ? args[0] as String? : null;
            widget.onCrosshairMove?.call(
              raw == null ? null : jsonDecode(raw) as Map<String, dynamic>,
            );
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
        debugPrint("TV_CHART_DART: onLoadStop: $url");
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
