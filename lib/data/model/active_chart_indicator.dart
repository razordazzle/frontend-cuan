import 'package:flutter/material.dart';

import '../../utils/css_color.dart';
import 'indicator_level.dart';
import 'indicator_line_style.dart';

/// Nilai plot indikator per id indikator (mis. SMA: [MA, Smoothing MA]); null = tidak ada nilai.
typedef IndicatorPlotValues = Map<String, List<double?>>;

class ActiveChartIndicator {
  /// Jumlah desimal saat precision = 'Default'.
  static const int defaultPrecisionDigits = 2;
  static const IndicatorLineStyle defaultSmoothingStyle = IndicatorLineStyle(
    color: Color(0xFFFFEB3B),
  );

  // Default RSI mengikuti TradingView.
  static const Color _defaultLevelColor = Color(0xFF787B86);
  static const IndicatorLevel defaultUpperLevel = IndicatorLevel(
    value: 70,
    style: IndicatorLineStyle(color: _defaultLevelColor, lineStyle: 1),
  );
  static const IndicatorLevel defaultMiddleLevel = IndicatorLevel(
    value: 50,
    style: IndicatorLineStyle(color: Color(0x80787B86), lineStyle: 1),
  );
  static const IndicatorLevel defaultLowerLevel = IndicatorLevel(
    value: 30,
    style: IndicatorLineStyle(color: _defaultLevelColor, lineStyle: 1),
  );
  static const IndicatorFill defaultBandsFill = IndicatorFill(
    color: Color(0x1A7E57C2),
  );
  static const IndicatorGradientFill defaultOverboughtFill =
      IndicatorGradientFill(
        topColor: Color(0xFF4CAF50),
        bottomColor: Color(0x004CAF50),
      );
  static const IndicatorGradientFill defaultOversoldFill =
      IndicatorGradientFill(
        topColor: Color(0x00F23645),
        bottomColor: Color(0xFFF23645),
      );
  static const IndicatorLineStyle defaultBollingerStyle = IndicatorLineStyle(
    color: Color(0xFF4CAF50),
  );

  // Default Volume: warna naik/turun tema app dengan opacity 50%.
  static const Color defaultVolumeGrowingColor = Color(0x8021C07A);
  static const Color defaultVolumeFallingColor = Color(0x80E53935);

  /// Tipe smoothing yang menambah Bollinger Bands di sekitar garis MA (khusus RSI).
  static const String bollingerSmoothingType = 'SMA + Bollinger Bands';

  final String id;
  final String type; // 'sma', 'rsi', 'vol'
  String title;
  bool isVisible;
  int? _period;
  Color? color;

  int get period => _period ?? 20;
  set period(int val) => _period = val;

  int? _lineWidth;
  bool? _isLineVisible;
  int? _lineStyle; // 0: solid, 1: dashed, 2: dotted
  String? _source; // 'Close', 'Open', 'High', 'Low', 'HL2', 'HLC3', 'OHLC4'
  int? _offset;
  String? _smoothingType; // 'None', 'SMA', 'EMA', 'RMA', 'WMA', 'VWMA'
  int? _smoothingLength;
  IndicatorLineStyle? _smoothingStyle;
  IndicatorLevel? _upperLevel;
  IndicatorLevel? _middleLevel;
  IndicatorLevel? _lowerLevel;
  IndicatorFill? _bandsFill;
  IndicatorGradientFill? _overboughtFill;
  IndicatorGradientFill? _oversoldFill;
  IndicatorLineStyle? _bollingerStyle;
  Color? _volumeGrowingColor;
  Color? _volumeFallingColor;
  bool? _colorByPreviousClose;
  double? _bbStdDev;
  String? _precision; // 'Default', '0', '1', etc.
  bool? _labelsOnPriceScale;
  bool? _valuesInStatusLine;
  bool? _inputsInStatusLine;
  String? _plotType; // 'Line', 'Line with breaks', 'Step line', etc.
  bool? _priceLine;

  int get lineWidth => _lineWidth ?? 2;
  set lineWidth(int val) => _lineWidth = val;

  /// Visibilitas garis utama saja (checkbox di tab Style); [isVisible] = seluruh indikator.
  bool get isLineVisible => _isLineVisible ?? true;
  set isLineVisible(bool val) => _isLineVisible = val;

  int get lineStyle => _lineStyle ?? 0;
  set lineStyle(int val) => _lineStyle = val;

