import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../utils/css_color.dart';

/// Style satu garis plot indikator (mis. garis Smoothing MA).
@immutable
class IndicatorLineStyle {
  final Color color;
  final int lineWidth;
  final int lineStyle; // 0: solid, 1: dashed, 2: dotted
  final bool isVisible;

  const IndicatorLineStyle({
    required this.color,
    this.lineWidth = 1,
    this.lineStyle = 0,
    this.isVisible = true,
  });

  IndicatorLineStyle copyWith({
    Color? color,
    int? lineWidth,
    int? lineStyle,
    bool? isVisible,
  }) {
    return IndicatorLineStyle(
      color: color ?? this.color,
      lineWidth: lineWidth ?? this.lineWidth,
      lineStyle: lineStyle ?? this.lineStyle,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicatorLineStyle &&
          color == other.color &&
          lineWidth == other.lineWidth &&
          lineStyle == other.lineStyle &&
          isVisible == other.isVisible;

  @override
  int get hashCode => Object.hash(color, lineWidth, lineStyle, isVisible);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'color': color.toCssRgba(),
    'lineWidth': lineWidth,
    'lineStyle': lineStyle,
    'isVisible': isVisible,
  };
}
