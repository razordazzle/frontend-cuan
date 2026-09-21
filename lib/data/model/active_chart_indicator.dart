import 'package:flutter/material.dart';

class ActiveChartIndicator {
  final String id;
  final String type; // 'sma', 'rsi', 'vol'
  String title;
  bool isVisible;
  int period;
  Color? color;

  ActiveChartIndicator({
    required this.id,
    required this.type,
    required this.title,
    this.isVisible = true,
    this.period = 20,
    this.color,
  });

  ActiveChartIndicator copyWith({
    String? id,
    String? type,
    String? title,
    bool? isVisible,
    int? period,
    Color? color,
  }) {
    return ActiveChartIndicator(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      isVisible: isVisible ?? this.isVisible,
      period: period ?? this.period,
      color: color ?? this.color,
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
          color == other.color;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      title.hashCode ^
      isVisible.hashCode ^
      period.hashCode ^
      color.hashCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'title': title,
        'isVisible': isVisible,
        'period': period,
        'color': color != null
            ? '#${(color!.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
            : null,
      };
}
