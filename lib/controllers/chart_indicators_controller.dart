import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../data/model/active_chart_indicator.dart';
import '../data/model/indicator_line_style.dart';

/// State indikator teknikal di halaman chart TradingView (saham & IHSG).
///
/// [indicators] selalu diganti instance list baru setiap ada perubahan,
/// supaya perbandingan old/new widget di `TvChartWidget` tetap akurat.
class ChartIndicatorsController extends ChangeNotifier {
  static const int _defaultSmaPeriod = 20;
  static const int _defaultRsiPeriod = 14;
  static const int _defaultRsiSmoothingLength = 14;
  static const List<Color> _smaPalette = <Color>[
    Color(0xFF2962FF),
    Color(0xFFFF6D00),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFFFFD600),
  ];
  static const Color _defaultRsiColor = Color(0xFFE91E63);
  static const int _defaultVolumeMaLength = 20;

  /// Garis Volume MA default biru & tersembunyi (volume tampil seperti sebelumnya).
  static const IndicatorLineStyle _defaultVolumeMaStyle = IndicatorLineStyle(
    color: Color(0xFF2962FF),
    isVisible: false,
  );

  /// Nilai plot terkini dari chart (ikut crosshair). Dipisah dari [notifyListeners]
  /// karena update-nya sangat sering dan cukup me-rebuild legend saja.
  final ValueNotifier<IndicatorPlotValues> plotValues =
      ValueNotifier<IndicatorPlotValues>(const <String, List<double?>>{});

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

  @override
  void dispose() {
    plotValues.dispose();
    super.dispose();
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

    final ActiveChartIndicator? created = switch (type) {
      'sma' => ActiveChartIndicator(
        id: id,
        type: type,
        title: '',
        period: _defaultSmaPeriod,
        color: _smaPalette[sameTypeCount % _smaPalette.length],
      ),
      // Default RSI ala TradingView: RSI-based MA (SMA 14) aktif & label nilai di price scale.
      'rsi' => ActiveChartIndicator(
        id: id,
        type: type,
        title: '',
        period: _defaultRsiPeriod,
        color: _defaultRsiColor,
        smoothingType: 'SMA',
        smoothingLength: _defaultRsiSmoothingLength,
        labelsOnPriceScale: true,
      ),
      'vol' => ActiveChartIndicator(
        id: id,
        type: type,
        title: '',
        period: _defaultVolumeMaLength,
        smoothingStyle: _defaultVolumeMaStyle,
        labelsOnPriceScale: true,
      ),
      _ => null,
    };
    return created?.copyWith(title: '${created.inputsTitle}$suffix');
  }
}