  String get source => _source ?? 'Close';
  set source(String val) => _source = val;

  int get offset => _offset ?? 0;
  set offset(int val) => _offset = val;

  String get smoothingType => _smoothingType ?? 'None';
  set smoothingType(String val) => _smoothingType = val;

  int get smoothingLength => _smoothingLength ?? 14;
  set smoothingLength(int val) => _smoothingLength = val;

  IndicatorLineStyle get smoothingStyle =>
      _smoothingStyle ?? defaultSmoothingStyle;
  set smoothingStyle(IndicatorLineStyle val) => _smoothingStyle = val;

  bool get hasSmoothing => smoothingType != 'None';
  bool get hasBollingerBands => smoothingType == bollingerSmoothingType;

  IndicatorLevel get upperLevel => _upperLevel ?? defaultUpperLevel;
  set upperLevel(IndicatorLevel val) => _upperLevel = val;

  IndicatorLevel get middleLevel => _middleLevel ?? defaultMiddleLevel;
  set middleLevel(IndicatorLevel val) => _middleLevel = val;

  IndicatorLevel get lowerLevel => _lowerLevel ?? defaultLowerLevel;
  set lowerLevel(IndicatorLevel val) => _lowerLevel = val;

  /// Isian background di antara level atas & bawah.
  IndicatorFill get bandsFill => _bandsFill ?? defaultBandsFill;
  set bandsFill(IndicatorFill val) => _bandsFill = val;

  /// Gradien di antara garis RSI & level atas saat RSI di atas level atas.
  IndicatorGradientFill get overboughtFill =>
      _overboughtFill ?? defaultOverboughtFill;
  set overboughtFill(IndicatorGradientFill val) => _overboughtFill = val;

  /// Gradien di antara garis RSI & level bawah saat RSI di bawah level bawah.
  IndicatorGradientFill get oversoldFill =>
      _oversoldFill ?? defaultOversoldFill;
  set oversoldFill(IndicatorGradientFill val) => _oversoldFill = val;

  IndicatorLineStyle get bollingerStyle =>
      _bollingerStyle ?? defaultBollingerStyle;
  set bollingerStyle(IndicatorLineStyle val) => _bollingerStyle = val;

  /// Warna batang volume saat naik / turun.
  Color get volumeGrowingColor =>
      _volumeGrowingColor ?? defaultVolumeGrowingColor;
  set volumeGrowingColor(Color val) => _volumeGrowingColor = val;

  Color get volumeFallingColor =>
      _volumeFallingColor ?? defaultVolumeFallingColor;
  set volumeFallingColor(Color val) => _volumeFallingColor = val;

  /// True: arah batang dibanding close sebelumnya; false: dibanding open bar yang sama.
  bool get colorByPreviousClose => _colorByPreviousClose ?? false;
  set colorByPreviousClose(bool val) => _colorByPreviousClose = val;

  double get bbStdDev => _bbStdDev ?? 2.0;
  set bbStdDev(double val) => _bbStdDev = val;

  String get precision => _precision ?? 'Default';
  set precision(String val) => _precision = val;

  /// Jumlah desimal nilai indikator di price scale & status line.
  int get precisionDigits => int.tryParse(precision) ?? defaultPrecisionDigits;

  bool get labelsOnPriceScale => _labelsOnPriceScale ?? false;
  set labelsOnPriceScale(bool val) => _labelsOnPriceScale = val;

  bool get valuesInStatusLine => _valuesInStatusLine ?? true;
  set valuesInStatusLine(bool val) => _valuesInStatusLine = val;

  bool get inputsInStatusLine => _inputsInStatusLine ?? true;
  set inputsInStatusLine(bool val) => _inputsInStatusLine = val;

  String get plotType => _plotType ?? 'Line';
  set plotType(String val) => _plotType = val;

  bool get priceLine => _priceLine ?? false;
  set priceLine(bool val) => _priceLine = val;

  /// Nama indikator tanpa input (dipakai di status line saat inputs disembunyikan).
  String get shortTitle => switch (type) {
    'sma' => 'SMA',
    'rsi' => 'RSI',
    'vol' => 'Vol',
    _ => title,
  };

  /// Judul dengan input utama, mis. "SMA 20 close" / "RSI 14 close".
  /// Input smoothing sengaja tidak dimasukkan supaya legend tetap ringkas.
  String get inputsTitle => switch (type) {
    'sma' || 'rsi' => '$shortTitle $period ${source.toLowerCase()}',
    _ => shortTitle,
  };

