import 'package:flutter/material.dart';

const double kFieldRadius = 12.0;

/// InputDecoration yang theme-aware (light = filled putih, dark = outline).
InputDecoration formDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  Widget? prefix,
  Widget? suffix,
  bool? filledOverride, // kalau mau paksa filled = true/false
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final isLight = theme.brightness == Brightness.light;
  final filled = filledOverride ?? isLight;

  return InputDecoration(
    labelText: label,
    hintText: hint ?? label,
    filled: filled,
    fillColor: filled ? Colors.white : null,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    prefixIcon: prefix,
    suffixIcon: suffix,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kFieldRadius),
      borderSide: BorderSide(
        color: cs.outline.withValues(alpha: filled ? .45 : .30),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kFieldRadius),
      borderSide: BorderSide(color: cs.primary, width: 1.6),
    ),
  );
}

Color softShadowColor(BuildContext context, {double light = .12, double dark = .25}) {
  final isLight = Theme.of(context).brightness == Brightness.light;
  return Colors.black.withValues(alpha: isLight ? light : dark);
}