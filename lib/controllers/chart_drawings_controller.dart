import 'dart:collection';

import 'package:flutter/foundation.dart';

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
  final Set<ChartDrawingTool> _favoriteTools = <ChartDrawingTool>{
    ChartDrawingTool.rectangle,
    ChartDrawingTool.trendline,
    ChartDrawingTool.horizontalLine,
    ChartDrawingTool.fibonacci,
  };

  ChartDrawingTool? get activeTool => _activeTool;
  bool get showFibonacci => _showFibonacci;
  bool get isToolbarVisible => _isToolbarVisible;

  /// Tool favorit, urut sesuai waktu ditambahkan (jadi urutan tombol di toolbar chart).
  Set<ChartDrawingTool> get favoriteTools =>
      UnmodifiableSetView<ChartDrawingTool>(_favoriteTools);
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
    if (!_favoriteTools.remove(tool)) _favoriteTools.add(tool);
    notifyListeners();
  }

  void closeToolbar() {
    _isToolbarVisible = false;
    _activeTool = null;
    notifyListeners();
  }

  /// Objek dari [tool] baru di-update oleh chart, jadi mode gambar tool itu diakhiri.
  void _syncObjects(ChartDrawingTool tool) {
    if (isDrawing(tool)) _activeTool = null;
    notifyListeners();
  }
}