  ActiveChartIndicator({
    required this.id,
    required this.type,
    required this.title,
    this.isVisible = true,
    int? period,
    this.color,
    int? lineWidth,
    bool? isLineVisible,
    int? lineStyle,
    String? source,
    int? offset,
    String? smoothingType,
    int? smoothingLength,
    IndicatorLineStyle? smoothingStyle,
    IndicatorLevel? upperLevel,
    IndicatorLevel? middleLevel,
    IndicatorLevel? lowerLevel,
    IndicatorFill? bandsFill,
    IndicatorGradientFill? overboughtFill,
    IndicatorGradientFill? oversoldFill,
    IndicatorLineStyle? bollingerStyle,
    Color? volumeGrowingColor,
    Color? volumeFallingColor,
    bool? colorByPreviousClose,
    double? bbStdDev,
    String? precision,
    bool? labelsOnPriceScale,
    bool? valuesInStatusLine,
    bool? inputsInStatusLine,
    String? plotType,
    bool? priceLine,
  }) : _period = period ?? 20,
       _isLineVisible = isLineVisible ?? true,
       _lineWidth = lineWidth ?? 2,
       _lineStyle = lineStyle ?? 0,
       _source = source ?? 'Close',
       _offset = offset ?? 0,
       _smoothingType = smoothingType ?? 'None',
       _smoothingLength = smoothingLength ?? 14,
       _smoothingStyle = smoothingStyle ?? defaultSmoothingStyle,
       _upperLevel = upperLevel ?? defaultUpperLevel,
       _middleLevel = middleLevel ?? defaultMiddleLevel,
       _lowerLevel = lowerLevel ?? defaultLowerLevel,
       _bandsFill = bandsFill ?? defaultBandsFill,
       _overboughtFill = overboughtFill ?? defaultOverboughtFill,
       _oversoldFill = oversoldFill ?? defaultOversoldFill,
       _bollingerStyle = bollingerStyle ?? defaultBollingerStyle,
       _volumeGrowingColor = volumeGrowingColor ?? defaultVolumeGrowingColor,
       _volumeFallingColor = volumeFallingColor ?? defaultVolumeFallingColor,
       _colorByPreviousClose = colorByPreviousClose ?? false,
       _bbStdDev = bbStdDev ?? 2.0,
       _precision = precision ?? 'Default',
       _labelsOnPriceScale = labelsOnPriceScale ?? false,
       _valuesInStatusLine = valuesInStatusLine ?? true,
       _inputsInStatusLine = inputsInStatusLine ?? true,
       _plotType = plotType ?? 'Line',
       _priceLine = priceLine ?? false;

