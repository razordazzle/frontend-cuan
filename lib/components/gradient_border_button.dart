import 'dart:math' as math;

import 'package:flutter/material.dart';

class GradientBorderButton extends StatelessWidget {
  final String label;
  final Gradient borderGradient; // gradasi di tepi (border)
  final Gradient backgroundGradient; // gradasi isi tombol
  final TextStyle? textStyle;
  final VoidCallback? onPressed;
  final double height;
  final double radius; // radius luar
  final double borderThickness; // ketebalan border
  final bool shadow;
  final Color? shadowColor;

  const GradientBorderButton({
    super.key,
    required this.label,
    required this.borderGradient,
    required this.backgroundGradient,
    this.textStyle,
    this.onPressed,
    this.height = 52,
    this.radius = 30,
    this.borderThickness = 1.5,
    this.shadow = true,this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final double innerRadius = math.max(0.0, radius - borderThickness);
    final bool useShadow = shadow && (shadowColor ?? Colors.black).alpha > 0;

     final child = Container(
      height: height,
      decoration: BoxDecoration(
        gradient: borderGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: useShadow
            ? [
                BoxShadow(
                  color: shadowColor ??
                      (Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withValues(alpha: .25)
                          : Colors.black.withValues(alpha: .12)),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(borderThickness),
        child: Container(
          decoration: BoxDecoration(
            gradient: backgroundGradient,
            borderRadius: BorderRadius.circular(innerRadius),
          ),
          alignment: Alignment.center,
          child: Text(label, style: textStyle),
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onPressed,
        child: child,
      ),
    );
  }
}
