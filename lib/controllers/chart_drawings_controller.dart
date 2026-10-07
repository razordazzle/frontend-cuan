import 'package:flutter/foundation.dart';

import 'persisted_favorites.dart';

enum ChartDrawingTool { fibonacci, horizontalLine, trendline, rectangle }

/// State drawing tools di halaman chart TradingView (saham & IHSG).
///
/// Hanya satu tool yang bisa aktif menggambar dalam satu waktu ([activeTool]).
/// List objek drawing selalu diganti instance baru setiap ada perubahan,
/// supaya perbandingan old/new widget di `TvChartWidget` tetap akurat.
class ChartDrawingsController extends ChangeNotifier {
  ChartDrawingTool? _activeTool;
  bool _showFibonacci = false;
  bool _isToolbarVisible = false;
  List<Map<String, dynamic>> _horizontalLines = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _trendlines = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _rectangles = const <Map<String, dynamic>>[];
  final PersistedFavorites<ChartDrawingTool> _favoriteTools =
      PersistedFavorites<ChartDrawingTool>(
        storageKey: 'chart.drawingFavorites',
        defaults: const <ChartDrawingTool>[
          ChartDrawingTool.rectangle,
          ChartDrawingTool.trendline,
          ChartDrawingTool.horizontalLine,
          ChartDrawingTool.fibonacci,
        ],
        encode: (ChartDrawingTool tool) => tool.name,
        decode: (String name) => ChartDrawingTool.values.asNameMap()[name],
      );
  bool _isDisposed = false;

  /// Favorit tampil di toolbar chart, jadi begitu selesai dimuat perlu rebuild.
  ChartDrawingsController() {
    _favoriteTools.load().then((bool changed) {
      if (changed && !_isDisposed) notifyListeners();
    });
  }

  ChartDrawingTool? get activeTool => _activeTool;
  bool get showFibonacci => _showFibonacci;
  bool get isToolbarVisible => _isToolbarVisible;

  /// Tool favorit, urut sesuai waktu ditambahkan (jadi urutan tombol di toolbar chart).
  Set<ChartDrawingTool> get favoriteTools => _favoriteTools.items;
  bool isFavorite(ChartDrawingTool tool) => _favoriteTools.contains(tool);
  List<Map<String, dynamic>> get horizontalLines => _horizontalLines;
  List<Map<String, dynamic>> get trendlines => _trendlines;
  List<Map<String, dynamic>> get rectangles => _rectangles;

  bool isDrawing(ChartDrawingTool tool) => _activeTool == tool;
  bool get isDrawingAny => _activeTool != null;
  bool get isToolbarActive => _isToolbarVisible || isDrawingAny;

  bool get hasDrawings =>
      _showFibonacci ||
      _horizontalLines.isNotEmpty ||
      _trendlines.isNotEmpty ||
      _rectangles.isNotEmpty;

  void startDrawing(ChartDrawingTool tool) {
    _activeTool = tool;
    if (tool == ChartDrawingTool.fibonacci) _showFibonacci = true;
    notifyListeners();
  }

  void toggleDrawing(ChartDrawingTool tool) =>
      isDrawing(tool) ? stopDrawing() : startDrawing(tool);

  void stopDrawing() {
    if (_activeTool == null) return;
    _activeTool = null;
    notifyListeners();
  }

  /// Dipanggil saat chart selesai menaruh satu objek dari [tool].
  void finishDrawing(ChartDrawingTool tool) {
    if (isDrawing(tool)) stopDrawing();
  }

  void deleteFibonacci() {
    _showFibonacci = false;
    if (isDrawing(ChartDrawingTool.fibonacci)) _activeTool = null;
    notifyListeners();
  }

  void setHorizontalLines(List<Map<String, dynamic>> lines) {
    _horizontalLines = List<Map<String, dynamic>>.unmodifiable(lines);
    _syncObjects(ChartDrawingTool.horizontalLine);
  }

  void setTrendlines(List<Map<String, dynamic>> lines) {
    _trendlines = List<Map<String, dynamic>>.unmodifiable(lines);
    _syncObjects(ChartDrawingTool.trendline);
  }

  void setRectangles(List<Map<String, dynamic>> rectangles) {
    _rectangles = List<Map<String, dynamic>>.unmodifiable(rectangles);
    _syncObjects(ChartDrawingTool.rectangle);
  }

  void clearAll() {
    _activeTool = null;
    _showFibonacci = false;
    _horizontalLines = const <Map<String, dynamic>>[];
    _trendlines = const <Map<String, dynamic>>[];
    _rectangles = const <Map<String, dynamic>>[];
    notifyListeners();
  }

  void setToolbarVisible(bool visible) {
    if (_isToolbarVisible == visible) return;
    _isToolbarVisible = visible;
    notifyListeners();
  }

  void toggleFavorite(ChartDrawingTool tool) {
    _favoriteTools.toggle(tool);
    notifyListeners();
  }

  void closeToolbar() {
    _isToolbarVisible = false;
    _activeTool = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Objek dari [tool] baru di-update oleh chart, jadi mode gambar tool itu diakhiri.
  void _syncObjects(ChartDrawingTool tool) {
    if (isDrawing(tool)) _activeTool = null;
    notifyListeners();
  }
}
