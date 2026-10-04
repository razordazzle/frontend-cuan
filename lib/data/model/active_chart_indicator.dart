import 'package:flutter/material.dart';

import 'indicator_line_style.dart';

/// Nilai plot indikator per id indikator (mis. SMA: [MA, Smoothing MA]); null = tidak ada nilai.
typedef IndicatorPlotValues = Map<String, List<double?>>;

class ActiveChartIndicator {
  /// Jumlah desimal saat precision = 'Default'.
  static const int defaultPrecisionDigits = 2;
  static const IndicatorLineStyle defaultSmoothingStyle = IndicatorLineStyle(
    color: Color(0xFFFFEB3B),
  );

  final String id;
  final String type; // 'sma', 'rsi', 'vol'
  String title;
  bool isVisible;
  int? _period;
  Color? color;

  int get period => _period ?? 20;
  set period(int val) => _period = val;

  int? _lineWidth;
  int? _lineStyle; // 0: solid, 1: dashed, 2: dotted
  String? _source; // 'Close', 'Open', 'High', 'Low', 'HL2', 'HLC3', 'OHLC4'
  int? _offset;
  String? _smoothingType; // 'None', 'SMA', 'EMA', 'RMA', 'WMA', 'VWMA'
  int? _smoothingLength;
  IndicatorLineStyle? _smoothingStyle;
  double? _bbStdDev;
  String? _precision; // 'Default', '0', '1', etc.
  bool? _labelsOnPriceScale;
  bool? _valuesInStatusLine;
  bool? _inputsInStatusLine;
  String? _plotType; // 'Line', 'Line with breaks', 'Step line', etc.
  bool? _priceLine;

  int get lineWidth => _lineWidth ?? 2;
  set lineWidth(int val) => _lineWidth = val;

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

  ActiveChartIndicator({
    required this.id,
    required this.type,
    required this.title,
    this.isVisible = true,
    int? period,
    this.color,
    int? lineWidth,
    int? lineStyle,
    String? source,
    int? offset,
    String? smoothingType,
    int? smoothingLength,
    IndicatorLineStyle? smoothingStyle,
    double? bbStdDev,
    String? precision,
    bool? labelsOnPriceScale,
    bool? valuesInStatusLine,
    bool? inputsInStatusLine,
    String? plotType,
    bool? priceLine,
  }) : _period = period ?? 20,
       _lineWidth = lineWidth ?? 2,
       _lineStyle = lineStyle ?? 0,
       _source = source ?? 'Close',
       _offset = offset ?? 0,
       _smoothingType = smoothingType ?? 'None',
       _smoothingLength = smoothingLength ?? 14,
       _smoothingStyle = smoothingStyle ?? defaultSmoothingStyle,
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
    int? lineStyle,
    String? source,
    int? offset,
    String? smoothingType,
    int? smoothingLength,
    IndicatorLineStyle? smoothingStyle,
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
      lineStyle: lineStyle ?? this.lineStyle,
      source: source ?? this.source,
      offset: offset ?? this.offset,
      smoothingType: smoothingType ?? this.smoothingType,
      smoothingLength: smoothingLength ?? this.smoothingLength,
      smoothingStyle: smoothingStyle ?? this.smoothingStyle,
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
          lineStyle == other.lineStyle &&
          source == other.source &&
          offset == other.offset &&
          smoothingType == other.smoothingType &&
          smoothingLength == other.smoothingLength &&
          smoothingStyle == other.smoothingStyle &&
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
    lineStyle,
    source,
    offset,
    smoothingType,
    smoothingLength,
    smoothingStyle,
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
  };
}
