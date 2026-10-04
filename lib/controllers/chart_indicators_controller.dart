import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/model/active_chart_indicator.dart';

/// State indikator teknikal di halaman chart TradingView (saham & IHSG).
///
/// [indicators] selalu diganti instance list baru setiap ada perubahan,
/// supaya perbandingan old/new widget di `TvChartWidget` tetap akurat.
class ChartIndicatorsController extends ChangeNotifier {
  static const int _defaultSmaPeriod = 20;
  static const int _defaultRsiPeriod = 14;

  List<ActiveChartIndicator> _indicators = const <ActiveChartIndicator>[];
  String? _selectedId;
  final Set<String> _favorites = <String>{
    'Moving Average',
    'Relative Strength Index',
    'Volume',
  };

  List<ActiveChartIndicator> get indicators => _indicators;
  int get count => _indicators.length;

  /// Id indikator yang sedang terseleksi di legend chart.
  String? get selectedId => _selectedId;

  Set<String> get favorites => UnmodifiableSetView<String>(_favorites);

  bool hasType(String type) =>
      _indicators.any((ActiveChartIndicator i) => i.type == type);

  bool isTypeVisible(String type) => _indicators.any(
    (ActiveChartIndicator i) => i.type == type && i.isVisible,
  );

  ActiveChartIndicator? findById(String id) {
    final int index = _indexOf(id);
    return index == -1 ? null : _indicators[index];
  }

  /// Tambah indikator baru dengan setting default. Tipe yang belum didukung diabaikan.
  void add(String type) {
    final ActiveChartIndicator? created = _createDefault(type);
    if (created == null) return;
    _indicators = List<ActiveChartIndicator>.unmodifiable(
      <ActiveChartIndicator>[..._indicators, created],
    );
    notifyListeners();
  }

  void update(ActiveChartIndicator indicator) {
    final int index = _indexOf(indicator.id);
    if (index == -1) return;
    _replaceAt(index, indicator);
  }

  void toggleVisibility(String id) {
    final int index = _indexOf(id);
    if (index == -1) return;
    final ActiveChartIndicator current = _indicators[index];
    _replaceAt(index, current.copyWith(isVisible: !current.isVisible));
  }

  void remove(String id) {
    final int index = _indexOf(id);
    if (index == -1) return;
    _indicators = List<ActiveChartIndicator>.unmodifiable(
      <ActiveChartIndicator>[
        ..._indicators.take(index),
        ..._indicators.skip(index + 1),
      ],
    );
    if (_selectedId == id) _selectedId = null;
    notifyListeners();
  }

  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  /// Favorit hanya dibaca saat sheet indikator dibuka, jadi tidak perlu memicu rebuild chart.
  void toggleFavorite(String name) {
    if (!_favorites.remove(name)) _favorites.add(name);
  }

  int _indexOf(String id) =>
      _indicators.indexWhere((ActiveChartIndicator i) => i.id == id);

  void _replaceAt(int index, ActiveChartIndicator indicator) {
    _indicators = List<ActiveChartIndicator>.unmodifiable(
      <ActiveChartIndicator>[..._indicators]..[index] = indicator,
    );
    notifyListeners();
  }

  ActiveChartIndicator? _createDefault(String type) {
    final int sameTypeCount = _indicators
        .where((ActiveChartIndicator i) => i.type == type)
        .length;
    final String suffix = sameTypeCount > 0 ? ' ${sameTypeCount + 1}' : '';
    final String id = '${type}_${DateTime.now().microsecondsSinceEpoch}';

    return switch (type) {
      'sma' => ActiveChartIndicator(
        id: id,
        type: type,
        title: 'SMA $_defaultSmaPeriod close$suffix',
        period: _defaultSmaPeriod,
      ),
      'rsi' => ActiveChartIndicator(
        id: id,
        type: type,
        title: 'RSI $_defaultRsiPeriod close$suffix',
        period: _defaultRsiPeriod,
      ),
      'vol' => ActiveChartIndicator(id: id, type: type, title: 'Vol$suffix'),
      _ => null,
    };
  }
}