  ActiveChartIndicator copyWith({
    String? id,
    String? type,
    String? title,
    bool? isVisible,
    int? period,
    Color? color,
    int? lineWidth,
    bool? isLineVisible,
    int? lineStyle,
    String? source,
    int? offset,
    String? smoothingType,
    int? smoothingLength,
    IndicatorLineStyle? smoothingStyle,
    IndicatorLevel? upperLevel,
    IndicatorLevel? middleLevel,
    IndicatorLevel? lowerLevel,
    IndicatorFill? bandsFill,
    IndicatorGradientFill? overboughtFill,
    IndicatorGradientFill? oversoldFill,
    IndicatorLineStyle? bollingerStyle,
    Color? volumeGrowingColor,
    Color? volumeFallingColor,
    bool? colorByPreviousClose,
    double? bbStdDev,
    String? precision,
    bool? labelsOnPriceScale,
    bool? valuesInStatusLine,
    bool? inputsInStatusLine,
    String? plotType,
    bool? priceLine,
  }) {
    return ActiveChartIndicator(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      isVisible: isVisible ?? this.isVisible,
      period: period ?? this.period,
      color: color ?? this.color,
      lineWidth: lineWidth ?? this.lineWidth,
      isLineVisible: isLineVisible ?? this.isLineVisible,
      lineStyle: lineStyle ?? this.lineStyle,
      source: source ?? this.source,
      offset: offset ?? this.offset,
      smoothingType: smoothingType ?? this.smoothingType,
      smoothingLength: smoothingLength ?? this.smoothingLength,
      smoothingStyle: smoothingStyle ?? this.smoothingStyle,
      upperLevel: upperLevel ?? this.upperLevel,
      middleLevel: middleLevel ?? this.middleLevel,
      lowerLevel: lowerLevel ?? this.lowerLevel,
      bandsFill: bandsFill ?? this.bandsFill,
      overboughtFill: overboughtFill ?? this.overboughtFill,
      oversoldFill: oversoldFill ?? this.oversoldFill,
      bollingerStyle: bollingerStyle ?? this.bollingerStyle,
      volumeGrowingColor: volumeGrowingColor ?? this.volumeGrowingColor,
      volumeFallingColor: volumeFallingColor ?? this.volumeFallingColor,
      colorByPreviousClose: colorByPreviousClose ?? this.colorByPreviousClose,
      bbStdDev: bbStdDev ?? this.bbStdDev,
      precision: precision ?? this.precision,
      labelsOnPriceScale: labelsOnPriceScale ?? this.labelsOnPriceScale,
      valuesInStatusLine: valuesInStatusLine ?? this.valuesInStatusLine,
      inputsInStatusLine: inputsInStatusLine ?? this.inputsInStatusLine,
      plotType: plotType ?? this.plotType,
      priceLine: priceLine ?? this.priceLine,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveChartIndicator &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          title == other.title &&
          isVisible == other.isVisible &&
          period == other.period &&
          color == other.color &&
          lineWidth == other.lineWidth &&
          isLineVisible == other.isLineVisible &&
          lineStyle == other.lineStyle &&
          source == other.source &&
          offset == other.offset &&
          smoothingType == other.smoothingType &&
          smoothingLength == other.smoothingLength &&
          smoothingStyle == other.smoothingStyle &&
          upperLevel == other.upperLevel &&
          middleLevel == other.middleLevel &&
          lowerLevel == other.lowerLevel &&
          bandsFill == other.bandsFill &&
          overboughtFill == other.overboughtFill &&
          oversoldFill == other.oversoldFill &&
          bollingerStyle == other.bollingerStyle &&
          volumeGrowingColor == other.volumeGrowingColor &&
          volumeFallingColor == other.volumeFallingColor &&
          colorByPreviousClose == other.colorByPreviousClose &&
          bbStdDev == other.bbStdDev &&
          precision == other.precision &&
          labelsOnPriceScale == other.labelsOnPriceScale &&
          valuesInStatusLine == other.valuesInStatusLine &&
          inputsInStatusLine == other.inputsInStatusLine &&
          plotType == other.plotType &&
          priceLine == other.priceLine;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    type,
    title,
    isVisible,
    period,
    color,
    lineWidth,
    isLineVisible,
    lineStyle,
    source,
    offset,
    smoothingType,
    smoothingLength,
    smoothingStyle,
    upperLevel,
    middleLevel,
    lowerLevel,
    bandsFill,
    overboughtFill,
    oversoldFill,
    bollingerStyle,
    volumeGrowingColor,
    volumeFallingColor,
    colorByPreviousClose,
    bbStdDev,
    precision,
    labelsOnPriceScale,
    valuesInStatusLine,
    inputsInStatusLine,
    plotType,
    priceLine,
  ]);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type,
    'title': title,
    'isVisible': isVisible,
    'period': period,
    'color': color?.toCssRgba(),
    'lineWidth': lineWidth,
    'isLineVisible': isLineVisible,
    'lineStyle': lineStyle,
    'source': source,
    'offset': offset,
    'smoothingType': smoothingType,
    'smoothingLength': smoothingLength,
    'smoothingStyle': smoothingStyle.toJson(),
    'bbStdDev': bbStdDev,
    'precisionDigits': precisionDigits,
    'labelsOnPriceScale': labelsOnPriceScale,
    'plotType': plotType,
    'priceLine': priceLine,
    if (type == 'rsi') ...<String, dynamic>{
      'levels': <String, dynamic>{
        'upper': upperLevel.toJson(),
        'middle': middleLevel.toJson(),
        'lower': lowerLevel.toJson(),
      },
      'bandsFill': bandsFill.toJson(),
      'overboughtFill': overboughtFill.toJson(),
      'oversoldFill': oversoldFill.toJson(),
      'bollingerStyle': bollingerStyle.toJson(),
    },
    if (type == 'vol') ...<String, dynamic>{
      'volume': <String, dynamic>{
        'growingColor': volumeGrowingColor.toCssRgba(),
        'fallingColor': volumeFallingColor.toCssRgba(),
        'colorByPreviousClose': colorByPreviousClose,
      },
    },
  };
}
