import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../utils/css_color.dart';
import 'indicator_line_style.dart';

/// Garis level horizontal di pane indikator (mis. RSI 70 / 50 / 30).
@immutable
class IndicatorLevel {
  final double value;
  final IndicatorLineStyle style;

  const IndicatorLevel({required this.value, required this.style});

  IndicatorLevel copyWith({double? value, IndicatorLineStyle? style}) =>
      IndicatorLevel(value: value ?? this.value, style: style ?? this.style);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicatorLevel && value == other.value && style == other.style;

  @override
  int get hashCode => Object.hash(value, style);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'value': value,
    ...style.toJson(),
  };
}

/// Warna isian area (mis. background di antara level atas & bawah RSI).
@immutable
class IndicatorFill {
  final Color color;
  final bool isVisible;

  const IndicatorFill({required this.color, this.isVisible = true});

  IndicatorFill copyWith({Color? color, bool? isVisible}) => IndicatorFill(
    color: color ?? this.color,
    isVisible: isVisible ?? this.isVisible,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicatorFill &&
          color == other.color &&
          isVisible == other.isVisible;

  @override
  int get hashCode => Object.hash(color, isVisible);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'color': color.toCssRgba(),
    'isVisible': isVisible,
  };
}

/// Isian gradien vertikal (mis. area overbought/oversold RSI), dari [topColor] ke [bottomColor].
@immutable
class IndicatorGradientFill {
  final Color topColor;
  final Color bottomColor;
  final bool isVisible;

  const IndicatorGradientFill({
    required this.topColor,
    required this.bottomColor,
    this.isVisible = true,
  });

  IndicatorGradientFill copyWith({
    Color? topColor,
    Color? bottomColor,
    bool? isVisible,
  }) => IndicatorGradientFill(
    topColor: topColor ?? this.topColor,
    bottomColor: bottomColor ?? this.bottomColor,
    isVisible: isVisible ?? this.isVisible,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicatorGradientFill &&
          topColor == other.topColor &&
          bottomColor == other.bottomColor &&
          isVisible == other.isVisible;

  @override
  int get hashCode => Object.hash(topColor, bottomColor, isVisible);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'topColor': topColor.toCssRgba(),
    'bottomColor': bottomColor.toCssRgba(),
    'isVisible': isVisible,
  };
}
