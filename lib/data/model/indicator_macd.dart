import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../utils/css_color.dart';
import 'indicator_level.dart';
import 'indicator_line_style.dart';

/// Arah batang histogram MACD; nama sama dengan key warna yang dikirim/diterima chart.
enum MacdTrend { growAbove, fallAbove, growBelow, fallBelow }

/// Histogram MACD: visibilitas + warna per [MacdTrend] (default TradingView).
@immutable
class MacdHistogramStyle {
  final bool isVisible;
  final Color growAbove;
  final Color fallAbove;
  final Color growBelow;
  final Color fallBelow;

  const MacdHistogramStyle({
    this.isVisible = true,
    this.growAbove = const Color(0xFF26A69A),
    this.fallAbove = const Color(0xFFB2DFDB),
    this.growBelow = const Color(0xFFFFCDD2),
    this.fallBelow = const Color(0xFFFF5252),
  });

  Color colorOf(MacdTrend trend) => switch (trend) {
    MacdTrend.growAbove => growAbove,
    MacdTrend.fallAbove => fallAbove,
    MacdTrend.growBelow => growBelow,
    MacdTrend.fallBelow => fallBelow,
  };

  MacdHistogramStyle copyWith({
    bool? isVisible,
    Color? growAbove,
    Color? fallAbove,
    Color? growBelow,
    Color? fallBelow,
  }) => MacdHistogramStyle(
    isVisible: isVisible ?? this.isVisible,
    growAbove: growAbove ?? this.growAbove,
    fallAbove: fallAbove ?? this.fallAbove,
    growBelow: growBelow ?? this.growBelow,
    fallBelow: fallBelow ?? this.fallBelow,
  );

  /// Ganti satu warna sesuai [trend].
  MacdHistogramStyle withColor(MacdTrend trend, Color color) => switch (trend) {
    MacdTrend.growAbove => copyWith(growAbove: color),
    MacdTrend.fallAbove => copyWith(fallAbove: color),
    MacdTrend.growBelow => copyWith(growBelow: color),
    MacdTrend.fallBelow => copyWith(fallBelow: color),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacdHistogramStyle &&
          isVisible == other.isVisible &&
          growAbove == other.growAbove &&
          fallAbove == other.fallAbove &&
          growBelow == other.growBelow &&
          fallBelow == other.fallBelow;

  @override
  int get hashCode =>
      Object.hash(isVisible, growAbove, fallAbove, growBelow, fallBelow);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'isVisible': isVisible,
    'colors': <String, String>{
      for (final MacdTrend trend in MacdTrend.values)
        trend.name: colorOf(trend).toCssRgba(),
    },
  };
}

/// Input & style khusus MACD. Garis MACD sendiri memakai style utama indikator
/// (color, lineWidth, lineStyle, isLineVisible), source memakai `source` indikator.
@immutable
class MacdSettings {
  static const List<String> maTypes = <String>['EMA', 'SMA'];

  final int fastLength;
  final int slowLength;
  final int signalLength;
  final String oscillatorMaType;
  final String signalMaType;
  final MacdHistogramStyle histogram;
  final IndicatorLineStyle signalStyle;
  final IndicatorLevel zeroLine;

  const MacdSettings({
    this.fastLength = 12,
    this.slowLength = 26,
    this.signalLength = 9,
    this.oscillatorMaType = 'EMA',
    this.signalMaType = 'EMA',
    this.histogram = const MacdHistogramStyle(),
    this.signalStyle = const IndicatorLineStyle(color: Color(0xFFFF6D00)),
    this.zeroLine = const IndicatorLevel(
      value: 0,
      style: IndicatorLineStyle(color: Color(0x80787B86)),
    ),
  });

  MacdSettings copyWith({
    int? fastLength,
    int? slowLength,
    int? signalLength,
    String? oscillatorMaType,
    String? signalMaType,
    MacdHistogramStyle? histogram,
    IndicatorLineStyle? signalStyle,
    IndicatorLevel? zeroLine,
  }) => MacdSettings(
    fastLength: fastLength ?? this.fastLength,
    slowLength: slowLength ?? this.slowLength,
    signalLength: signalLength ?? this.signalLength,
    oscillatorMaType: oscillatorMaType ?? this.oscillatorMaType,
    signalMaType: signalMaType ?? this.signalMaType,
    histogram: histogram ?? this.histogram,
    signalStyle: signalStyle ?? this.signalStyle,
    zeroLine: zeroLine ?? this.zeroLine,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacdSettings &&
          fastLength == other.fastLength &&
          slowLength == other.slowLength &&
          signalLength == other.signalLength &&
          oscillatorMaType == other.oscillatorMaType &&
          signalMaType == other.signalMaType &&
          histogram == other.histogram &&
          signalStyle == other.signalStyle &&
          zeroLine == other.zeroLine;

  @override
  int get hashCode => Object.hash(
    fastLength,
    slowLength,
    signalLength,
    oscillatorMaType,
    signalMaType,
    histogram,
    signalStyle,
    zeroLine,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fastLength': fastLength,
    'slowLength': slowLength,
    'signalLength': signalLength,
    'oscillatorMaType': oscillatorMaType,
    'signalMaType': signalMaType,
    'histogram': histogram.toJson(),
    'signalStyle': signalStyle.toJson(),
    'zeroLine': zeroLine.toJson(),
  };
}
